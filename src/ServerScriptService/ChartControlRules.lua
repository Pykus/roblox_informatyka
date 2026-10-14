local ChartControlRules = {}

function ChartControlRules.NewState()
	return {
		stage = 1,
		range = nil,
		chartType = nil,
		title = false,
		labels = false,
		compared = false,
		published = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

function ChartControlRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Wykres jest już opublikowany.", stage = state.stage, completed = true }
	end
	if action == "range" then
		if value ~= "sales" then
			return fail(state, "DEBUG ZAKRESU • Zaznacz tylko kategorie i wartości sprzedaży.")
		end
		state.range = value
		return true, { message = "Zakres danych wybrany poprawnie.", stage = state.stage }
	elseif action == "type" then
		if not state.range then
			return fail(state, "DEBUG WYKRESU • Najpierw wybierz zakres danych.")
		end
		if value ~= "column" then
			return fail(state, "DEBUG TYPU • Do porównania kategorii wybierz wykres kolumnowy.")
		end
		state.chartType = value
		state.stage = 2
		return true, { message = "Wykres kolumnowy pokazuje porównanie kategorii.", stage = 2, stageChanged = true }
	elseif action == "title" then
		if state.stage ~= 2 then
			return fail(state, "DEBUG TYTUŁU • Najpierw zbuduj wykres.")
		end
		state.title = true
		return true, { message = "Tytuł wykresu dodany.", stage = state.stage }
	elseif action == "labels" then
		if not state.title then
			return fail(state, "DEBUG ETYKIET • Najpierw dodaj czytelny tytuł.")
		end
		state.labels = true
		return true, { message = "Etykiety wartości są widoczne.", stage = state.stage }
	elseif action == "compare" then
		if not state.labels then
			return fail(state, "DEBUG ODCZYTU • Wykres nie jest jeszcze opisany.")
		end
		state.compared = true
		return true, { message = "Wniosek: najwyższa wartość należy do kategorii B.", stage = state.stage }
	elseif action == "publish" then
		if not state.compared then
			return fail(state, "DEBUG PUBLIKACJI • Najpierw odczytaj wniosek z wykresu.")
		end
		state.published = true
		state.completed = true
		return true, { message = "Wykres opublikowany z zakresem, typem, tytułem i etykietami.", stage = 3, completed = true }
	end
	return fail(state, "Nieznana akcja.")
end

function ChartControlRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return ChartControlRules
