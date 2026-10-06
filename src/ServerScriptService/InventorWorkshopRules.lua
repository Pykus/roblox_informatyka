local Rules = {}

Rules.Slots = {
	INPUT = "MOTION_SENSOR",
	PROCESSOR = "CONTROLLER",
	OUTPUT = "MOTOR",
}

Rules.ValidLinks = {
	INPUT_PROCESSOR = true,
	PROCESSOR_OUTPUT = true,
}

function Rules.NewState()
	return {
		installed = {},
		links = {},
		stage = 1,
		mistakes = 0,
		completed = false,
	}
end

local function installedCount(state)
	local count = 0
	for slotId in pairs(Rules.Slots) do
		if state.installed[slotId] then
			count += 1
		end
	end
	return count
end

local function linksCount(state)
	local count = 0
	for linkId in pairs(Rules.ValidLinks) do
		if state.links[linkId] then
			count += 1
		end
	end
	return count
end

function Rules.Install(state, slotId, moduleId)
	local expected = Rules.Slots[slotId]
	if not expected then
		return false, { reason = "unknown_slot" }
	end
	if state.installed[slotId] then
		return false, { reason = "slot_filled" }
	end
	if moduleId ~= expected then
		state.mistakes += 1
		return false, { reason = "wrong_module", expected = expected }
	end

	state.installed[slotId] = moduleId
	if installedCount(state) == 3 then
		state.stage = math.max(state.stage, 2)
	end
	return true, {
		installed = installedCount(state),
		stage = state.stage,
	}
end

function Rules.Connect(state, linkId)
	if state.stage < 2 then
		return false, { reason = "assembly_incomplete" }
	end
	if linkId == "INPUT_OUTPUT" then
		state.mistakes += 1
		return false, { reason = "bypass_processor" }
	end
	if not Rules.ValidLinks[linkId] then
		return false, { reason = "unknown_link" }
	end
	if state.links[linkId] then
		return false, { reason = "already_connected" }
	end
	if linkId == "PROCESSOR_OUTPUT" and not state.links.INPUT_PROCESSOR then
		state.mistakes += 1
		return false, { reason = "wrong_order" }
	end

	state.links[linkId] = true
	if linksCount(state) == 2 then
		state.stage = math.max(state.stage, 3)
	end
	return true, {
		links = linksCount(state),
		stage = state.stage,
	}
end

function Rules.RunTest(state)
	if state.stage < 3 then
		return false, { reason = "wiring_incomplete" }
	end
	if state.completed then
		return false, { reason = "already_completed" }
	end
	state.completed = true
	return true, {
		completed = true,
		mistakes = state.mistakes,
	}
end

function Rules.Progress(state)
	return state.stage, installedCount(state), linksCount(state)
end

return Rules