from pathlib import Path
import re
import sys

root = Path.home() / "RobloxGameForge" / "projects" / "CyberEscapeRoom"
priority = (root / "src/ReplicatedStorage/Modules/PriorityMissions.lua").read_text(encoding="utf-8")
engine = (root / "src/ServerScriptService/MissionEngine.lua").read_text(encoding="utf-8")

grades = ["SP4","SP5","SP6","SP7","SP8","LO1","LO2","LO3"]

arch_start = engine.index("local archetype = {")
arch_end = engine.index("local palette = {", arch_start)
arch_types = set(re.findall(r'(\w+)\s*=\s*"([^"]+)"', engine[arch_start:arch_end]))
arch_types = {a for a, _ in arch_types}

grade_positions = []
for grade in grades:
    m = re.search(rf'\b{grade}\s*=\s*\{{', priority)
    if not m:
        print("MISSING_GRADE", grade)
        sys.exit(2)
    grade_positions.append((m.start(), grade))
grade_positions.sort()

entries = []
errors = []
for idx, (start, grade) in enumerate(grade_positions):
    end = grade_positions[idx+1][0] if idx+1 < len(grade_positions) else priority.index("\n}", start)
    block = priority[start:end]
    hits = list(re.finditer(r'\[(\d+)\]\s*=\s*\{', block))
    seen = set()
    for j, hit in enumerate(hits):
        nr = int(hit.group(1))
        eend = hits[j+1].start() if j+1 < len(hits) else len(block)
        chunk = block[hit.start():eend]
        def get(field):
            m = re.search(rf'{field}\s*=\s*"([^"]+)"', chunk)
            return m.group(1) if m else None
        typ = get("type")
        name = get("name")
        variant = get("variant")
        dm = re.search(r'difficulty\s*=\s*(\d+)', chunk)
        difficulty = int(dm.group(1)) if dm else None
        entries.append((grade,nr,typ,name,variant,difficulty))
        seen.add(nr)
        if typ not in arch_types:
            errors.append(f"{grade}/{nr:02d}: unknown archetype type {typ}")
        if not name or not variant or difficulty not in (1,2,3):
            errors.append(f"{grade}/{nr:02d}: incomplete metadata")
    expected = set(range(1, 12)) if grade in ("LO2", "LO3") else set(range(3, 12))
    if seen != expected:
        expected_label = "1-11" if grade in ("LO2", "LO3") else "3-11"
        errors.append(f"{grade}: expected {expected_label}, got {sorted(seen)}")

print(f"PRIORITY_LEVELS={len(entries)}")
for grade in grades:
    rows=[e for e in entries if e[0]==grade]
    print(f"{grade}={len(rows)}: " + ", ".join(f"{e[1]:02d}:{e[2]}" for e in rows))
print(f"ERRORS={len(errors)}")
for e in errors:
    print("ERROR:", e)

if len(entries) != 76 or errors:
    sys.exit(2)