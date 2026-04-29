#!/bin/bash
# =============================================================================
# groq.sh — Cliente de Groq AI para la terminal
# Groq ofrece inferencia ultrarrápida y gratuita (sin tarjeta de crédito)
# Modelos disponibles: llama-3.3-70b-versatile, llama-3.1-8b-instant,
#                      mixtral-8x7b-32768, gemma2-9b-it, y otros
#
# CONFIGURACIÓN DE API KEY:
#   1. Registrate gratis en https://console.groq.com
#   2. Creá una API key en "API Keys"
#   3. Guardala:
#      echo 'tu-clave' > ~/.config/groq_api_key && chmod 600 ~/.config/groq_api_key
#   O con variable de entorno:
#      export GROQ_API_KEY="tu-clave"
#
# MODOS DE USO:
#   ./groq.sh "pregunta"                     → respuesta única
#   ./groq.sh                                → chat interactivo con historial
#   echo "pregunta" | ./groq.sh              → desde pipe
#   df -h | ./groq.sh "analizá esto"         → pipe con prompt adicional
#   ./groq.sh -m llama-3.1-8b-instant "..."  → modelo más rápido
#   ./groq.sh -l                             → listar modelos disponibles
#   ./groq.sh -h                             → ayuda
#
# DEPENDENCIAS: curl, jq
#   sudo apt install curl jq
# =============================================================================

API_KEY=""
MODEL_DEFAULT="llama-3.3-70b-versatile"
CONFIG_FILE="$HOME/.config/groq_api_key"
API_URL="https://api.groq.com/openai/v1/chat/completions"

CYAN='\033[0;36m'
AMARILLO='\033[1;33m'
VERDE='\033[0;32m'
ROJO='\033[0;31m'
GRIS='\033[0;90m'
NEGRITA='\033[1m'
RESET='\033[0m'

SISTEMA="Sos un asistente técnico experto en Linux, administración de sistemas Debian y programación. Fecha: $(date '+%A %d/%m/%Y %H:%M'). Ubicación: Mendoza, Argentina. Respondé siempre en español rioplatense, de forma clara y concisa."

uso() {
    echo -e "${CYAN}Uso:${RESET}"
    echo "  ./groq.sh \"pregunta\"                  → respuesta única"
    echo "  ./groq.sh                              → chat interactivo"
    echo "  echo \"texto\" | ./groq.sh               → desde pipe"
    echo "  comando | ./groq.sh \"prompt adicional\" → pipe + pregunta"
    echo "  ./groq.sh -m <modelo> \"pregunta\"       → elegir modelo"
    echo "  ./groq.sh -l                           → listar modelos"
    echo "  ./groq.sh -h                           → esta ayuda"
    echo ""
    echo -e "${CYAN}Modelos recomendados:${RESET}"
    echo "  llama-3.3-70b-versatile   (por defecto, el más capaz)"
    echo "  llama-3.1-8b-instant      (el más rápido, respuestas al instante)"
    echo "  mixtral-8x7b-32768        (contexto muy largo, 32K tokens)"
    echo "  gemma2-9b-it              (de Google, bueno para código)"
}

resolver_api_key() {
    [ -n "$API_KEY" ] && return
    [ -n "$GROQ_API_KEY" ] && API_KEY="$GROQ_API_KEY" && return
    if [ -f "$CONFIG_FILE" ]; then
        API_KEY=$(tr -d '[:space:]' < "$CONFIG_FILE")
        [ -n "$API_KEY" ] && return
    fi
    echo -e "${ROJO}Error: No se encontró la API key de Groq.${RESET}"
    echo -e "  Registrate gratis en: ${AMARILLO}https://console.groq.com${RESET}"
    echo -e "  Luego guardá tu key:  ${AMARILLO}echo 'tu-clave' > ~/.config/groq_api_key${RESET}"
    exit 1
}

listar_modelos() {
    resolver_api_key
    echo -e "${GRIS}Consultando modelos disponibles...${RESET}"
    curl -s "https://api.groq.com/openai/v1/models" \
        -H "Authorization: Bearer ${API_KEY}" | \
        jq -r '.data[] | select(.active // true) | "  \(.id)"' 2>/dev/null | sort
}

llamar_api() {
    local MESSAGES_JSON="$1"

    curl -s "$API_URL" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg model "$MODEL" \
            --argjson messages "$MESSAGES_JSON" \
            '{
                model: $model,
                messages: $messages,
                temperature: 0.7,
                max_tokens: 2048
            }')"
}

