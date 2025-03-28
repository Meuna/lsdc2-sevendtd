#!/bin/bash
export HOME=$LSDC2_HOME
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH

./update-server.sh

# Init the serveradmin.xml file if $ADMIN_STEAMID is provided
if [ -n "$ADMIN_STEAMID" ]; then
    # Create the serveradmin.xml is it does not exists
    admin_file=$SAVES_FOLDER/serveradmin.xml
    if [ ! -f $admin_file ]; then
        mkdir -p $SAVES_FOLDER
        cp serveradmin.xml $admin_file
    fi
    # And give the admin to whoever configured the server
    xmlstarlet ed --inplace \
        -s "/adminTools/users" -t elem -n "user" -v "" \
        -i "/adminTools/users/user[not(@platform)]" -t attr -n "platform" -v "Steam" \
        -i "/adminTools/users/user[not(@userid)]" -t attr -n "userid" -v "$ADMIN_STEAMID" \
        -i "/adminTools/users/user[not(@name)]" -t attr -n "name" -v "LSDC2 Master" \
        -i "/adminTools/users/user[not(@permission_level)]" -t attr -n "permission_level" -v "0" \
        $admin_file
fi

# Edit the configuration file
config_file=serverconfig.xml

server_name=lsdc2
server_description="Le serveur des copains"
server_visibility=1

SERVER_PASS=${SERVER_PASS:-password}

# Try to find if a worldname exists in the GeneratedWorlds folder. If not use the default world
world_name=$(ls $GAME_SAVEDIR/$WORLDS_DIRNAME)
world_name=${world_name:-Navezgane}

# Try to find if a gamename exists in the Saves folder. If not start a new game
game_savename=$(ls $GAME_SAVEDIR/$SAVES_DIRNAME/"$world_name")
game_savename=${game_savename:-lsdc2}

GAME_DAYLENGTH=${GAME_DAYLENGTH:-60}
case "$GAME_DIFFICULTY" in
    Scavenger|scavenger|0) GAME_DIFFICULTY=0;;
    Adventurer|adventurer|1) GAME_DIFFICULTY=1;;
    Nomad|nomad|2) GAME_DIFFICULTY=2;;
    Warrior|warrior|3) GAME_DIFFICULTY=3;;
    Survivalist|survivalist|4) GAME_DIFFICULTY=4;;
    Insane|insane|5) GAME_DIFFICULTY=5;;
    *) GAME_DIFFICULTY=1;;
esac
case "$SERVER_ALLOW_CROSSPLAY" in
    True|Yes|true|yes|1) SERVER_ALLOW_CROSSPLAY=true;;
    *) SERVER_ALLOW_CROSSPLAY=false;;
esac

xmlstarlet ed --inplace \
    -u "/ServerSettings/property[@name='ServerName']/@value" -v "$server_name" \
    -u "/ServerSettings/property[@name='ServerDescription']/@value" -v "$server_description" \
    -u "/ServerSettings/property[@name='ServerPassword']/@value" -v "$SERVER_PASS" \
    -u "/ServerSettings/property[@name='Region']/@value" -v "Europe" \
    -u "/ServerSettings/property[@name='ServerPort']/@value" -v "$GAME_PORT" \
    -u "/ServerSettings/property[@name='ServerVisibility']/@value" -v "$server_visibility" \
    -u "/ServerSettings/property[@name='ServerMaxWorldTransferSpeedKiBs']/@value" -v "1300" \
    -u "/ServerSettings/property[@name='TelnetEnabled']/@value" -v "false" \
    -u "/ServerSettings/property[@name='TerminalWindowEnabled']/@value" -v "false" \
    -u "/ServerSettings/property[@name='ServerAllowCrossplay']/@value" -v "$SERVER_ALLOW_CROSSPLAY" \
    -u "/ServerSettings/property[@name='EACEnabled']/@value" -v "$SERVER_ALLOW_CROSSPLAY" \
    -s "/ServerSettings" -t elem -n "property" -v "" \
        -i "/ServerSettings/property[not(@name)]" -t attr -n "name" -v "UserDataFolder" \
        -i "/ServerSettings/property[not(@value)]" -t attr -n "value" -v "$GAME_SAVEDIR" \
    -u "/ServerSettings/property[@name='GameWorld']/@value" -v "$world_name" \
    -u "/ServerSettings/property[@name='GameName']/@value" -v "$game_savename" \
    -u "/ServerSettings/property[@name='GameDifficulty']/@value" -v "$GAME_DIFFICULTY" \
    -u "/ServerSettings/property[@name='DayNightLength']/@value" -v "$GAME_DAYLENGTH" \
    $config_file

shutdown() {
    kill -INT $pid
}

trap shutdown SIGINT SIGTERM

./7DaysToDieServer.x86_64 -quit -batchmode -nographics -dedicated -configfile=$config_file &
pid=$!
wait $pid
