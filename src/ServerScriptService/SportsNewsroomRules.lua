local Rules = {}

Rules.Facts = { "SCORE", "SHOTS", "POSSESSION", "FOULS" }
Rules.ChartTarget = {
	HOME = 12,
	AWAY = 6,
}
Rules.ChartMax = 15
Rules.CameraTarget = 2

function Rules.NewState()
	return {
		stage = 1,
		scanned = {},
		notes = {},
		chart = {
			HOME = 9,
			AWAY = 9,
		},
		chartReady = false,
		cameraPosition = 1,
		photoReady = false,
		errors = 0,
		completed = false,
	}
end

local factText = {
	SCORE = "Falcons 3 : 1 Comets",
	SHOTS = "Strzały: 12 : 6",
	POSSESSION = "Posiadanie: 58% : 42%",
	FOULS = "Faule: 4 : 7",
}

function Rules.ScanFact(state, factId)
	if state.stage ~= 1 then
		return false, "Notatnik danych jest już zamknięty."
	end
	if not table.find(Rules.Facts, factId) then
		return false, "Nieznany panel danych."
	end
	if state.scanned[factId] then
		return false, "Ten fakt jest już w notatniku."
	end
	state.scanned[factId] = true
	table.insert(state.notes, factText[factId])
	if #state.notes == #Rules.Facts then
		state.stage = 2
	end
	return true, factText[factId]
end

function Rules.ScannedCount(state)
	local count = 0
	for _, factId in ipairs(Rules.Facts) do
		if state.scanned[factId] then
			count += 1
		end
	end
	return count
end

function Rules.AdjustChart(state, side, delta)
	if state.stage ~= 2 then
		return false, "Wykres nie jest teraz aktywny."
	end
	if side ~= "HOME" and side ~= "AWAY" then
		return false, "Nieznana seria danych."
	end
	if delta ~= 1 and delta ~= -1 then
		return false, "Zmiana musi wynosić +1 lub -1."
	end
	state.chart[side] = math.clamp(state.chart[side] + delta, 0, Rules.ChartMax)
	state.chartReady = false
	return true, state.chart[side]
end

function Rules.ValidateChart(state)
	if state.stage ~= 2 then
		return false, "Wykres nie jest teraz aktywny."
	end
	if state.chart.HOME ~= Rules.ChartTarget.HOME then
		state.errors += 1
		return false, string.format("Falcons: wykres pokazuje %d, a dane mówią 12.", state.chart.HOME)
	end
	if state.chart.AWAY ~= Rules.ChartTarget.AWAY then
		state.errors += 1
		return false, string.format("Comets: wykres pokazuje %d, a dane mówią 6.", state.chart.AWAY)
	end
	state.chartReady = true
	state.stage = 3
	return true, "Wykres strzałów jest zgodny z danymi."
end

function Rules.MoveCamera(state, delta)
	if state.stage ~= 3 or state.photoReady then
		return false, "Kamera nie jest teraz aktywna."
	end
	if delta ~= 1 and delta ~= -1 then
		return false, "Kamera porusza się o jeden punkt."
	end
	state.cameraPosition = math.clamp(state.cameraPosition + delta, 1, 3)
	return true, state.cameraPosition
end

function Rules.Capture(state)
	if state.stage ~= 3 or not state.chartReady then
		return false, "Najpierw przygotuj poprawny wykres."
	end
	if state.cameraPosition ~= Rules.CameraTarget then
		state.errors += 1
		return false, "Kadr nie obejmuje jednocześnie wyniku i wykresu. Ustaw kamerę centralnie."
	end
	state.photoReady = true
	return true, "Zdjęcie reporterskie zapisane."
end

function Rules.CanPublish(state)
	return Rules.ScannedCount(state) == #Rules.Facts and state.chartReady and state.photoReady
end

function Rules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

function Rules.Publish(state)
	if not Rules.CanPublish(state) then
		return false, "Brakuje notatki, poprawnego wykresu lub zdjęcia."
	end
	state.completed = true
	return true, {
		efficiency = Rules.Efficiency(state),
		errors = state.errors,
		notes = #state.notes,
	}
end

function Rules.NoteText(state)
	if #state.notes == 0 then
		return "NOTATNIK REPORTERA\n—"
	end
	return "NOTATNIK REPORTERA\n" .. table.concat(state.notes, "\n")
end

return Rules