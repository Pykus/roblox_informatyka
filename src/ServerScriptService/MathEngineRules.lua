local Rules = {}

Rules.Functions = { "SQRT", "FLOOR", "CEIL" }

Rules.Stations = {
	{
		id = "LASER",
		title = "RAMIĘ LASERA",
		input = 81,
		target = 9,
		expected = "SQRT",
		prompt = "Pole kwadratu wynosi 81. Ustaw długość boku.",
		reason = "sqrt(81) = 9, więc pierwiastek odzyskuje długość boku z pola.",
	},
	{
		id = "ELEVATOR",
		title = "WINDA SERWISOWA",
		input = 7.8,
		target = 7,
		expected = "FLOOR",
		prompt = "Winda może zatrzymać się tylko na pełnym piętrze nie wyżej niż 7.8.",
		reason = "floor(7.8) = 7, bo floor zaokrągla w dół.",
	},
	{
		id = "PACKER",
		title = "PAKOWARKA",
		input = 7.2,
		target = 8,
		expected = "CEIL",
		prompt = "Ładunek zajmuje 7.2 sekcji. Ile pełnych sekcji trzeba zarezerwować?",
		reason = "ceil(7.2) = 8, bo ceil zaokrągla w górę do pełnej potrzebnej liczby sekcji.",
	},
}

local function compute(functionId, value)
	if functionId == "SQRT" then
		return math.sqrt(value)
	elseif functionId == "FLOOR" then
		return math.floor(value)
	elseif functionId == "CEIL" then
		return math.ceil(value)
	end
	return nil
end

function Rules.NewState()
	return {
		index = 1,
		errors = 0,
		completed = false,
		results = {},
		attempts = 0,
	}
end

function Rules.CurrentStation(state)
	local station = Rules.Stations[state.index]
	if not station then
		return nil
	end
	return {
		id = station.id,
		title = station.title,
		input = station.input,
		target = station.target,
		expected = station.expected,
		prompt = station.prompt,
		reason = station.reason,
	}
end

function Rules.Apply(state, functionId)
	if state.completed then
		return false, {
			message = "Silnik matematyczny jest już uruchomiony.",
		}
	end
	if not table.find(Rules.Functions, functionId) then
		return false, {
			message = "Nieznana funkcja matematyczna.",
		}
	end

	local station = Rules.Stations[state.index]
	if not station then
		return false, {
			message = "Brak aktywnego stanowiska.",
		}
	end

	local output = compute(functionId, station.input)
	state.attempts += 1

	if functionId ~= station.expected then
		state.errors += 1
		return false,
			{
				station = station.id,
				functionId = functionId,
				input = station.input,
				output = output,
				target = station.target,
				message = string.format(
					"%s(%s) daje %s, ale stanowisko potrzebuje %s. %s",
					string.lower(functionId),
					tostring(station.input),
					tostring(output),
					tostring(station.target),
					station.reason
				),
			}
	end

	state.results[station.id] = output
	state.index += 1

	return true,
		{
			station = station.id,
			functionId = functionId,
			input = station.input,
			output = output,
			target = station.target,
			reason = station.reason,
			nextStation = Rules.CurrentStation(state),
			allSolved = state.index > #Rules.Stations,
		}
end

function Rules.CanComplete(state)
	if state.index <= #Rules.Stations then
		return false
	end
	for _, station in ipairs(Rules.Stations) do
		if state.results[station.id] ~= station.target then
			return false
		end
	end
	return true
end

function Rules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

function Rules.Complete(state)
	if not Rules.CanComplete(state) then
		return false, "Najpierw skalibruj wszystkie trzy stanowiska."
	end
	state.completed = true
	return true, {
		efficiency = Rules.Efficiency(state),
		errors = state.errors,
		attempts = state.attempts,
	}
end

function Rules.FunctionLabel(functionId)
	if functionId == "SQRT" then
		return "math.sqrt(x)"
	elseif functionId == "FLOOR" then
		return "math.floor(x)"
	elseif functionId == "CEIL" then
		return "math.ceil(x)"
	end
	return "?"
end

return Rules