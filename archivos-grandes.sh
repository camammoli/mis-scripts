#!/bin/bash
# =============================================================================
# archivos-grandes.sh — Busca archivos que superan un tamaño dado
# Debian 12 Bookworm | No requiere root (para /home)
# Uso: ./archivos-grandes.sh [directorio] [tamaño_mínimo_MB]
#      ./archivos-grandes.sh /home/carlos 50
#      ./archivos-grandes.sh / 500          (requiere sudo para todo el sistema)
# Por defecto: busca en $HOME archivos > 100 MB
# =============================================================================

CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
RESET='\033[0m'

DIR="${1:-$HOME}"
MIN_MB="${2:-100}"

if [ ! -d "$DIR" ]; then
    echo "Error: '$DIR' no es un directorio válido."
    exit 1
fi

echo ""
echo -e "${CYAN}  ARCHIVOS GRANDES (> ${MIN_MB} MB) en ${DIR}${RESET}"
echo -e "${CYAN}──────────────────────────────────────────${RESET}"
echo ""

RESULTADO=$(find "$DIR" -type f -size +${MIN_MB}M 2>/dev/null \
    | xargs du -h 2>/dev/null \
    | sort -rh \
    | head -30)

if [ -z "$RESULTADO" ]; then
    echo -e "  ${AMARILLO}No se encontraron archivos mayores a ${MIN_MB} MB en ${DIR}.${RESET}"
else
    echo "$RESULTADO" | awk '{printf "  %-8s %s\n", $1, $2}'
fi

echo ""
