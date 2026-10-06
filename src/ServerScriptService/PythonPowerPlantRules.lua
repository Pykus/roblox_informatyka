local Rules = {}

Rules.GridSize = 5
Rules.Sequence = { "PUMP", "FAN", "BRIDGE", "CORE" }
Rules.Pads = {
	PUMP = { X = 0, Y = 2 },
	FAN = { X = 2, Y = 2 },
	BRIDGE = { X = 2, Y = 4 },
	CORE = { X = 4, Y = 4 },
}

function Rules.NewState()
	return {
		nextIndex = 1,
		activated = {},
		completed = false,
		errors = 0,
	}
end

function Rules.InBounds(x, y)
	return x >= 0 and x < Rules.GridSize and y >= 0 and y < Rules.GridSize
end

function Rules.PadAt(x, y)
	for id, pos in pairs(Rules.Pads) do
		if pos.X == x and pos.Y == y then
			return id
		end
	end
	return nil
end

function Rules.Step(state, x, y)
	if not Rules.InBounds(x, y) then
		return false, "Robot wyszedł poza siatkę.", false
	end

	local pad = Rules.PadAt(x, y)
	if not pad then
		return true, "track", false
	end
	if state.activated[pad] then
		return true, "already", state.completed
	end

	local expected = Rules.Sequence[state.nextIndex]
	if pad ~= expected then
		state.errors += 1
		return false, string.format("Najpierw aktywuj %s, a nie %s.", expected or "kolejny etap", pad), false
	end

	state.activated[pad] = true
	state.nextIndex += 1
	if pad == "CORE" then
		state.completed = true
	end
	return true, pad, state.completed
end

function Rules.ActivatedCount(state)
	local count = 0
	for _, id in ipairs(Rules.Sequence) do
		if state.activated[id] then
			count += 1
		end
	end
	return count
end

function Rules.Complete(state)
	if not state.completed or Rules.ActivatedCount(state) ~= #Rules.Sequence then
		return false, "Elektrownia nie ma jeszcze pełnej sekwencji zasilania."
	end
	return true
end

return Rules