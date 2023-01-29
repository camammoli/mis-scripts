#!/bin/bash
echo "Información del sistema en $(hostname) el $(date)":
echo "Distribución: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Procesador: $(grep 'model name' /proc/cpuinfo | head -n1 | cut -d':' -f2)"
echo "Memoria RAM: $(grep 'MemTotal' /proc/meminfo | cut -d':' -f2)"
