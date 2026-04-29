#!/bin/bash
# =============================================================================
# gemini.sh — Cliente de Google Gemini AI para la terminal
# Debian 12 Bookworm | No requiere root
#
# CONFIGURACIÓN DE API KEY (elegí una opción):
#   1. Archivo de configuración (recomendado):
#      echo 'tu-clave' > ~/.config/gemini_api_key && chmod 600 ~/.config/gemini_api_key
#   2. Variable de entorno:
#      export GEMINI_API_KEY="tu-clave"
#   3. Hardcodeada abajo en API_KEY=
#
# MODOS DE USO:
#   ./gemini.sh "pregunta"                    → respuesta única y sale
#   ./gemini.sh                               → chat interactivo con historial
#   echo "pregunta" | ./gemini.sh             → desde pipe
#   ./gemini.sh -m gemini-1.5-pro "pregunta"  → elegir modelo
#   ./gemini.sh -s "pregunta"                 → sin búsqueda web
#   ./gemini.sh -h                            → ayuda
#
# DEPENDENCIAS: curl, jq
#   sudo apt install curl jq
# =============================================================================

API_KEY=""
MODEL_DEFAULT="gemini-2.0-flash"
CONFIG_FILE="$HOME/.config/gemini_api_key"

CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
VERDE='\033[0;32m'
ROJO='\033[0;31m'
GRIS='\033[0;90m'
NEGRITA='\033[1m'
RESET='\033[0m'

uso() {
    echo -e "${CYAN}Uso:${RESET}"
    echo "  ./gemini.sh \"pregunta\"               → respuesta única"
    echo "  ./gemini.sh                           → chat interactivo"
    echo "  echo \"pregunta\" | ./gemini.sh         → desde pipe"
    echo "  ./gemini.sh -m <modelo> \"pregunta\"    → elegir modelo"
    echo "  ./gemini.sh -s \"pregunta\"             → sin búsqueda web"
    echo ""
    echo -e "${CYAN}Modelos:${RESET}"
    echo "  gemini-2.0-flash   (por defecto, rápido + búsqueda web)"
    echo "  gemini-1.5-flash   (rápido, sin búsqueda)"
    echo "  gemini-1.5-pro     (más capaz, más lento)"
}

resolver_api_key() {
    [ -n "$API_KEY" ] && return
    [ -n "$GEMINI_API_KEY" ] && API_KEY="$GEMINI_API_KEY" && return
    if [ -f "$CONFIG_FILE" ]; then
        API_KEY=$(tr -d '[:space:]' < "$CONFIG_FILE")
        [ -n "$API_KEY" ] && return
    fi
    echo -e "${ROJO}Error: No se encontró la API key de Gemini.${RESET}"
    echo -e "Configurala con: ${AMARILLO}echo 'tu-clave' > ~/.config/gemini_api_key${RESET}"
    exit 1
}

llamar_api() {
    local CONTENTS_JSON="$1"
    local SEARCH="$2"
    local URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}"

    local PAYLOAD
    if [ "$SEARCH" = "true" ]; then
        PAYLOAD=$(jq -n \
            --argjson contents "$CONTENTS_JSON" \
            '{
                tools: [{ google_search: {} }],
                generationConfig: { temperature: 0.7, maxOutputTokens: 2048 },
                contents: $contents
            }')
    else
        PAYLOAD=$(jq -n \
            --argjson contents "$CONTENTS_JSON" \
            '{
                generationConfig: { temperature: 0.7, maxOutputTokens: 2048 },
                contents: $contents
            }')
    fi

    curl -s -X POST "$URL" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD"
}

extraer_texto() {
    echo "$1" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null
}

mostrar_respuesta() {
    local TEXTO="$1"
    echo ""
    echo -e "${CYAN}┌─ Gemini (${MODEL}) ──────────────────────────────────${RESET}"
    while IFS= read -r LINEA; do
        echo -e "${CYAN}│${RESET} $LINEA"
    done <<< "$TEXTO"
    echo -e "${CYAN}└─────────────────────────────────────────────────────${RESET}"
    echo ""
}

# ── Parsear argumentos ────────────────────────────────────────────────────────

MODEL="$MODEL_DEFAULT"
SEARCH="true"
PROMPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) uso; exit 0 ;;
        -m|--model) MODEL="$2"; shift 2 ;;
        -s|--no-search) SEARCH="false"; shift ;;
        -*) echo -e "${ROJO}Opción desconocida: $1${RESET}"; uso; exit 1 ;;
        *) PROMPT="$1"; shift ;;
    esac
