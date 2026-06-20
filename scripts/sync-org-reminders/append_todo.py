import sys
import json
import os
from datetime import datetime

ORG_FILE = "/Users/maddisenmohnsen/dev/org/todo.org"

def append_todos(todos):
    if not todos:
        return
        
    try:
        with open(ORG_FILE, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        lines = []
        
    # Find the * Inbox heading or append to end
    inbox_idx = -1
    for i, line in enumerate(lines):
        if line.strip() == "* Inbox":
            inbox_idx = i
            break
            
    if inbox_idx == -1:
        lines.append("\n* Inbox\n")
        inbox_idx = len(lines) - 1
        
    # We append our new todos right after the * Inbox heading (or at the end of its children)
    # Actually, appending at the end of the file is safest if * Inbox is the last heading.
    # Let's see if there are other headings after * Inbox.
    insert_idx = len(lines)
    for i in range(inbox_idx + 1, len(lines)):
        if lines[i].startswith("* "):
            insert_idx = i
            break
            
    new_lines = []
    for t in todos:
        priority_str = ""
        if t["priority"] == 1:
            priority_str = " [#A]"
        elif t["priority"] == 5:
            priority_str = " [#B]"
        elif t["priority"] == 9:
            priority_str = " [#C]"
            
        title = t["title"]
        new_lines.append(f"** TODO{priority_str} {title}\n")
        
        if t.get("dueDate"):
            try:
                # Convert YYYY-MM-DD to YYYY-MM-DD Day
                dt = datetime.strptime(t["dueDate"], "%Y-%m-%d")
                date_str = dt.strftime("%Y-%m-%d %a")
                new_lines.append(f"SCHEDULED: <{date_str}>\n")
            except Exception:
                pass
                
    lines[insert_idx:insert_idx] = new_lines
    
    with open(ORG_FILE, 'w') as f:
        f.writelines(lines)
        
    print(f"Appended {len(todos)} new reminders to {ORG_FILE}")

if __name__ == "__main__":
    input_data = sys.stdin.read()
    try:
        todos = json.loads(input_data)
        append_todos(todos)
    except Exception as e:
        print(f"Error parsing input: {e}", file=sys.stderr)
