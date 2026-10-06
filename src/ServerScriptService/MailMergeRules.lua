local MailMergeRules = {}

MailMergeRules.Fields = { "IMIE", "KLASA", "MIASTO" }
MailMergeRules.Expected = { "IMIE", "KLASA", "MIASTO" }
MailMergeRules.Records = {
	{ IMIE = "Ala", KLASA = "2A", MIASTO = "Gdańsk" },
	{ IMIE = "Olek", KLASA = "2B", MIASTO = "Sopot" },
	{ IMIE = "Maja", KLASA = "2C", MIASTO = "Gdynia" },
}
MailMergeRules.Template = "Cześć <<IMIE>>! Klasa <<KLASA>> jedzie na warsztaty w mieście <<MIASTO>>."

function MailMergeRules.NewState()
	return {
		stage = 1,
		mapping = { "MIASTO", "IMIE", "KLASA" },
		previewed = {},
		previewCount = 0,
		errors = 0,
		completed = false,
	}
end

local function nextField(current)
	local index = table.find(MailMergeRules.Fields, current) or 1
	return MailMergeRules.Fields[(index % #MailMergeRules.Fields) + 1]
end

function MailMergeRules.CycleMapping(state, slot)
	if state.stage ~= 1 or not MailMergeRules.Expected[slot] then
		return false, "Mapowanie jest już zablokowane."
	end
	state.mapping[slot] = nextField(state.mapping[slot])
	return true, string.format("<<%s>> pobiera teraz kolumnę %s.", MailMergeRules.Expected[slot], state.mapping[slot])
end

function MailMergeRules.ValidateMapping(state)
	if state.stage ~= 1 then
		return false, "Mapowanie zostało już zatwierdzone."
	end

	local used = {}
	for slot, expected in ipairs(MailMergeRules.Expected) do
		local actual = state.mapping[slot]
		if used[actual] then
			state.errors += 1
			return false, string.format("DEBUG MAPOWANIA • Kolumna %s jest użyta więcej niż raz.", actual)
		end
		used[actual] = true
		if actual ~= expected then
			state.errors += 1
			return false,
				string.format(
					"DEBUG MAPOWANIA • Placeholder <<%s>> jest podłączony do %s. Popraw kabel.",
					expected,
					actual
				)
		end
	end

	state.stage = 2
	return true, "Mapowanie 3/3 poprawne. Teraz sprawdź podgląd wszystkich rekordów."
end

function MailMergeRules.Render(state, recordIndex)
	local record = MailMergeRules.Records[recordIndex]
	if not record then
		return nil
	end
	local text = MailMergeRules.Template
	for slot, placeholder in ipairs(MailMergeRules.Expected) do
		local sourceField = state.mapping[slot]
		text = text:gsub("<<" .. placeholder .. ">>", record[sourceField] or "?")
	end
	return text
end

function MailMergeRules.Preview(state, recordIndex)
	if state.stage ~= 2 then
		return false, "Najpierw zatwierdź mapowanie pól.", nil
	end
	local rendered = MailMergeRules.Render(state, recordIndex)
	if not rendered then
		return false, "Nieznany rekord.", nil
	end

	if not state.previewed[recordIndex] then
		state.previewed[recordIndex] = true
		state.previewCount += 1
	end

	if state.previewCount == #MailMergeRules.Records then
		state.stage = 3
		return true, "Podgląd 3/3 gotowy. Seria jest gotowa do druku.", rendered
	end

	return true, string.format("Podgląd %d/3 gotowy. Sprawdź pozostałe rekordy.", state.previewCount), rendered
end

function MailMergeRules.PrintBatch(state)
	if state.stage ~= 3 then
		state.errors += 1
		return false, "DRUK ZABLOKOWANY • Najpierw sprawdź wszystkie trzy podglądy.", nil
	end

	local letters = {}
	for index = 1, #MailMergeRules.Records do
		letters[index] = MailMergeRules.Render(state, index)
	end
	state.completed = true
	state.stage = 4
	return true, "Scalono i wydrukowano 3 spersonalizowane listy.", letters
end

function MailMergeRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return MailMergeRules