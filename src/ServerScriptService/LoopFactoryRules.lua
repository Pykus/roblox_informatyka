local LoopFactoryRules = {}

LoopFactoryRules.Stages = {
	{
		id = "STAMP",
		target = 4,
		challenge = "Linia potrzebuje dokładnie 4 obudów. Napraw range(), aby pętla wykonała 4 iteracje.",
		starter = "for i in range(3):\n    print(i)\n# Cel: 4 obudowy\n",
	},
	{
		id = "PACK",
		target = 6,
		challenge = "Pakowarka ma przygotować dokładnie 6 paczek. Użyj jednej pętli for i obserwuj indeksy 0–5.",
		starter = "for i in range(6):\n    print(i)\n",
	},
	{
		id = "BATCH",
		target = 3,
		requireVariable = true,
		challenge = "Steruj wielkością serii zmienną: ustaw liczbę, a potem użyj range(zmienna), aby wykonać dokładnie 3 iteracje.",
		starter = "seria = 3\nfor i in range(seria):\n    print(i)\n",
	},
}

function LoopFactoryRules.NewState()
	return {
		stage = 1,
		errors = 0,
		completed = false,
	}
end

function LoopFactoryRules.Current(state)
	return LoopFactoryRules.Stages[state.stage]
end

local function loopUsesVariable(source)
	return source:match("[%a_][%w_]*%s*=%s*%-?%d+") ~= nil and source:match("range%s*%(%s*[%a_][%w_]*%s*%)") ~= nil
end

function LoopFactoryRules.Analyze(state, source, plan)
	local stage = LoopFactoryRules.Current(state)
	if not stage then
		return false, { message = "Fabryka jest już uruchomiona.", produced = 0 }
	end

	if not source:match("for%s+[%a_][%w_]*%s+in%s+range%s*%(") then
		state.errors += 1
		return false, {
			message = "DEBUG PĘTLI • Brakuje for ... in range(...):",
			produced = 0,
		}
	end

	if stage.requireVariable and not loopUsesVariable(source) then
		state.errors += 1
		return false,
			{
				message = "DEBUG SERII • Etap 3 wymaga zmiennej użytej w range(zmienna).",
				produced = 0,
			}
	end

	local values = {}
	for _, command in ipairs(plan) do
		if command.op ~= "print" then
			state.errors += 1
			return false,
				{
					message = "DEBUG LINII • W tej fabryce ciało pętli ma raportować iterację przez print(i).",
					produced = #values,
				}
		end
		table.insert(values, tostring(command.value))
	end

	local produced = #values
	if produced ~= stage.target then
		state.errors += 1
		local relation = produced < stage.target and "za mało" or "za dużo"
		return false,
			{
				message = string.format(
					"DEBUG OFF-BY-ONE • Wyprodukowano %d, cel %d (%s). Popraw argument range().",
					produced,
					stage.target,
					relation
				),
				produced = produced,
				values = values,
			}
	end

	for index = 1, stage.target do
		local expected = tostring(index - 1)
		if values[index] ~= expected then
			state.errors += 1
			return false,
				{
					message = string.format(
						"DEBUG INDEKSU • Iteracja %d powinna raportować %s, a raportuje %s.",
						index,
						expected,
						tostring(values[index])
					),
					produced = produced,
					values = values,
				}
		end
	end

	local passedStage = state.stage
	state.stage += 1
	if state.stage > #LoopFactoryRules.Stages then
		state.completed = true
	end

	return true,
		{
			stage = passedStage,
			produced = produced,
			values = values,
			completed = state.completed,
			message = string.format("Seria %s gotowa: %d poprawnych iteracji.", stage.id, produced),
		}
end

function LoopFactoryRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return LoopFactoryRules