#!/bin/bash
# =============================================================================
# monitor-live.sh — Monitor en tiempo real del sistema
# Debian 12 Bookworm | No requiere root
# Uso: ./monitor-live.sh
# Salir con Ctrl+C
# =============================================================================

VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
CYAN='\033[0;36m'
NEGRITA='\033[1m'
RESET='\033[0m'

INTERVALO=2

barra() {
    local PCT=$1
    local ANCHO=20
    local LLENO=$(( PCT * ANCHO / 100 ))
    local VACIO=$(( ANCHO - LLENO ))
    local COLOR="$VERDE"
    [ "$PCT" -ge 70 ] && COLOR="$AMARILLO"
    [ "$PCT" -ge 90 ] && COLOR="$ROJO"
    printf "${COLOR}["
    printf '%0.s█' $(seq 1 $LLENO 2>/dev/null)
    printf '%0.s░' $(seq 1 $VACIO 2>/dev/null)
    printf "]${RESET} %3d%%" "$PCT"
}

mostrar() {
    clear
    echo -e "${NEGRITA}${CYAN}  MONITOR DEL SISTEMA — $(date '+%d/%m/%Y %H:%M:%S') — Ctrl+C para salir${RESET}"
    echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"

    # CPU
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%id,' 2>/dev/null || echo "0")
    CPU_PCT=$(awk "BEGIN{printf \"%d\", 100 - ${CPU_IDLE}}" 2>/dev/null || echo "0")
    LOAD=$(cut -d' ' -f1-3 /proc/loadavg)
    echo -e "  ${AMARILLO}CPU  ${RESET} $(barra $CPU_PCT)  carga: ${LOAD}"

    # RAM
    RAM_INFO=$(free | awk 'NR==2{printf "%d %d %d", $2, $3, int($3*100/$2)}')
    RAM_TOT=$(echo $RAM_INFO | awk '{printf "%.1f GB", $1/1024/1024}')
    RAM_USD=$(echo $RAM_INFO | awk '{printf "%.1f GB", $2/1024/1024}')
    RAM_PCT=$(echo $RAM_INFO | awk '{print $3}')
    echo -e "  ${AMARILLO}RAM  ${RESET} $(barra $RAM_PCT)  ${RAM_USD} / ${RAM_TOT}"

    # SWAP
    SWAP_INFO=$(free | awk 'NR==3{if($2>0) printf "%d %d %d", $2, $3, int($3*100/$2); else print "0 0 0"}')
    SWAP_TOT=$(echo $SWAP_INFO | awk '{printf "%.1f GB", $1/1024/1024}')
    SWAP_USD=$(echo $SWAP_INFO | awk '{printf "%.1f GB", $2/1024/1024}')
    SWAP_PCT=$(echo $SWAP_INFO | awk '{print $3}')
    if [ "$(echo $SWAP_INFO | awk '{print $1}')" != "0" ]; then
        echo -e "  ${AMARILLO}SWAP ${RESET} $(barra $SWAP_PCT)  ${SWAP_USD} / ${SWAP_TOT}"
    fi

    # Disco raíz
    DISCO_INFO=$(df / | awk 'NR==2{printf "%d %d", $5, $4/1024/1024}')
    DISCO_PCT=$(echo $DISCO_INFO | awk '{print $1}' | tr -d '%')
    DISCO_LIBRE=$(echo $DISCO_INFO | awk '{printf "%.1f GB libre", $2}')
    echo -e "  ${AMARILLO}DISCO${RESET} $(barra $DISCO_PCT)  ${DISCO_LIBRE}"

    # Temperatura
    TEMP_FILE="/sys/class/thermal/thermal_zone0/temp"
    if [ -f "$TEMP_FILE" ]; then
        TEMP=$(awk '{printf "%.1f°C", $1/1000}' "$TEMP_FILE")
        echo -e "  ${AMARILLO}TEMP ${RESET} ${TEMP}"
    fi

    echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"

    # Top 5 por CPU
    echo -e "  ${AMARILLO}Top 5 por CPU:${RESET}"
    ps aux --sort=-%cpu | awk 'NR>1 && NR<=6 {printf "  %-5s %-8s %-5s %-5s %s\n", $1, $2, $3"%", $4"%", $11}' \
        | head -5

    echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"

    # Top 5 por RAM
    echo -e "  ${AMARILLO}Top 5 por RAM:${RESET}"
    ps aux --sort=-%mem | awk 'NR>1 && NR<=6 {printf "  %-5s %-8s %-5s %-5s %s\n", $1, $2, $3"%", $4"%", $11}' \
        | head -5

    echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"
    echo -e "  Actualizando cada ${INTERVALO}s…"
}

trap 'echo -e "\n${VERDE}Monitor detenido.${RESET}"; exit 0' INT TERM

while true; do
    mostrar
    sleep "$INTERVALO"
done
