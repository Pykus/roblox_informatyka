local MathEngine = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("MathEngineRules"))

local C = {
	dark = Color3.fromRGB(35, 40, 48),
	steel = Color3.fromRGB(104, 115, 124),
	white = Color3.fromRGB(235, 239, 241),
	teal = Color3.fromRGB(57, 176, 173),
	blue = Color3.fromRGB(66, 129, 207),
	orange = Color3.fromRGB(229, 137, 52),
	yellow = Color3.fromRGB(239, 196, 67),
	green = Color3.fromRGB(70, 204, 116),
	red = Color3.fromRGB(225, 72, 75),
}

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function label(target, text, face, maxText, bgColor, textColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 430)
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 0.04
	txt.BackgroundColor3 = bgColor or C.dark
	txt.TextColor3 = textColor or C.white
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = maxText or 29
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText or ""
	pr.MaxActivationDistance = 14
	pr.HoldDuration = 0.08
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.4
	l.Range = range or 18
	l.Parent = target
	return l
end

local function tween(target, goal, seconds)
	local t = TweenService:Create(
		target,
		TweenInfo.new(seconds or 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	t:Play()
	return t
end

local function message(remote, player, text, good)
	remote:FireClient(player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function hud(remote, player, title, objective, score)
	remote:FireClient(player, {
		kind = "hud",
		title = title,
		objective = objective,
		score = score or 0,
	})
end
function MathEngine.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Funkcje matematyczne"
	state.mathEngine = Rules.NewState()
	state.mathBusy = false
	state.mathEntryReady = false

	local floor = part(
		model,
		"MathEngineFloor",
		Vector3.new(94, 1, 110),
		origin + Vector3.new(0, 0.2, 8),
		Color3.fromRGB(174, 181, 185),
		Enum.Material.Concrete
	)
	floor.CanCollide = true

	local header = part(
		model,
		"MathEngineHeader",
		Vector3.new(72, 9, 2),
		origin + Vector3.new(0, 22, -43),
		C.white,
		Enum.Material.Metal
	)
	label(header, "MATH ENGINE\nFUNKCJA → WYNIK → RUCH MASZYNY", Enum.NormalId.Front, 30, C.white, C.dark)

	local calibrationConsole = part(
		model,
		"MathCalibrationConsole",
		Vector3.new(14, 6, 8),
		origin + Vector3.new(0, 4, -44),
		C.blue,
		Enum.Material.Metal
	)
	calibrationConsole.CanCollide = false
	calibrationConsole.CanTouch = false
	label(calibrationConsole, "START KALIBRACJI\nWŁĄCZ ZASILANIE", Enum.NormalId.Front, 22, C.blue, C.white)
	local calibrationLight = light(calibrationConsole, C.yellow, 0.7, 12)

	local statusBoard = part(
		model,
		"MathEngineStatus",
		Vector3.new(44, 12, 2),
		origin + Vector3.new(0, 11, -31),
		C.dark,
		Enum.Material.Metal
	)
	local statusText =
		label(statusBoard, "STANOWISKO 1/3\nRAMIĘ LASERA\nWEJŚCIE 81 → CEL 9", Enum.NormalId.Front, 26)

	local resultBoard = part(
		model,
		"MathEngineResult",
		Vector3.new(28, 10, 2),
		origin + Vector3.new(30, 10, -30),
		C.dark,
		Enum.Material.Metal
	)
	local resultText = label(resultBoard, "LIVE OUTPUT\n—", Enum.NormalId.Front, 25)

	local explanationBoard = part(
		model,
		"MathEngineExplanation",
		Vector3.new(28, 14, 2),
		origin + Vector3.new(-30, 12, -28),
		C.dark,
		Enum.Material.Metal
	)
	local explanationText = label(
		explanationBoard,
		"CEL\nDobierz funkcję tak, aby wynik sterował maszyną zgodnie z wymaganiem.",
		Enum.NormalId.Front,
		22
	)

	local buttonPositions = {
		SQRT = origin + Vector3.new(-22, 4, -17),
		FLOOR = origin + Vector3.new(0, 4, -17),
		CEIL = origin + Vector3.new(22, 4, -17),
	}
	local buttonColors = {
		SQRT = C.blue,
		FLOOR = C.teal,
		CEIL = C.orange,
	}
	local functionPrompts = {}
	for _, functionId in ipairs(Rules.Functions) do
		local button = part(
			model,
			"MathFunction_" .. functionId,
			Vector3.new(18, 6, 9),
			buttonPositions[functionId],
			buttonColors[functionId],
			Enum.Material.SmoothPlastic
		)
		label(button, Rules.FunctionLabel(functionId), Enum.NormalId.Front, 24, buttonColors[functionId], C.white)

		local control = part(
			model,
			"MathFunctionControl_" .. functionId,
			Vector3.new(4, 3, 4),
			buttonPositions[functionId] + Vector3.new(0, -0.2, 7),
			buttonColors[functionId],
			Enum.Material.Metal
		)
		control.CanCollide = false
		control.CanTouch = false
		functionPrompts[functionId] = control
	end
	local stationBases = {}
	local stationLights = {}
	local conduits = {}
	local stationLabels = {}

	local stationX = {
		LASER = -30,
		ELEVATOR = 0,
		PACKER = 30,
	}

	for _, station in ipairs(Rules.Stations) do
		local x = stationX[station.id]
		local base = part(
			model,
			"MathStation_" .. station.id,
			Vector3.new(24, 1, 24),
			origin + Vector3.new(x, 1, 11),
			Color3.fromRGB(126, 137, 143),
			Enum.Material.Metal
		)
		base.CanCollide = true
		stationBases[station.id] = base

		local sign = part(
			model,
			"MathStationSign_" .. station.id,
			Vector3.new(22, 9, 2),
			origin + Vector3.new(x, 10, 23),
			C.dark,
			Enum.Material.Metal
		)
		stationLabels[station.id] = label(
			sign,
			station.title .. "\nWEJŚCIE: " .. tostring(station.input) .. "\nCEL: " .. tostring(station.target),
			Enum.NormalId.Back,
			22
		)
		stationLights[station.id] = light(sign, C.yellow, 0.35, 12)

		local conduit = part(
			model,
			"MathConduit_" .. station.id,
			Vector3.new(5, 0.7, 28),
			origin + Vector3.new(x, 1.1, 31),
			C.steel,
			Enum.Material.Metal
		)
		conduit.CanCollide = false
		conduits[station.id] = conduit
	end

	local laserRail = part(
		model,
		"MathLaserRail",
		Vector3.new(20, 2, 4),
		origin + Vector3.new(-30, 5, 11),
		C.steel,
		Enum.Material.Metal
	)
	laserRail.CanCollide = false
	local laserHead =
		part(model, "MathLaserHead", Vector3.new(4, 7, 6), origin + Vector3.new(-39, 8, 11), C.blue, Enum.Material.Neon)
	laserHead.CanCollide = false
	local laserBeam =
		part(model, "MathLaserBeam", Vector3.new(1, 1, 13), origin + Vector3.new(-39, 5, 17), C.red, Enum.Material.Neon)
	laserBeam.CanCollide = false
	laserBeam.Transparency = 0.3

	local elevatorTower = part(
		model,
		"MathElevatorTower",
		Vector3.new(14, 20, 4),
		origin + Vector3.new(0, 11, 14),
		C.steel,
		Enum.Material.Metal
	)
	elevatorTower.CanCollide = false
	local elevatorPlatform = part(
		model,
		"MathElevatorPlatform",
		Vector3.new(13, 2, 10),
		origin + Vector3.new(0, 3, 8),
		C.teal,
		Enum.Material.Metal
	)
	elevatorPlatform.CanCollide = true
	local elevatorMarker = part(
		model,
		"MathElevatorMarker",
		Vector3.new(12, 2, 2),
		origin + Vector3.new(0, 16, 11),
		C.green,
		Enum.Material.Neon
	)
	elevatorMarker.CanCollide = false
	label(elevatorMarker, "CEL 7", Enum.NormalId.Back, 20, C.green, C.white)

	local packerFrame = part(
		model,
		"MathPackerFrame",
		Vector3.new(22, 2, 6),
		origin + Vector3.new(30, 14, 11),
		C.orange,
		Enum.Material.Metal
	)
	packerFrame.CanCollide = false
	local packerBoxes = {}
	for i = 1, 10 do
		local row = math.floor((i - 1) / 5)
		local col = (i - 1) % 5
		local box = part(
			model,
			"MathPackerBox_" .. i,
			Vector3.new(3.5, 3.5, 3.5),
			origin + Vector3.new(23 + col * 3.5, 4 + row * 4, 11),
			C.steel,
			Enum.Material.Metal
		)
		box.Transparency = 0.7
		box.CanCollide = false
		packerBoxes[i] = box
	end

	local packerTarget = part(
		model,
		"MathPackerTarget",
		Vector3.new(20, 4, 2),
		origin + Vector3.new(30, 10, 20),
		C.green,
		Enum.Material.SmoothPlastic
	)
	label(packerTarget, "CEL: 8 PEŁNYCH SEKCJI", Enum.NormalId.Back, 20, C.green, C.white)
	local reactor = part(
		model,
		"MathEngineReactor",
		Vector3.new(20, 20, 20),
		origin + Vector3.new(0, 10, 50),
		Color3.fromRGB(74, 80, 87),
		Enum.Material.Metal
	)
	reactor.Shape = Enum.PartType.Ball
	reactor.CanCollide = false
	local reactorLight = light(reactor, C.red, 0.5, 20)

	local reactorRing = part(
		model,
		"MathEngineReactorRing",
		Vector3.new(28, 2, 28),
		origin + Vector3.new(0, 10, 50),
		C.steel,
		Enum.Material.Metal
	)
	reactorRing.Shape = Enum.PartType.Cylinder
	reactorRing.CFrame = CFrame.new(reactorRing.Position) * CFrame.Angles(0, 0, math.rad(90))
	reactorRing.CanCollide = false

	local launchConsole = part(
		model,
		"MathEngineLaunchConsole",
		Vector3.new(24, 7, 9),
		origin + Vector3.new(-25, 4.5, 49),
		C.yellow,
		Enum.Material.Metal
	)
	label(launchConsole, "URUCHOM MATH ENGINE", Enum.NormalId.Front, 24, C.yellow, C.dark)

	local operatorDesk = part(
		model,
		"MathOperatorDesk",
		Vector3.new(16, 4, 8),
		origin + Vector3.new(-39, 2, 35),
		C.steel,
		Enum.Material.Metal
	)
	operatorDesk.CanCollide = false
	operatorDesk.CanTouch = false
	local operatorKeyboard = part(
		model,
		"MathOperatorKeyboard",
		Vector3.new(6, 0.8, 2.4),
		origin + Vector3.new(-41, 4.4, 34),
		C.dark,
		Enum.Material.Metal
	)
	operatorKeyboard.CanCollide = false
	operatorKeyboard.CanTouch = false
	local operatorMouse = part(
		model,
		"MathOperatorMouse",
		Vector3.new(2, 0.9, 1.6),
		origin + Vector3.new(-34, 4.45, 34),
		C.dark,
		Enum.Material.Metal
	)
	operatorMouse.CanCollide = false
	operatorMouse.CanTouch = false

	local coreRack = part(
		model,
		"MathEngineCoreRack",
		Vector3.new(7, 11, 5),
		origin + Vector3.new(17, 5.5, 48),
		C.dark,
		Enum.Material.Metal
	)
	coreRack.CanCollide = false
	coreRack.CanTouch = false

	local gate = part(
		model,
		"MathEngineGate",
		Vector3.new(34, 18, 2),
		origin + Vector3.new(25, 9, 61),
		C.steel,
		Enum.Material.Metal
	)
	label(gate, "WYJŚCIE ZABLOKOWANE\n3 FUNKCJE WYMAGANE", Enum.NormalId.Back, 24)
	local gateOpen = gate.Position + Vector3.new(0, 20, 0)

	local launchPrompt
	local stationIndexById = {
		LASER = 1,
		ELEVATOR = 2,
		PACKER = 3,
	}

	local function updateHud()
		hud(remote, player, title, state.objective, state.score)
	end

	local function setFunctionPrompts(enabled)
		for _, button in pairs(functionPrompts) do
			local pr = button:FindFirstChildOfClass("ProximityPrompt")
			if pr then
				pr.Enabled = enabled
			end
		end
	end

	local function previewLaser(output, good)
		local clamped = math.clamp(output, 0, 12)
		local target = origin + Vector3.new(-40 + clamped * 1.1, 8, 11)
		tween(laserHead, { Position = target }, 0.45)
		tween(laserBeam, { Position = target + Vector3.new(0, -3, 6) }, 0.45)
		laserHead.Color = good and C.green or C.red
		laserBeam.Color = good and C.green or C.red
	end

	local function previewElevator(output, good)
		local clamped = math.clamp(output, 0, 9)
		local targetY = origin.Y + 2.5 + clamped * 1.9
		tween(elevatorPlatform, { Position = Vector3.new(origin.X, targetY, origin.Z + 8) }, 0.55)
		elevatorPlatform.Color = good and C.green or C.red
	end

	local function previewPacker(output, good)
		local count = math.clamp(math.floor(output + 0.0001), 0, #packerBoxes)
		for i, box in ipairs(packerBoxes) do
			if i <= count then
				box.Transparency = 0
				box.Color = good and C.green or C.red
				box.Material = Enum.Material.SmoothPlastic
			else
				box.Transparency = 0.7
				box.Color = C.steel
				box.Material = Enum.Material.Metal
			end
		end
	end

	local function previewStation(stationId, output, good)
		if stationId == "LASER" then
			previewLaser(output, good)
		elseif stationId == "ELEVATOR" then
			previewElevator(output, good)
		elseif stationId == "PACKER" then
			previewPacker(output, good)
		end
	end

	local function currentStatus()
		if not state.mathEntryReady then
			statusText.Text = "KALIBRACJA OFFLINE\nWŁĄCZ KONSOLĘ PRZY WEJŚCIU"
			explanationText.Text = "ETAP START\nUruchom zasilanie stanowisk, a potem dobieraj sqrt / floor / ceil."
			return
		end
		local station = Rules.CurrentStation(state.mathEngine)
		if not station then
			statusText.Text = "KALIBRACJA 3/3\nGOTOWA DO STARTU"
			explanationText.Text = "WSZYSTKIE FUNKCJE ZGODNE\nUruchom wspólny silnik."
			return
		end
		statusText.Text = string.format(
			"STANOWISKO %d/3\n%s\nWEJŚCIE %s → CEL %s",
			state.mathEngine.index,
			station.title,
			tostring(station.input),
			tostring(station.target)
		)
		explanationText.Text = "ZADANIE\n" .. station.prompt
	end
	local function applyFunction(functionId)
		if not state.mathEntryReady or state.done or state.mathBusy then
			return
		end
		local station = Rules.CurrentStation(state.mathEngine)
		if not station then
			return
		end

		state.mathBusy = true
		local ok, result = Rules.Apply(state.mathEngine, functionId)
		if result.output ~= nil then
			resultText.Text = string.format(
				"%s\n%s(%s) = %s\nCEL = %s",
				ok and "LIVE OUTPUT ✓" or "LIVE OUTPUT ✗",
				string.lower(functionId),
				tostring(result.input),
				tostring(result.output),
				tostring(result.target)
			)
			previewStation(result.station, result.output, ok)
		end

		if not ok then
			state.score = math.max(0, state.score - 5)
			statusBoard.Color = C.red
			explanationBoard.Color = C.red
			explanationText.Text = "DEBUG FUNKCJI\n" .. tostring(result.message)
			message(remote, player, tostring(result.message), false)
			updateHud()
			task.delay(1.2, function()
				if not state.done then
					statusBoard.Color = C.dark
					explanationBoard.Color = C.dark
					currentStatus()
				end
			end)
			state.mathBusy = false
			return
		end

		state.score += 45
		local solvedId = result.station
		stationBases[solvedId].Color = C.green
		stationLights[solvedId].Color = C.green
		stationLights[solvedId].Brightness = 2
		conduits[solvedId].Color = C.green
		conduits[solvedId].Material = Enum.Material.Neon
		stationLabels[solvedId].Text = string.format(
			"%s\n%s(%s) = %s\nGOTOWE",
			Rules.Stations[stationIndexById[solvedId]].title,
			string.lower(functionId),
			tostring(result.input),
			tostring(result.output)
		)
		explanationBoard.Color = C.green
		explanationText.Text = "DLACZEGO DZIAŁA?\n" .. result.reason
		message(remote, player, result.reason, true)

		if result.allSolved then
			setFunctionPrompts(false)
			currentStatus()
			statusBoard.Color = C.green
			resultBoard.Color = C.green
			coreRack.Color = C.teal
			coreRack.Material = Enum.Material.Neon
			state.objective = "Trzy stanowiska skalibrowane • uruchom wspólny Math Engine."
			launchPrompt.Enabled = true
		else
			currentStatus()
			state.objective = "Następne stanowisko • wybierz funkcję, której wynik spełni cel maszyny."
		end
		updateHud()
		state.mathBusy = false
	end

	for _, functionId in ipairs(Rules.Functions) do
		local button = functionPrompts[functionId]
		prompt(button, "UŻYJ FUNKCJI", Rules.FunctionLabel(functionId), function(who)
			if who == player then
				applyFunction(functionId)
			end
		end)
	end
	setFunctionPrompts(false)

	local calibrationPrompt
	calibrationPrompt = prompt(calibrationConsole, "WŁĄCZ KALIBRACJĘ", "Math Engine", function(who)
		if who ~= player or state.mathEntryReady or state.done then
			return
		end
		state.mathEntryReady = true
		calibrationPrompt.Enabled = false
		calibrationConsole.Color = C.green
		calibrationConsole.Material = Enum.Material.Neon
		calibrationLight.Color = C.green
		calibrationLight.Brightness = 2.2
		setFunctionPrompts(true)
		currentStatus()
		state.objective = "STANOWISKO 1/3 • Pole = 81. Wybierz funkcję, która ustawi ramię lasera na długość 9."
		message(remote, player, "Kalibracja online. Teraz przetestuj sqrt / floor / ceil na pierwszej maszynie.", true)
		updateHud()
	end)

	launchPrompt = prompt(launchConsole, "START", "Math Engine", function(who)
		if who ~= player or state.done or state.mathBusy then
			return
		end

		local ok, result = Rules.Complete(state.mathEngine)
		if not ok then
			message(remote, player, result, false)
			return
		end

		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += result.efficiency
		launchPrompt.Enabled = false
		reactor.Color = C.green
		reactor.Material = Enum.Material.Neon
		reactorLight.Color = C.green
		reactorLight.Brightness = 3
		reactorLight.Range = 32
		reactorRing.Color = C.teal
		reactorRing.Material = Enum.Material.Neon
		coreRack.Color = C.green
		coreRack.Material = Enum.Material.Neon
		statusBoard.Color = C.green
		statusText.Text = string.format("MATH ENGINE ONLINE\nEFEKTYWNOŚĆ %d%%", result.efficiency)
		explanationBoard.Color = C.green
		explanationText.Text = "FUNKCJA ZWRACA WARTOŚĆ\nTa wartość może bezpośrednio sterować światem programu."
		tween(gate, { Position = gateOpen }, 1.1)

		task.spawn(function()
			for _ = 1, 3 do
				tween(reactorRing, {
					CFrame = reactorRing.CFrame * CFrame.Angles(math.rad(120), 0, 0),
				}, 0.55).Completed:Wait()
			end
		end)

		state.objective = string.format(
			"Math Engine ukończony: sqrt/floor/ceil sterują trzema maszynami; błędy %d.",
			result.errors
		)
		remote:FireClient(player, {
			kind = "objective",
			text = state.objective,
			score = state.score,
		})
		message(
			remote,
			player,
			"Silnik działa. Funkcja nie jest tylko tekstem w kodzie — jej wynik może sterować ruchem, pozycją i zasobami.",
			true
		)
		updateHud()
	end)
	launchPrompt.Enabled = false

	currentStatus()
	state.objective = "ETAP START • Podejdź do konsoli przy wejściu i włącz kalibrację Math Engine."
	updateHud()
	message(
		remote,
		player,
		"ZACZNIJ TUTAJ: włącz konsolę kalibracji przy wejściu. Dopiero potem aktywują się sqrt / floor / ceil.",
		true
	)
end

return MathEngine