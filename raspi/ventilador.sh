#!/bin/bash
# =============================================================================
# ventilador.sh — Control manual del ventilador (Raspberry Pi 5)
# Requiere: sudo configurado para los comandos tee sobre /sys/class/hwmon/
# =============================================================================

# Detectar el path correcto dinámicamente (el número de hwmon puede cambiar)
detect_paths() {
    for hwmon in /sys/class/hwmon/hwmon*; do
        [[ -f "$hwmon/pwm1" ]] && PWM_PATH="$hwmon/pwm1" && \
            ENABLE_PATH="$hwmon/pwm1_enable" && \
            RPM_PATH="$hwmon/fan1_input" && return 0
    done
    echo "❌ No se encontró interfaz hwmon con pwm1. ¿Es una Raspberry Pi 5?"
    exit 1
}

detect_paths

menu() {
    while true; do
        clear
        echo "🔧 Control del ventilador — Raspberry Pi 5"
        echo "  hwmon: $PWM_PATH"
        echo "-------------------------------------------"
        echo "1) Apagar ventilador"
        echo "2) Velocidad baja  (25%)"
        echo "3) Velocidad media (50%)"
        echo "4) Velocidad alta  (75%)"
        echo "5) Velocidad máxima (100%)"
        echo "6) Ver RPM actuales"
        echo "7) Modo MANUAL"
        echo "8) Modo AUTOMÁTICO"
        echo "9) Ver modo actual"
        echo "0) Salir"
        echo
        read -rp "Opción [0-9]: " opcion

        case $opcion in
            1)
                echo 1 | sudo tee "$ENABLE_PATH" > /dev/null
                echo 0 | sudo tee "$PWM_PATH" > /dev/null
                echo "✅ Ventilador apagado."
                ;;
            2)
                echo 1 | sudo tee "$ENABLE_PATH" > /dev/null
                echo 64 | sudo tee "$PWM_PATH" > /dev/null
                echo "✅ Velocidad baja (64/255)."
                ;;
            3)
                echo 1 | sudo tee "$ENABLE_PATH" > /dev/null
                echo 128 | sudo tee "$PWM_PATH" > /dev/null
                echo "✅ Velocidad media (128/255)."
                ;;
            4)
                echo 1 | sudo tee "$ENABLE_PATH" > /dev/null
                echo 192 | sudo tee "$PWM_PATH" > /dev/null
                echo "✅ Velocidad alta (192/255)."
                ;;
            5)
                echo 1 | sudo tee "$ENABLE_PATH" > /dev/null
                echo 255 | sudo tee "$PWM_PATH" > /dev/null
                echo "✅ Velocidad máxima (255/255)."
                ;;
            6)
                if [[ -r "$RPM_PATH" ]]; then
                    RPM=$(cat "$RPM_PATH")
                    echo "🌀 RPM actuales: $RPM"
                else
                    echo "⚠️  No se pudo leer RPM desde $RPM_PATH"
                fi
                ;;
            7)
                echo 1 | sudo tee "$ENABLE_PATH" > /dev/null
                echo "📟 Modo MANUAL activado."
                ;;
            8)
                echo 2 | sudo tee "$ENABLE_PATH" > /dev/null
                echo "📟 Modo AUTOMÁTICO activado."
                ;;
            9)
                MODE=$(cat "$ENABLE_PATH" 2>/dev/null)
                case "$MODE" in
                    0) echo "📟 Modo: DESHABILITADO (0)" ;;
                    1) echo "📟 Modo: MANUAL (1)" ;;
                    2) echo "📟 Modo: AUTOMÁTICO (2)" ;;
                    *) echo "❓ Modo desconocido: $MODE" ;;
                esac
                ;;
            0)
                echo "Saliendo..."
                exit 0
                ;;
            *)
                echo "Opción no válida."
                ;;
        esac

        echo
        read -rp "Presioná Enter para continuar..."
    done
}

menu
