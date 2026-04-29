#!/bin/bash
# Libera caché de memoria de Linux sin afectar el sistema de archivos.
# Requiere root.

if [[ $EUID -ne 0 ]]; then
    echo "Este script requiere permisos de root. Ejecutá: sudo $0"
    exit 1
fi

echo "Uso de memoria antes:"
free -h

echo ""
echo "Sincronizando sistema de archivos..."
sync

echo "Liberando caché de página, dentries e inodes..."
echo 3 > /proc/sys/vm/drop_caches

echo ""
echo "Uso de memoria después:"
free -h

echo ""
echo "Optimización finalizada."
