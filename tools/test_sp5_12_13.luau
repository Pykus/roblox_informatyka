local Stop = require("../src/ServerScriptService/StopMotionStudioRules")
local Tink = require("../src/ServerScriptService/TinkercadWorkshopRules")

local s = Stop.NewState()
local ok = Stop.Apply(s, "capture", 2)
if ok or s.errors ~= 1 or s.nextFrame ~= 1 then
	error("[SP5-12-13-QA] Stop motion must reject out-of-order first frame", 0)
end
for frameNo = 1, 4 do
	local passed = Stop.Apply(s, "capture", frameNo)
	if not passed then
		error("[SP5-12-13-QA] Stop motion frame sequence failed at " .. frameNo, 0)
	end
end
if s.stage ~= 2 then
	error("[SP5-12-13-QA] Stop motion must enter stage 2 after 4 frames", 0)
end
local badTiming = { Stop.Apply(s, "timing", "fast") }
if badTiming[1] then
	error("[SP5-12-13-QA] Stop motion must reject wrong timing", 0)
end
assert(Stop.Apply(s, "timing", "medium"))
assert(Stop.Apply(s, "preview"))
local exported, exportResult = Stop.Apply(s, "export")
if not exported or not exportResult.completed or not s.completed then
	error("[SP5-12-13-QA] Stop motion must complete only after preview/export", 0)
end

local t = Tink.NewState()
local earlyAlign = { Tink.Apply(t, "align") }
if earlyAlign[1] or t.errors ~= 1 then
	error("[SP5-12-13-QA] Tinkercad must reject align before shapes", 0)
end
assert(Tink.Apply(t, "place", "box"))
assert(Tink.Apply(t, "place", "cylinder"))
assert(Tink.Apply(t, "place", "wedge"))
if t.stage ~= 2 then
	error("[SP5-12-13-QA] Tinkercad must enter stage 2 after 3 primitives", 0)
end
local earlyGroup = { Tink.Apply(t, "group") }
if earlyGroup[1] then
	error("[SP5-12-13-QA] Tinkercad must require align before group", 0)
end
assert(Tink.Apply(t, "align"))
assert(Tink.Apply(t, "group"))
assert(Tink.Apply(t, "scale"))
local finalOk, final = Tink.Apply(t, "export")
if not finalOk or not final.completed or not t.completed then
	error("[SP5-12-13-QA] Tinkercad export must complete after align/group/scale", 0)
end

print("[SP5-12-13-QA] PASS stop-motion ordered capture")
print("[SP5-12-13-QA] PASS stop-motion timing/preview/export")
print("[SP5-12-13-QA] PASS Tinkercad intentional primitives")
print("[SP5-12-13-QA] PASS Tinkercad align/group/scale/export")
print("[SP5-12-13-QA] ALL_OK")
