#!/usr/bin/env bash
# Sync Org Mode Todos to Apple Reminders

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$DIR/parse_todo.py" | "$DIR/sync_reminders_bin"
