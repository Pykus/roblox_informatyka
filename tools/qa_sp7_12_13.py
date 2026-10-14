from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
S=ROOT/"src"/"ServerScriptService"; M=ROOT/"src"/"ReplicatedStorage"/"Modules"
priority=(M/"PriorityMissions.lua").read_text(encoding="utf-8-sig")
rules=(M/"MissionRules.lua").read_text(encoding="utf-8-sig")
engine=(S/"MissionEngine.lua").read_text(encoding="utf-8-sig")
semantic=(S/"SemanticAssetDecorator.server.lua").read_text(encoding="utf-8-sig")
sheet=(S/"SpreadsheetProblemLab.lua").read_text(encoding="utf-8-sig")
sheet_rules=(S/"SpreadsheetProblemRules.lua").read_text(encoding="utf-8-sig")
chart=(S/"ChartControlRoom.lua").read_text(encoding="utf-8-sig")
chart_rules=(S/"ChartControlRules.lua").read_text(encoding="utf-8-sig")
matrix=(ROOT/"tools"/"RELEASE_PLAYTEST_MATRIX.md").read_text(encoding="utf-8-sig")
checks={
"priority":'variant = "spreadsheet_problem"' in priority and 'variant = "chart_presentation"' in priority,
"descriptions":"spreadsheet_problem =" in rules and "chart_presentation =" in rules,
"dispatch":"SpreadsheetProblemLab.Run" in engine and "ChartControlRoom.Run" in engine,
"sheet_actions":all(x in sheet_rules for x in ['"input"','"formula"','"whatif"','"check"']),
"sheet_stage":"state.stage = 2" in sheet_rules and "state.completed = true" in sheet_rules,
"sheet_live":"SpreadsheetProblemOutputGate" in sheet and "WHAT‑IF" in sheet and "TweenService:Create(monitor" in sheet,
"chart_actions":all(x in chart_rules for x in ['"range"','"type"','"title"','"labels"','"compare"','"publish"']),
"chart_stage":"state.stage = 2" in chart_rules and "state.completed = true" in chart_rules,
"chart_live":"ChartBar_" in chart and "raiseBars" in chart and "TweenService:Create(data.part" in chart,
"sem_sheet":all(x in semantic for x in ['spreadsheet_problem_laptop = "laptop"','spreadsheet_formula_console = "controlConsole"','spreadsheet_result_monitor = "monitor"','{ "spreadsheet_input_control_", "pushButton" }']),
"sem_chart":all(x in semantic for x in ['chart_range_scanner = "scanner"','chart_preview_monitor = "monitor"','chart_publish_console = "controlConsole"']),
"los":"RequiresLineOfSight = false" in sheet and "RequiresLineOfSight = false" in chart,
"readable":"MinTextSize = minSize or 18" in sheet and "Brightness = 1.2" in sheet and "MinTextSize = minSize or 18" in chart and "Brightness = 1.2" in chart,
"done":"ctx.state.done = true" in sheet and "ctx.state.done = true" in chart,
"matrix":"SP7/12 Spreadsheet Problem Lab" in matrix and "SP7/13 Chart Control Room" in matrix,
"not_quiz":"quiz" not in (sheet+chart).lower(),
}
bad=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(f"[SP7-12-13-STATIC-QA] {'PASS' if v else 'FAIL'} {k}")
if bad: raise SystemExit("SP7_12_13_STATIC_QA_FAILED: "+",".join(bad))
print("[SP7-12-13-STATIC-QA] ALL_OK")