done

# ── Verificar dependencias ────────────────────────────────────────────────────

for DEP in curl jq; do
    if ! command -v "$DEP" &>/dev/null; then
        echo -e "${ROJO}Error: '$DEP' no está instalado. Ejecutá: sudo apt install $DEP${RESET}"
        exit 1
    fi
done

resolver_api_key

# ── Modo pipe ─────────────────────────────────────────────────────────────────

if [ ! -t 0 ] && [ -z "$PROMPT" ]; then
    PROMPT=$(cat)
fi

CONTEXTO="Fecha y hora: $(date '+%A %d/%m/%Y %H:%M'). Ubicación: Mendoza, Argentina."

# ── Modo pregunta única ───────────────────────────────────────────────────────

if [ -n "$PROMPT" ]; then
    TEXTO_COMPLETO="${CONTEXTO}"$'\n\n'"${PROMPT}"

    CONTENTS=$(jq -n \
        --arg texto "$TEXTO_COMPLETO" \
        '[{"role":"user","parts":[{"text":$texto}]}]')

    echo -e "${GRIS}Consultando Gemini...${RESET}"
    RESPONSE=$(llamar_api "$CONTENTS" "$SEARCH")
    TEXTO=$(extraer_texto "$RESPONSE")

    if [ "$TEXTO" != "null" ] && [ -n "$TEXTO" ]; then
        mostrar_respuesta "$TEXTO"
    else
        echo -e "${ROJO}Error en la respuesta de la API:${RESET}"
        echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
        exit 1
    fi
    exit 0
fi

# ── Modo chat interactivo ─────────────────────────────────────────────────────

HIST_FILE=$(mktemp /tmp/gemini_chat_XXXXXX.json)
trap 'rm -f "$HIST_FILE"' EXIT

# Mensaje de sistema inicial
jq -n \
    --arg ctx "Sos un asistente técnico experto en Linux, administración de sistemas y programación. ${CONTEXTO} Respondé siempre en español rioplatense." \
    '[{"role":"user","parts":[{"text":$ctx}]},{"role":"model","parts":[{"text":"Entendido, estoy listo para ayudarte."}]}]' \
    > "$HIST_FILE"

echo ""
echo -e "${NEGRITA}${CYAN}  Chat con Gemini (${MODEL})${RESET}"
echo -e "${GRIS}  Búsqueda web: $([ "$SEARCH" = "true" ] && echo "activada" || echo "desactivada")${RESET}"
echo -e "${GRIS}  Comandos especiales: 'salir' | 'limpiar' para nueva conversación${RESET}"
echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"
echo ""

while true; do
    echo -ne "${VERDE}Vos: ${RESET}"
    IFS= read -r INPUT

    [ -z "$INPUT" ] && continue

    case "${INPUT,,}" in
        salir|exit|quit|chau|bye)
            echo -e "${GRIS}Hasta luego.${RESET}"
            break
            ;;
        limpiar|clear|reset|nueva)
            jq -n \
                --arg ctx "Sos un asistente técnico experto en Linux. $(date '+%H:%M') Respondé en español rioplatense." \
                '[{"role":"user","parts":[{"text":$ctx}]},{"role":"model","parts":[{"text":"Listo, nueva conversación."}]}]' \
                > "$HIST_FILE"
            echo -e "${GRIS}Conversación reiniciada.${RESET}\n"
            continue
            ;;
    esac

    # Agregar mensaje del usuario al historial
    NUEVO_HIST=$(jq \
        --arg msg "$INPUT" \
        '. + [{"role":"user","parts":[{"text":$msg}]}]' \
        "$HIST_FILE")

    echo -e "${GRIS}...${RESET}"
    RESPONSE=$(llamar_api "$NUEVO_HIST" "$SEARCH")
    TEXTO=$(extraer_texto "$RESPONSE")

    if [ "$TEXTO" = "null" ] || [ -z "$TEXTO" ]; then
        echo -e "${ROJO}Error en la respuesta:${RESET}"
        echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
        continue
    fi

    # Guardar historial con la respuesta del modelo
    echo "$NUEVO_HIST" | jq \
        --arg resp "$TEXTO" \
        '. + [{"role":"model","parts":[{"text":$resp}]}]' \
        > "$HIST_FILE"

    mostrar_respuesta "$TEXTO"
done
