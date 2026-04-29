#!/bin/bash
# =============================================================================
# restic_backup.sh — Backup incremental con Restic a Google Drive (rclone)
# Requiere: restic, rclone configurado con remote "gdrive"
# Contraseña: ~/.config/restic_password (chmod 600, crearlo antes de usar)
# Cron sugerido: 0 3 * * * /home/carlos/scripts/restic_backup.sh >> /home/carlos/scripts/restic.log 2>&1
# =============================================================================

PASSWORD_FILE="$HOME/.config/restic_password"
LOG_FILE="$HOME/scripts/restic.log"
BACKUP_TAG="sistema"
KEEP_DAILY=7
KEEP_WEEKLY=4

# Telegram (opcional — script telegram-alert.sh)
TELEGRAM_SCRIPT="$HOME/scripts/telegram-alert.sh"

notify() {
    local msg="$1"
    echo "$msg"
    [[ -x "$TELEGRAM_SCRIPT" ]] && "$TELEGRAM_SCRIPT" "$msg"
}

# Verificar contraseña
if [[ ! -f "$PASSWORD_FILE" ]]; then
    echo "❌ No existe $PASSWORD_FILE"
    echo "   Crealo con: echo 'tu-contraseña' > $PASSWORD_FILE && chmod 600 $PASSWORD_FILE"
    exit 1
fi

export RESTIC_REPOSITORY="rclone:gdrive:restic-backups"
export RESTIC_PASSWORD_FILE="$PASSWORD_FILE"

fecha=$(date '+%Y-%m-%d %H:%M:%S')
echo ""
echo "=========================================="
echo "[${fecha}] Iniciando backup Restic"
echo "=========================================="

# Backup principal
restic backup \
    /home \
    /etc \
    /opt \
    /srv \
    /var/lib \
    /boot \
    /root \
    --exclude '/home/*/.cache' \
    --exclude /var/tmp \
    --exclude /tmp \
    --tag "$BACKUP_TAG"

if [[ $? -ne 0 ]]; then
    notify "❌ *Restic backup FALLIDO* en $(hostname) — $(date '+%Y-%m-%d %H:%M')"
    exit 1
fi

# Backup de lista de paquetes
dpkg --get-selections > /tmp/dpkg-list.txt
restic backup /tmp/dpkg-list.txt --tag paquetes
rm -f /tmp/dpkg-list.txt

# Rotar snapshots (sistema Y paquetes)
restic forget --keep-daily "$KEEP_DAILY" --keep-weekly "$KEEP_WEEKLY" --prune --tag "$BACKUP_TAG"
restic forget --keep-daily "$KEEP_DAILY" --keep-weekly "$KEEP_WEEKLY" --prune --tag paquetes

fecha_fin=$(date '+%Y-%m-%d %H:%M:%S')
echo "[${fecha_fin}] Backup completado correctamente"
notify "✅ *Restic backup OK* en $(hostname) — $(date '+%Y-%m-%d %H:%M')"
