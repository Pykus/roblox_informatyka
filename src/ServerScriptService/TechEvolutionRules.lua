local TechEvolutionRules = {}

local ORDER = { "mainframe", "pc", "internet", "mobile_ai" }

function TechEvolutionRules.NewState()
	return {
		stage = 1,
		nextIndex = 1,
		placed = {},
		links = {},
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

function TechEvolutionRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Oś rozwoju jest już naprawiona.", stage = state.stage, completed = true }
	end
	if action == "era" then
		local expected = ORDER[state.nextIndex]
		if value ~= expected then
			return fail(state, "DEBUG CZASU • Ten element nie pasuje do następnego miejsca osi.")
		end
		state.placed[value] = true
		state.nextIndex += 1
		if state.nextIndex > #ORDER then
			state.stage = 2
			return true, { message = "4/4 epoki ułożone. Połącz przełomy z ich skutkami.", stage = 2, stageChanged = true }
		end
		return true, { message = string.format("Oś czasu: %d/4 epoki.", state.nextIndex - 1), stage = state.stage }
	elseif action == "link" then
		if state.stage ~= 2 then
			return fail(state, "DEBUG POŁĄCZENIA • Najpierw napraw chronologię.")
		end
		local valid = value == "internet_network" or value == "mobile_everywhere" or value == "ai_assist"
		if not valid then
			return fail(state, "DEBUG SKUTKU • To połączenie nie opisuje rozwoju informatyki.")
		end
		state.links[value] = true
		local n = 0
		for _ in pairs(state.links) do n += 1 end
		if n >= 3 then
			state.completed = true
			return true, { message = "Oś technologii działa: rozwój sprzętu, sieci, mobilności i AI jest połączony.", stage = 3, completed = true }
		end
		return true, { message = string.format("Połączenia: %d/3.", n), stage = state.stage }
	end
	return fail(state, "Nieznana akcja.")
end

function TechEvolutionRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return TechEvolutionRules
