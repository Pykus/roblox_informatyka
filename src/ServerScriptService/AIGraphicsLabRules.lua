local AIGraphicsLabRules = {}

local REQUIRED_TOKENS = {
	subject = true,
	style = true,
	privacy = true,
}

function AIGraphicsLabRules.NewState()
	return {
		stage = 1,
		briefScanned = false,
		tokens = {},
		generated = false,
		chosenVariant = nil,
		improved = false,
		approved = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

local function tokenCount(state)
	local count = 0
	for key in pairs(REQUIRED_TOKENS) do
		if state.tokens[key] then
			count += 1
		end
	end
	return count
end

function AIGraphicsLabRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Projekt jest już zatwierdzony.", stage = state.stage, completed = true }
	end

	if action == "brief" then
		state.briefScanned = true
		return true, {
			message = "Brief: plakat szkolnego Dnia Ziemi. Zbierz 3 bezpieczne składniki promptu.",
			stage = state.stage,
		}
	end

	if action == "token" then
		if not state.briefScanned then
			return fail(state, "DEBUG PROMPTU • Najpierw zeskanuj brief.")
		end
		if not REQUIRED_TOKENS[value] then
			return fail(state, "DEBUG PROMPTU • Ten składnik nie pasuje do zadania.")
		end
		state.tokens[value] = true
		local count = tokenCount(state)
		if count == 3 then
			state.stage = 2
			return true, {
				message = "Prompt ma temat, styl i zasadę prywatności. Uruchom generator wariantów.",
				stage = state.stage,
				stageChanged = true,
			}
		end
		return true, {
			message = string.format("Prompt: %d/3 składniki.", count),
			stage = state.stage,
		}
	end

	if action == "generate" then
		if tokenCount(state) < 3 then
			return fail(state, "DEBUG GENEROWANIA • Prompt jest niepełny.")
		end
		state.generated = true
		return true, {
			message = "Wygenerowano 3 symulowane warianty. Porównaj czytelność i zgodność z briefem.",
			stage = state.stage,
		}
	end

	if action == "choose" then
		if not state.generated then
			return fail(state, "DEBUG WYBORU • Najpierw wygeneruj warianty.")
		end
		if value ~= "B" then
			local why = value == "A"
					and "Wariant A jest przeładowany detalami."
				or "Wariant C zawiera nieczytelny tekst wygenerowany przez AI."
			return fail(state, "DEBUG OCENY • " .. why .. " Spróbuj innego wariantu.")
		end
		state.chosenVariant = "B"
		state.stage = 3
		return true, {
			message = "Wariant B jest czytelny i zgodny z briefem. Teraz popraw prompt.",
			stage = state.stage,
			stageChanged = true,
		}
	end

	if action == "improve" then
		if state.chosenVariant ~= "B" then
			return fail(state, "DEBUG ITERACJI • Najpierw wybierz najlepszy wariant.")
		end
		state.improved = true
		return true, {
			message = "Prompt poprawiony: prosta kompozycja, bez tekstu i bez danych osobowych.",
			stage = state.stage,
		}
	end

	if action == "approve" then
		if not state.improved then
			return fail(state, "DEBUG ZATWIERDZENIA • Najpierw wykonaj iterację promptu.")
		end
		state.approved = true
		state.completed = true
		return true, {
			message = "Projekt zatwierdzony przez człowieka. AI pomogło, ale decyzję podjąłeś Ty.",
			stage = 4,
			completed = true,
		}
	end

	return fail(state, "Nieznana akcja.")
end

function AIGraphicsLabRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return AIGraphicsLabRules
