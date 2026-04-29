#!/bin/bash
# =============================================================================
# actualizar.sh — Actualización segura del sistema con log
# Debian 12 Bookworm | Requiere root (sudo)
# Uso: sudo ./actualizar.sh
# =============================================================================

LOG="/var/log/mis-actualizaciones.log"
FECHA=$(date '+%Y-%m-%d %H:%M:%S')

VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
RESET='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${ROJO}Este script necesita ejecutarse como root: sudo $0${RESET}"
    exit 1
fi

log() { echo -e "$1"; echo "$(date '+%H:%M:%S') $1" >> "$LOG"; }

echo "" | tee -a "$LOG"
log "===== ACTUALIZACIÓN — ${FECHA} ====="

# apt update
log "${AMARILLO}[1/4] Actualizando lista de paquetes...${RESET}"
apt update -qq 2>&1 | tee -a "$LOG"

# Mostrar qué se va a actualizar
UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "^Listing" | grep -c "upgradable" || true)

if [ "$UPGRADABLE" -eq 0 ]; then
    log "${VERDE}El sistema ya está actualizado. No hay nada que hacer.${RESET}"
    exit 0
fi

echo ""
log "${AMARILLO}Paquetes con actualización disponible (${UPGRADABLE}):${RESET}"
apt list --upgradable 2>/dev/null | grep -v "^Listing" | tee -a "$LOG"
echo ""

read -rp "¿Proceder con la actualización? [s/N]: " RESP
if [[ ! "$RESP" =~ ^[sS]$ ]]; then
    log "Actualización cancelada por el usuario."
    exit 0
fi

# apt upgrade
log "${AMARILLO}[2/4] Instalando actualizaciones...${RESET}"
DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1 | tee -a "$LOG"

# autoremove
log "${AMARILLO}[3/4] Eliminando paquetes obsoletos...${RESET}"
apt autoremove -y 2>&1 | tee -a "$LOG"

# autoclean
log "${AMARILLO}[4/4] Limpiando caché de paquetes...${RESET}"
apt autoclean -y 2>&1 | tee -a "$LOG"

log "${VERDE}Actualización completada.${RESET}"

# Reinicio pendiente
if [ -f /var/run/reboot-required ]; then
    log "${AMARILLO}⚠ Se instaló un kernel u otro componente que requiere reiniciar.${RESET}"
    if [ -f /var/run/reboot-required.pkgs ]; then
        log "  Paquetes que lo requieren: $(cat /var/run/reboot-required.pkgs | tr '\n' ' ')"
    fi
fi

log "===== FIN ====="
echo ""
echo -e "${VERDE}Log guardado en: ${LOG}${RESET}"
echo ""
