local ChronoMuseumRules = {}

ChronoMuseumRules.Order = { "TRANSISTOR", "ARPANET", "MICROCHIP", "WWW" }

ChronoMuseumRules.Exhibits = {
	TRANSISTOR = {
		label = "TRANSISTOR",
		year = 1947,
		candidates = { 1969, 1991, 1947 },
	},
	ARPANET = {
		label = "ARPANET",
		year = 1969,
		candidates = { 2007, 1969, 1947 },
	},
	MICROCHIP = {
		label = "MIKROPROCESOR",
		year = 1971,
		candidates = { 1947, 1981, 1971 },
	},
	WWW = {
		label = "WORLD WIDE WEB",
		year = 1991,
		candidates = { 1971, 1991, 2007 },
	},
}

function ChronoMuseumRules.NewState()
	local indices = {}
	for id in pairs(ChronoMuseumRules.Exhibits) do
		indices[id] = 1
	end
	return {
		indices = indices,
		stabilized = {},
		stabilizedCount = 0,
		scanIndex = 0,
		errors = 0,
		done = false,
	}
end

function ChronoMuseumRules.CurrentYear(state, id)
	local exhibit = ChronoMuseumRules.Exhibits[id]
	if not exhibit then
		return nil
	end
	local index = state.indices[id] or 1
	return exhibit.candidates[index]
end

function ChronoMuseumRules.CycleYear(state, id)
	local exhibit = ChronoMuseumRules.Exhibits[id]
	if not exhibit or state.stabilized[id] then
		return false, ChronoMuseumRules.CurrentYear(state, id)
	end
	local index = (state.indices[id] or 1) + 1
	if index > #exhibit.candidates then
		index = 1
	end
	state.indices[id] = index
	return true, exhibit.candidates[index]
end

function ChronoMuseumRules.Stabilize(state, id)
	local exhibit = ChronoMuseumRules.Exhibits[id]
	if not exhibit then
		return false, "Nieznany eksponat."
	end
	if state.stabilized[id] then
		return true, "Eksponat jest już stabilny."
	end
	local current = ChronoMuseumRules.CurrentYear(state, id)
	if current ~= exhibit.year then
		state.errors += 1
		return false,
			string.format(
				"ANOMALIA CZASU • %s ma rok %d, ale ten kamień milowy pochodzi z innej daty.",
				exhibit.label,
				current
			)
	end
	state.stabilized[id] = true
	state.stabilizedCount += 1
	return true, string.format("%s ustabilizowany: %d.", exhibit.label, exhibit.year)
end

function ChronoMuseumRules.AllStabilized(state)
	return state.stabilizedCount == #ChronoMuseumRules.Order
end

function ChronoMuseumRules.Scan(state, id)
	if not ChronoMuseumRules.AllStabilized(state) then
		return false, "Najpierw ustabilizuj wszystkie cztery eksponaty."
	end
	local expected = ChronoMuseumRules.Order[state.scanIndex + 1]
	if not expected then
		return false, "Sekwencja chronologiczna jest już kompletna."
	end
	if id ~= expected then
		state.errors += 1
		state.scanIndex = 0
		return false,
			string.format(
				"DEBUG CHRONOLOGII • %s nie jest teraz najwcześniejszym kamieniem milowym. Sekwencja skanu została wyzerowana.",
				ChronoMuseumRules.Exhibits[id].label
			)
	end
	state.scanIndex += 1
	return true,
		string.format(
			"Chronologia %d/4 • %s %d",
			state.scanIndex,
			ChronoMuseumRules.Exhibits[id].label,
			ChronoMuseumRules.Exhibits[id].year
		)
end

function ChronoMuseumRules.ScanComplete(state)
	return state.scanIndex == #ChronoMuseumRules.Order
end

function ChronoMuseumRules.Synchronize(state)
	if not ChronoMuseumRules.ScanComplete(state) then
		state.errors += 1
		return false, "Zegar odrzuca synchronizację: najpierw zeskanuj 4 kamienie milowe od najstarszego."
	end
	state.done = true
	return true, "Chronologia zsynchronizowana."
end

function ChronoMuseumRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return ChronoMuseumRules