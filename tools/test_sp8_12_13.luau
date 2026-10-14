local Hist=require("../src/ServerScriptService/TechEvolutionRules")
local Future=require("../src/ServerScriptService/FutureSystemsRules")
local h=Hist.NewState()
local wrong={Hist.Apply(h,"era","pc")}; if wrong[1] then error("[SP8-QA] history must enforce chronology",0) end
for _,k in ipairs({"mainframe","pc","internet","mobile_ai"}) do assert(Hist.Apply(h,"era",k)) end
if h.stage~=2 then error("[SP8-QA] history must enter link stage",0) end
for _,k in ipairs({"internet_network","mobile_everywhere","ai_assist"}) do assert(Hist.Apply(h,"link",k)) end
if not h.completed then error("[SP8-QA] history must complete after 3 links",0) end
local f=Future.NewState()
local early={Future.Apply(f,"privacy")}; if early[1] then error("[SP8-QA] future privacy must wait for systems",0) end
for _,k in ipairs({"work","home","city"}) do assert(Future.Apply(f,"system",k)) end
assert(Future.Apply(f,"privacy")); assert(Future.Apply(f,"human"))
local ok,res=Future.Apply(f,"simulate"); if not ok or not res.completed or not f.completed then error("[SP8-QA] future simulation must finish",0) end
print("[SP8-12-13-QA] PASS chronology")
print("[SP8-12-13-QA] PASS technology impact links")
print("[SP8-12-13-QA] PASS future systems/privacy/human control")
print("[SP8-12-13-QA] ALL_OK")
