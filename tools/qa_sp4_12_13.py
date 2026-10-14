from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "src" / "ServerScriptService"
MODULES = ROOT / "src" / "ReplicatedStorage" / "Modules"

priority = (MODULES / "PriorityMissions.lua").read_text(encoding="utf-8-sig")
rules = (MODULES / "MissionRules.lua").read_text(encoding="utf-8-sig")
engine = (SERVER / "MissionEngine.lua").read_text(encoding="utf-8-sig")
semantic = (SERVER / "SemanticAssetDecorator.server.lua").read_text(encoding="utf-8-sig")
kleki = (SERVER / "KlekiStudio.lua").read_text(encoding="utf-8-sig")
kleki_rules = (SERVER / "KlekiStudioRules.lua").read_text(encoding="utf-8-sig")
ai = (SERVER / "AIGraphicsLab.lua").read_text(encoding="utf-8-sig")
ai_rules = (SERVER / "AIGraphicsLabRules.lua").read_text(encoding="utf-8-sig")
matrix = (ROOT / "tools" / "RELEASE_PLAYTEST_MATRIX.md").read_text(encoding="utf-8-sig")

checks = {
    "available_to_13": "PriorityMissions.AvailableTo = 13" in priority,
    "sp4_12_priority": 'variant = "kleki_layers"' in priority and 'name = "Kleki Studio: warstwy i rysowanie online"' in priority,
    "sp4_13_priority": 'variant = "ai_graphics"' in priority and 'name = "AI Graphics Lab: człowiek prowadzi AI"' in priority,
    "descriptions": "kleki_layers =" in rules and "ai_graphics =" in rules,
    "engine_requires": 'WaitForChild("KlekiStudio")' in engine and 'WaitForChild("AIGraphicsLab")' in engine,
    "engine_dispatches": 'mission.variant == "kleki_layers"' in engine and "KlekiStudio.Run" in engine
        and 'mission.variant == "ai_graphics"' in engine and "AIGraphicsLab.Run" in engine,
    "kleki_actions": all(token in kleki_rules for token in ['"tool"', '"color"', '"stroke"', '"layer"', '"visibility"', '"export"']),
    "kleki_two_stage": "state.stage = 2" in kleki_rules and "state.completed = true" in kleki_rules,
    "kleki_retry_debug": "DEBUG RYSOWANIA" in kleki_rules and "DEBUG WARSTWY" in kleki_rules and "DEBUG EKSPORTU" in kleki_rules,
    "ai_actions": all(token in ai_rules for token in ['"brief"', '"token"', '"generate"', '"choose"', '"improve"', '"approve"']),
    "ai_three_stage": "state.stage = 2" in ai_rules and "state.stage = 3" in ai_rules and "state.completed = true" in ai_rules,
    "ai_human_decision": "AI pomogło, ale decyzję podjąłeś Ty" in ai_rules,
    "kleki_prompts_3plus": kleki.count("ProximityPrompt") >= 1 and kleki.count("prompt(") >= 7,
    "ai_prompts_3plus": ai.count("ProximityPrompt") >= 1 and ai.count("prompt(") >= 8,
    "prompt_no_los": "RequiresLineOfSight = false" in kleki and "RequiresLineOfSight = false" in ai,
    "readable_world_text": "MinTextSize = minSize or 18" in kleki and "Brightness = 1.2" in kleki
        and "MinTextSize = minSize or 18" in ai and "Brightness = 1.2" in ai,
    "kleki_live_canvas": "KlekiBaseStroke_" in kleki and "KlekiOverlayStroke_" in kleki and "TweenService:Create" in kleki,
    "ai_live_gallery": "AIGraphicsVariantMonitor_" in ai and "AIGraphicsPromptPreview" in ai and "TweenService:Create" in ai,
    "finale_sets_done": "ctx.state.done = true" in kleki and "ctx.state.done = true" in ai,
    "important_3d_audited": kleki.count('SetAttribute("Important3DPlaceholder", true)') >= 7
        and ai.count('SetAttribute("Important3DPlaceholder", true)') >= 8,
    "semantic_kleki": all(token in semantic for token in [
        'kleki_operator_desk = "desk"',
        'kleki_artist_tablet = "tablet"',
        'kleki_preview_monitor = "monitor"',
        'kleki_export_printer = "printer"',
        '{ "kleki_palette_control_", "pushButton" }',
    ]),
    "semantic_ai": all(token in semantic for token in [
        'ai_graphics_operator_desk = "desk"',
        'ai_graphics_brief_scanner = "scanner"',
        'ai_graphics_prompt_console = "controlConsole"',
        'ai_graphics_printer = "printer"',
        '{ "ai_graphics_variant_monitor_", "monitor" }',
    ]),
    "release_matrix_12": "SP4/12 Kleki Studio" in matrix,
    "release_matrix_13": "SP4/13 AI Graphics Lab" in matrix,
    "not_quiz_shell": "quiz" not in (kleki + ai).lower(),
}

bad = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[SP4-12-13-STATIC-QA] {'PASS' if ok else 'FAIL'} {name}")

if bad:
    raise SystemExit("SP4_12_13_STATIC_QA_FAILED: " + ",".join(bad))

print("[SP4-12-13-STATIC-QA] ALL_OK")
