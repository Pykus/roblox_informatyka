local Rules = {}

Rules.Stages = {
	{
		id = "TRAINING",
		values = { 4, 1, 3, 2 },
		optimal = 4,
	},
	{
		id = "FREIGHT",
		values = { 5, 1, 4, 2, 3 },
		optimal = 6,
	},
}

local function copyValues(source)
	local out = {}
	for index, value in ipairs(source) do
		out[index] = value
	end
	return out
end

function Rules.Inversions(values)
	local count = 0
	for left = 1, #values - 1 do
		for right = left + 1, #values do
			if values[left] > values[right] then
				count += 1
			end
		end
	end
	return count
end

function Rules.IsSorted(values)
	for index = 1, #values - 1 do
		if values[index] > values[index + 1] then
			return false
		end
	end
	return true
end

local function loadStage(state, stageIndex)
	local stage = Rules.Stages[stageIndex]
	state.stage = stageIndex
	state.values = copyValues(stage.values)
	state.moves = 0
	state.awaitingNext = false
end

function Rules.NewState()
	local state = {
		stage = 1,
		totalMoves = 0,
		badMoves = 0,
		completed = false,
		summaries = {},
	}
	loadStage(state, 1)
	return state
end

function Rules.Current(state)
	return Rules.Stages[state.stage]
end

function Rules.Target(state)
	local target = copyValues(state.values)
	table.sort(target)
	return target
end

function Rules.Swap(state, index)
	if state.completed then
		return false, "Skład jest już uporządkowany."
	end
	if state.awaitingNext then
		return false, "Najpierw uruchom następną serię dźwignią."
	end
	if index < 1 or index >= #state.values then
		return false, "Można zamieniać tylko sąsiednie wagony."
	end

	local before = Rules.Inversions(state.values)
	local left = state.values[index]
	local right = state.values[index + 1]

	state.values[index], state.values[index + 1] = right, left
	state.moves += 1
	state.totalMoves += 1

	local after = Rules.Inversions(state.values)
	local improved = after < before
	if not improved then
		state.badMoves += 1
	end

	local sorted = Rules.IsSorted(state.values)
	local stage = Rules.Current(state)
	local result = {
		index = index,
		left = left,
		right = right,
		before = before,
		after = after,
		improved = improved,
		sorted = sorted,
		moves = state.moves,
		optimal = stage.optimal,
		values = copyValues(state.values),
	}

	if sorted then
		local excess = math.max(0, state.moves - stage.optimal)
		table.insert(state.summaries, {
			stage = state.stage,
			moves = state.moves,
			optimal = stage.optimal,
			excess = excess,
		})
		result.excess = excess
		if state.stage == #Rules.Stages then
			state.completed = true
			result.completed = true
		else
			state.awaitingNext = true
		end
	end

	return true, result
end

function Rules.StartNext(state)
	if state.completed then
		return false, "Obie serie są już gotowe."
	end
	if not state.awaitingNext then
		return false, "Najpierw uporządkuj bieżący skład."
	end
	loadStage(state, state.stage + 1)
	return true,
		{
			stage = state.stage,
			values = copyValues(state.values),
			optimal = Rules.Current(state).optimal,
		}
end

function Rules.TotalOptimal()
	local total = 0
	for _, stage in ipairs(Rules.Stages) do
		total += stage.optimal
	end
	return total
end

function Rules.Efficiency(state)
	local excess = math.max(0, state.totalMoves - Rules.TotalOptimal())
	return {
		score = math.max(40, 100 - excess * 6),
		excess = excess,
		badMoves = state.badMoves,
		moves = state.totalMoves,
		optimal = Rules.TotalOptimal(),
	}
end

return Rules