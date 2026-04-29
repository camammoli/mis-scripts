#!/bin/bash
# =============================================================================
# telegram-alert.sh — Alerta del sistema vía Telegram
# Debian 12 Bookworm | No requiere root
#
# Envía alertas al bot de Telegram cuando disco, RAM o CPU superan umbrales.
# Ideal para correr con cron cada hora o desde otros scripts de monitoreo.
#
# CONFIGURACIÓN DE CREDENCIALES (elegí una opción):
#   1. Archivo de configuración (recomendado):
#      echo 'TOKEN:CHAT_ID' > ~/.config/telegram_alert && chmod 600 ~/.config/telegram_alert
#   2. Variables de entorno:
#      export TELEGRAM_TOKEN="tu-token"
#      export TELEGRAM_CHAT_ID="tu-chat-id"
#   3. Hardcodeadas abajo en TOKEN= y CHAT_ID=
#
# MODOS DE USO:
#   ./telegram-alert.sh               → verificar umbrales y alertar si se superan
#   ./telegram-alert.sh "mensaje"     → enviar mensaje libre (sin verificar umbrales)
#   ./telegram-alert.sh --test        → enviar mensaje de prueba
#   ./telegram-alert.sh --status      → mostrar estado actual sin enviar
#   echo "texto" | ./telegram-alert.sh → enviar desde pipe
#
# CRON sugerido (verificar cada hora):
#   0 * * * * /ruta/telegram-alert.sh >> $HOME/Logs/telegram-alert.log 2>&1
# =============================================================================

# ── Credenciales ──────────────────────────────────────────────────────────────

TOKEN=""
CHAT_ID=""
CONFIG_FILE="$HOME/.config/telegram_alert"

# ── Umbrales de alerta ────────────────────────────────────────────────────────

UMBRAL_DISCO=85       # % de uso de disco para alertar
UMBRAL_RAM=90         # % de uso de RAM para alertar
UMBRAL_SWAP=70        # % de uso de SWAP para alertar
UMBRAL_CARGA=4.0      # load average (1 min) para alertar

# ── Configuración ─────────────────────────────────────────────────────────────

HOST=$(hostname)
COOLDOWN_FILE="/tmp/telegram_alert_cooldown_${HOST}"
COOLDOWN_MINUTOS=60   # No repetir la misma alerta por este tiempo

ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
RESET='\033[0m'

# ── Funciones ─────────────────────────────────────────────────────────────────

