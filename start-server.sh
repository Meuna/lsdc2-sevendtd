#!/bin/bash
export HOME=$SEVENDTD_HOME
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH

./update-server.sh

# Init the serveradmin.xml file if it does not exists
ADMIN_FILE=$SAVES_FOLDER/serveradmin.xml
if [ ! -f $ADMIN_FILE ]; then
    cp serveradmin.xml $ADMIN_FILE
fi
# And give the admin to whoever configured the server
xmlstarlet ed --inplace \
    -s "/adminTools/users" -t elem -n "user" -v "" \
    -i "/adminTools/users/user[not(@platform)]" -t attr -n "platform" -v "Steam" \
    -i "/adminTools/users/user[not(@userid)]" -t attr -n "userid" -v "$ADMIN_STEAMID" \
    -i "/adminTools/users/user[not(@name)]" -t attr -n "name" -v "LSDC2 Master" \
    -i "/adminTools/users/user[not(@permission_level)]" -t attr -n "permission_level" -v "0" \
    $ADMIN_FILE

# Edit the configuration file
CONFIG_FILE=serverconfig.xml

# Try to find if a worldname exists in the GeneratedWorlds folder. If not use the default world
WORLD_NAME=$(ls $GENERATED_WORLDS_FOLDER)
WORLD_NAME=${WORLD_NAME:-Navezgane}

# Try to find if a gamename exists in the Saves folder. If not start a new game
GAME_NAME=$(ls $SAVES_FOLDER/"$WORLD_NAME")
GAME_NAME=${GAME_NAME:-$SERVER_NAME}

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
    -u "/ServerSettings/property[@name='ServerName']/@value" -v "$SERVER_NAME" \
    -u "/ServerSettings/property[@name='ServerDescription']/@value" -v "$SERVER_DESCRIPTION" \
    -u "/ServerSettings/property[@name='ServerPassword']/@value" -v "$SERVER_PASS" \
    -u "/ServerSettings/property[@name='Region']/@value" -v "Europe" \
    -u "/ServerSettings/property[@name='ServerPort']/@value" -v "$SERVER_PORT" \
    -u "/ServerSettings/property[@name='ServerVisibility']/@value" -v "$SERVER_VISIBILITY" \
    -u "/ServerSettings/property[@name='ServerMaxWorldTransferSpeedKiBs']/@value" -v "1300" \
    -u "/ServerSettings/property[@name='TelnetEnabled']/@value" -v "false" \
    -u "/ServerSettings/property[@name='TerminalWindowEnabled']/@value" -v "false" \
    -u "/ServerSettings/property[@name='ServerAllowCrossplay']/@value" -v "$SERVER_ALLOW_CROSSPLAY" \
    -u "/ServerSettings/property[@name='EACEnabled']/@value" -v "$SERVER_ALLOW_CROSSPLAY" \
    -s "/ServerSettings" -t elem -n "property" -v "" \
        -i "/ServerSettings/property[not(@name)]" -t attr -n "name" -v "UserDataFolder" \
        -i "/ServerSettings/property[not(@value)]" -t attr -n "value" -v "$USER_DATA_FOLDER" \
    -u "/ServerSettings/property[@name='GameWorld']/@value" -v "$WORLD_NAME" \
    -u "/ServerSettings/property[@name='GameName']/@value" -v "$GAME_NAME" \
    -u "/ServerSettings/property[@name='GameDifficulty']/@value" -v "$GAME_DIFFICULTY" \
    -u "/ServerSettings/property[@name='DayNightLength']/@value" -v "$GAME_DAYLENGTH" \
    $CONFIG_FILE

shutdown() {
    kill -INT $pid
}

trap shutdown SIGINT SIGTERM

./7DaysToDieServer.x86_64 -quit -batchmode -nographics -dedicated -configfile=$CONFIG_FILE &
pid=$!
wait $pid
