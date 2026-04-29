#!/bin/bash
# =============================================================================
# resumen.sh — Reporte completo del estado del sistema
# Debian 12 Bookworm | No requiere root (con sudo muestra más detalle)
# Uso: ./resumen.sh
#      ./resumen.sh > reporte-$(date +%F).txt   ← guardar a archivo
# =============================================================================

CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
VERDE='\033[0;32m'
ROJO='\033[0;31m'
NEGRITA='\033[1m'
RESET='\033[0m'

sep() { echo -e "${CYAN}══════════════════════════════════════════════════════${RESET}"; }
lin() { echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"; }

sep
echo -e "${NEGRITA}${CYAN}  REPORTE DEL SISTEMA — $(date '+%A %d/%m/%Y %H:%M:%S')${RESET}"
sep

# ── Sistema ──────────────────────────────────────────────
echo -e "\n${AMARILLO}SISTEMA${RESET}"
lin
echo "  Hostname  : $(hostname)"
echo "  Debian    : $(cat /etc/debian_version)"
echo "  Kernel    : $(uname -r) ($(uname -m))"
echo "  Uptime    : $(uptime -p)"
echo "  Carga     : $(cut -d' ' -f1-3 /proc/loadavg) (1, 5, 15 min)"
[ -f /var/run/reboot-required ] && \
    echo -e "  ${AMARILLO}⚠ Reinicio pendiente.${RESET}"

# ── Red ──────────────────────────────────────────────────
echo -e "\n${AMARILLO}RED${RESET}"
lin
echo "  IP local  : $(hostname -I | awk '{print $1}')"
echo "  IP pública: $(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo 'sin acceso')"
echo "  Interfaces:"
ip -brief addr show | awk '{printf "    %-10s %-8s %s\n", $1, $2, $3}'

# ── Memoria ──────────────────────────────────────────────
echo -e "\n${AMARILLO}MEMORIA${RESET}"
lin
free -h | awk '
    NR==1{printf "  %-10s %8s %8s %8s %8s\n","", $2,$3,$4,$6}
    NR==2{printf "  %-10s %8s %8s %8s %8s\n","RAM", $2,$3,$4,$6}
    NR==3{printf "  %-10s %8s %8s %8s\n","SWAP",$2,$3,$4}'

# ── Disco ────────────────────────────────────────────────
echo -e "\n${AMARILLO}DISCO${RESET}"
lin
df -h --output=source,size,used,avail,pcent,target \
    -x tmpfs -x devtmpfs -x udev 2>/dev/null | \
    awk 'NR==1{printf "  %-18s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
         {printf "  %-18s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6}'

echo ""
echo "  Directorios más pesados en /home:"
du -h --max-depth=2 "$HOME" 2>/dev/null | sort -rh | head -8 | \
    awk '{printf "    %-8s %s\n", $1, $2}'

# ── CPU ──────────────────────────────────────────────────
echo -e "\n${AMARILLO}CPU${RESET}"
lin
grep 'model name' /proc/cpuinfo | head -1 | \
    awk -F: '{printf "  Modelo : %s\n", $2}' | xargs -I{} echo {}
echo "  Núcleos: $(nproc)"
TEMP_FILE="/sys/class/thermal/thermal_zone0/temp"
[ -f "$TEMP_FILE" ] && \
    echo "  Temp   : $(awk '{printf "%.1f°C", $1/1000}' "$TEMP_FILE")"

# ── Servicios ────────────────────────────────────────────
echo -e "\n${AMARILLO}SERVICIOS (systemd)${RESET}"
lin
echo "  Fallidos:"
FAILED=$(systemctl --failed --no-legend 2>/dev/null | awk '{print "    ✗ "$1}')
if [ -n "$FAILED" ]; then
    echo -e "${ROJO}${FAILED}${RESET}"
else
    echo -e "  ${VERDE}Sin servicios caídos.${RESET}"
fi

echo ""
echo "  Activos de interés:"
for SVC in ssh cron cups NetworkManager bluetooth; do
    if systemctl is-active --quiet "$SVC" 2>/dev/null; then
        echo -e "  ${VERDE}  ✓ ${SVC}${RESET}"
    else
        systemctl list-unit-files --no-legend 2>/dev/null | grep -q "^${SVC}" && \
            echo -e "  ${ROJO}  ✗ ${SVC} (inactivo)${RESET}"
    fi
done

# ── Actualizaciones ──────────────────────────────────────
echo -e "\n${AMARILLO}ACTUALIZACIONES${RESET}"
lin
PEND=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
if [ "$PEND" -gt 0 ]; then
    echo -e "  ${AMARILLO}${PEND} paquete(s) disponibles para actualizar.${RESET}"
    apt list --upgradable 2>/dev/null | grep -v "^Listing" | \
        awk '{printf "    %s\n", $0}' | head -15
else
    echo -e "  ${VERDE}Sistema al día.${RESET}"
fi

# ── Últimos errores ───────────────────────────────────────
echo -e "\n${AMARILLO}ÚLTIMOS ERRORES DEL SISTEMA (journal)${RESET}"
lin
ERRORES=$(journalctl -p err -n 10 --no-pager 2>/dev/null | tail -10)
if [ -n "$ERRORES" ]; then
    echo "$ERRORES" | awk '{printf "  %s\n", $0}'
else
    echo -e "  ${VERDE}Sin errores recientes en el journal.${RESET}"
fi

# ── Últimos accesos ──────────────────────────────────────
echo -e "\n${AMARILLO}ÚLTIMOS ACCESOS${RESET}"
lin
last -n 5 -a | head -6 | awk '{printf "  %s\n", $0}'

sep
echo -e "  Reporte generado: $(date '+%d/%m/%Y %H:%M:%S')"
sep
echo ""