resolver_credenciales() {
    [[ -n "$TOKEN" && -n "$CHAT_ID" ]] && return 0

    if [[ -n "$TELEGRAM_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        TOKEN="$TELEGRAM_TOKEN"
        CHAT_ID="$TELEGRAM_CHAT_ID"
        return 0
    fi

    if [[ -f "$CONFIG_FILE" ]]; then
        TOKEN=$(cut -d: -f1 < "$CONFIG_FILE" | tr -d '[:space:]')
        CHAT_ID=$(cut -d: -f2 < "$CONFIG_FILE" | tr -d '[:space:]')
        [[ -n "$TOKEN" && -n "$CHAT_ID" ]] && return 0
    fi

    echo -e "${ROJO}Error: credenciales de Telegram no configuradas.${RESET}"
    echo "  Opción 1: echo 'TOKEN:CHAT_ID' > ~/.config/telegram_alert"
    echo "  Opción 2: export TELEGRAM_TOKEN=... && export TELEGRAM_CHAT_ID=..."
    exit 1
}

enviar_mensaje() {
    local TEXTO="$1"
    local URL="https://api.telegram.org/bot${TOKEN}/sendMessage"

    local RESP
    RESP=$(curl -s -X POST "$URL" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${TEXTO}" \
        -d "parse_mode=Markdown" \
        --max-time 15)

    if echo "$RESP" | grep -q '"ok":true'; then
        echo -e "${VERDE}✓ Mensaje enviado a Telegram.${RESET}"
        return 0
    else
        echo -e "${ROJO}✗ Error al enviar a Telegram:${RESET}"
        echo "$RESP"
        return 1
    fi
}

en_cooldown() {
    local CLAVE="$1"
    local ARCHIVO="${COOLDOWN_FILE}_${CLAVE}"
    if [[ -f "$ARCHIVO" ]]; then
        local HACE
        HACE=$(( $(date +%s) - $(stat -c %Y "$ARCHIVO") ))
        [[ $HACE -lt $((COOLDOWN_MINUTOS * 60)) ]] && return 0
    fi
    return 1
}

marcar_cooldown() {
    touch "${COOLDOWN_FILE}_${1}"
}

limpiar_cooldown() {
    local CLAVE="$1"
    rm -f "${COOLDOWN_FILE}_${CLAVE}"
}

verificar_disco() {
    local ALERTAS=()
    while IFS= read -r line; do
        local pct mount
        pct=$(echo "$line" | awk '{gsub(/%/,""); print $1}')
        mount=$(echo "$line" | awk '{print $2}')
        if [[ "$pct" =~ ^[0-9]+$ ]] && [ "$pct" -ge "$UMBRAL_DISCO" ]; then
            ALERTAS+=("💾 *Disco ${mount}* al ${pct}% (umbral: ${UMBRAL_DISCO}%)")
            marcar_cooldown "disco_${mount//\//_}"
        else
            limpiar_cooldown "disco_${mount//\//_}"
        fi
    done < <(df -h --output=pcent,target -x tmpfs -x devtmpfs -x udev 2>/dev/null | tail -n +2)
    printf '%s\n' "${ALERTAS[@]}"
}

verificar_ram() {
    local TOTAL USADO PCT
    read -r TOTAL USADO < <(free | awk 'NR==2{print $2, $3}')
    PCT=$(awk "BEGIN{printf \"%d\", ($USADO/$TOTAL)*100}")
    if [ "$PCT" -ge "$UMBRAL_RAM" ]; then
        echo "🧠 *RAM* al ${PCT}% (umbral: ${UMBRAL_RAM}%)"
        marcar_cooldown "ram"
    else
        limpiar_cooldown "ram"
    fi
}

verificar_swap() {
    local TOTAL USADO PCT
    read -r TOTAL USADO < <(free | awk 'NR==3{print $2, $3}')
    if [ "$TOTAL" -gt 0 ]; then
        PCT=$(awk "BEGIN{printf \"%d\", ($USADO/$TOTAL)*100}")
        if [ "$PCT" -ge "$UMBRAL_SWAP" ]; then
            echo "♻️ *SWAP* al ${PCT}% (umbral: ${UMBRAL_SWAP}%)"
            marcar_cooldown "swap"
        else
            limpiar_cooldown "swap"
        fi
    fi
}

verificar_carga() {
    local CARGA
    CARGA=$(cut -d' ' -f1 /proc/loadavg)
    if awk "BEGIN{exit !($CARGA > $UMBRAL_CARGA)}"; then
        echo "⚙️ *Carga CPU* en ${CARGA} (umbral: ${UMBRAL_CARGA})"
        marcar_cooldown "carga"
    else
        limpiar_cooldown "carga"
    fi
}

mostrar_estado() {
    echo ""
    echo "Estado actual del sistema:"
    echo ""
    df -h --output=pcent,target -x tmpfs -x devtmpfs -x udev 2>/dev/null | tail -n +2 | \
        awk '{gsub(/%/,""); printf "  Disco %-20s %3s%% (umbral: '"$UMBRAL_DISCO"'%%)\n", $2, $1}'
    free | awk 'NR==2{printf "  RAM        %3d%% (umbral: '"$UMBRAL_RAM"'%%)\n", int($3/$2*100)}'
    free | awk 'NR==3{if($2>0) printf "  SWAP       %3d%% (umbral: '"$UMBRAL_SWAP"'%%)\n", int($3/$2*100)}'
    echo "  Carga      $(cut -d' ' -f1 /proc/loadavg) (umbral: ${UMBRAL_CARGA})"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

case "${1:-}" in
    --test)
        resolver_credenciales
        enviar_mensaje "🔔 *Test desde ${HOST}*
\`telegram-alert.sh\` funcionando correctamente.
\`$(date '+%d/%m/%Y %H:%M:%S')\`"
        exit $?
        ;;
    --status)
        mostrar_estado
        exit 0
        ;;
    -h|--help)
        sed -n '/^# MODOS/,/^# =/p' "$0" | grep "^#" | sed 's/^# \?//'
        exit 0
        ;;
esac

# Modo pipe o mensaje libre
if [ ! -t 0 ] && [[ -z "${1:-}" ]]; then
    TEXTO=$(cat)
    resolver_credenciales
    enviar_mensaje "📩 *${HOST}*: ${TEXTO}"
    exit $?
fi

if [[ -n "${1:-}" ]]; then
    resolver_credenciales
    enviar_mensaje "📩 *${HOST}*: ${1}"
    exit $?
fi

# Modo automático: verificar umbrales
resolver_credenciales

ALERTAS=()
while IFS= read -r a; do [[ -n "$a" ]] && ALERTAS+=("$a"); done < <(verificar_disco)
while IFS= read -r a; do [[ -n "$a" ]] && ALERTAS+=("$a"); done < <(verificar_ram)
while IFS= read -r a; do [[ -n "$a" ]] && ALERTAS+=("$a"); done < <(verificar_swap)
while IFS= read -r a; do [[ -n "$a" ]] && ALERTAS+=("$a"); done < <(verificar_carga)

if [ ${#ALERTAS[@]} -eq 0 ]; then
    echo -e "${VERDE}Sistema OK — sin alertas.${RESET}"
    exit 0
fi

MENSAJE="⚠️ *Alerta en ${HOST}*
$(date '+%d/%m/%Y %H:%M')

$(printf '%s\n' "${ALERTAS[@]}")"

echo -e "${AMARILLO}Alertas detectadas:${RESET}"
printf '  %s\n' "${ALERTAS[@]}"

enviar_mensaje "$MENSAJE"
