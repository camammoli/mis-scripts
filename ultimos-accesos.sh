#!/bin/bash
# =============================================================================
# ultimos-accesos.sh — Últimos accesos, intentos fallidos y usuarios activos
# Debian 12 Bookworm | No requiere root (con sudo muestra más detalle)
# Uso: ./ultimos-accesos.sh
# =============================================================================

CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
VERDE='\033[0;32m'
ROJO='\033[0;31m'
RESET='\033[0m'

separador() { echo -e "${CYAN}──────────────────────────────────────────${RESET}"; }

echo ""
echo -e "${CYAN}  ACCESOS AL SISTEMA — $(date '+%d/%m/%Y %H:%M:%S')${RESET}"
separador

# Usuarios conectados ahora
echo -e "${AMARILLO}Usuarios activos ahora:${RESET}"
who | awk '{printf "  %-12s %-10s %s %s\n", $1, $2, $3, $4}'
[ -z "$(who)" ] && echo "  (ninguno)"

separador

# Últimos inicios de sesión
echo -e "${AMARILLO}Últimos 10 inicios de sesión:${RESET}"
last -n 10 -a | head -12 | awk '{printf "  %s\n", $0}'

separador

# Intentos fallidos
echo -e "${AMARILLO}Intentos de acceso fallidos (últimas 24 h):${RESET}"
if [ "$EUID" -eq 0 ]; then
    # Con root: leer auth.log directamente
    FALLIDOS=$(grep -i "failed\|failure\|invalid" /var/log/auth.log 2>/dev/null \
        | grep "$(date '+%b %e')" | tail -20)
    if [ -n "$FALLIDOS" ]; then
        echo "$FALLIDOS" | awk '{printf "  %s\n", $0}' | tail -15
    else
        echo -e "  ${VERDE}Sin intentos fallidos hoy.${RESET}"
    fi
else
    # Sin root: usar journalctl
    FALLIDOS=$(journalctl _SYSTEMD_UNIT=sshd.service --since "24 hours ago" \
        2>/dev/null | grep -i "failed\|invalid" | tail -15)
    if [ -n "$FALLIDOS" ]; then
        echo "$FALLIDOS" | awk '{printf "  %s\n", $0}'
    else
        # Intentar con sudo en auth.log
        FALLIDOS=$(sudo grep -i "failed\|failure" /var/log/auth.log 2>/dev/null \
            | grep "$(date '+%b %e')" | tail -15)
        [ -n "$FALLIDOS" ] && echo "$FALLIDOS" | awk '{printf "  %s\n", $0}' \
            || echo -e "  ${VERDE}Sin intentos fallidos detectados (ejecutá con sudo para más detalle).${RESET}"
    fi
fi

separador

# Último reboot
echo -e "${AMARILLO}Historial de reinicios:${RESET}"
last reboot | head -5 | awk '{printf "  %s\n", $0}'

separador
echo ""
