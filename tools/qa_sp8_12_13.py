from pathlib import Path
R=Path(__file__).resolve().parents[1];S=R/"src"/"ServerScriptService";M=R/"src"/"ReplicatedStorage"/"Modules"
p=(M/"PriorityMissions.lua").read_text(encoding="utf-8-sig");r=(M/"MissionRules.lua").read_text(encoding="utf-8-sig");e=(S/"MissionEngine.lua").read_text(encoding="utf-8-sig");sem=(S/"SemanticAssetDecorator.server.lua").read_text(encoding="utf-8-sig")
h=(S/"TechEvolutionGallery.lua").read_text(encoding="utf-8-sig");hr=(S/"TechEvolutionRules.lua").read_text(encoding="utf-8-sig");f=(S/"FutureSystemsCity.lua").read_text(encoding="utf-8-sig");fr=(S/"FutureSystemsRules.lua").read_text(encoding="utf-8-sig");m=(R/"tools"/"RELEASE_PLAYTEST_MATRIX.md").read_text(encoding="utf-8-sig")
checks={
"priority":'variant = "tech_evolution"' in p and 'variant = "future_systems"' in p,
"desc":"tech_evolution =" in r and "future_systems =" in r,
"dispatch":"TechEvolutionGallery.Run" in e and "FutureSystemsCity.Run" in e,
"history_actions":'"era"' in hr and '"link"' in hr and "state.completed = true" in hr,
"history_scene":"TechEvolutionArtifact_Mainframe" in h and "TechEvolutionArtifact_PC" in h and "TechEvolutionArtifact_Internet" in h and "TechEvolutionArtifact_MobileAI" in h,
"history_sem":all(x in sem for x in ['tech_evolution_artifact_mainframe = "serverRack"','tech_evolution_artifact_pc = "desktop"','tech_evolution_artifact_internet = "router"','tech_evolution_artifact_mobile_ai = "phone"']),
"future_actions":all(x in fr for x in ['"system"','"privacy"','"human"','"simulate"']) and "state.completed=true" in fr.replace(" ",""),
"future_scene":"FutureWorkRobot" in f and "FutureHomeTablet" in f and "FutureCityDrone" in f,
"future_sem":all(x in sem for x in ['future_work_robot = "robot"','future_home_tablet = "tablet"','future_city_drone = "drone"','future_human_console = "controlConsole"']),
"los":"RequiresLineOfSight=false" in h.replace(" ","") and "RequiresLineOfSight=false" in f.replace(" ",""),
"readable":"MinTextSize=minSize or 18" in h.replace(" ","") and "MinTextSize=minSize or 18" in f.replace(" ",""),
"done":"ctx.state.done=true" in h.replace(" ","") and "ctx.state.done=true" in f.replace(" ",""),
"matrix":"SP8/12 Tech Evolution Gallery" in m and "SP8/13 Future Systems City" in m,
"not_quiz":"quiz" not in (h+f).lower(),
}
bad=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(f"[SP8-12-13-STATIC-QA] {'PASS' if v else 'FAIL'} {k}")
if bad: raise SystemExit("SP8_12_13_STATIC_QA_FAILED: "+",".join(bad))
print("[SP8-12-13-STATIC-QA] ALL_OK")
