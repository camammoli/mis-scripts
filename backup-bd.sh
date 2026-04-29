#!/bin/bash
# =============================================================================
# backup-bd.sh — Descarga dumps de bases de datos desde un servidor remoto
# Requiere: curl, gzip
#
# Asume que el servidor tiene un endpoint que recibe X-Api-Secret y devuelve
# el dump SQL del nombre de base de datos pedido como parámetro ?db=nombre
#
# CONFIGURACIÓN: editá las variables de abajo antes de usar.
# Cron sugerido (cada día a las 3:00):
#   0 3 * * * /ruta/backup-bd.sh >> $HOME/Logs/backup-bd.log 2>&1
# =============================================================================

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

# URL del endpoint de backup en tu servidor
BACKUP_URL="https://tu-servidor.com/admin/backup_bd.php"

# Secret compartido con el servidor para autenticar la petición
API_SECRET="tu_secret_aqui"

# Directorio donde se guardan los backups
BACKUP_DIR="$HOME/Backups/BD"

# Cuántos días guardar los backups antes de borrarlos
KEEP_DAYS=14

# Bases de datos a respaldar (agregar o quitar)
BASES_DE_DATOS=(
    "mi_base_principal"
    "mi_base_secundaria"
)

# =============================================================================
# NO MODIFICAR DEBAJO DE ESTA LÍNEA
# =============================================================================

set -euo pipefail
LOG_PREFIX="[backup-bd] $(date '+%Y-%m-%d %H:%M:%S')"
mkdir -p "$BACKUP_DIR"

backup_db() {
    local db="$1"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local outfile="${BACKUP_DIR}/${db}_${timestamp}.sql.gz"
    local tmpfile="${BACKUP_DIR}/.tmp_${db}_${timestamp}.sql"

    echo "${LOG_PREFIX} Descargando ${db}..."
    if curl -sf \
        -H "X-Api-Secret: ${API_SECRET}" \
        "${BACKUP_URL}?db=${db}" \
        -o "$tmpfile" \
        --max-time 120; then

        local size
        size=$(wc -c < "$tmpfile")
        if [ "$size" -lt 100 ]; then
            echo "${LOG_PREFIX} ERROR: respuesta demasiado pequeña (${size} bytes) para ${db}"
            rm -f "$tmpfile"
            return 1
        fi

        gzip -c "$tmpfile" > "$outfile"
        rm -f "$tmpfile"
        local gz_size
        gz_size=$(du -sh "$outfile" | cut -f1)
        echo "${LOG_PREFIX} OK: ${outfile} (${gz_size})"
    else
        echo "${LOG_PREFIX} ERROR: curl falló para ${db}"
        rm -f "$tmpfile"
        return 1
    fi
}

for DB in "${BASES_DE_DATOS[@]}"; do
    backup_db "$DB" || true
done

echo "${LOG_PREFIX} Limpiando backups de más de ${KEEP_DAYS} días..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime "+${KEEP_DAYS}" -delete

echo "${LOG_PREFIX} Backups actuales:"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "${LOG_PREFIX} (sin backups)"
