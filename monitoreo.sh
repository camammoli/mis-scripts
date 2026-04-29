#!/bin/bash
# Monitorea el uso del disco y envía un correo si supera el umbral.
# Configurar EMAIL y UMBRAL antes de usar.
# Para automatizar: agregar al cron con  crontab -e

EMAIL="tu@correo.com"   # destinatario de la alerta
UMBRAL=80               # porcentaje de uso de disco que dispara la alerta
PARTICION="/"           # partición a monitorear

uso=$(df -h "$PARTICION" | awk 'NR==2 { gsub(/%/,""); print $5 }')

if [ "$uso" -gt "$UMBRAL" ]; then
    MENSAJE="Alerta de disco en $(hostname): uso al ${uso}% en $PARTICION (umbral: ${UMBRAL}%) — $(date)"
    echo "$MENSAJE" | mail -s "⚠️ Disco lleno: $(hostname)" "$EMAIL"
    echo "$MENSAJE"
else
    echo "Disco OK: ${uso}% usado en $PARTICION (umbral: ${UMBRAL}%)"
fi
