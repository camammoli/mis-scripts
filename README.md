# mis-scripts

Scripts de administración y monitoreo para sistemas Debian/Ubuntu.

## Scripts disponibles

| Script | Descripción |
|---|---|
| `actualizar.sh` | Actualiza paquetes del sistema (`apt update && upgrade`) |
| `limpiar.sh` | Elimina paquetes huérfanos, limpia caché y logs viejos |
| `info.sh` | Muestra información básica del sistema (distro, kernel, CPU, RAM) |
| `monitoreo.sh` | Alerta por correo si el uso del disco supera un umbral configurable |
| `optimizar.sh` | Limpieza de caché de memoria (sin tocar el filesystem) |

## Uso

```bash
# Dar permisos de ejecución
chmod +x *.sh

# Ejecutar
./actualizar.sh
./limpiar.sh
./info.sh
./monitoreo.sh     # configurar EMAIL y UMBRAL antes de usar
```

## Configuración de monitoreo.sh

Editar las variables al inicio del script:

```bash
EMAIL="tu@correo.com"
UMBRAL=80   # porcentaje de uso de disco para disparar la alerta
```

Para automatizar con cron:

```
# Verificar disco todos los días a las 8:00
0 8 * * * /ruta/a/monitoreo.sh
```

## Notas

- Testeados en Debian 12 y Ubuntu 22.04
- Requieren `bash` 4+
- `monitoreo.sh` requiere `mailutils` instalado para enviar correos

## Licencia

CC BY-SA 4.0
