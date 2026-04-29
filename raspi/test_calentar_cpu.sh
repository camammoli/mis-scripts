#!/bin/bash
# =============================================================================
# test_calentar_cpu.sh — Estrés de CPU para verificar respuesta del ventilador
# Uso: ./test_calentar_cpu.sh [segundos] [procesos]
# =============================================================================

NUM_PROCESOS=${2:-4}
TIEMPO=${1:-60}
INTERVALO=5
PIDS=()

get_temp() {
    local raw
    raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    [[ -n "$raw" ]] && echo "scale=1; $raw / 1000" | bc || echo "N/A"
}

get_rpm() {
    for hwmon in /sys/class/hwmon/hwmon*/fan1_input; do
        [[ -r "$hwmon" ]] && cat "$hwmon" && return
    done
    echo "N/A"
}

cleanup() {
    echo ""
    echo "🛑 Interrumpido — deteniendo procesos..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null
    done
    echo "✅ Temperatura final: $(get_temp)°C | RPM: $(get_rpm)"
    exit 0
}
trap cleanup INT TERM

echo "🚀 Iniciando $NUM_PROCESOS procesos de carga durante ${TIEMPO}s..."
for ((i=0; i<NUM_PROCESOS; i++)); do
    yes > /dev/null &
    PIDS+=($!)
done

ELAPSED=0
while [[ "$ELAPSED" -lt "$TIEMPO" ]]; do
    echo "🌡️  ${ELAPSED}s — Temp: $(get_temp)°C | RPM: $(get_rpm)"
    sleep "$INTERVALO"
    ELAPSED=$((ELAPSED + INTERVALO))
done

echo "🛑 Tiempo completado — deteniendo procesos..."
for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null
done
wait "${PIDS[@]}" 2>/dev/null

echo "✅ Temperatura final: $(get_temp)°C | RPM: $(get_rpm)"
