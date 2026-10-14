local KlekiStudioRules = {}

function KlekiStudioRules.NewState()
	return {
		stage = 1,
		tool = nil,
		color = nil,
		baseStrokes = 0,
		layerCreated = false,
		overlayStrokes = 0,
		visibilityChecked = false,
		exported = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

function KlekiStudioRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Praca jest już wyeksportowana.", stage = state.stage, completed = true }
	end

	if action == "tool" then
		state.tool = value
		if value ~= "brush" then
			return fail(state, "DEBUG NARZĘDZIA • Do szkicu wybierz PĘDZEL.")
		end
		return true, { message = "Pędzel gotowy. Teraz wybierz kolor turkusowy.", stage = state.stage }
	end

	if action == "color" then
		state.color = value
		if state.stage == 1 and value ~= "cyan" then
			return fail(state, "DEBUG KOLORU • Pierwsza warstwa ma być turkusowa.")
		end
		if state.stage == 2 and value ~= "magenta" then
			return fail(state, "DEBUG KOLORU • Druga warstwa ma być różowa, aby było ją łatwo porównać.")
		end
		return true, { message = "Kolor ustawiony.", stage = state.stage }
	end

	if action == "stroke" then
		if state.tool ~= "brush" then
			return fail(state, "DEBUG RYSOWANIA • Najpierw wybierz PĘDZEL.")
		end
		if state.stage == 1 then
			if state.color ~= "cyan" then
				return fail(state, "DEBUG RYSOWANIA • Szkic wykonaj kolorem turkusowym.")
			end
			state.baseStrokes += 1
			if state.baseStrokes >= 3 then
				state.stage = 2
				return true, {
					message = "Szkic gotowy: 3/3 kreski. Dodaj nową warstwę.",
					stage = state.stage,
					stageChanged = true,
				}
			end
			return true, {
				message = string.format("Szkic: %d/3 kreski.", state.baseStrokes),
				stage = state.stage,
			}
		end
		if not state.layerCreated then
			return fail(state, "DEBUG WARSTWY • Przed dalszym rysowaniem dodaj drugą warstwę.")
		end
		if state.color ~= "magenta" then
			return fail(state, "DEBUG RYSOWANIA • Na drugiej warstwie użyj różowego koloru.")
		end
		state.overlayStrokes += 1
		return true, {
			message = string.format("Warstwa 2: %d/2 kreski.", math.min(state.overlayStrokes, 2)),
			stage = state.stage,
		}
	end

	if action == "layer" then
		if state.stage ~= 2 then
			return fail(state, "DEBUG WARSTWY • Najpierw ukończ szkic 3/3.")
		end
		if state.layerCreated then
			return false, { message = "Druga warstwa już istnieje.", stage = state.stage }
		end
		state.layerCreated = true
		return true, { message = "Warstwa 2 dodana. Wybierz kolor różowy.", stage = state.stage }
	end

	if action == "visibility" then
		if not state.layerCreated or state.overlayStrokes < 2 then
			return fail(state, "DEBUG PODGLĄDU • Najpierw narysuj 2 kreski na drugiej warstwie.")
		end
		state.visibilityChecked = true
		return true, {
			message = "Porównałeś warstwy. Możesz przygotować eksport.",
			stage = state.stage,
		}
	end

	if action == "export" then
		if not state.visibilityChecked then
			return fail(state, "DEBUG EKSPORTU • Przed eksportem wyłącz i włącz podgląd warstwy 2.")
		end
		state.exported = true
		state.completed = true
		return true, {
			message = "Eksport gotowy. Obraz zachował obie warstwy i poprawną kompozycję.",
			stage = 3,
			completed = true,
		}
	end

	return fail(state, "Nieznana akcja.")
end

function KlekiStudioRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return KlekiStudioRules