extraer_texto() {
    echo "$1" | jq -r '.choices[0].message.content' 2>/dev/null
}

mostrar_respuesta() {
    local TEXTO="$1"
    echo ""
    echo -e "${CYAN}┌─ Groq · ${MODEL} ──────────────────────────────────${RESET}"
    while IFS= read -r LINEA; do
        echo -e "${CYAN}│${RESET} $LINEA"
    done <<< "$TEXTO"
    echo -e "${CYAN}└─────────────────────────────────────────────────────${RESET}"
    echo ""
}

# ── Parsear argumentos ────────────────────────────────────────────────────────

MODEL="$MODEL_DEFAULT"
PROMPT=""
PIPE_DATA=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    uso; exit 0 ;;
        -l|--list)    listar_modelos; exit 0 ;;
        -m|--model)   MODEL="$2"; shift 2 ;;
        -*)           echo -e "${ROJO}Opción desconocida: $1${RESET}"; uso; exit 1 ;;
        *)            PROMPT="$1"; shift ;;
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

if [ ! -t 0 ]; then
    PIPE_DATA=$(cat)
fi

# Combinar pipe + prompt
if [ -n "$PIPE_DATA" ] && [ -n "$PROMPT" ]; then
    PROMPT_FINAL="${PROMPT}"$'\n\n```\n'"${PIPE_DATA}"$'\n```'
elif [ -n "$PIPE_DATA" ]; then
    PROMPT_FINAL="$PIPE_DATA"
else
    PROMPT_FINAL="$PROMPT"
fi

# ── Modo pregunta única ───────────────────────────────────────────────────────

if [ -n "$PROMPT_FINAL" ]; then
    MESSAGES=$(jq -n \
        --arg sys "$SISTEMA" \
        --arg usr "$PROMPT_FINAL" \
        '[
            {"role":"system","content":$sys},
            {"role":"user","content":$usr}
        ]')

    echo -e "${GRIS}Consultando Groq...${RESET}"
    RESPONSE=$(llamar_api "$MESSAGES")
    TEXTO=$(extraer_texto "$RESPONSE")

    if [ "$TEXTO" != "null" ] && [ -n "$TEXTO" ]; then
        mostrar_respuesta "$TEXTO"
    else
        echo -e "${ROJO}Error en la respuesta:${RESET}"
        echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
        exit 1
    fi
    exit 0
fi

# ── Modo chat interactivo ─────────────────────────────────────────────────────

HIST_FILE=$(mktemp /tmp/groq_chat_XXXXXX.json)
trap 'rm -f "$HIST_FILE"' EXIT

# Inicializar con mensaje de sistema
jq -n --arg sys "$SISTEMA" \
    '[{"role":"system","content":$sys}]' > "$HIST_FILE"

echo ""
echo -e "${NEGRITA}${CYAN}  Chat con Groq · ${MODEL}${RESET}"
echo -e "${GRIS}  Comandos: 'salir' para terminar | 'limpiar' para nueva conversación | 'modelo <nombre>' para cambiar${RESET}"
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
            jq -n --arg sys "$SISTEMA" \
                '[{"role":"system","content":$sys}]' > "$HIST_FILE"
            echo -e "${GRIS}Conversación reiniciada.${RESET}\n"
            continue
            ;;
        modelo\ *)
            NUEVO_MOD="${INPUT#modelo }"
            MODEL="$NUEVO_MOD"
            echo -e "${GRIS}Modelo cambiado a: ${MODEL}${RESET}\n"
            continue
            ;;
    esac

    # Agregar mensaje del usuario al historial
    NUEVO_HIST=$(jq \
        --arg msg "$INPUT" \
        '. + [{"role":"user","content":$msg}]' \
        "$HIST_FILE")

    echo -e "${GRIS}...${RESET}"
    RESPONSE=$(llamar_api "$NUEVO_HIST")
    TEXTO=$(extraer_texto "$RESPONSE")

    if [ "$TEXTO" = "null" ] || [ -z "$TEXTO" ]; then
        echo -e "${ROJO}Error en la respuesta:${RESET}"
        echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
        continue
    fi

    # Guardar historial con la respuesta
    echo "$NUEVO_HIST" | jq \
        --arg resp "$TEXTO" \
        '. + [{"role":"assistant","content":$resp}]' \
        > "$HIST_FILE"

    mostrar_respuesta "$TEXTO"
done
