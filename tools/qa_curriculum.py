from pathlib import Path
import re, collections, sys

root = Path.home() / "RobloxGameForge" / "projects" / "CyberEscapeRoom"
rules_text = (root / "src/ReplicatedStorage/Modules/MissionRules.lua").read_text(encoding="utf-8")
engine_text = (root / "src/ServerScriptService/MissionEngine.lua").read_text(encoding="utf-8")
curr_text = (root / "src/ReplicatedStorage/Modules/Curriculum.lua").read_text(encoding="utf-8")

def _top_level_entries(block):
    start = block.index("{")
    depth = 0
    in_string = False
    escaped = False
    entry_start = None
    entries = []

    for i in range(start, len(block)):
        c = block[i]

        if in_string:
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == '"':
                in_string = False
            continue

        if c == '"':
            in_string = True
            continue

        if c == "{":
            depth += 1
            if depth == 2:
                entry_start = i
        elif c == "}":
            if depth == 2 and entry_start is not None:
                entries.append(block[entry_start:i + 1])
                entry_start = None
            depth -= 1

    return entries


def parse_rules(block_name, next_name):
    a = rules_text.index("local " + block_name + " = {")
    b = rules_text.index("local " + next_name + " = {", a)
    block = rules_text[a:b]
    out = []

    for entry in _top_level_entries(block):
        m = re.match(r'^\{\s*\{(.*?)\}\s*,\s*"([^"]+)"\s*,?\s*\}$', entry, re.S)
        if not m:
            continue
        needles = re.findall(r'"([^"]+)"', m.group(1))
        out.append((needles, m.group(2)))

    return out

topic_rules = parse_rules("topicRules", "sectionRules")
section_rules = parse_rules("sectionRules", "descriptions")

arch_start = engine_text.index("local archetype = {")
arch_end = engine_text.index("local palette = {", arch_start)
arch_types = set(re.findall(r'(\w+)\s*=\s*"[^"]+"', engine_text[arch_start:arch_end]))

def unescape(s):
    return bytes(s, "utf-8").decode("unicode_escape").encode("latin1", "ignore").decode("utf-8", "ignore") if "\\" in s else s

lessons = []
current_grade = None
for line in curr_text.splitlines():
    gm = re.match(r'Curriculum\.(\w+) =', line)
    if gm:
        current_grade = gm.group(1)
    m = re.search(r'\{nr=(\d+),topic="(.*?)",hours=(\d+),section="(.*?)",material=', line)
    if m and current_grade:
        topic = m.group(2).replace('\\\"','"').replace('\\n','\n').replace('\\\\','\\')
        section = m.group(4).replace('\\\"','"').replace('\\n','\n').replace('\\\\','\\')
        lessons.append((current_grade, int(m.group(1)), topic, section))

def match(text, rules):
    t = text.lower()
    for needles, typ in rules:
        if any(n.lower() in t for n in needles):
            return typ
    return None

counts = collections.Counter()
generic = []
missing = []
for grade, nr, topic, section in lessons:
    typ = match(topic, topic_rules) or match(section, section_rules) or "GenericChallenge"
    counts[typ] += 1
    if typ == "GenericChallenge":
        generic.append((grade, nr, topic))
    if typ not in arch_types:
        missing.append((grade, nr, topic, typ))

print(f"LESSONS={len(lessons)}")
for typ, n in counts.most_common():
    print(f"{typ}: {n}")
print(f"GENERIC={len(generic)}")
for row in generic[:60]:
    print("GENERIC_ITEM:", *row, sep=" | ")
print(f"MISSING_ARCHETYPE={len(missing)}")
for row in missing:
    print("MISSING:", *row, sep=" | ")

if len(lessons) != 185 or missing:
    sys.exit(2)