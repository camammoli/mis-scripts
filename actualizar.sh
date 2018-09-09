#!/bin/bash

# Nombre del script
minombre=$(basename $0)

# Si hay parametros los analiza y actua en consecuencia
if [[ $# > 0 ]]; then
  case $@ in
    --ver ) echo && echo "$minombre Version 0.1.0" && echo "Ariel Mammoli" && echo && exit 0;;
    --auto )
      noconfirma="--yes"
      sinsalida=" 1> /dev/null";;
    * )
      echo
      echo "$minombre solo permite un parametro ('--auto') que indica que el script"
      echo "se esta ejecutando como parte de un script mayor, por lo tanto no"
      echo "esperara confirmacion (asume si siempre)"
      echo
      exit 0;;
  esac
fi

# Si no se ejecuta como root no puede continuar
if [[ $EUID -ne 0 ]]; then
  echo
  echo "Houston we have a problem..."
  echo "Este script debe ser ejecutado por el usuario root"
  echo "Ejecute 'sudo ./echo $minombre'"
  exit 1
fi

# Revisa si el archivo log ya existe y notifica
if [[ -f err_$minombre.log ]]; then
  echo
  echo "Houston we have a problem..."
  echo "Revise el archivo 'err_$minombre.log'; contiene informacion sobre errores"
  echo "de ejecuciones previas de $minombre."
  echo "Ejecute 'rm err_$minombre.log'"
  exit 1
fi

if [[ $sinsalida = "" ]]; then echo && echo "Preparando actualizacion..."; fi
apt-get update $noconfirma 2> err_$minombre.log $sinsalida
  errores=$

if [[ $sinsalida = "" ]]; then echo && echo "Actualizando..."; fi
apt-get upgrade $noconfirma 2>> err_$minombre.log $sinsalida
  errores=$errores+$
apt-get full-upgrade $noconfirma 2>> err_$minombre.log $sinsalida
  errores=$errores+$

if [[ $sinsalida = "" ]]; then echo && echo "Limpiando temporales..."; fi
apt-get clean $noconfirma 2>> err_$minombre.log $sinsalida
  errores=$errores+$
apt-get autoclean $noconfirma 2>> err_$minombre.log $sinsalida
  errores=$errores+$
apt-get autoremove $noconfirma 2>> err_$minombre.log $sinsalida
  errores=$errores+$

if [[ $sinsalida = "" ]]; then echo; fi
if [[ $errores > 0 ]]; then
  # Error ...
  if [[ $sinsalida = "" ]]; then echo "Houston we have a problem..." && echo "Revise el archivo err_$minombre.log para ver una lista de errores al actualizar."; fi
  exit 1
else
  if [[ $sinsalida = "" ]]; then echo "Sistema actualizado!"; fi
  rm -f err_$minombre.log
  exit 0
fi
