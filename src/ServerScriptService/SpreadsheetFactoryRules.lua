local Rules = {}

Rules.Rows = { "BATTERY", "SENSOR", "CABLE" }
Rules.TargetFormula = {
	D2 = "B2*C2",
	D3 = "B3*C3",
	D4 = "B4*C4",
	D5 = "SUM(D2:D4)",
}
Rules.TargetBudget = 80

function Rules.NewState()
	return {
		stage = 1,
		quantities = {
			BATTERY = 2,
			SENSOR = 3,
			CABLE = 7,
		},
		prices = {
			BATTERY = 12,
			SENSOR = 8,
			CABLE = 4,
		},
		formulas = {
			D2 = nil,
			D3 = nil,
			D4 = nil,
			D5 = nil,
		},
		errors = 0,
		productionRuns = 0,
		completed = false,
	}
end

function Rules.InstallFormula(state, cell, formula)
	if not Rules.TargetFormula[cell] then
		return false, "Nieznana komórka formuły."
	end
	state.formulas[cell] = formula
	local correct = formula == Rules.TargetFormula[cell]
	if not correct then
		state.errors += 1
		return false, string.format("%s daje zły wynik. Sprawdź odwołania.", cell)
	end
	return true
end

function Rules.FormulaCorrect(state, cell)
	return state.formulas[cell] == Rules.TargetFormula[cell]
end

function Rules.FormulaValue(state, cell)
	local formula = state.formulas[cell]
	if cell == "D2" then
		if formula == "B2*C2" then
			return state.quantities.BATTERY * state.prices.BATTERY
		elseif formula == "B2+C2" then
			return state.quantities.BATTERY + state.prices.BATTERY
		end
	elseif cell == "D3" then
		if formula == "B3*C3" then
			return state.quantities.SENSOR * state.prices.SENSOR
		elseif formula == "B2*C3" then
			return state.quantities.BATTERY * state.prices.SENSOR
		end
	elseif cell == "D4" then
		if formula == "B4*C4" then
			return state.quantities.CABLE * state.prices.CABLE
		elseif formula == "B4+C4" then
			return state.quantities.CABLE + state.prices.CABLE
		end
	elseif cell == "D5" then
		if formula == "SUM(D2:D4)" then
			return Rules.GrandTotal(state)
		elseif formula == "SUM(B2:C4)" then
			return state.quantities.BATTERY
				+ state.prices.BATTERY
				+ state.quantities.SENSOR
				+ state.prices.SENSOR
				+ state.quantities.CABLE
				+ state.prices.CABLE
		end
	end
	return nil
end

function Rules.FirstBrokenFormula(state)
	for _, cell in ipairs({ "D2", "D3", "D4", "D5" }) do
		if not Rules.FormulaCorrect(state, cell) then
			return cell
		end
	end
	return nil
end

function Rules.AllFormulasCorrect(state)
	for cell, expected in pairs(Rules.TargetFormula) do
		if state.formulas[cell] ~= expected then
			return false
		end
	end
	return true
end

function Rules.RowTotal(state, row)
	local q = state.quantities[row]
	local p = state.prices[row]
	if not q or not p then
		return nil
	end
	return q * p
end

function Rules.GrandTotal(state)
	local sum = 0
	for _, row in ipairs(Rules.Rows) do
		sum += Rules.RowTotal(state, row)
	end
	return sum
end

function Rules.CanRunProduction(state)
	return state.stage == 1 and Rules.AllFormulasCorrect(state)
end

function Rules.StartProduction(state)
	if not Rules.AllFormulasCorrect(state) then
		return false, "Napraw wszystkie cztery formuły."
	end
	state.stage = 2
	state.productionRuns += 1
	return true, Rules.GrandTotal(state)
end

function Rules.FinishProduction(state)
	if state.stage ~= 2 then
		return false, "Linia nie pracuje."
	end
	state.stage = 3
	return true
end

function Rules.AdjustQuantity(state, row, delta)
	if state.stage ~= 3 then
		return false, "Dane wejściowe zmieniasz po pierwszym przebiegu."
	end
	if not table.find(Rules.Rows, row) then
		return false, "Nieznany wiersz."
	end
	if delta ~= 1 and delta ~= -1 then
		return false, "Dozwolone są zmiany o 1."
	end
	state.quantities[row] = math.clamp(state.quantities[row] + delta, 1, 12)
	return true, Rules.GrandTotal(state)
end

function Rules.TargetReached(state)
	return state.stage == 3 and Rules.GrandTotal(state) == Rules.TargetBudget
end

function Rules.Complete(state)
	if not Rules.TargetReached(state) then
		return false,
			string.format("Budżet wynosi %d. Cel fabryki to %d.", Rules.GrandTotal(state), Rules.TargetBudget)
	end
	state.completed = true
	return true
end

return Rules