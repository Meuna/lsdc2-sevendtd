FROM docker.io/steamcmd/steamcmd:ubuntu

ENV SEVENDTD_SERVER_APPID=294420 \
    SEVENDTD_HOME=/sevendtd

ENV USER_DATA_FOLDER=$SEVENDTD_HOME/UserDataFolder

ENV SAVES_FOLDER=$USER_DATA_FOLDER/Saves \
    GENERATED_WORLDS_FOLDER=$USER_DATA_FOLDER/GeneratedWorlds \
    ADMIN_STEAMID= \
    GAME_DIFFICULTY=Adventurer \
    GAME_DAYLENGTH=60 \
    SERVER_NAME=lsdc2 \
    SERVER_DESCRIPTION="Le serveur des copains" \
    SERVER_PORT=26900 \
    SERVER_PASS=password \
    SERVER_VISIBILITY=1 \
    SERVER_ALLOW_CROSSPLAY=false

ENV LSDC2_SNIFF_IFACE="eth0" \
    LSDC2_SNIFF_FILTER="(tcp port 26900) or (udp portrange 26900-26905)" \
    LSDC2_CWD=$SEVENDTD_HOME \
    LSDC2_UID=2000 \
    LSDC2_GID=2000 \
    LSDC2_PERSIST_FILES="Saves;GeneratedWorlds" \
    LSDC2_ZIPFROM=$USER_DATA_FOLDER

WORKDIR $SEVENDTD_HOME

ADD https://github.com/Meuna/lsdc2-serverwrap/releases/download/v0.3.2/serverwrap /serverwrap

COPY start-server.sh update-server.sh serveradmin.xml $SEVENDTD_HOME
RUN apt-get update && apt-get install -y xmlstarlet \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g $LSDC2_GID sevendtd \
    && useradd -g $LSDC2_GID -u $LSDC2_UID -d $SEVENDTD_HOME -o --no-create-home sevendtd \
    && chmod u+x /serverwrap update-server.sh start-server.sh \
    && mkdir -p $GENERATED_WORLDS_FOLDER \
    && mkdir -p $SAVES_FOLDER \
    && chown -R sevendtd:sevendtd $SEVENDTD_HOME \
    && su sevendtd ./update-server.sh \
    && rm -rf /root/.steam /ubuntu/.steam \
    && rm -rf /sevendtd/Data/Worlds/P*

EXPOSE 26900/tcp
ENTRYPOINT ["/serverwrap"]
CMD ["./start-server.sh"]
