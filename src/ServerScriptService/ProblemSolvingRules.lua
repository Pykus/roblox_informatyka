local Rules = {}

Rules.Probes = {
	SENSOR = { label = "FOTOKOMÓRKA", result = "WYKRYWA SKRZYNKĘ", good = true },
	MOTOR = { label = "SILNIK", result = "OBRACA SIĘ POPRAWNIE", good = true },
	CABLE = { label = "PRZEWÓD SYGNAŁOWY", result = "BRAK CIĄGŁOŚCI", good = false },
}

Rules.RepairOrder = { "STOP", "CONNECT", "POWER" }

function Rules.NewState()
	return {
		observed = {},
		observedCount = 0,
		diagnosis = nil,
		repairIndex = 1,
		repaired = false,
		verified = false,
		mistakes = 0,
	}
end

function Rules.Observe(state, probeId)
	local probe = Rules.Probes[probeId]
	if not probe then
		return false, "Nieznany punkt pomiarowy."
	end
	if not state.observed[probeId] then
		state.observed[probeId] = true
		state.observedCount += 1
	end
	return true, probe
end

function Rules.AllObserved(state)
	return state.observedCount == 3
end

function Rules.Diagnose(state, probeId)
	if not Rules.AllObserved(state) then
		return false, "Najpierw wykonaj wszystkie trzy pomiary."
	end
	if probeId ~= "CABLE" then
		state.mistakes += 1
		return false, "Ten podzespół przeszedł test. Szukaj sprzeczności w wynikach pomiarów."
	end
	state.diagnosis = probeId
	return true, "Diagnoza potwierdzona: przerwany przewód sygnałowy."
end

function Rules.RepairStep(state, stepId)
	if state.diagnosis ~= "CABLE" then
		return false, "Najpierw ustal przyczynę usterki."
	end
	local expected = Rules.RepairOrder[state.repairIndex]
	if stepId ~= expected then
		state.mistakes += 1
		return false, "Nie ten krok. Naprawę wykonuj bezpiecznie i w logicznej kolejności."
	end
	state.repairIndex += 1
	if state.repairIndex > #Rules.RepairOrder then
		state.repaired = true
	end
	return true, state.repaired and "Naprawa gotowa do testu." or "Krok wykonany poprawnie."
end

function Rules.Verify(state)
	if not state.repaired then
		return false, "Nie uruchamiaj próby przed ukończeniem naprawy."
	end
	state.verified = true
	return true, "Test przeszedł: sygnał dociera do sterownika, a linia działa."
end

return Rules