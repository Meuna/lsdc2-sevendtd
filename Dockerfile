FROM docker.io/steamcmd/steamcmd:ubuntu

ENV LSDC2_USER=lsdc2 \
    LSDC2_HOME=/lsdc2 \
    LSDC2_UID=2000 \
    LSDC2_GID=2000

WORKDIR $LSDC2_HOME

ENV USER_DATA_FOLDER=$LSDC2_HOME/UserDataFolder

COPY update-server.sh $LSDC2_HOME
RUN apt-get update && apt-get install -y xmlstarlet \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g $LSDC2_GID $LSDC2_USER \
    && useradd -g $LSDC2_GID -u $LSDC2_UID -d $LSDC2_HOME -o --no-create-home $LSDC2_USER \
    && chown -R $LSDC2_USER:$LSDC2_USER $LSDC2_HOME \
    && chmod u+x update-server.sh \
    && su $LSDC2_USER ./update-server.sh \
    && rm -rf /root/.steam \
    && rm -rf /$LSDC2_HOME/Data/Worlds/P*

ADD https://github.com/Meuna/lsdc2-serverwrap/releases/download/v0.3.2/serverwrap /usr/local/bin
COPY start-server.sh $LSDC2_HOME
RUN chown $LSDC2_USER:$LSDC2_USER start-server.sh \
    && chmod +x /usr/local/bin/serverwrap start-server.sh

ENV GAME_SAVEDIR=$LSDC2_HOME/savedir \
    SAVES_DIRNAME=Saves \
    WORLDS_DIRNAME=GeneratedWorlds \
    GAME_PORT=26900

ENV LSDC2_SNIFF_IFACE="eth0" \
    LSDC2_SNIFF_FILTER="(tcp port $GAME_PORT) or (udp portrange 26900-26905)" \
    LSDC2_PERSIST_FILES="$SAVES_DIRNAME;$WORLDS_DIRNAME" \
    LSDC2_ZIPFROM=$USER_DATA_FOLDER

EXPOSE 26900/tcp
ENTRYPOINT ["serverwrap"]
CMD ["./start-server.sh"]
