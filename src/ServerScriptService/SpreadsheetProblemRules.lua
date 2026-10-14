local SpreadsheetProblemRules = {}

function SpreadsheetProblemRules.NewState()
	return {
		stage = 1,
		inputs = {},
		formula = false,
		whatIf = false,
		checked = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

local function inputCount(state)
	local n = 0
	for _, key in ipairs({ "students", "price", "discount" }) do
		if state.inputs[key] then n += 1 end
	end
	return n
end

function SpreadsheetProblemRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Model arkusza jest już sprawdzony.", stage = state.stage, completed = true }
	end
	if action == "input" then
		if value ~= "students" and value ~= "price" and value ~= "discount" then
			return fail(state, "DEBUG DANYCH • Wprowadź tylko dane potrzebne do modelu.")
		end
		state.inputs[value] = true
		if inputCount(state) == 3 then
			state.stage = 2
			return true, { message = "Dane wejściowe 3/3 gotowe. Zbuduj formułę kosztu.", stage = 2, stageChanged = true }
		end
		return true, { message = string.format("Dane wejściowe: %d/3.", inputCount(state)), stage = state.stage }
	elseif action == "formula" then
		if inputCount(state) < 3 then
			return fail(state, "DEBUG FORMUŁY • Najpierw uzupełnij wszystkie dane wejściowe.")
		end
		state.formula = true
		return true, { message = "Formuła = liczba × cena × (1-rabat) działa.", stage = state.stage }
	elseif action == "whatif" then
		if not state.formula then
			return fail(state, "DEBUG WHAT‑IF • Najpierw zbuduj formułę.")
		end
		state.whatIf = true
		return true, { message = "Zmiana rabatu przelicza wynik automatycznie.", stage = state.stage }
	elseif action == "check" then
		if not state.whatIf then
			return fail(state, "DEBUG WERYFIKACJI • Najpierw wykonaj próbę what‑if.")
		end
		state.checked = true
		state.completed = true
		return true, { message = "Model rozwiązuje problem i reaguje na zmianę danych.", stage = 3, completed = true }
	end
	return fail(state, "Nieznana akcja.")
end

function SpreadsheetProblemRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return SpreadsheetProblemRules
