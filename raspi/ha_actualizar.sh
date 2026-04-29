#!/bin/bash
# =============================================================================
# actualizar.sh — Actualizar Home Assistant en Docker
# Uso: sudo ./actualizar.sh
# =============================================================================

CONTAINER_NAME="homeassistant"
IMAGE="ghcr.io/home-assistant/home-assistant:stable"
CONFIG_DIR="/home/carlos/homeassistant"
BACKUP_DIR="/home/carlos/ha_backups"
KEEP_BACKUPS=10        # cuántos backups conservar
HA_WAIT=90             # segundos a esperar para que HA arranque
TELEGRAM_SCRIPT="/home/carlos/scripts/telegram-alert.sh"

notify() {
    local msg="$1"
    echo "$msg"
    [[ -x "$TELEGRAM_SCRIPT" ]] && "$TELEGRAM_SCRIPT" "$msg"
}

echo "### [1/6] Creando backup de configuración..."
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/ha_backup_$(date +%F_%H-%M).tar.gz"
tar -czf "$BACKUP_FILE" -C "$CONFIG_DIR" . && echo "    → $BACKUP_FILE"

# Rotar backups antiguos
TOTAL_BACKUPS=$(ls "$BACKUP_DIR"/ha_backup_*.tar.gz 2>/dev/null | wc -l)
if [[ "$TOTAL_BACKUPS" -gt "$KEEP_BACKUPS" ]]; then
    EXCESO=$((TOTAL_BACKUPS - KEEP_BACKUPS))
    ls -t "$BACKUP_DIR"/ha_backup_*.tar.gz | tail -n "$EXCESO" | xargs rm -f
    echo "    → Eliminados $EXCESO backups antiguos (conservando $KEEP_BACKUPS)"
fi

echo "### [2/6] Bajando imagen nueva..."
docker pull "$IMAGE"

echo "### [3/6] Parando contenedor..."
docker stop "$CONTAINER_NAME" 2>/dev/null || echo "    (contenedor no estaba corriendo)"

echo "### [4/6] Eliminando contenedor viejo..."
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo "### [5/6] Lanzando contenedor nuevo..."
docker run -d --name "$CONTAINER_NAME" \
    --restart=unless-stopped \
    -e TZ=America/Argentina/Mendoza \
    -v "$CONFIG_DIR":/config \
    --network host \
    "$IMAGE"

echo "### [6/6] Verificando que Home Assistant arranque (hasta ${HA_WAIT}s)..."
STARTED=false
for ((i=1; i<=HA_WAIT; i+=5)); do
    sleep 5
    STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
    if [[ "$STATUS" == "running" ]]; then
        # Verificar que el puerto 8123 responda
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8123 | grep -qE "^(200|302|401)"; then
            STARTED=true
            break
        fi
    fi
    echo "    Esperando... ${i}s (estado: ${STATUS})"
done

# Limpieza
docker image prune -f > /dev/null
docker container prune -f > /dev/null

if $STARTED; then
    notify "✅ *Home Assistant actualizado* en $(hostname) — $(date '+%Y-%m-%d %H:%M') — arrancó correctamente"
else
    notify "⚠️ *Home Assistant actualizado* pero no respondió en ${HA_WAIT}s — verificar manualmente"
fi
