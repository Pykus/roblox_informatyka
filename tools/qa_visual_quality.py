from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "src" / "ServerScriptService"
THEMES = SERVER / "VisualThemes.lua"
infra = {"DecisionScenarios.lua","GameServer.server.lua","MissionEngine.lua","PythonSubset.lua","SessionStandings.lua","VisualThemes.lua"}
issues, warnings = [], []

for path in sorted(SERVER.glob("*.lua")):
    if path.name in infra or path.name.endswith("Rules.lua"):
        continue
    text = path.read_text(encoding="utf-8-sig")
    mins = [int(v) for v in re.findall(r"MinTextSize\s*=\s*(\d+)", text)]
    if mins and min(mins) < 16:
        issues.append(f"{path.name}: MinTextSize={min(mins)} < 16")
    strokes = [float(v) for v in re.findall(r"TextStrokeTransparency\s*=\s*(0?\.\d+)", text)]
    if strokes and max(strokes) > 0.65:
        issues.append(f"{path.name}: TextStrokeTransparency={max(strokes):.2f} > 0.65")
    if text.count("local " + path.stem + " = {}") > 1:
        issues.append(f"{path.name}: duplicate module declaration")
    prompt_sites = len(re.findall(r"\bprompt\s*\(", text))
    colors = len(set(re.findall(r"Color3\.fromRGB\([^\r\n]+?\)", text)))
    if len(text.splitlines()) < 280 or prompt_sites < 2:
        warnings.append(f"{path.name}: inspect complexity ({len(text.splitlines())} lines, {prompt_sites} prompt sites)")
    if colors < 8:
        warnings.append(f"{path.name}: low visual palette diversity ({colors} RGB literals)")

theme_text = THEMES.read_text(encoding="utf-8-sig")
def theme(name):
    m = re.search(rf"\b{name}\s*=\s*\"([^\"]+)\"", theme_text)
    return m.group(1) if m else None
for group in [("paint_shapes","paint_text","paint_composition"),("graphics_tricks","image_transform"),("photo_edit_1","photo_edit_2")]:
    vals = [theme(x) for x in group]
    if len(set(vals)) == 1:
        issues.append(f"theme repetition {group}: {vals[0]}")
print("VISUAL_QA", "PASS" if not issues else "FAIL")
for x in issues: print("ERROR", x)
for x in warnings: print("WARN", x)
sys.exit(1 if issues else 0)