local News = require("../src/ServerScriptService/SchoolNewsroomRules")
local Clip = require("../src/ServerScriptService/ClipchampStudioRules")

local n = News.NewState()
local earlyArticle = { News.Apply(n, "article") }
if earlyArticle[1] or n.errors ~= 1 then
	error("[SP6-12-13-QA] Newspaper must require cover before article", 0)
end
assert(News.Apply(n, "cover"))
assert(News.Apply(n, "article"))
assert(News.Apply(n, "photo"))
assert(News.Apply(n, "page2"))
if n.stage ~= 2 then
	error("[SP6-12-13-QA] Newspaper must enter stage 2 after complete page 1 + page2", 0)
end
local earlyNumbers = { News.Apply(n, "numbers") }
if earlyNumbers[1] then
	error("[SP6-12-13-QA] Newspaper must require header before page numbers", 0)
end
assert(News.Apply(n, "header"))
assert(News.Apply(n, "numbers"))
assert(News.Apply(n, "preview"))
local printed, printResult = News.Apply(n, "print")
if not printed or not printResult.completed or not n.completed then
	error("[SP6-12-13-QA] Newspaper must complete after preview/print", 0)
end

local c = Clip.NewState()
local earlyTimeline = { Clip.Apply(c, "timeline", 1) }
if earlyTimeline[1] or c.errors ~= 1 then
	error("[SP6-12-13-QA] Clipchamp must require media import first", 0)
end
for i = 1, 3 do assert(Clip.Apply(c, "import", i)) end
if c.stage ~= 2 then
	error("[SP6-12-13-QA] Clipchamp must enter edit stage after 3 imports", 0)
end
local wrongOrder = { Clip.Apply(c, "timeline", 2) }
if wrongOrder[1] then
	error("[SP6-12-13-QA] Clipchamp must reject wrong clip order", 0)
end
for i = 1, 3 do assert(Clip.Apply(c, "timeline", i)) end
assert(Clip.Apply(c, "transition"))
assert(Clip.Apply(c, "audio"))
assert(Clip.Apply(c, "preview"))
local exported, exportResult = Clip.Apply(c, "export")
if not exported or not exportResult.completed or not c.completed then
	error("[SP6-12-13-QA] Clipchamp must complete after preview/export", 0)
end

print("[SP6-12-13-QA] PASS two-page newspaper structure")
print("[SP6-12-13-QA] PASS newspaper preview-before-print")
print("[SP6-12-13-QA] PASS Clipchamp imports and ordered timeline")
print("[SP6-12-13-QA] PASS Clipchamp transition/audio/preview/export")
print("[SP6-12-13-QA] ALL_OK")
