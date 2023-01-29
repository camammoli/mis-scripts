#!/bin/bash
free_space=$(df -h / | awk '{ print $5 }' | tail -n 1 | cut -d'%' -f1)
if [ "$free_space" -gt 70 ]; then
  echo "Espacio en disco alto en $(hostname) el $(date)." | mail -s "Advertencia de espacio en disco" admin@example.com
fi
