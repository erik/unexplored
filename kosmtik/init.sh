#!/bin/sh

export KOSMTIK_CONFIGPATH="kosmtik/.kosmtik-config.yml"
kosmtik serve kosmtik/project.mml --host 0.0.0.0
