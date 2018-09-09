#!/bin/sh
SERVICE='httpd'
if ps ax | grep -v grep | grep $SERVICE > /dev/null
then
echo "El servicio $SERVICE esta ejecutandose"
else
echo "Chanfle! El servicio $SERVICE esta detenido"
fi
