#!/usr/bin/env bash
# Pull New Apple Reminders to Org Mode

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/pull_reminders_bin" | python3 "$DIR/append_todo.py"
