local Rules = {}

Rules.ValidOrientations = {
	LANDSCAPE = true,
	PORTRAIT = true,
}

Rules.ValidContrast = {
	LOW = true,
	NORMAL = true,
	HIGH = true,
}

function Rules.NewState()
	return {
		orientation = "PORTRAIT",
		frame = -1,
		brightness = -1,
		contrast = "HIGH",
		mistakes = 0,
		completed = false,
	}
end

function Rules.SetOrientation(state, orientation)
	if not Rules.ValidOrientations[orientation] then
		return false, { reason = "invalid_orientation" }
	end
	state.orientation = orientation
	return true, { orientation = orientation }
end

function Rules.SetFrame(state, frame)
	if frame ~= -1 and frame ~= 0 and frame ~= 1 then
		return false, { reason = "invalid_frame" }
	end
	state.frame = frame
	return true, { frame = frame }
end

function Rules.SetBrightness(state, value)
	if type(value) ~= "number" or value < -2 or value > 2 or value % 1 ~= 0 then
		return false, { reason = "invalid_brightness" }
	end
	state.brightness = value
	return true, { brightness = value }
end

function Rules.SetContrast(state, contrast)
	if not Rules.ValidContrast[contrast] then
		return false, { reason = "invalid_contrast" }
	end
	state.contrast = contrast
	return true, { contrast = contrast }
end

function Rules.Readiness(state)
	local checks = {
		orientation = state.orientation == "LANDSCAPE",
		frame = state.frame == 0,
		brightness = state.brightness == 1,
		contrast = state.contrast == "NORMAL",
	}
	local ready = checks.orientation and checks.frame and checks.brightness and checks.contrast
	return ready, checks
end

function Rules.Capture(state)
	if state.completed then
		return false, { reason = "already_completed" }
	end

	local ready, checks = Rules.Readiness(state)
	if not ready then
		state.mistakes += 1
		return false, {
			reason = "not_ready",
			checks = checks,
			mistakes = state.mistakes,
		}
	end

	state.completed = true
	return true, {
		completed = true,
		mistakes = state.mistakes,
	}
end

return Rules