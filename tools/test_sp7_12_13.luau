local Sheet = require("../src/ServerScriptService/SpreadsheetProblemRules")
local Chart = require("../src/ServerScriptService/ChartControlRules")

local s = Sheet.NewState()
local earlyFormula = { Sheet.Apply(s, "formula") }
if earlyFormula[1] or s.errors ~= 1 then error("[SP7-12-13-QA] spreadsheet must require inputs",0) end
assert(Sheet.Apply(s,"input","students"))
assert(Sheet.Apply(s,"input","price"))
assert(Sheet.Apply(s,"input","discount"))
if s.stage ~= 2 then error("[SP7-12-13-QA] spreadsheet must enter stage2 after 3 inputs",0) end
assert(Sheet.Apply(s,"formula"))
assert(Sheet.Apply(s,"whatif"))
local checked, checkResult = Sheet.Apply(s,"check")
if not checked or not checkResult.completed or not s.completed then error("[SP7-12-13-QA] spreadsheet model must complete after what-if/check",0) end

local c = Chart.NewState()
local earlyType = { Chart.Apply(c,"type","column") }
if earlyType[1] then error("[SP7-12-13-QA] chart must require range first",0) end
assert(Chart.Apply(c,"range","sales"))
local wrong = { Chart.Apply(c,"type","pie") }
if wrong[1] then error("[SP7-12-13-QA] chart must reject wrong type for comparison",0) end
assert(Chart.Apply(c,"type","column"))
assert(Chart.Apply(c,"title"))
assert(Chart.Apply(c,"labels"))
assert(Chart.Apply(c,"compare"))
local published, publishResult = Chart.Apply(c,"publish")
if not published or not publishResult.completed or not c.completed then error("[SP7-12-13-QA] chart must complete after interpretation/publish",0) end

print("[SP7-12-13-QA] PASS spreadsheet inputs/formula/what-if")
print("[SP7-12-13-QA] PASS chart range/type/title/labels")
print("[SP7-12-13-QA] PASS chart interpretation before publish")
print("[SP7-12-13-QA] ALL_OK")
