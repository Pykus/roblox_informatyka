local DataImportDockRules = {}

DataImportDockRules.Delimiters = { ",", ";", "|" }
DataImportDockRules.Types = { "TEKST", "LICZBA", "DECIMAL" }
DataImportDockRules.Columns = { "produkt", "sztuki", "cena" }
DataImportDockRules.ExpectedTypes = { "TEKST", "LICZBA", "DECIMAL" }

DataImportDockRules.CsvRows = {
	{ "robot", "4", "129.50" },
	{ "sensor", "12", "39.90" },
	{ "kabel", "30", "8.25" },
}

DataImportDockRules.TxtRows = {
	{ "101", "OK", "08:15" },
	{ "102", "WARN", "08:16" },
	{ "103", "OK", "08:18" },
}

local function nextValue(list, current)
	local index = table.find(list, current) or 1
	return list[(index % #list) + 1]
end

function DataImportDockRules.NewState()
	return {
		stage = 1,
		delimiter = ",",
		headers = false,
		types = { "LICZBA", "TEKST", "TEKST" },
		errors = 0,
		completed = false,
	}
end

function DataImportDockRules.CycleDelimiter(state)
	if state.stage ~= 1 and state.stage ~= 3 then
		return false, "Separator jest teraz zablokowany."
	end
	state.delimiter = nextValue(DataImportDockRules.Delimiters, state.delimiter)
	return true, "Separator: " .. state.delimiter
end

function DataImportDockRules.ToggleHeaders(state)
	if state.stage ~= 1 and state.stage ~= 3 then
		return false, "Nagłówki są teraz zablokowane."
	end
	state.headers = not state.headers
	return true, state.headers and "Nagłówki: TAK" or "Nagłówki: NIE"
end

local function formatError(state, expectedDelimiter, expectedHeaders)
	if state.delimiter ~= expectedDelimiter then
		state.errors += 1
		return false,
			string.format(
				"DEBUG IMPORTU • Separator '%s' rozrzuca kolumny. Dla tego pliku użyj '%s'.",
				state.delimiter,
				expectedDelimiter
			),
			"SCATTER"
	end
	if state.headers ~= expectedHeaders then
		state.errors += 1
		return false,
			expectedHeaders and "DEBUG IMPORTU • Pierwszy wiersz to nazwy kolumn. Włącz NAGŁÓWKI."
				or "DEBUG IMPORTU • Ten TXT nie ma wiersza nagłówków. Wyłącz NAGŁÓWKI.",
			"HEADER"
	end
	return true
end

function DataImportDockRules.ValidateFormat(state)
	if state.stage == 1 then
		local ok, message, problem = formatError(state, ";", true)
		if not ok then
			return false, message, problem
		end
		state.stage = 2
		return true, "CSV ustawiony poprawnie: separator ';' + nagłówki.", "CSV_OK"
	elseif state.stage == 3 then
		local ok, message, problem = formatError(state, "|", false)
		if not ok then
			return false, message, problem
		end
		state.stage = 4
		state.completed = true
		return true, "TXT ustawiony poprawnie: separator '|' + brak nagłówków.", "TXT_OK"
	end
	return false, "Konfiguracja formatu jest teraz zablokowana.", "LOCKED"
end

function DataImportDockRules.CycleType(state, column)
	if state.stage ~= 2 or not DataImportDockRules.ExpectedTypes[column] then
		return false, "Typy kolumn są teraz zablokowane."
	end
	state.types[column] = nextValue(DataImportDockRules.Types, state.types[column])
	return true, string.format("%s → %s", DataImportDockRules.Columns[column], state.types[column])
end

function DataImportDockRules.ValidateTypes(state)
	if state.stage ~= 2 then
		return false, "Najpierw popraw format CSV.", nil
	end
	for index, expected in ipairs(DataImportDockRules.ExpectedTypes) do
		local actual = state.types[index]
		if actual ~= expected then
			state.errors += 1
			return false,
				string.format(
					"DEBUG TYPU • Kolumna '%s' ma %s, potrzebuje %s.",
					DataImportDockRules.Columns[index],
					actual,
					expected
				),
				index
		end
	end
	state.stage = 3
	state.delimiter = ","
	state.headers = true
	return true, "Typy 3/3 poprawne. Przełącz dok na plik events.txt.", nil
end

function DataImportDockRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return DataImportDockRules