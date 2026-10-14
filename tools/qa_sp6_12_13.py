from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "src" / "ServerScriptService"
MODULES = ROOT / "src" / "ReplicatedStorage" / "Modules"

priority = (MODULES / "PriorityMissions.lua").read_text(encoding="utf-8-sig")
rules = (MODULES / "MissionRules.lua").read_text(encoding="utf-8-sig")
engine = (SERVER / "MissionEngine.lua").read_text(encoding="utf-8-sig")
semantic = (SERVER / "SemanticAssetDecorator.server.lua").read_text(encoding="utf-8-sig")
news = (SERVER / "SchoolNewsroom.lua").read_text(encoding="utf-8-sig")
news_rules = (SERVER / "SchoolNewsroomRules.lua").read_text(encoding="utf-8-sig")
clip = (SERVER / "ClipchampStudio.lua").read_text(encoding="utf-8-sig")
clip_rules = (SERVER / "ClipchampStudioRules.lua").read_text(encoding="utf-8-sig")
matrix = (ROOT / "tools" / "RELEASE_PLAYTEST_MATRIX.md").read_text(encoding="utf-8-sig")

checks = {
    "sp6_12_priority": 'variant = "school_newspaper"' in priority and 'name = "School Newsroom: wielostronicowa gazetka"' in priority,
    "sp6_13_priority": 'variant = "clipchamp_video"' in priority and 'name = "Clipchamp Studio: film ze zdjęć"' in priority,
    "descriptions": "school_newspaper =" in rules and "clipchamp_video =" in rules,
    "engine_requires": 'WaitForChild("SchoolNewsroom")' in engine and 'WaitForChild("ClipchampStudio")' in engine,
    "engine_dispatches": 'mission.variant == "school_newspaper"' in engine and "SchoolNewsroom.Run" in engine
        and 'mission.variant == "clipchamp_video"' in engine and "ClipchampStudio.Run" in engine,
    "news_actions_3plus": all(token in news_rules for token in ['"cover"', '"article"', '"photo"', '"page2"', '"header"', '"numbers"', '"preview"', '"print"']),
    "news_two_stage": "state.stage = 2" in news_rules and "state.completed = true" in news_rules,
    "news_physical_pages": "SchoolNewsPage1" in news and "SchoolNewsPage2" in news and "TweenService:Create(page1" in news,
    "news_semantic": all(token in semantic for token in [
        'school_news_operator_desk = "desk"',
        'school_news_layout_laptop = "laptop"',
        'school_news_photo_scanner = "scanner"',
        'school_news_preview_monitor = "monitor"',
        'school_news_printer = "printer"',
        '{ "school_news_control_", "pushButton" }',
    ]),
    "clip_actions_3plus": all(token in clip_rules for token in ['"import"', '"timeline"', '"transition"', '"audio"', '"preview"', '"export"']),
    "clip_two_stage": "state.stage = 2" in clip_rules and "state.completed = true" in clip_rules,
    "clip_physical_timeline": "ClipchampTimeline" in clip and "TweenService:Create(ctx.clips[index].part" in clip
        and "ctx.timelineSlots[index]" in clip,
    "clip_live_preview": 'previewText.Text = "PREVIEW' in clip and "for index = 1, 3 do" in clip,
    "clip_semantic": all(token in semantic for token in [
        'clipchamp_operator_desk = "desk"',
        'clipchamp_laptop = "laptop"',
        'clipchamp_speaker = "speaker"',
        'clipchamp_preview_screen = "projectorScreen"',
        'clipchamp_export_console = "controlConsole"',
        '{ "clipchamp_import_control_", "pushButton" }',
        '{ "clipchamp_timeline_control_", "pushButton" }',
    ]),
    "prompt_no_los": "RequiresLineOfSight = false" in news and "RequiresLineOfSight = false" in clip,
    "readable_world_text": "MinTextSize = minSize or 18" in news and "Brightness = 1.2" in news
        and "MinTextSize = minSize or 18" in clip and "Brightness = 1.2" in clip,
    "finale_sets_done": "ctx.state.done = true" in news and "ctx.state.done = true" in clip,
    "release_matrix": "SP6/12 School Newsroom" in matrix and "SP6/13 Clipchamp Studio" in matrix,
    "not_quiz_shell": "quiz" not in (news + clip).lower(),
}

bad = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[SP6-12-13-STATIC-QA] {'PASS' if ok else 'FAIL'} {name}")
if bad:
    raise SystemExit("SP6_12_13_STATIC_QA_FAILED: " + ",".join(bad))
print("[SP6-12-13-STATIC-QA] ALL_OK")
