#!/bin/bash
export HOME=$LSDC2_HOME
export PATH=$PATH:/usr/games
sevendtd_server_appid=294420
steamcmd +force_install_dir $LSDC2_HOME +login anonymous +app_update $sevendtd_server_appid +quit