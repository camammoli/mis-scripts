#!/bin/bash
clear
while :
  do
    echo " Escoja una opcion "
    echo "1. quien soy?"
    echo "2. cuanto espacio tengo"
    echo "3. que es esto?"
    echo "4. Salir"
    echo -n "Seleccione una opcion [1 - 4]"
    read opcion
    case $opcion in
      1) echo "este eres:";
        whoami;;
      2) echo "tienes esto";
        df;;
      3) uname -r;;
      4) echo "chao";
        exit 1;;
      *) echo "$opc es una opcion invalida. Es tan dificil?";
    echo "Presiona una tecla para continuar...";
    read foo;;
  esac
  done
