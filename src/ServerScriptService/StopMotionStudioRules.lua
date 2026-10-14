local StopMotionStudioRules = {}

function StopMotionStudioRules.NewState()
	return {
		stage = 1,
		nextFrame = 1,
		captured = {},
		timing = nil,
		previewed = false,
		exported = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

function StopMotionStudioRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Animacja jest już wyeksportowana.", stage = state.stage, completed = true }
	end

	if action == "capture" then
		if state.stage ~= 1 then
			return fail(state, "DEBUG KLATKI • Wszystkie zdjęcia są już zrobione.")
		end
		if value ~= state.nextFrame then
			return fail(
				state,
				string.format("DEBUG KOLEJNOŚCI • Teraz potrzebna jest klatka %d, a wybrano %s.", state.nextFrame, tostring(value))
			)
		end
		state.captured[value] = true
		state.nextFrame += 1
		if state.nextFrame > 4 then
			state.stage = 2
			return true, {
				message = "4/4 klatki gotowe. Ustaw tempo i uruchom podgląd.",
				stage = state.stage,
				stageChanged = true,
			}
		end
		return true, {
			message = string.format("Klatka %d/4 zapisana. Przesuń obiekt i zrób następną.", value),
			stage = state.stage,
		}
	end

	if action == "timing" then
		if state.stage ~= 2 then
			return fail(state, "DEBUG TEMPA • Najpierw wykonaj 4 klatki.")
		end
		if value ~= "medium" then
			return fail(state, "DEBUG TEMPA • Dla tej sceny wybierz tempo 4 kl./s.")
		end
		state.timing = value
		return true, { message = "Tempo 4 kl./s ustawione.", stage = state.stage }
	end

	if action == "preview" then
		if not state.timing then
			return fail(state, "DEBUG PODGLĄDU • Najpierw ustaw tempo animacji.")
		end
		state.previewed = true
		return true, { message = "Podgląd działa: ruch jest płynny i zachowuje kolejność klatek.", stage = state.stage }
	end

	if action == "export" then
		if not state.previewed then
			return fail(state, "DEBUG EKSPORTU • Najpierw obejrzyj animację.")
		end
		state.exported = true
		state.completed = true
		return true, {
			message = "Animacja wyeksportowana po sprawdzeniu klatek i tempa.",
			stage = 3,
			completed = true,
		}
	end

	return fail(state, "Nieznana akcja.")
end

function StopMotionStudioRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return StopMotionStudioRules
