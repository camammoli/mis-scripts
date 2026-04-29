#!/bin/bash
# =============================================================================
# puertos-abiertos.sh — Lista puertos abiertos y conexiones activas
# Debian 12 Bookworm | Requiere root para ver todos los procesos (sudo)
# Uso: sudo ./puertos-abiertos.sh
# =============================================================================

CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
VERDE='\033[0;32m'
RESET='\033[0m'

separador() { echo -e "${CYAN}──────────────────────────────────────────${RESET}"; }

echo ""
echo -e "${CYAN}  PUERTOS ABIERTOS — $(date '+%d/%m/%Y %H:%M:%S')${RESET}"
separador

# Puertos TCP en escucha
echo -e "${AMARILLO}Puertos TCP en escucha (LISTEN):${RESET}"
ss -tlnp 2>/dev/null | awk 'NR==1{print "  "$0; next} /LISTEN/{printf "  %s\n", $0}'

separador

# Puertos UDP en escucha
echo -e "${AMARILLO}Puertos UDP activos:${RESET}"
ss -ulnp 2>/dev/null | awk 'NR==1{print "  "$0; next} {printf "  %s\n", $0}' | head -20

separador

# Conexiones establecidas
echo -e "${AMARILLO}Conexiones TCP establecidas:${RESET}"
CONN=$(ss -tnp state established 2>/dev/null | tail -n +2)
if [ -n "$CONN" ]; then
    echo "$CONN" | awk '{printf "  %s\n", $0}'
else
    echo -e "  ${VERDE}Sin conexiones establecidas actualmente.${RESET}"
fi

separador

# Resumen por puerto conocido
echo -e "${AMARILLO}Servicios comunes detectados:${RESET}"
declare -A SERVICIOS=(
    [22]="SSH" [80]="HTTP" [443]="HTTPS" [3306]="MySQL"
    [5432]="PostgreSQL" [25]="SMTP" [587]="SMTP-TLS"
    [21]="FTP" [8080]="HTTP-alt" [8443]="HTTPS-alt"
    [53]="DNS" [631]="CUPS/Impresión"
)

for PUERTO in "${!SERVICIOS[@]}"; do
    if ss -tlnp 2>/dev/null | grep -q ":${PUERTO} "; then
        echo -e "  ${VERDE}✓ Puerto ${PUERTO} (${SERVICIOS[$PUERTO]}) — activo${RESET}"
    fi
done | sort

separador
echo ""
