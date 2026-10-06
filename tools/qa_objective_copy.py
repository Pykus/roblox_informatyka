from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "src/ReplicatedStorage/Modules/MissionRules.lua"
ENGINE = ROOT / "src/ServerScriptService/MissionEngine.lua"

text = RULES.read_text(encoding="utf-8")
engine = ENGINE.read_text(encoding="utf-8")

START_PREFIX = "ETAP 1/3 • "
MAX_DESCRIPTION = 72
MAX_INITIAL_OBJECTIVE = len(START_PREFIX) + MAX_DESCRIPTION

rows = []
inside = False
for line_no, line in enumerate(text.splitlines(), start=1):
    if line.startswith("local descriptions = {") or line.startswith("local variantDescriptions = {"):
        inside = True
        continue
    if inside and line.strip() == "}":
        inside = False
        continue
    if not inside:
        continue
    match = re.search(r'^\s*[A-Za-z0-9_]+\s*=\s*"([^"]*)"', line)
    if match:
        value = match.group(1)
        rows.append((line_no, value))

bad = [(line, value) for line, value in rows if len(value) > MAX_DESCRIPTION]

print(f"[OBJECTIVE-COPY-QA] DESCRIPTIONS={len(rows)}")
print(f"[OBJECTIVE-COPY-QA] MAX_DESCRIPTION={max((len(v) for _, v in rows), default=0)}")
print(f"[OBJECTIVE-COPY-QA] MAX_INITIAL_OBJECTIVE={max((len(v) + len(START_PREFIX) for _, v in rows), default=0)}")

checks = {
    "generic_prefix_source": 'local initialObjective = "ETAP 1/3 • " .. mission.description' in engine,
    "descriptions_found": len(rows) >= 40,
    "mobile_copy_budget": not bad,
}

for name, ok in checks.items():
    print(f"[OBJECTIVE-COPY-QA] {'PASS' if ok else 'FAIL'} {name}")

for line, value in bad:
    print(f"[OBJECTIVE-COPY-QA] FAIL line={line} len={len(value)} text={value}")

if not all(checks.values()):
    raise SystemExit("OBJECTIVE_COPY_QA_FAILED")

print("[OBJECTIVE-COPY-QA] ALL_OK")