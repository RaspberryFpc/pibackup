#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Programm im Hintergrund starten
nohup sudo XDG_RUNTIME_DIR=/run/user/0 DISPLAY=:0 ./pibackup >/dev/null 2>&1 &

# Terminalprozess identifizieren und beenden
sleep 1
TERMINAL_PID=$(ps -o ppid= -p $$ | tr -d ' ')
kill -9 "$TERMINAL_PID"
