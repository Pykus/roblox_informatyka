local MessageLabRules = {}

MessageLabRules.Stages = {
	{
		id = "CLEAN",
		expected = { "server-07" },
		required = { "strip", "lower" },
		challenge = "Usuń zbędne spacje i ujednolić wielkość liter: wynik ma być server-07.",
		starter = 'raw = "  SERVER-07  "\nclean = raw.strip()\nprint(clean)\n',
		input = "  SERVER-07  ",
	},
	{
		id = "REPLACE",
		expected = { "status: online" },
		required = { "replace_twice" },
		challenge = "Napraw separator i status: status|offline ma zmienić się w status: online.",
		starter = 'msg = "status|offline"\nmsg = msg.replace("|", ": ")\nprint(msg)\n',
		input = "status|offline",
	},
	{
		id = "SLICE",
		expected = { "ERR-404", "7" },
		required = { "slice", "len" },
		challenge = "Wytnij sam kod ERR-404 i policz jego długość. Wypisz kod, potem liczbę znaków.",
		starter = 'code = "ERR-404-TEMP"\nprefix = code[0:8]\nsize = len(prefix)\nprint(prefix)\nprint(size)\n',
		input = "ERR-404-TEMP",
	},
}

function MessageLabRules.NewState()
	return {
		stage = 1,
		errors = 0,
		completed = false,
	}
end

function MessageLabRules.Current(state)
	return MessageLabRules.Stages[state.stage]
end

local function hasRequiredOperation(source, requirement)
	if requirement == "strip" then
		return source:find(".strip()", 1, true) ~= nil
	elseif requirement == "lower" then
		return source:find(".lower()", 1, true) ~= nil
	elseif requirement == "replace_twice" then
		local _, count = source:gsub("%.replace%s*%(", "")
		return count >= 2
	elseif requirement == "slice" then
		return source:match("%[%s*0%s*:%s*7%s*%]") ~= nil
	elseif requirement == "len" then
		return source:match("len%s*%(") ~= nil
	end
	return false
end

local function printedValues(plan)
	local out = {}
	for _, command in ipairs(plan) do
		if command.op == "print" then
			table.insert(out, tostring(command.value))
		else
			return nil, "W Message Lab wynik programu ma być raportowany przez print()."
		end
	end
	return out
end

function MessageLabRules.Analyze(state, source, plan)
	local stage = MessageLabRules.Current(state)
	if not stage then
		return false, { message = "Message Lab jest już uruchomiony.", values = {} }
	end

	for _, requirement in ipairs(stage.required) do
		if not hasRequiredOperation(source, requirement) then
			state.errors += 1
			local labels = {
				strip = "strip()",
				lower = "lower()",
				replace_twice = "dwóch operacji replace()",
				slice = "wycinka [0:7]",
				len = "len()",
			}
			return false,
				{
					message = "DEBUG NAPISU • Ten etap wymaga " .. labels[requirement] .. ".",
					values = {},
				}
		end
	end

	local values, planError = printedValues(plan)
	if not values then
		state.errors += 1
		return false, { message = "DEBUG NAPISU • " .. planError, values = {} }
	end

	if #values ~= #stage.expected then
		state.errors += 1
		return false,
			{
				message = string.format(
					"DEBUG WYJŚCIA • Program wypisał %d wartości, a etap oczekuje %d.",
					#values,
					#stage.expected
				),
				values = values,
			}
	end

	for index, expected in ipairs(stage.expected) do
		if values[index] ~= expected then
			state.errors += 1
			return false,
				{
					message = string.format(
						"DEBUG WYNIKU • Oczekiwano „%s”, program wypisał „%s”. Popraw kod i uruchom ponownie.",
						expected,
						tostring(values[index])
					),
					values = values,
				}
		end
	end

	local passedStage = state.stage
	state.stage += 1
	if state.stage > #MessageLabRules.Stages then
		state.completed = true
	end

	return true,
		{
			stage = passedStage,
			values = values,
			completed = state.completed,
			message = string.format("Stacja %s przetworzyła komunikat poprawnie.", stage.id),
		}
end

function MessageLabRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return MessageLabRules