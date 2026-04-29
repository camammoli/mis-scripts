#!/bin/bash
# =============================================================================
# backup-rsync.sh — Backup incremental con rsync
# Debian 12 Bookworm | No requiere root (para backup del propio home)
# Uso: ./backup-rsync.sh
#
# CONFIGURAR las variables de la sección "CONFIGURACIÓN" antes de usar.
# Requiere rsync: sudo apt install rsync
# =============================================================================

# =============================================================================
# CONFIGURACIÓN — Editá estos valores según tu entorno
# =============================================================================

# Directorios a respaldar (rutas absolutas o con $HOME)
ORIGENES=(
    "$HOME/Documentos"
    "$HOME/Scripts"
    "$HOME/Escritorio"
    # Agregá o quitá directorios según tus necesidades:
    # "$HOME/Proyectos"
    # "$HOME/Imágenes"
)

# Destino del backup. Ejemplos:
#   Disco externo  : DESTINO="/media/$USER/MiDisco/backups"
#   Carpeta local  : DESTINO="$HOME/Backups"
#   Servidor SSH   : DESTINO="usuario@192.168.1.100:/backups"
DESTINO="/media/$USER/Backup"

# Archivo de log (se crea automáticamente si no existe)
LOG="$HOME/Backups/backup-rsync.log"

# Patrones a excluir (no se copian)
EXCLUIR=(
    "*.tmp"
    "*.log"
    ".cache"
    "node_modules"
    "__pycache__"
    ".git"
    "*.iso"
    "*.vmdk"
)

# =============================================================================
# NO MODIFICAR DEBAJO DE ESTA LÍNEA
# =============================================================================

VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

FECHA=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p "$(dirname "$LOG")"

log() {
    echo -e "$1"
    echo "$(date '+%H:%M:%S') ${1//\\033\[[0-9;]*m/}" >> "$LOG"
}

if ! command -v rsync &>/dev/null; then
    echo -e "${ROJO}Error: rsync no está instalado. Ejecutá: sudo apt install rsync${RESET}"
    exit 1
fi

if [[ "$DESTINO" != *@* ]]; then
    if [ ! -d "$DESTINO" ]; then
        echo -e "${AMARILLO}El directorio destino no existe: ${DESTINO}${RESET}"
        read -rp "¿Crearlo? [s/N]: " RESP
        if [[ "$RESP" =~ ^[sS]$ ]]; then
            mkdir -p "$DESTINO" || { echo -e "${ROJO}No se pudo crear el directorio.${RESET}"; exit 1; }
        else
            exit 0
        fi
    fi
fi

echo "" >> "$LOG"
log "${CYAN}===== BACKUP — ${FECHA} =====${RESET}"
log "  Destino: ${DESTINO}"

EXCL_OPTS=()
for PAT in "${EXCLUIR[@]}"; do
    EXCL_OPTS+=("--exclude=${PAT}")
done

ERRORES=0

for ORIGEN in "${ORIGENES[@]}"; do
    if [ ! -d "$ORIGEN" ]; then
        log "${AMARILLO}  ⚠ Directorio no encontrado, se omite: ${ORIGEN}${RESET}"
        continue
    fi

    NOMBRE=$(basename "$ORIGEN")
    log "${AMARILLO}  → Copiando: ${ORIGEN}${RESET}"

    rsync -av --delete \
        "${EXCL_OPTS[@]}" \
        "$ORIGEN" \
        "${DESTINO}/" \
        >> "$LOG" 2>&1

    if [ $? -eq 0 ]; then
        log "${VERDE}    ✓ ${NOMBRE} completado.${RESET}"
    else
        log "${ROJO}    ✗ Error copiando ${NOMBRE}. Revisá el log: ${LOG}${RESET}"
        ERRORES=$((ERRORES + 1))
    fi
done

if [ "$ERRORES" -eq 0 ]; then
    log "${VERDE}===== BACKUP COMPLETADO SIN ERRORES =====${RESET}"
else
    log "${ROJO}===== BACKUP COMPLETADO CON ${ERRORES} ERROR(ES) =====${RESET}"
fi

echo ""
echo -e "${VERDE}Log guardado en: ${LOG}${RESET}"
echo ""
