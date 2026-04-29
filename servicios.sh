#!/bin/bash
# =============================================================================
# servicios.sh — Estado de servicios systemd configurables
# Debian 12 Bookworm | No requiere root
# Uso: ./servicios.sh [--watch] [--alerta-telegram]
#
# Muestra el estado de los servicios definidos en SERVICIOS_MONITOREAR.
# Con --watch: actualiza cada 5 segundos (Ctrl+C para salir)
# Con --alerta-telegram: usa telegram-alert.sh para notificar servicios caídos
# =============================================================================

# =============================================================================
# CONFIGURACIÓN — Editá la lista de servicios a monitorear
# =============================================================================

SERVICIOS_MONITOREAR=(
    "ssh"
    "cron"
    "NetworkManager"
    "cups"
    "ufw"
    # Servicios de aplicaciones (descomentar o agregar los que uses):
    # "apache2"
    # "nginx"
    # "mysql"
    # "postgresql"
    # "docker"
    # "fail2ban"
    # "postfix"
)

INTERVALO=5   # segundos entre actualizaciones en modo --watch

# =============================================================================

VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
CYAN='\033[0;36m'
GRIS='\033[0;90m'
NEGRITA='\033[1m'
RESET='\033[0m'

WATCH=false
TELEGRAM=false

for ARG in "$@"; do
    case "$ARG" in
        --watch)            WATCH=true ;;
        --alerta-telegram)  TELEGRAM=true ;;
        -h|--help)
            echo "Uso: $0 [--watch] [--alerta-telegram]"
            echo "  --watch            Actualiza cada ${INTERVALO}s (Ctrl+C para salir)"
            echo "  --alerta-telegram  Notifica servicios caídos por Telegram"
            exit 0
            ;;
    esac
done

mostrar() {
    local CAIDOS=()

    clear
    echo -e "${NEGRITA}${CYAN}  ESTADO DE SERVICIOS — $(date '+%d/%m/%Y %H:%M:%S')  ${HOST:-$(hostname)}${RESET}"
    echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"

    for SVC in "${SERVICIOS_MONITOREAR[@]}"; do
        # Verificar si el servicio existe
        if ! systemctl list-unit-files --no-legend 2>/dev/null | grep -q "^${SVC}\.service"; then
            echo -e "  ${GRIS}○ ${SVC}${RESET}  ${GRIS}(no instalado)${RESET}"
            continue
        fi

        local ACTIVO
        ACTIVO=$(systemctl is-active "$SVC" 2>/dev/null)
        local ENABLED
        ENABLED=$(systemctl is-enabled "$SVC" 2>/dev/null || echo "disabled")

        case "$ACTIVO" in
            active)
                echo -e "  ${VERDE}● ${SVC}${RESET}  ${GRIS}(${ENABLED})${RESET}"
                ;;
            activating)
                echo -e "  ${AMARILLO}◌ ${SVC}${RESET}  iniciando…"
                ;;
            *)
                echo -e "  ${ROJO}✗ ${SVC}${RESET}  ${ROJO}${ACTIVO}${RESET}  ${GRIS}(${ENABLED})${RESET}"
                CAIDOS+=("$SVC")
                ;;
        esac
    done

    echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"

    if [ ${#CAIDOS[@]} -eq 0 ]; then
        echo -e "  ${VERDE}Todos los servicios activos.${RESET}"
    else
        echo -e "  ${ROJO}Caídos: ${CAIDOS[*]}${RESET}"
        if $TELEGRAM; then
            local DIR
            DIR="$(dirname "$(readlink -f "$0")")"
            if [[ -x "${DIR}/telegram-alert.sh" ]]; then
                "${DIR}/telegram-alert.sh" "🔴 Servicios caídos en $(hostname): ${CAIDOS[*]}"
            fi
        fi
    fi

    $WATCH && echo -e "\n  ${GRIS}Actualizando cada ${INTERVALO}s — Ctrl+C para salir${RESET}"
}

if $WATCH; then
    trap 'echo -e "\n${VERDE}Monitor detenido.${RESET}"; exit 0' INT TERM
    while true; do
        mostrar
        sleep "$INTERVALO"
    done
else
    mostrar
fi
