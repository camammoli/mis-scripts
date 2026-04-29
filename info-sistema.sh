#!/bin/bash
# =============================================================================
# info-sistema.sh — Resumen rápido del estado del sistema
# Debian 12 Bookworm | No requiere root
# Uso: ./info-sistema.sh
# =============================================================================

VERDE='\033[0;32m'
CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
NEGRITA='\033[1m'
RESET='\033[0m'

separador() { echo -e "${CYAN}──────────────────────────────────────────${RESET}"; }

echo ""
echo -e "${NEGRITA}${CYAN}  RESUMEN DEL SISTEMA — $(date '+%d/%m/%Y %H:%M:%S')${RESET}"
separador

# Host y kernel
echo -e "${AMARILLO}Sistema:${RESET}"
echo "  Hostname  : $(hostname)"
echo "  Debian    : $(cat /etc/debian_version)"
echo "  Kernel    : $(uname -r)"
echo "  Uptime    : $(uptime -p)"
echo "  Último OK : $(who -b | awk '{print $3, $4}')"

separador

# Red
echo -e "${AMARILLO}Red:${RESET}"
IP_LOCAL=$(hostname -I | awk '{print $1}')
IP_PUB=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "sin acceso")
echo "  IP local  : ${IP_LOCAL}"
echo "  IP pública: ${IP_PUB}"
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
echo "  Interfaz  : ${IFACE}"

separador

# CPU
echo -e "${AMARILLO}CPU:${RESET}"
CPU_MODEL=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(nproc)
LOAD=$(cut -d' ' -f1-3 /proc/loadavg)
echo "  Modelo    : ${CPU_MODEL}"
echo "  Núcleos   : ${CPU_CORES}"
echo "  Carga     : ${LOAD} (1, 5, 15 min)"

# Temperatura (si está disponible)
TEMP_FILE="/sys/class/thermal/thermal_zone0/temp"
if [ -f "$TEMP_FILE" ]; then
    TEMP=$(awk '{printf "%.1f°C", $1/1000}' "$TEMP_FILE")
    echo "  Temp CPU  : ${TEMP}"
fi

separador

# RAM
echo -e "${AMARILLO}Memoria:${RESET}"
free -h | awk 'NR==2{printf "  RAM       : %s usados / %s total (libre: %s)\n", $3, $2, $4}'
free -h | awk 'NR==3{if($2!="0B") printf "  SWAP      : %s usados / %s total\n", $3, $2}'

separador

# Disco
echo -e "${AMARILLO}Disco:${RESET}"
df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x udev | \
    awk 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n", $1,$2,$3,$4,$5,$6; next}
         {printf "  %-20s %6s %6s %6s %5s  %s\n", $1,$2,$3,$4,$5,$6}'

separador

# Actualizaciones pendientes
echo -e "${AMARILLO}Actualizaciones:${RESET}"
if command -v apt &>/dev/null; then
    PEND=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
    if [ "$PEND" -gt 0 ]; then
        echo -e "  ${AMARILLO}${PEND} paquete(s) con actualización disponible.${RESET}"
    else
        echo -e "  ${VERDE}Sistema actualizado.${RESET}"
    fi
fi

# Reinicio pendiente
if [ -f /var/run/reboot-required ]; then
    echo -e "  ${AMARILLO}⚠ Se requiere reiniciar el sistema.${RESET}"
fi

separador
echo ""
