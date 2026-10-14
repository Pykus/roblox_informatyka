local SchoolNewsroomRules = {}

function SchoolNewsroomRules.NewState()
	return {
		stage = 1,
		cover = false,
		article = false,
		photo = false,
		page2 = false,
		header = false,
		pageNumbers = false,
		previewed = false,
		printed = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

function SchoolNewsroomRules.Apply(state, action)
	if state.completed then
		return false, { message = "Gazetka jest już wydrukowana.", stage = state.stage, completed = true }
	end

	if action == "cover" then
		state.cover = true
		return true, { message = "Okładka gotowa. Dodaj artykuł i zdjęcie.", stage = state.stage }
	elseif action == "article" then
		if not state.cover then
			return fail(state, "DEBUG UKŁADU • Najpierw przygotuj okładkę.")
		end
		state.article = true
		return true, { message = "Artykuł dodany do strony 1.", stage = state.stage }
	elseif action == "photo" then
		if not state.article then
			return fail(state, "DEBUG GRAFIKI • Najpierw dodaj artykuł, potem dopasuj zdjęcie.")
		end
		state.photo = true
		return true, { message = "Zdjęcie osadzone i opisane.", stage = state.stage }
	elseif action == "page2" then
		if not (state.cover and state.article and state.photo) then
			return fail(state, "DEBUG STRON • Strona 1 nie jest kompletna.")
		end
		state.page2 = true
		state.stage = 2
		return true, { message = "Druga strona dodana. Ustaw nagłówek i numery stron.", stage = state.stage, stageChanged = true }
	elseif action == "header" then
		if state.stage ~= 2 then
			return fail(state, "DEBUG NAGŁÓWKA • Najpierw utwórz stronę 2.")
		end
		state.header = true
		return true, { message = "Nagłówek gazetki ustawiony na obu stronach.", stage = state.stage }
	elseif action == "numbers" then
		if not state.header then
			return fail(state, "DEBUG NUMERACJI • Najpierw ustaw nagłówek dokumentu.")
		end
		state.pageNumbers = true
		return true, { message = "Numery stron 1/2 i 2/2 dodane.", stage = state.stage }
	elseif action == "preview" then
		if not state.pageNumbers then
			return fail(state, "DEBUG PODGLĄDU • Gazetka nie ma jeszcze pełnej struktury.")
		end
		state.previewed = true
		return true, { message = "Podgląd wydruku: obie strony są czytelne.", stage = state.stage }
	elseif action == "print" then
		if not state.previewed then
			return fail(state, "DEBUG DRUKU • Najpierw użyj podglądu wydruku.")
		end
		state.printed = true
		state.completed = true
		return true, { message = "Gazetka 2-stronicowa wydrukowana.", stage = 3, completed = true }
	end
	return fail(state, "Nieznana akcja.")
end

function SchoolNewsroomRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 7)
end

return SchoolNewsroomRules
