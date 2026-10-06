local Rules = {}

Rules.Stages = {
	{
		id = "AND",
		title = "AND AIRLOCK",
		expression = "A and B",
		defaultA = false,
		defaultB = false,
		expectedOutput = true,
		hint = "AND daje TRUE tylko wtedy, gdy oba wejścia są TRUE.",
	},
	{
		id = "OR",
		title = "OR BACKUP GATE",
		expression = "A or B",
		defaultA = false,
		defaultB = false,
		expectedOutput = true,
		hint = "OR daje TRUE, gdy co najmniej jedno wejście jest TRUE.",
	},
	{
		id = "NOT",
		title = "NOT QUARANTINE",
		expression = "not A",
		defaultA = true,
		defaultB = nil,
		expectedOutput = true,
		hint = "NOT odwraca wartość: not TRUE = FALSE, not FALSE = TRUE.",
	},
}

function Rules.NewState()
	return {
		stage = 1,
		a = Rules.Stages[1].defaultA,
		b = Rules.Stages[1].defaultB,
		errors = 0,
		passed = {},
		completed = false,
	}
end

function Rules.CurrentStage(state)
	return Rules.Stages[state.stage]
end

function Rules.Evaluate(gateId, a, b)
	if gateId == "AND" then
		return a and b
	elseif gateId == "OR" then
		return a or b
	elseif gateId == "NOT" then
		return not a
	end
	return false
end

function Rules.Output(state)
	local stage = Rules.CurrentStage(state)
	if not stage then
		return false
	end
	return Rules.Evaluate(stage.id, state.a, state.b)
end

function Rules.Toggle(state, input)
	local stage = Rules.CurrentStage(state)
	if not stage or state.completed then
		return false, "Brak aktywnej bramki."
	end
	if input == "A" then
		state.a = not state.a
		return true, state.a
	elseif input == "B" and stage.defaultB ~= nil then
		state.b = not state.b
		return true, state.b
	end
	return false, "To wejście nie istnieje w tej bramce."
end

local function advance(state)
	local current = Rules.CurrentStage(state)
	state.passed[current.id] = true
	state.stage += 1
	local nextStage = Rules.CurrentStage(state)
	if nextStage then
		state.a = nextStage.defaultA
		state.b = nextStage.defaultB
	end
end

function Rules.Test(state)
	local stage = Rules.CurrentStage(state)
	if not stage then
		return false, { message = "Wszystkie bramki są już gotowe." }
	end

	local output = Rules.Output(state)
	if output ~= stage.expectedOutput then
		state.errors += 1
		return false,
			{
				gate = stage.id,
				output = output,
				message = string.format(
					"DEBUG %s: wynik jest %s. %s Zmień wejście i sprawdź ponownie.",
					stage.id,
					tostring(output),
					stage.hint
				),
			}
	end

	local passedId = stage.id
	advance(state)
	return true,
		{
			gate = passedId,
			output = output,
			nextStage = Rules.CurrentStage(state),
			allPassed = state.stage > #Rules.Stages,
		}
end

function Rules.CanComplete(state)
	return state.passed.AND == true
		and state.passed.OR == true
		and state.passed.NOT == true
		and state.stage > #Rules.Stages
end

function Rules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

function Rules.Complete(state)
	if not Rules.CanComplete(state) then
		return false, "Najpierw uruchom AND, OR i NOT."
	end
	state.completed = true
	return true, {
		efficiency = Rules.Efficiency(state),
		errors = state.errors,
	}
end

return Rules