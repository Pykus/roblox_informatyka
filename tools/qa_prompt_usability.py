from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "src" / "ServerScriptService"

creation = re.compile(r'local\s+(\w+)\s*=\s*Instance\.new\("ProximityPrompt"\)')
errors = []
count = 0

for path in sorted(SERVER.rglob("*.lua")):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    for index, line in enumerate(lines):
        match = creation.search(line)
        if not match:
            continue
        count += 1
        var = match.group(1)
        # Prompt configuration is intentionally local and compact in this project.
        window = "\n".join(lines[index:index + 12])
        required = f"{var}.RequiresLineOfSight = false"
        if required not in window:
            errors.append(f"{path.name}:{index + 1} missing {required}")

print(f"[PROMPT-USABILITY-QA] CREATED_PROMPTS={count}")
for error in errors:
    print(f"[PROMPT-USABILITY-QA] FAIL {error}")

if errors:
    raise SystemExit("PROMPT_USABILITY_QA_FAILED")

print("[PROMPT-USABILITY-QA] ALL_OK")