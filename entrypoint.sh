#!/bin/bash

set -e;

printf "                                                     .                  \n";
printf "   ___      _                                       ":"                 \n";
printf "  / __\__ _| |__  _ __ ___  _ __   ___  ___       ___:____     |"\/"|   \n";
printf " / /  / _' | '_ \| '__/ _ \| '_ \ / _ \/ __|    ,'        '.    \  /    \n";
printf "/ /__| (_| | |_) | | | (_) | | | |  __/\__ \    |  O        \___/  |    \n";
printf "\____/\__,_|_.__/|_|  \___/|_| |_|\___||___/  ~^~^~^~^~^~^~^~^~^~^~^~^~ \n";
printf "    ___ ___ _  _   ___                                                  \n";
printf "   / __/ __| || | / __| ___ _ ___ _____ _ _      https://github.com     \n";
printf "   \__ \__ \ __ | \__ \/ -_) '_\ V / -_) '_|           /sergiocabral    \n";
printf "   |___/___/_||_| |___/\___|_|  \_/\___|_|            /Docker.Ssh       \n";
printf "\n";

printf "Entrypoint for docker image: SSH Server\n";

SSHD_EXECUTABLE=$(which sshd || echo "");
SSHKEYGEN_EXECUTABLE=$(which ssh-keygen || echo "");
SUFFIX_TEMPLATE=".template";
DIR_CONF="/etc/ssh";
DIR_CONF_BACKUP="$DIR_CONF.original";
DIR_CONF_DOCKER="$DIR_CONF.conf";
DIR_CONF_TEMPLATES="$DIR_CONF.templates";
DIR_HOME="/home";
DIR_SCRIPTS="${DIR_SCRIPTS:-/root}";
LS="ls --color=auto -CFl";

if [ ! -e "$SSHD_EXECUTABLE" ];
then
    printf "SSH Server is not installed.\n" >> /dev/stderr;
    exit 1;
fi

IS_FIRST_CONFIGURATION=$((test ! -d $DIR_CONF_BACKUP && echo true) || echo false);

if [ $IS_FIRST_CONFIGURATION = true ];
then
    printf "This is the FIRST RUN.\n";

    if [ -z "$( ls -Fla $DIR_CONF | grep .pub )" ];
    then
        printf "Configuring SSH server keys.\n";
        $SSHKEYGEN_EXECUTABLE -A;
    fi

    printf "Configuring directories.\n";

    mkdir -p $DIR_CONF_BACKUP && cp -R $DIR_CONF/* $DIR_CONF_BACKUP;
    mkdir -p $DIR_CONF_DOCKER && cp -R $DIR_CONF/* $DIR_CONF_DOCKER;
    rm -R $DIR_CONF;
    ln -s $DIR_CONF_DOCKER $DIR_CONF;

    mkdir -p $DIR_CONF_TEMPLATES;

    if [ -d "$DIR_CONF_TEMPLATES" ] && [ ! -z "$(ls -A $DIR_CONF_TEMPLATES)" ];
    then
        printf "Warning: The $DIR_CONF_TEMPLATES directory already existed and will not have its content overwritten.\n";
    else
        printf "Creating files templates in $DIR_CONF_TEMPLATES\n";

        cp -R $DIR_CONF/ssh_config $DIR_CONF_TEMPLATES/ssh_config$SUFFIX_TEMPLATE;
        cp -R $DIR_CONF/sshd_config $DIR_CONF_TEMPLATES/sshd_config$SUFFIX_TEMPLATE;
    fi
    $LS -Ad $DIR_CONF_TEMPLATES/*;

    printf "Configured directories:\n";
    
    $LS -d $DIR_CONF $DIR_CONF_BACKUP $DIR_CONF_DOCKER $DIR_CONF_TEMPLATES;

    printf "Running SSH Server for the first time.\n";
    $SSHD_EXECUTABLE;
    sleep 1;
    pkill sshd;
else
    printf "This is NOT the first run.\n";
fi

printf "Tip: Use files $DIR_CONF_TEMPLATES/*$SUFFIX_TEMPLATE to make the files in the $DIR_CONF directory with replacement of environment variables with their values.\n";

$DIR_SCRIPTS/envsubst-files.sh "$SUFFIX_TEMPLATE" "$DIR_CONF_TEMPLATES" "$DIR_CONF";

printf "Starting SSH server.\n";

$SSHD_EXECUTABLE;

sleep infinity;