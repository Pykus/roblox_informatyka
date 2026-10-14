local ClipchampStudioRules = {}

function ClipchampStudioRules.NewState()
	return {
		stage = 1,
		imported = {},
		order = {},
		transition = false,
		audio = false,
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

local function importedCount(state)
	local n = 0
	for i = 1, 3 do
		if state.imported[i] then n += 1 end
	end
	return n
end

function ClipchampStudioRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Film jest już wyeksportowany.", stage = state.stage, completed = true }
	end

	if action == "import" then
		if value < 1 or value > 3 then
			return fail(state, "DEBUG IMPORTU • Wybierz zdjęcie 1, 2 lub 3.")
		end
		state.imported[value] = true
		if importedCount(state) == 3 then
			state.stage = 2
			return true, { message = "3/3 zdjęcia zaimportowane. Ułóż je na timeline.", stage = state.stage, stageChanged = true }
		end
		return true, { message = string.format("Import: %d/3 zdjęcia.", importedCount(state)), stage = state.stage }
	elseif action == "timeline" then
		if importedCount(state) < 3 then
			return fail(state, "DEBUG TIMELINE • Najpierw zaimportuj wszystkie zdjęcia.")
		end
		local expected = #state.order + 1
		if value ~= expected then
			return fail(state, string.format("DEBUG KOLEJNOŚCI • Następny klip to %d.", expected))
		end
		table.insert(state.order, value)
		return true, { message = string.format("Timeline: %d/3 klipy.", #state.order), stage = state.stage }
	elseif action == "transition" then
		if #state.order < 3 then
			return fail(state, "DEBUG PRZEJŚCIA • Najpierw ułóż 3 klipy.")
		end
		state.transition = true
		return true, { message = "Przejście między klipami ustawione.", stage = state.stage }
	elseif action == "audio" then
		if not state.transition then
			return fail(state, "DEBUG DŹWIĘKU • Najpierw dodaj przejście.")
		end
		state.audio = true
		return true, { message = "Ścieżka audio dodana i wyciszona do bezpiecznego poziomu.", stage = state.stage }
	elseif action == "preview" then
		if not state.audio then
			return fail(state, "DEBUG PODGLĄDU • Film nie ma kompletnego montażu.")
		end
		state.previewed = true
		return true, { message = "Podgląd: 3 klipy, przejście i dźwięk działają.", stage = state.stage }
	elseif action == "export" then
		if not state.previewed then
			return fail(state, "DEBUG EKSPORTU • Najpierw obejrzyj cały film.")
		end
		state.exported = true
		state.completed = true
		return true, { message = "Film wyeksportowany po pełnym podglądzie.", stage = 3, completed = true }
	end
	return fail(state, "Nieznana akcja.")
end

function ClipchampStudioRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 7)
end

return ClipchampStudioRules
