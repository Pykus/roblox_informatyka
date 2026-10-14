from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "src" / "ServerScriptService"
MODULES = ROOT / "src" / "ReplicatedStorage" / "Modules"

priority = (MODULES / "PriorityMissions.lua").read_text(encoding="utf-8-sig")
rules = (MODULES / "MissionRules.lua").read_text(encoding="utf-8-sig")
engine = (SERVER / "MissionEngine.lua").read_text(encoding="utf-8-sig")
semantic = (SERVER / "SemanticAssetDecorator.server.lua").read_text(encoding="utf-8-sig")
stop = (SERVER / "StopMotionStudio.lua").read_text(encoding="utf-8-sig")
stop_rules = (SERVER / "StopMotionStudioRules.lua").read_text(encoding="utf-8-sig")
tink = (SERVER / "TinkercadWorkshop.lua").read_text(encoding="utf-8-sig")
tink_rules = (SERVER / "TinkercadWorkshopRules.lua").read_text(encoding="utf-8-sig")
matrix = (ROOT / "tools" / "RELEASE_PLAYTEST_MATRIX.md").read_text(encoding="utf-8-sig")

checks = {
    "sp5_12_priority": 'variant = "stop_motion"' in priority and 'name = "Stop-Motion Studio: klatka po klatce"' in priority,
    "sp5_13_priority": 'variant = "tinkercad_3d"' in priority and 'name = "Tinkercad Workshop: pierwszy model 3D"' in priority,
    "descriptions": "stop_motion =" in rules and "tinkercad_3d =" in rules,
    "engine_requires": 'WaitForChild("StopMotionStudio")' in engine and 'WaitForChild("TinkercadWorkshop")' in engine,
    "engine_dispatches": 'mission.variant == "stop_motion"' in engine and "StopMotionStudio.Run" in engine
        and 'mission.variant == "tinkercad_3d"' in engine and "TinkercadWorkshop.Run" in engine,
    "stop_two_stage": "state.stage = 2" in stop_rules and "state.completed = true" in stop_rules,
    "stop_actions_3plus": all(token in stop_rules for token in ['"capture"', '"timing"', '"preview"', '"export"']),
    "stop_retry_debug": "DEBUG KOLEJNOŚCI" in stop_rules and "DEBUG TEMPA" in stop_rules and "DEBUG EKSPORTU" in stop_rules,
    "stop_live_motion": "TweenService:Create(robot" in stop and "StopMotionThumbnail_" in stop and "for frameNo = 1, 4 do" in stop,
    "stop_semantic_3d": all(token in semantic for token in [
        'stop_motion_operator_desk = "desk"',
        'stop_motion_camera = "camera"',
        'stop_motion_robot = "robot"',
        'stop_motion_preview_screen = "projectorScreen"',
        'stop_motion_export_console = "controlConsole"',
        '{ "stop_motion_shutter_control_", "pushButton" }',
    ]),
    "tink_two_stage": "state.stage = 2" in tink_rules and "state.completed = true" in tink_rules,
    "tink_actions_3plus": all(token in tink_rules for token in ['"place"', '"align"', '"group"', '"scale"', '"export"']),
    "tink_intentional_primitives": 'TinkercadPrimitiveBox' in tink and 'TinkercadPrimitiveCylinder' in tink
        and 'TinkercadPrimitiveWedge' in tink and 'Important3DPlaceholder' not in tink.split('TinkercadPrimitiveBox', 1)[1].split('local shapeControls', 1)[0],
    "tink_live_transform": "TweenService:Create(target" in tink and "shape.Material = Enum.Material.Neon" in tink
        and "shape.Size *= 0.82" in tink,
    "tink_semantic_station": all(token in semantic for token in [
        'tinkercad_operator_desk = "desk"',
        'tinkercad_laptop = "laptop"',
        'tinkercad_shape_rack = "shelf"',
        'tinkercad_export_printer = "printer"',
        '{ "tinkercad_shape_control_", "pushButton" }',
    ]),
    "prompt_no_los": "RequiresLineOfSight = false" in stop and "RequiresLineOfSight = false" in tink,
    "readable_world_text": "MinTextSize = minSize or 18" in stop and "Brightness = 1.2" in stop
        and "MinTextSize = minSize or 18" in tink and "Brightness = 1.2" in tink,
    "finale_sets_done": "ctx.state.done = true" in stop and "ctx.state.done = true" in tink,
    "release_matrix": "SP5/12 Stop-Motion Studio" in matrix and "SP5/13 Tinkercad Workshop" in matrix,
    "not_quiz_shell": "quiz" not in (stop + tink).lower(),
}

bad = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[SP5-12-13-STATIC-QA] {'PASS' if ok else 'FAIL'} {name}")
if bad:
    raise SystemExit("SP5_12_13_STATIC_QA_FAILED: " + ",".join(bad))
print("[SP5-12-13-STATIC-QA] ALL_OK")
