local PCEmergencyRoomRules = {}

PCEmergencyRoomRules.PatientOrder = { "CPU", "DISK", "DRIVER" }
PCEmergencyRoomRules.ToolOrder = { "TASK_MANAGER", "CLEANUP", "ROLLBACK" }

PCEmergencyRoomRules.Patients = {
	CPU = {
		label = "PACJENT A • LAG",
		symptom = "Wentylator pracuje głośno, okna reagują z opóźnieniem.",
		metrics = { cpu = 96, disk = 42, driver = "OK" },
		tool = "TASK_MANAGER",
		repair = "Zamknij zawieszony proces w Menedżerze zadań.",
	},
	DISK = {
		label = "PACJENT B • BRAK MIEJSCA",
		symptom = "Aktualizacja nie może się zainstalować: brakuje miejsca.",
		metrics = { cpu = 18, disk = 98, driver = "OK" },
		tool = "CLEANUP",
		repair = "Usuń pliki tymczasowe narzędziem Oczyszczanie dysku.",
	},
	DRIVER = {
		label = "PACJENT C • OBRAZ",
		symptom = "Po aktualizacji obraz miga i zmienia rozdzielczość.",
		metrics = { cpu = 24, disk = 51, driver = "BŁĄD" },
		tool = "ROLLBACK",
		repair = "Wycofaj wadliwy sterownik ekranu i wykonaj test.",
	},
}

PCEmergencyRoomRules.Tools = {
	TASK_MANAGER = { label = "MENEDŻER ZADAŃ", short = "CPU / proces" },
	CLEANUP = { label = "OCZYSZCZANIE", short = "miejsce na dysku" },
	ROLLBACK = { label = "COFNIJ STEROWNIK", short = "sterownik urządzenia" },
}

local function countKeys(map)
	local count = 0
	for _, value in pairs(map) do
		if value then
			count += 1
		end
	end
	return count
end

function PCEmergencyRoomRules.NewState()
	return {
		scanned = {},
		repaired = {},
		verified = {},
		selectedTool = nil,
		errors = 0,
		done = false,
	}
end

function PCEmergencyRoomRules.Scan(state, patientId)
	local patient = PCEmergencyRoomRules.Patients[patientId]
	if not patient then
		return false, "Nieznany komputer."
	end
	if state.scanned[patientId] then
		return true, patient
	end
	state.scanned[patientId] = true
	return true, patient
end

function PCEmergencyRoomRules.ScanCount(state)
	return countKeys(state.scanned)
end

function PCEmergencyRoomRules.AllScanned(state)
	return PCEmergencyRoomRules.ScanCount(state) == #PCEmergencyRoomRules.PatientOrder
end

function PCEmergencyRoomRules.SelectTool(state, toolId)
	local tool = PCEmergencyRoomRules.Tools[toolId]
	if not tool then
		return false, "Nieznane narzędzie."
	end
	if not PCEmergencyRoomRules.AllScanned(state) then
		return false, "Najpierw wykonaj triage: zeskanuj wszystkie trzy komputery."
	end
	state.selectedTool = toolId
	return true, tool
end

function PCEmergencyRoomRules.ApplyRepair(state, patientId)
	local patient = PCEmergencyRoomRules.Patients[patientId]
	if not patient then
		return false, { reason = "Nieznany komputer." }
	end
	if not PCEmergencyRoomRules.AllScanned(state) then
		return false, { reason = "Najpierw zeskanuj wszystkie komputery." }
	end
	if state.repaired[patientId] then
		return true, { already = true, patient = patient }
	end
	if not state.selectedTool then
		return false, { reason = "Wybierz narzędzie z wózka serwisowego." }
	end
	if state.selectedTool ~= patient.tool then
		state.errors += 1
		local wrong = state.selectedTool
		state.selectedTool = nil
		return false,
			{
				reason = string.format(
					"DEBUG SERWISU • %s nie pasuje do objawu. Spójrz na CPU, dysk i stan sterownika.",
					PCEmergencyRoomRules.Tools[wrong].label
				),
				wrongTool = wrong,
				expectedTool = patient.tool,
			}
	end

	state.repaired[patientId] = true
	state.selectedTool = nil
	return true, { patient = patient, tool = patient.tool }
end

function PCEmergencyRoomRules.RepairCount(state)
	return countKeys(state.repaired)
end

function PCEmergencyRoomRules.AllRepaired(state)
	return PCEmergencyRoomRules.RepairCount(state) == #PCEmergencyRoomRules.PatientOrder
end

function PCEmergencyRoomRules.Verify(state, patientId)
	local patient = PCEmergencyRoomRules.Patients[patientId]
	if not patient then
		return false, "Nieznany komputer."
	end
	if not state.repaired[patientId] then
		state.errors += 1
		return false, "Najpierw wykonaj właściwą naprawę tego komputera."
	end
	if not PCEmergencyRoomRules.AllRepaired(state) then
		return false, "Najpierw napraw wszystkie trzy komputery, potem uruchom testy."
	end
	if state.verified[patientId] then
		return true, patient
	end
	state.verified[patientId] = true
	if countKeys(state.verified) == #PCEmergencyRoomRules.PatientOrder then
		state.done = true
	end
	return true, patient
end

function PCEmergencyRoomRules.VerifyCount(state)
	return countKeys(state.verified)
end

function PCEmergencyRoomRules.AllVerified(state)
	return state.done and PCEmergencyRoomRules.VerifyCount(state) == #PCEmergencyRoomRules.PatientOrder
end

function PCEmergencyRoomRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return PCEmergencyRoomRules