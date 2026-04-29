#!/bin/bash
# =============================================================================
# uso-disco.sh — Uso de disco por directorio, ordenado de mayor a menor
# Debian 12 Bookworm | No requiere root (para /home)
# Uso: ./uso-disco.sh [directorio]
#      ./uso-disco.sh /var
# =============================================================================

CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
VERDE='\033[0;32m'
RESET='\033[0m'

DIR="${1:-$HOME}"

if [ ! -d "$DIR" ]; then
    echo "Error: '$DIR' no es un directorio válido."
    exit 1
fi

echo ""
echo -e "${CYAN}  USO DE DISCO — ${DIR}${RESET}"
echo -e "${CYAN}──────────────────────────────────────────${RESET}"

# Subdirectorios del nivel indicado, ordenados por tamaño
echo -e "${AMARILLO}Subdirectorios (mayor a menor):${RESET}"
du -h --max-depth=1 "$DIR" 2>/dev/null \
    | sort -rh \
    | head -20 \
    | awk '{printf "  %-8s %s\n", $1, $2}'

echo ""
echo -e "${AMARILLO}Particiones montadas:${RESET}"
df -h --output=source,size,used,avail,pcent,target \
    -x tmpfs -x devtmpfs -x udev 2>/dev/null \
    | awk 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6; next}
           {printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6}'

echo ""

# Advertencia si alguna partición supera el 85%
df -h --output=pcent,target -x tmpfs -x devtmpfs -x udev 2>/dev/null | tail -n +2 | while read -r pct mount; do
    NUM=${pct%\%}
    if [ "$NUM" -ge 85 ] 2>/dev/null; then
        echo -e "  ${AMARILLO}⚠ Atención: ${mount} está al ${pct} de capacidad.${RESET}"
    fi
done
