local Rules = {}

Rules.GridSize = 5
Rules.Sensor = { X = 0, Y = 2 }
Rules.Chip = { X = 2, Y = 2 }
Rules.Server = { X = 4, Y = 4 }

Rules.Blocked = {
	["1:0"] = true,
	["1:1"] = true,
	["3:2"] = true,
	["3:3"] = true,
}

function Rules.NewState()
	return {
		sensorActive = false,
		visited = {},
		hits = 0,
		completed = false,
	}
end

function Rules.Key(x, y)
	return string.format("%d:%d", x, y)
end

function Rules.InBounds(x, y)
	return x >= 0 and x < Rules.GridSize and y >= 0 and y < Rules.GridSize
end

function Rules.CanEnter(x, y)
	if not Rules.InBounds(x, y) then
		return false, "granica planszy"
	end
	if Rules.Blocked[Rules.Key(x, y)] then
		return false, "bariera laserowa"
	end
	return true
end

function Rules.MarkStep(state, x, y)
	local key = Rules.Key(x, y)
	state.visited[key] = true
	if x == Rules.Sensor.X and y == Rules.Sensor.Y then
		state.sensorActive = true
		return true, "sensor"
	end
	return true, "track"
end

function Rules.CanPickup(state, x, y)
	if x ~= Rules.Chip.X or y ~= Rules.Chip.Y then
		return false, "pickup() działa tylko na polu CHIP (2,2)."
	end
	if not state.sensorActive then
		return false, "Najpierw aktywuj SENSOR na (0,2), aby odblokować CHIP."
	end
	return true
end

function Rules.CanDrop(state, x, y)
	if x ~= Rules.Server.X or y ~= Rules.Server.Y then
		return false, "drop() musi zostać wykonane na SERWERZE (4,4)."
	end
	return true
end

function Rules.Complete(state)
	if not state.sensorActive then
		return false, "Sensor nie został aktywowany."
	end
	state.completed = true
	return true
end

return Rules