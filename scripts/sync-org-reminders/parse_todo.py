import re
import sys
import json
import hashlib
from datetime import datetime

ORG_FILE = "/Users/maddisenmohnsen/dev/org/todo.org"

# Regex patterns
HEADING_RE = re.compile(r'^(\*+)\s+(TODO|WAIT)\s+(?:\[#(A|B|C)\]\s+)?(.*?)\s*(:[a-zA-Z0-9_@:]+:)?$')
# SCHEDULED or DEADLINE format: <YYYY-MM-DD Day Time? Repeater?>
DATE_RE = re.compile(r'^\s*(?:SCHEDULED:|DEADLINE:)\s*<(\d{4}-\d{2}-\d{2})[^>]*>')

def parse_org_file(filepath):
    todos = []
    current_todo = None
    
    try:
        with open(filepath, 'r') as f:
            for line in f:
                heading_match = HEADING_RE.match(line)
                if heading_match:
                    if current_todo:
                        todos.append(current_todo)
                        
                    stars, state, priority, title, tags = heading_match.groups()
                    
                    # Compute stable sync ID based on title and tags
                    id_string = f"{title.strip()}-{tags or ''}"
                    sync_id = hashlib.md5(id_string.encode('utf-8')).hexdigest()[:12]
                    
                    priority_val = 0
                    if priority == 'A': priority_val = 1
                    elif priority == 'B': priority_val = 5
                    elif priority == 'C': priority_val = 9
                    
                    current_todo = {
                        "id": sync_id,
                        "title": title.strip(),
                        "priority": priority_val,
                        "dueDate": None,
                        "state": state
                    }
                    continue
                
                if current_todo:
                    date_match = DATE_RE.match(line)
                    if date_match and not current_todo["dueDate"]:
                        date_str = date_match.group(1)
                        current_todo["dueDate"] = date_str
                    
                    # if we encounter a new heading that isn't TODO/WAIT, stop processing current_todo
                    if line.startswith('*') and not line.startswith(' '):
                        todos.append(current_todo)
                        current_todo = None
                        
            if current_todo:
                todos.append(current_todo)
                
    except FileNotFoundError:
        print(json.dumps({"error": f"File not found: {filepath}"}), file=sys.stderr)
        sys.exit(1)
        
    return todos

if __name__ == "__main__":
    todos = parse_org_file(ORG_FILE)
    print(json.dumps(todos, indent=2))
