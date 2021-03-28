#!/bin/sh

export KOSMTIK_CONFIGPATH="kosmtik/.kosmtik-config.yml"

# Creating default Kosmtik settings file
if [ ! -e "$KOSMTIK_CONFIGPATH" ]; then
    cp /tmp/.kosmtik-config.yml "$KOSMTIK_CONFIGPATH"
fi

kosmtik serve kosmtik/project.mml --host 0.0.0.0
