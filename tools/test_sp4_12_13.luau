local Kleki = require("../src/ServerScriptService/KlekiStudioRules")
local AI = require("../src/ServerScriptService/AIGraphicsLabRules")

local k = Kleki.NewState()

local ok, result = Kleki.Apply(k, "stroke")
if ok or k.stage ~= 1 or k.errors ~= 1 then
	error("[SP4-12-13-QA] Kleki must reject drawing before tool/color", 0)
end

assert(Kleki.Apply(k, "tool", "brush"))
assert(Kleki.Apply(k, "color", "cyan"))
for _ = 1, 3 do
	assert(Kleki.Apply(k, "stroke"))
end
if k.stage ~= 2 or k.baseStrokes ~= 3 then
	error("[SP4-12-13-QA] Kleki stage 1 must end after 3 cyan strokes", 0)
end

local badLayerStroke = { Kleki.Apply(k, "stroke") }
if badLayerStroke[1] or k.stage ~= 2 then
	error("[SP4-12-13-QA] Kleki must require second layer before overlay strokes", 0)
end

assert(Kleki.Apply(k, "layer"))
assert(Kleki.Apply(k, "color", "magenta"))
assert(Kleki.Apply(k, "stroke"))
assert(Kleki.Apply(k, "stroke"))
assert(Kleki.Apply(k, "visibility"))
local finalOk, final = Kleki.Apply(k, "export")
if not finalOk or not final.completed or not k.completed then
	error("[SP4-12-13-QA] Kleki export must complete after layer comparison", 0)
end
if Kleki.Efficiency(k) >= 100 then
	error("[SP4-12-13-QA] Kleki debug mistakes must reduce efficiency", 0)
end

local a = AI.NewState()
local earlyGenerate = { AI.Apply(a, "generate") }
if earlyGenerate[1] or a.errors ~= 1 then
	error("[SP4-12-13-QA] AI lab must reject generation before brief/tokens", 0)
end

assert(AI.Apply(a, "brief"))
assert(AI.Apply(a, "token", "subject"))
assert(AI.Apply(a, "token", "style"))
assert(AI.Apply(a, "token", "privacy"))
if a.stage ~= 2 then
	error("[SP4-12-13-QA] AI lab needs all three prompt ingredients", 0)
end
assert(AI.Apply(a, "generate"))

local wrongVariant, wrong = AI.Apply(a, "choose", "C")
if wrongVariant or not string.find(wrong.message, "nieczytelny", 1, true) then
	error("[SP4-12-13-QA] AI lab must explain why variant C is rejected", 0)
end

assert(AI.Apply(a, "choose", "B"))
if a.stage ~= 3 or a.chosenVariant ~= "B" then
	error("[SP4-12-13-QA] AI lab must reach human iteration stage after B", 0)
end
assert(AI.Apply(a, "improve"))
local approved, approval = AI.Apply(a, "approve")
if not approved or not approval.completed or not a.completed then
	error("[SP4-12-13-QA] AI lab must finish only after human improvement and approval", 0)
end

print("[SP4-12-13-QA] PASS Kleki retry without mission restart")
print("[SP4-12-13-QA] PASS Kleki two-stage layer workflow")
print("[SP4-12-13-QA] PASS AI prompt ingredients")
print("[SP4-12-13-QA] PASS AI variant evaluation and retry")
print("[SP4-12-13-QA] PASS human iteration and approval")
print("[SP4-12-13-QA] ALL_OK")
