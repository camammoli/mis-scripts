#!/bin/bash
lockfile=/var/lock/loquesea.lock
if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
echo "hago muchas cosas aqui tranquilamente"
rm -f "$lockfile"
trap - INT TERM EXIT
else
echo "Ya hay otro proceso de este script ejecutandose"
echo "corriendo con el PID: $(cat $lockfile)"
fi
