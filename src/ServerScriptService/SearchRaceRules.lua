local Rules = {}

Rules.Values = { 4, 9, 15, 22, 31, 37, 44, 52, 63, 71, 84, 96 }
Rules.Target = 71

local function midpoint(low, high)
	return math.floor((low + high) / 2)
end

function Rules.NewState()
	return {
		stage = 1,
		linearIndex = 1,
		linearChecks = 0,
		linearDone = false,
		binaryLow = 1,
		binaryHigh = #Rules.Values,
		binaryIndex = midpoint(1, #Rules.Values),
		binaryChecks = 0,
		binaryDone = false,
		errors = 0,
		completed = false,
	}
end

function Rules.LinearNext(state)
	if state.stage ~= 1 or state.linearDone then
		return false, "Tor liniowy nie jest teraz aktywny."
	end
	local index = state.linearIndex
	local value = Rules.Values[index]
	if not value then
		return false, "Koniec danych bez wyniku."
	end

	state.linearChecks += 1
	local found = value == Rules.Target
	if found then
		state.linearDone = true
		state.stage = 2
		state.binaryLow = 1
		state.binaryHigh = #Rules.Values
		state.binaryIndex = midpoint(state.binaryLow, state.binaryHigh)
	else
		state.linearIndex += 1
	end

	return true, {
		index = index,
		value = value,
		found = found,
		checks = state.linearChecks,
	}
end

function Rules.BinaryCurrent(state)
	if state.binaryDone then
		return nil
	end
	local index = state.binaryIndex
	return {
		index = index,
		value = Rules.Values[index],
		low = state.binaryLow,
		high = state.binaryHigh,
		checks = state.binaryChecks,
	}
end

function Rules.BinaryDecision(state, decision)
	if state.stage ~= 2 or state.binaryDone then
		return false, "Tor binarny nie jest teraz aktywny."
	end
	if decision ~= "HIGHER" and decision ~= "LOWER" and decision ~= "FOUND" then
		return false, "Nieznana decyzja."
	end

	local index = state.binaryIndex
	local value = Rules.Values[index]
	local expected
	if value == Rules.Target then
		expected = "FOUND"
	elseif value < Rules.Target then
		expected = "HIGHER"
	else
		expected = "LOWER"
	end

	state.binaryChecks += 1
	if decision ~= expected then
		state.errors += 1
		return false,
			string.format(
				"%d jest %s celu %d. Zmień kierunek.",
				value,
				value < Rules.Target and "mniejsze od" or "większe od",
				Rules.Target
			)
	end

	if decision == "FOUND" then
		state.binaryDone = true
		state.stage = 3
		return true,
			{
				found = true,
				index = index,
				value = value,
				checks = state.binaryChecks,
				low = state.binaryLow,
				high = state.binaryHigh,
			}
	end

	if decision == "HIGHER" then
		state.binaryLow = index + 1
	else
		state.binaryHigh = index - 1
	end

	if state.binaryLow > state.binaryHigh then
		return false, "Zakres binarny został opróżniony."
	end
	state.binaryIndex = midpoint(state.binaryLow, state.binaryHigh)

	return true,
		{
			found = false,
			index = index,
			value = value,
			checks = state.binaryChecks,
			low = state.binaryLow,
			high = state.binaryHigh,
			nextIndex = state.binaryIndex,
			nextValue = Rules.Values[state.binaryIndex],
		}
end

function Rules.BinaryPath()
	local low = 1
	local high = #Rules.Values
	local path = {}
	while low <= high do
		local index = midpoint(low, high)
		table.insert(path, index)
		local value = Rules.Values[index]
		if value == Rules.Target then
			break
		elseif value < Rules.Target then
			low = index + 1
		else
			high = index - 1
		end
	end
	return path
end

function Rules.CanRace(state)
	return state.stage == 3 and state.linearDone and state.binaryDone
end

function Rules.Complete(state)
	if not Rules.CanRace(state) then
		return false, "Najpierw ukończ oba algorytmy."
	end
	state.completed = true
	return true,
		{
			linearChecks = state.linearChecks,
			binaryChecks = state.binaryChecks,
			saved = state.linearChecks - state.binaryChecks,
		}
end

return Rules