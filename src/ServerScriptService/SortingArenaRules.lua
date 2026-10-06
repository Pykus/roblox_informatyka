local Rules = {}

Rules.PracticeValues = { 42, 17, 63, 8, 31 }
Rules.SpeedValues = { 11, 23, 19, 35, 47 }

local function copyValues(source)
	local out = {}
	for i, value in ipairs(source) do
		out[i] = value
	end
	return out
end

local function resetRound(state, values, stage)
	state.stage = stage
	state.values = copyValues(values)
	state.pass = 1
	state.index = 1
	state.passSwaps = 0
	state.comparisons = 0
	state.swaps = 0
	state.roundDone = false
	state.earlyStop = false
	state.history = {}
end

function Rules.NewState()
	local state = {
		stage = 1,
		errors = 0,
		completed = false,
		practiceComparisons = nil,
		practiceSwaps = nil,
		speedComparisons = nil,
		speedSwaps = nil,
	}
	resetRound(state, Rules.PracticeValues, 1)
	return state
end

function Rules.CurrentPair(state)
	if state.roundDone or (state.stage ~= 1 and state.stage ~= 2) then
		return nil
	end
	local activeEnd = #state.values - (state.pass - 1)
	if state.index >= activeEnd + 1 then
		return nil
	end
	return {
		index = state.index,
		left = state.values[state.index],
		right = state.values[state.index + 1],
		pass = state.pass,
		activeEnd = activeEnd,
	}
end

function Rules.ExpectedDecision(state)
	local pair = Rules.CurrentPair(state)
	if not pair then
		return nil
	end
	if pair.left > pair.right then
		return "SWAP"
	end
	return "KEEP"
end

local function pushHistory(state, left, right, decision)
	table.insert(state.history, {
		left = left,
		right = right,
		decision = decision,
		pass = state.pass,
	})
	while #state.history > 6 do
		table.remove(state.history, 1)
	end
end

local function finishRound(state, earlyStop)
	state.roundDone = true
	state.earlyStop = earlyStop
	if state.stage == 1 then
		state.practiceComparisons = state.comparisons
		state.practiceSwaps = state.swaps
	elseif state.stage == 2 then
		state.speedComparisons = state.comparisons
		state.speedSwaps = state.swaps
		state.stage = 3
	end
end

local function advancePair(state)
	local activeEnd = #state.values - (state.pass - 1)
	state.index += 1
	if state.index < activeEnd then
		return
	end

	if state.passSwaps == 0 then
		finishRound(state, true)
		return
	end

	if state.pass >= #state.values - 1 then
		finishRound(state, false)
		return
	end

	state.pass += 1
	state.index = 1
	state.passSwaps = 0
end

function Rules.Decide(state, decision)
	if decision ~= "KEEP" and decision ~= "SWAP" then
		return false, "Nieznana decyzja sortera."
	end
	local pair = Rules.CurrentPair(state)
	if not pair then
		return false, "Brak aktywnej pary do porównania."
	end

	local expected = Rules.ExpectedDecision(state)
	if decision ~= expected then
		state.errors += 1
		if expected == "SWAP" then
			return false, string.format("%d > %d, więc para wymaga ZAMIANY.", pair.left, pair.right)
		end
		return false, string.format("%d ≤ %d, więc kolejność jest już poprawna.", pair.left, pair.right)
	end

	state.comparisons += 1
	if decision == "SWAP" then
		state.values[pair.index], state.values[pair.index + 1] = state.values[pair.index + 1], state.values[pair.index]
		state.swaps += 1
		state.passSwaps += 1
	end
	pushHistory(state, pair.left, pair.right, decision)
	advancePair(state)
	return true,
		{
			decision = decision,
			left = pair.left,
			right = pair.right,
			index = pair.index,
			comparisons = state.comparisons,
			swaps = state.swaps,
			roundDone = state.roundDone,
			earlyStop = state.earlyStop,
		}
end

function Rules.StartSpeedRound(state)
	if state.stage ~= 1 or not state.roundDone then
		return false, "Najpierw ukończ rundę treningową."
	end
	resetRound(state, Rules.SpeedValues, 2)
	return true
end

function Rules.IsSorted(values)
	for i = 1, #values - 1 do
		if values[i] > values[i + 1] then
			return false
		end
	end
	return true
end

function Rules.CanFinish(state)
	return state.stage == 3 and state.speedComparisons ~= nil and Rules.IsSorted(state.values)
end

function Rules.Efficiency(state)
	local saved = math.max(0, 10 - (state.speedComparisons or 10))
	local score = math.max(40, 100 - state.errors * 10)
	return {
		score = score,
		saved = saved,
		errors = state.errors,
		practiceComparisons = state.practiceComparisons or 0,
		speedComparisons = state.speedComparisons or 0,
	}
end

function Rules.Complete(state)
	if not Rules.CanFinish(state) then
		return false, "Najpierw ukończ obie rundy sortowania."
	end
	state.completed = true
	return true, Rules.Efficiency(state)
end

return Rules