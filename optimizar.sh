#!/bin/bash
echo "Ejecutando la optimización del sistema..."
echo "Desactivando swap temporalmente..."
swapoff -a
echo "Optimizando el sistema de archivos..."
fsck -y /dev/sda1
echo "Reactivando swap..."
swapon -a
echo "Optimización finalizada."
