local TimelineMuseumRules = {}

TimelineMuseumRules.Eras = { "1946", "1981", "2007" }
TimelineMuseumRules.Artifacts = {
	ENIAC = { era = "1946", label = "ENIAC", detail = "Wielki komputer lampowy" },
	PC = { era = "1981", label = "IBM PC", detail = "Komputer osobisty" },
	PHONE = { era = "2007", label = "Smartfon", detail = "Komputer w kieszeni" },
}

function TimelineMuseumRules.NewState()
	return {
		carrying = nil,
		placed = {},
		placedCount = 0,
		rideIndex = 0,
		scanned = {},
		scanCount = 0,
	}
end

function TimelineMuseumRules.GetArtifact(id)
	return TimelineMuseumRules.Artifacts[id]
end

function TimelineMuseumRules.CanLoad(state, id)
	if not state or not TimelineMuseumRules.Artifacts[id] then
		return false, "Nieznany eksponat."
	end
	if state.carrying then
		return false, "Wózek jest już zajęty."
	end
	if state.placed[id] then
		return false, "Ten eksponat jest już na wystawie."
	end
	return true, "Eksponat załadowany."
end

function TimelineMuseumRules.Load(state, id)
	local ok, why = TimelineMuseumRules.CanLoad(state, id)
	if not ok then
		return false, why
	end
	state.carrying = id
	return true, why
end

function TimelineMuseumRules.CanPlace(state, era)
	if not state or not state.carrying then
		return false, "Najpierw załaduj eksponat na wózek."
	end
	local artifact = TimelineMuseumRules.Artifacts[state.carrying]
	if not artifact or artifact.era ~= era then
		return false, "Ten eksponat nie pasuje do tej epoki."
	end
	return true, "Chronologia poprawna."
end
function TimelineMuseumRules.Place(state, era)
	local ok, why = TimelineMuseumRules.CanPlace(state, era)
	if not ok then
		return false, why, nil
	end
	local id = state.carrying
	state.carrying = nil
	state.placed[id] = era
	state.placedCount += 1
	return true, why, id
end

function TimelineMuseumRules.AllPlaced(state)
	return state and state.placedCount == 3
end

function TimelineMuseumRules.NextRideEra(state)
	if not TimelineMuseumRules.AllPlaced(state) then
		return nil, "Najpierw ustaw wszystkie eksponaty."
	end
	if state.rideIndex >= #TimelineMuseumRules.Eras then
		return nil, "Trasa muzeum została przejechana."
	end
	return TimelineMuseumRules.Eras[state.rideIndex + 1], nil
end

function TimelineMuseumRules.Arrive(state, era)
	local expected = TimelineMuseumRules.Eras[state.rideIndex + 1]
	if era ~= expected then
		return false, "Jedź po osi czasu po kolei."
	end
	state.rideIndex += 1
	return true, "Przystanek " .. era
end
function TimelineMuseumRules.CanScan(state, era)
	if not state or state.rideIndex == 0 then
		return false, "Najpierw dojedź do epoki."
	end
	local current = TimelineMuseumRules.Eras[state.rideIndex]
	if era ~= current then
		return false, "Skanuj eksponat przy aktualnym przystanku."
	end
	if state.scanned[era] then
		return false, "Ta epoka jest już zeskanowana."
	end
	return true, "Skan potwierdzony."
end

function TimelineMuseumRules.Scan(state, era)
	local ok, why = TimelineMuseumRules.CanScan(state, era)
	if not ok then
		return false, why
	end
	state.scanned[era] = true
	state.scanCount += 1
	return true, why
end

function TimelineMuseumRules.RouteComplete(state)
	return state and state.scanCount == #TimelineMuseumRules.Eras
end

function TimelineMuseumRules.ArtifactForEra(era)
	for id, artifact in pairs(TimelineMuseumRules.Artifacts) do
		if artifact.era == era then
			return id, artifact
		end
	end
	return nil, nil
end

return TimelineMuseumRules