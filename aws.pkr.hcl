packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  lsdc2-gamename       = "sevendtd"
  lsdc2-user           = "lsdc2"
  lsdc2-home           = "/lsdc2"
  lsdc2-gid            = 2000
  lsdc2-uid            = 2000
  lsdc2-serverwrap-url = "https://github.com/Meuna/lsdc2-serverwrap/releases/download/v0.5.1/serverwrap"
  lsdc2-service        = "lsdc2.service"
  game-savedir         = "/lsdc2/savedir"
  saves-dirname        = "Saves"
  worlds-dirname       = "GeneratedWorlds"
  game-port            = 26900
}

# Source image
source "amazon-ebs" "ubuntu-noble-latest" {
  ami_name            = "lsdc2/images/${local.lsdc2-gamename}"
  spot_instance_types = ["m6a.large", "m6i.large", "m7i-flex.large", "m7i.large", "m5.large", "m5a.large"]
  spot_price          = "0.05"
  tags = {
    "lsdc2.gamename" = "${local.lsdc2-gamename}-ec2"
  }
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    throughput            = 400
    iops                  = 6000
    delete_on_termination = true
  }
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble*24.04*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username          = "ubuntu"
  force_deregister      = true
  force_delete_snapshot = true
}

# Provisionning
build {
  name = "lsdc2/packer/${local.lsdc2-gamename}"
  sources = [
    "source.amazon-ebs.ubuntu-noble-latest"
  ]

  # Provision server packets
  provisioner "shell" {
    inline = [
      "sudo add-apt-repository -y multiverse",
      "sudo dpkg --add-architecture i386",
      "echo steamcmd steam/license note '' | sudo debconf-set-selections",
      "echo steamcmd steam/question select 'I AGREE' | sudo debconf-set-selections",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl xmlstarlet steamcmd",
    ]
  }

  # Provision lsdc2 stack
  provisioner "file" {
    sources     = ["start-server.sh", "update-server.sh", "serveradmin.xml"]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo groupadd -g ${local.lsdc2-gid} -o ${local.lsdc2-user}",
      "sudo useradd -g ${local.lsdc2-gid} -u ${local.lsdc2-uid} -d ${local.lsdc2-home} -o --no-create-home ${local.lsdc2-user}",
      "sudo mkdir -p ${local.lsdc2-home}",
      "sudo mv /tmp/* ${local.lsdc2-home}",
      "sudo chown -R ${local.lsdc2-user}:${local.lsdc2-user} ${local.lsdc2-home}",
      "sudo chmod u+x ${local.lsdc2-home}/*.sh",
      "sudo -u ${local.lsdc2-user} LSDC2_HOME=${local.lsdc2-home} ${local.lsdc2-home}/update-server.sh",
      "sudo rm -rf /${local.lsdc2-home}/Data/Worlds/P*"
    ]
  }

  # Provision LSDC2 service
  provisioner "file" {
    content     = <<EOF
[Unit]
Description=LSDC2 proces
After=network.target

[Service]
User=root
EnvironmentFile=${local.lsdc2-home}/lsdc2.env
ExecStart=serverwrap ${local.lsdc2-home}/start-server.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF
    destination = "/tmp/${local.lsdc2-service}"
  }

  provisioner "file" {
    content     = <<EOF
LSDC2_USER=${local.lsdc2-user}
LSDC2_HOME=${local.lsdc2-home}
LSDC2_UID=${local.lsdc2-uid}
LSDC2_GID=${local.lsdc2-gid}
LSDC2_SNIFF_FILTER="udp dst portrange 26900-26905"
LSDC2_CWD=${local.lsdc2-home}
LSDC2_PERSIST_FILES="${local.saves-dirname};${local.worlds-dirname}"
LSDC2_ZIPFROM=${local.game-savedir}
GAME_SAVEDIR=${local.game-savedir}
WORLDS_DIRNAME=${local.worlds-dirname}
SAVES_DIRNAME=${local.saves-dirname}
GAME_PORT=${local.game-port}
EOF
    destination = "/tmp/lsdc2.env"
  }

  provisioner "shell" {
    inline = [
      "sudo curl -L ${local.lsdc2-serverwrap-url} -o /usr/local/bin/serverwrap",
      "sudo chmod +x /usr/local/bin/serverwrap",
      "sudo mv /tmp/${local.lsdc2-service} /etc/systemd/system/${local.lsdc2-service}",
      "sudo mv /tmp/lsdc2.env ${local.lsdc2-home}/lsdc2.env",
      "sudo chown root:root ${local.lsdc2-home}/lsdc2.env",
    ]
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /root/.steam /var/lib/apt/lists/* /tmp/* /var/tmp/*",
      "sudo find / -name authorized_keys -exec rm -f {} \\;"
    ]
  }

}
