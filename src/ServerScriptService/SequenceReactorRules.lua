local SequenceReactorRules = {}

SequenceReactorRules.Tutorial = {
	seed = { 4, 7, 10 },
	step = 3,
	nextValues = { 13, 16, 19 },
}

SequenceReactorRules.Repair = {
	startValues = { 5, 9, 13, 18, 21 },
	expected = { 5, 9, 13, 17, 21 },
	faultIndex = 4,
}

SequenceReactorRules.Generator = {
	start = 2,
	step = 5,
	count = 5,
}

local function copyArray(source)
	local out = {}
	for index, value in ipairs(source) do
		out[index] = value
	end
	return out
end

function SequenceReactorRules.NewState()
	return {
		stage = 1,
		errors = 0,
		tutorialStep = 1,
		tutorialRule = 1,
		tutorialValues = copyArray(SequenceReactorRules.Tutorial.seed),
		scannedIndex = nil,
		repairValues = copyArray(SequenceReactorRules.Repair.startValues),
		generator = {
			start = 1,
			step = 2,
			count = 4,
		},
		completed = false,
	}
end

function SequenceReactorRules.AdjustTutorialRule(state, delta)
	if state.stage ~= 1 then
		return false, "Etap ręcznego generatora jest już zakończony."
	end
	state.tutorialRule = math.clamp(state.tutorialRule + delta, 1, 6)
	return true, state.tutorialRule
end

function SequenceReactorRules.TutorialNext(state)
	if state.stage ~= 1 then
		return false, { message = "Etap ręcznego generatora jest już zakończony." }
	end

	local expectedRule = SequenceReactorRules.Tutorial.step
	if state.tutorialRule ~= expectedRule then
		state.errors += 1
		return false,
			{
				message = string.format(
					"DEBUG REGUŁY • Ustawiono +%d, ale różnice 4→7 i 7→10 wskazują +%d.",
					state.tutorialRule,
					expectedRule
				),
			}
	end

	local expected = SequenceReactorRules.Tutorial.nextValues[state.tutorialStep]
	if not expected then
		return false, { message = "Wszystkie ręczne wyrazy są już gotowe." }
	end

	table.insert(state.tutorialValues, expected)
	state.tutorialStep += 1
	local finished = state.tutorialStep > #SequenceReactorRules.Tutorial.nextValues
	if finished then
		state.stage = 2
	end

	return true,
		{
			value = expected,
			index = #state.tutorialValues,
			finished = finished,
			message = finished and "Ręczny generator gotowy: 4, 7, 10, 13, 16, 19."
				or string.format("Poprawny następny wyraz: %d.", expected),
		}
end

function SequenceReactorRules.ScanRepairCell(state, index)
	if state.stage ~= 2 then
		return false, { message = "Skaner awarii nie jest teraz aktywny." }
	end
	if index < 1 or index > #state.repairValues then
		return false, { message = "Nieprawidłowy indeks komórki." }
	end

	state.scannedIndex = index
	local expected = SequenceReactorRules.Repair.expected[index]
	local actual = state.repairValues[index]
	local faulty = actual ~= expected

	return true,
		{
			index = index,
			actual = actual,
			expected = expected,
			faulty = faulty,
			message = faulty
					and string.format("ANOMALIA • komórka %d ma %d, a reguła +4 daje %d.", index, actual, expected)
				or string.format("Komórka %d jest zgodna z regułą +4.", index),
		}
end

function SequenceReactorRules.AdjustRepair(state, delta)
	if state.stage ~= 2 then
		return false, "Naprawa nie jest teraz aktywna."
	end
	if not state.scannedIndex then
		return false, "Najpierw zeskanuj komórkę."
	end

	local index = state.scannedIndex
	state.repairValues[index] = math.clamp(state.repairValues[index] + delta, 0, 99)
	return true, state.repairValues[index]
end

function SequenceReactorRules.VerifyRepair(state)
	if state.stage ~= 2 then
		return false, { message = "Etap naprawy nie jest teraz aktywny." }
	end

	for index, expected in ipairs(SequenceReactorRules.Repair.expected) do
		if state.repairValues[index] ~= expected then
			state.errors += 1
			return false,
				{
					index = index,
					actual = state.repairValues[index],
					expected = expected,
					message = string.format(
						"DEBUG CIĄGU • element %d ma %d, powinien mieć %d.",
						index,
						state.repairValues[index],
						expected
					),
				}
		end
	end

	state.stage = 3
	return true, {
		message = "Ciąg naprawiony: 5, 9, 13, 17, 21. Generator parametrów odblokowany.",
	}
end

local GENERATOR_LIMITS = {
	start = { 0, 9 },
	step = { 1, 9 },
	count = { 3, 7 },
}

function SequenceReactorRules.AdjustGenerator(state, key, delta)
	if state.stage ~= 3 or state.completed then
		return false, "Generator nie jest teraz aktywny."
	end
	local limits = GENERATOR_LIMITS[key]
	if not limits then
		return false, "Nieznany parametr generatora."
	end
	state.generator[key] = math.clamp(state.generator[key] + delta, limits[1], limits[2])
	return true, state.generator[key]
end

function SequenceReactorRules.Generate(state)
	if state.stage ~= 3 or state.completed then
		return false, { message = "Generator nie jest teraz aktywny." }
	end

	local target = SequenceReactorRules.Generator
	local cfg = state.generator
	if cfg.start ~= target.start or cfg.step ~= target.step or cfg.count ~= target.count then
		state.errors += 1
		local problems = {}
		if cfg.start ~= target.start then
			table.insert(problems, string.format("START=%d zamiast %d", cfg.start, target.start))
		end
		if cfg.step ~= target.step then
			table.insert(problems, string.format("KROK=%d zamiast %d", cfg.step, target.step))
		end
		if cfg.count ~= target.count then
			table.insert(problems, string.format("N=%d zamiast %d", cfg.count, target.count))
		end
		return false, {
			message = "DEBUG GENERATORA • " .. table.concat(problems, ", ") .. ".",
		}
	end

	local values = {}
	for index = 0, cfg.count - 1 do
		table.insert(values, cfg.start + index * cfg.step)
	end
	state.completed = true
	return true, {
		values = values,
		message = "Generator poprawny: " .. table.concat(values, ", ") .. ".",
	}
end

function SequenceReactorRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return SequenceReactorRules