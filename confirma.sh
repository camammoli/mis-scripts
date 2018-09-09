#!/bin/bash
while true; do
  echo
  read -p "esta seguro de hacer lo que sea que vaya a hacer " yn
  case $yn in
    yes ) break;;
    no ) exit;;
    * ) echo "por favor responda yes o no";;
  esac
done
echo "si se ejecuta esto es que aceptaste"
