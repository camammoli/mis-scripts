#!/bin/bash
AUTHORIZED_USER="usuario_permitido"
if [ $USER != $AUTHORIZED_USER ]; then
echo "Este script debe ser ejecutado por el usuario $AUTHORIZED_USER" 1>&2
exit 1
fi
