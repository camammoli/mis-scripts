# mis-scripts

Scripts de administración y monitoreo para sistemas **Debian 12 / Ubuntu 22.04+**.

Colección personal de herramientas de línea de comandos para el día a día: monitoreo, limpieza, backups, alertas y clientes de IA desde la terminal.

---

## Scripts disponibles

### Sistema

| Script | Descripción | Root |
|---|---|---|
| `info-sistema.sh` | Resumen del sistema: hostname, IP, CPU, RAM, disco, temp, uptime | No |
| `resumen.sh` | Reporte completo: todo lo de info-sistema + servicios caídos, errores del journal, últimas actualizaciones | No* |
| `monitor-live.sh` | Monitor en tiempo real con barras de uso (CPU, RAM, SWAP, disco, top procesos) — Ctrl+C para salir | No |
| `actualizar.sh` | Update + upgrade con confirmación, log persistente y detección de reinicio pendiente | Sí |
| `limpieza.sh` | Libera disco: apt autoremove, journal vacuum, /tmp, thumbnails — muestra espacio ganado | Sí |
| `optimizar.sh` | Libera caché de memoria via `/proc/sys/vm/drop_caches` (seguro, sin tocar filesystem) | Sí |

### Disco y archivos

| Script | Descripción | Root |
|---|---|---|
| `uso-disco.sh` | Uso por directorio ordenado de mayor a menor; alerta si alguna partición supera el 85% | No |
| `archivos-grandes.sh` | Busca archivos que superen un tamaño configurable (default: 100 MB) | No |

### Red y seguridad

| Script | Descripción | Root |
|---|---|---|
| `puertos-abiertos.sh` | Lista puertos TCP/UDP abiertos, conexiones activas y servicios conocidos detectados | Sí* |
| `ultimos-accesos.sh` | Últimos logins, intentos fallidos de SSH y usuarios activos ahora mismo | No* |

### Monitoreo y alertas

| Script | Descripción | Root |
|---|---|---|
| `monitoreo.sh` | Alerta por correo si el uso del disco supera un umbral configurable | No |
| `servicios.sh` | Estado de servicios systemd configurables; opción `--watch` y `--alerta-telegram` | No |
| `telegram-alert.sh` | Envía alertas a Telegram cuando disco/RAM/CPU superan umbrales. También acepta mensajes libres y pipe | No |

### Backups

| Script | Descripción | Root |
|---|---|---|
| `backup-rsync.sh` | Backup incremental con rsync a disco externo o servidor SSH. Configurable, con log | No |
| `backup-bd.sh` | Descarga y comprime dumps SQL desde un servidor remoto via API. Con rotación automática | No |

### IA en la terminal

| Script | Descripción | Root |
|---|---|---|
| `gemini.sh` | Cliente de Google Gemini: modo pregunta, chat interactivo con historial, búsqueda web, pipe | No |
| `groq.sh` | Cliente de Groq (Llama 3, Mixtral, Gemma2): chat interactivo, cambio de modelo en caliente, pipe | No |

---

## Instalación

```bash
git clone https://github.com/camammoli/mis-scripts.git
cd mis-scripts
chmod +x *.sh
```

Para usar los scripts desde cualquier parte del sistema:

```bash
echo 'export PATH="$PATH:'"$(pwd)"'"' >> ~/.bashrc
source ~/.bashrc
```

---

## Uso rápido

```bash
# Ver estado del sistema
./info-sistema.sh

# Monitor en tiempo real
./monitor-live.sh

# Limpiar disco (requiere sudo)
sudo ./limpieza.sh

# Buscar archivos grandes
./archivos-grandes.sh /home 200       # archivos > 200 MB en /home

# Uso de disco
./uso-disco.sh /var

# Últimas alertas de seguridad
./ultimos-accesos.sh

# Backup incremental (configurar DESTINO y ORIGENES antes)
./backup-rsync.sh

# Chat con IA desde la terminal
./gemini.sh "cómo libero RAM en Linux"
./groq.sh                             # chat interactivo

# Enviar alerta a Telegram
./telegram-alert.sh                   # verificar umbrales automáticamente
./telegram-alert.sh "servidor reiniciado"
df -h | ./telegram-alert.sh           # enviar por pipe

# Estado de servicios
./servicios.sh
./servicios.sh --watch                # actualiza cada 5s
./servicios.sh --alerta-telegram      # notifica caídos por Telegram
```

---

## Configuración

### telegram-alert.sh y servicios.sh

```bash
# Obtener TOKEN en @BotFather y CHAT_ID con @userinfobot
echo 'TOKEN:CHAT_ID' > ~/.config/telegram_alert
chmod 600 ~/.config/telegram_alert

# Probar
./telegram-alert.sh --test
```

### gemini.sh

```bash
# API key gratuita en https://aistudio.google.com
echo 'tu-api-key' > ~/.config/gemini_api_key
chmod 600 ~/.config/gemini_api_key
```

### groq.sh

```bash
# API key gratuita en https://console.groq.com (sin tarjeta)
echo 'tu-api-key' > ~/.config/groq_api_key
chmod 600 ~/.config/groq_api_key
```

### backup-rsync.sh y backup-bd.sh

Editar las variables de configuración al inicio de cada script. Están claramente marcadas.

---

## Cron de ejemplo

```bash
crontab -e
```

```
# Verificar sistema y alertar por Telegram cada hora
0 * * * * /ruta/mis-scripts/telegram-alert.sh >> $HOME/Logs/alertas.log 2>&1

# Backup de directorios todos los días a las 3:00
0 3 * * * /ruta/mis-scripts/backup-rsync.sh >> $HOME/Logs/backup.log 2>&1

# Backup de base de datos todos los días a las 3:30
30 3 * * * /ruta/mis-scripts/backup-bd.sh >> $HOME/Logs/backup-bd.log 2>&1

# Limpieza semanal (domingos a las 4:00)
0 4 * * 0 sudo /ruta/mis-scripts/limpieza.sh >> $HOME/Logs/limpieza.log 2>&1
```

---

## Compatibilidad

- **Testeados en:** Debian 12 (Bookworm) con kernel 6.1
- **Deberían funcionar en:** Ubuntu 22.04+, Linux Mint 21+
- **Dependencias opcionales:** `rsync` (backup-rsync), `curl` + `jq` (gemini, groq, telegram-alert)
- Scripts de IA: gratuitos con registro, no requieren tarjeta de crédito

---

## Licencia

CC BY-SA 4.0 — Carlos Ariel Mammoli (LU2MCA), Mendoza, Argentina
