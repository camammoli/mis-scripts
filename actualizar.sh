#!/bin/bash

echo Preparando actualizacion
sudo apt update
echo Actualizando...
sudo apt upgrade
sudo apt full-upgrade
echo Limpiando temporales
sudo apt clean
sudo apt autoclean
sudo apt autoremove
echo Sistema actualizado
