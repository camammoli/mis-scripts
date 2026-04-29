#!/bin/bash
# =============================================================================
# cooler_temp_volt.sh — Monitor de temperatura, ventilador y voltaje (Pi 5)
# Uso: ./cooler_temp_volt.sh [--alerta]   (--alerta: solo avisa si hay problema)
# Cron sugerido: */5 * * * * /home/carlos/scripts/cooler_temp_volt.sh
# =============================================================================

LOG_FILE="/home/carlos/scripts/monitor.log"
MAX_LOG_LINES=5000
TEMP_ALERTA=75        # °C — avisa por Telegram si se supera
ALERTA_SOLO=false
[[ "$1" == "--alerta" ]] && ALERTA_SOLO=true

# --- Temperatura ---
TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 | cut -d\' -f1)
TEMP=${TEMP:-"N/A"}

# --- RPM real del ventilador (busca el path correcto dinámicamente) ---
RPM="N/A"
for hwmon in /sys/class/hwmon/hwmon*/fan1_input; do
    [[ -r "$hwmon" ]] && RPM=$(cat "$hwmon") && break
done

# --- Voltaje del núcleo ---
VCORE=$(vcgencmd measure_volts core 2>/dev/null | cut -d= -f2 | sed 's/V//')
VCORE=${VCORE:-"N/A"}

# --- Estado de throttling ---
THROTTLED=$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2)
THROTTLED=${THROTTLED:-"N/A"}
# 0x0 = todo bien; cualquier otro valor indica problema
[[ "$THROTTLED" != "0x0" ]] && THROTTLED_WARN=" ⚠️ THROTTLE" || THROTTLED_WARN=""

LINEA="[$(date '+%Y-%m-%d %H:%M:%S')] Temp: ${TEMP}°C | RPM: ${RPM} | V: ${VCORE}V | Throttle: ${THROTTLED}${THROTTLED_WARN}"

# --- Log con rotación ---
echo "$LINEA" >> "$LOG_FILE"
TOTAL=$(wc -l < "$LOG_FILE")
if [[ "$TOTAL" -gt "$MAX_LOG_LINES" ]]; then
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

# --- Alerta Telegram si temperatura supera umbral ---
TEMP_INT=${TEMP%.*}
if [[ "$TEMP_INT" =~ ^[0-9]+$ ]] && [[ "$TEMP_INT" -ge "$TEMP_ALERTA" ]]; then
    TELEGRAM_SCRIPT="/home/carlos/scripts/telegram-alert.sh"
    MSG="⚠️ *Raspberry Pi — Temperatura alta*: ${TEMP}°C (umbral: ${TEMP_ALERTA}°C) | RPM: ${RPM} | Throttle: ${THROTTLED}"
    if [[ -x "$TELEGRAM_SCRIPT" ]]; then
        "$TELEGRAM_SCRIPT" "$MSG"
    fi
fi

# --- Salida en consola si no es modo --alerta o si hay problema ---
if ! $ALERTA_SOLO || [[ "$TEMP_INT" -ge "$TEMP_ALERTA" ]] || [[ "$THROTTLED" != "0x0" ]]; then
    echo "$LINEA"
fi
