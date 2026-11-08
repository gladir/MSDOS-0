#!/bin/bash
# Compile le noyau et COMMAND.PAS avec TPC, fabrique IO.SYS (MAKER sous DOSBox),
# puis demarre le tout dans l'emulateur de DEVENV (mode headless /KERNELTEST).
# Variables : TPC (compilateur Linux), DEVENV (executable Linux), W (dossier de travail)
#   TPC=/chemin/tpc DEVENV=/chemin/devenv ./BOOTTEST.sh [-DKDEBUG] [script.txt]
# Exemple de script : run 2300000 / type ver / run 3000000 / screen
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
W=${W:-/tmp/msdos0-boot}
TPC=${TPC:?definir TPC}
DEVENV=${DEVENV:?definir DEVENV}
rm -rf "$W"; mkdir -p "$W/src" "$W/disk"
cp "$HERE"/*.PAS "$W/src"; cp "$HERE/../COMMAND.PAS" "$W/src"
( cd "$W/src" && "$TPC" -M ${1:--DNONE} MAKER.PAS && "$TPC" COMMAND.PAS )
cp "$W/src/COMMAND.EXE" "$W/disk/"; cp "$W/src/MAKER.EXE" "$W/disk/MAKER.EXE"
( cd "$W/disk" && printf '[sdl]\nfullscreen=false\n[autoexec]\nmount c %s\nc:\nMAKER.EXE\nexit\n' "$PWD" > ../conf &&
  SDL_VIDEODRIVER=dummy timeout 60 dosbox -conf ../conf -noconsole >/dev/null 2>&1; rm -f MAKER.EXE )
ls -l "$W/disk/IO.SYS"
SCRIPT=${2:-}
[ -n "$SCRIPT" ] && SC="/KTSCRIPT:$SCRIPT" || SC=""
xvfb-run -a "$DEVENV" "/KERNELTEST,$W/disk" /KTDRIVE:C /KTSTEPS:12000000 $SC /KTINT:21
