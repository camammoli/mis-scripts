#!/bin/bash
# =============================================================================
# limpieza.sh — Liberar espacio en disco
# Debian 12 Bookworm | Requiere root (sudo)
# Uso: sudo ./limpieza.sh
# =============================================================================

VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${ROJO}Este script necesita ejecutarse como root: sudo $0${RESET}"
    exit 1
fi

separador() { echo -e "${CYAN}──────────────────────────────────────────${RESET}"; }

disco_libre() { df -h / | awk 'NR==2{print $4}'; }

echo ""
echo -e "${CYAN}  LIMPIEZA DEL SISTEMA — $(date '+%d/%m/%Y %H:%M:%S')${RESET}"
separador
LIBRE_ANTES=$(df / | awk 'NR==2{print $4}')
echo -e "  Espacio libre antes: ${AMARILLO}$(disco_libre)${RESET}"
separador

# 1. apt autoremove
echo -e "\n${AMARILLO}[1/5] Eliminando paquetes huérfanos (autoremove)...${RESET}"
apt autoremove -y

# 2. apt autoclean
echo -e "\n${AMARILLO}[2/5] Limpiando caché de apt...${RESET}"
apt autoclean -y
apt clean

# 3. Journals viejos
echo -e "\n${AMARILLO}[3/5] Limpiando logs de systemd (> 7 días)...${RESET}"
JOURNAL_ANTES=$(du -sh /var/log/journal 2>/dev/null | cut -f1)
journalctl --vacuum-time=7d
echo "  (antes ocupaba ${JOURNAL_ANTES})"

# 4. /tmp y /var/tmp
echo -e "\n${AMARILLO}[4/5] Limpiando archivos temporales (> 7 días)...${RESET}"
find /tmp -type f -atime +7 -delete 2>/dev/null && echo "  /tmp limpio"
find /var/tmp -type f -atime +7 -delete 2>/dev/null && echo "  /var/tmp limpio"

# 5. Thumbnails del usuario
echo -e "\n${AMARILLO}[5/5] Limpiando thumbnails del home...${RESET}"
USUARIO=$(logname 2>/dev/null || echo "carlos")
THUMB="/home/${USUARIO}/.cache/thumbnails"
if [ -d "$THUMB" ]; then
    THUMB_SIZE=$(du -sh "$THUMB" 2>/dev/null | cut -f1)
    find "$THUMB" -type f -atime +30 -delete 2>/dev/null
    echo "  thumbnails procesados (antes: ${THUMB_SIZE})"
else
    echo "  No hay carpeta de thumbnails."
fi

# Resultado
separador
LIBRE_DESPUES=$(df / | awk 'NR==2{print $4}')
LIBERADO=$(( LIBRE_DESPUES - LIBRE_ANTES ))
echo -e "  Espacio libre después : ${VERDE}$(disco_libre)${RESET}"
if [ "$LIBERADO" -gt 0 ]; then
    echo -e "  Espacio liberado      : ${VERDE}$(numfmt --to=iec $((LIBERADO * 1024)))${RESET}"
fi
separador
echo ""
