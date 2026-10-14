local TinkercadWorkshopRules = {}

local REQUIRED = { box = true, cylinder = true, wedge = true }

function TinkercadWorkshopRules.NewState()
	return {
		stage = 1,
		placed = {},
		aligned = false,
		grouped = false,
		scaled = false,
		exported = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

local function placedCount(state)
	local count = 0
	for key in pairs(REQUIRED) do
		if state.placed[key] then count += 1 end
	end
	return count
end

function TinkercadWorkshopRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Model 3D jest już gotowy.", stage = state.stage, completed = true }
	end

	if action == "place" then
		if state.stage ~= 1 then
			return fail(state, "DEBUG KSZTAŁTU • Bryły są już zbudowane; teraz ustaw ich położenie.")
		end
		if not REQUIRED[value] then
			return fail(state, "DEBUG KSZTAŁTU • Wybierz sześcian, cylinder albo klin.")
		end
		state.placed[value] = true
		local count = placedCount(state)
		if count == 3 then
			state.stage = 2
			return true, {
				message = "3/3 bryły na stole. Teraz wyrównaj, zgrupuj i ustaw skalę.",
				stage = state.stage,
				stageChanged = true,
			}
		end
		return true, { message = string.format("Model: %d/3 potrzebne bryły.", count), stage = state.stage }
	end

	if action == "align" then
		if placedCount(state) < 3 then
			return fail(state, "DEBUG WYRÓWNANIA • Najpierw dodaj wszystkie 3 bryły.")
		end
		state.aligned = true
		return true, { message = "Bryły wyrównane do wspólnej osi.", stage = state.stage }
	end

	if action == "group" then
		if not state.aligned then
			return fail(state, "DEBUG GRUPOWANIA • Najpierw wyrównaj elementy.")
		end
		state.grouped = true
		return true, { message = "Elementy tworzą jedną grupę.", stage = state.stage }
	end

	if action == "scale" then
		if not state.grouped then
			return fail(state, "DEBUG SKALI • Najpierw zgrupuj model.")
		end
		state.scaled = true
		return true, { message = "Model przeskalowany do pola roboczego.", stage = state.stage }
	end

	if action == "export" then
		if not state.scaled then
			return fail(state, "DEBUG EKSPORTU • Najpierw ustaw poprawną skalę.")
		end
		state.exported = true
		state.completed = true
		return true, {
			message = "Model 3D gotowy do eksportu. Prymitywy zostały połączone świadomie.",
			stage = 3,
			completed = true,
		}
	end

	return fail(state, "Nieznana akcja.")
end

function TinkercadWorkshopRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return TinkercadWorkshopRules
