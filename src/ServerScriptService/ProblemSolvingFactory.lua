local ProblemSolvingFactory = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rules = require(script.Parent:WaitForChild("ProblemSolvingRules"))
local VisualThemes = require(script.Parent:WaitForChild("VisualThemes"))

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Parent = parent
	return p
end

local function label(target, text, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(960, 480)
	gui.LightInfluence = 0
	gui.Parent = target
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -24, 1, -20)
	txt.Position = UDim2.fromOffset(12, 10)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(246, 249, 252)
	txt.TextStrokeTransparency = 0.6
	txt.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = 38
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 13
	pr.HoldDuration = 0.08
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function glow(target, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.6
	light.Range = range or 18
	light.Parent = target
	return light
end

local function message(remote, player, text, good)
	remote:FireClient(player, { kind = "message", text = text, good = good })
end

local function hud(remote, player, title, objective, score)
	remote:FireClient(player, {
		kind = "hud",
		title = title,
		objective = objective,
		score = score or 0,
	})
end

local function cable(parent, name, a, b, color)
	local delta = b - a
	local p = part(parent, name, Vector3.new(0.7, 0.7, delta.Magnitude), (a + b) / 2, color, Enum.Material.Neon)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	p.CanCollide = false
	return p
end

local function missionRoot(instance)
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") and string.sub(current.Name, 1, 8) == "Mission_" then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function followSemanticVisual(source)
	task.spawn(function()
		local root = missionRoot(source)
		if not root then
			return
		end
		local semantic = nil
		for _ = 1, 100 do
			semantic = root:FindFirstChild("Semantic_" .. source.Name)
			if semantic and semantic:IsA("Model") then
				break
			end
			task.wait(0.05)
		end
		if not semantic or not semantic:IsA("Model") then
			return
		end
		local offset = source.CFrame:ToObjectSpace(semantic:GetPivot())
		while source.Parent and semantic.Parent do
			semantic:PivotTo(source.CFrame * offset)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function control(parent, name, position, color, text)
	local button = part(parent, name, Vector3.new(5.5, 2.5, 5.5), position, color, Enum.Material.SmoothPlastic)
	button.CanCollide = false
	button.CanTouch = false
	label(button, text, Enum.NormalId.Front)
	return button
end

function ProblemSolvingFactory.Run(model, origin, player, lesson, mission, remote, state, accent)
	local profile = VisualThemes.Get(mission)
	local title = mission.name or "Misja: rozwiązanie problemu"
	state.problem = Rules.NewState()
	state.problemStage = 1
	state.problemEntryReady = false

	local deck = part(
		model,
		"FactoryDeck",
		Vector3.new(74, 1, 104),
		origin + Vector3.new(0, 0.25, 10),
		Color3.fromRGB(30, 37, 44),
		Enum.Material.DiamondPlate
	)
	deck.CanCollide = true

	local brief = part(
		model,
		"RepairBrief",
		Vector3.new(52, 12, 2),
		origin + Vector3.new(0, 9, -39),
		Color3.fromRGB(77, 55, 30),
		Enum.Material.Metal
	)
	brief.CanCollide = false
	label(brief, "LINIA AWARYJNA\nNIE ZGADUJ • ZBIERZ OBJAWY • USTAL PRZYCZYNĘ • NAPRAW • SPRAWDŹ")
	glow(brief, Color3.fromRGB(255, 185, 70), 1.5, 20)

	local belt = part(
		model,
		"ConveyorBelt",
		Vector3.new(14, 1.2, 68),
		origin + Vector3.new(0, 2.1, 12),
		Color3.fromRGB(42, 49, 57),
		Enum.Material.Metal
	)
	for _, x in ipairs({ -8.4, 8.4 }) do
		part(
			model,
			"ConveyorRail",
			Vector3.new(1, 3.5, 70),
			origin + Vector3.new(x, 3.8, 12),
			Color3.fromRGB(82, 92, 104),
			Enum.Material.Metal
		)
	end

	for z = -20, 42, 8 do
		local roller = part(
			model,
			"Roller",
			Vector3.new(13, 0.45, 1),
			origin + Vector3.new(0, 2.8, z),
			profile.accent,
			Enum.Material.Neon
		)
		roller.CanCollide = false
	end

	local crate = part(
		model,
		"ConveyorCrate",
		Vector3.new(7, 5, 7),
		origin + Vector3.new(0, 5.1, -19),
		Color3.fromRGB(182, 118, 55),
		Enum.Material.Wood
	)
	label(crate, "PACZKA TESTOWA")
	followSemanticVisual(crate)
	local motor = part(
		model,
		"FactoryMotor",
		Vector3.new(10, 9, 10),
		origin + Vector3.new(-25, 5, 7),
		Color3.fromRGB(55, 92, 122),
		Enum.Material.Metal
	)
	local motorText = label(motor, "SILNIK\nSTATUS: ?")
	local motorLight = glow(motor, Color3.fromRGB(255, 184, 60), 1.2, 17)

	local controller = part(
		model,
		"FactoryController",
		Vector3.new(12, 11, 8),
		origin + Vector3.new(25, 6, 7),
		Color3.fromRGB(45, 64, 85),
		Enum.Material.Metal
	)
	local controllerText = label(controller, "STEROWNIK\nBRAK SYGNAŁU")
	local controllerLight = glow(controller, Color3.fromRGB(232, 75, 62), 1.8, 19)

	local sensorLeft =
		part(model, "SensorPostL", Vector3.new(2, 10, 2), origin + Vector3.new(-10, 7, -6), Color3.fromRGB(62, 73, 83))
	local sensorRight =
		part(model, "SensorPostR", Vector3.new(2, 10, 2), origin + Vector3.new(10, 7, -6), Color3.fromRGB(62, 73, 83))
	part(model, "SensorArch", Vector3.new(22, 2, 2), origin + Vector3.new(0, 12, -6), Color3.fromRGB(62, 73, 83))
	local sensorBeam = cable(
		model,
		"SensorBeam",
		sensorLeft.Position + Vector3.new(1.2, 0, 0),
		sensorRight.Position - Vector3.new(1.2, 0, 0),
		Color3.fromRGB(255, 184, 60)
	)
	local sensorText = label(sensorLeft, "FOTOKOMÓRKA\nSTATUS: ?", Enum.NormalId.Left)
	local cableA = cable(
		model,
		"SignalCableA",
		origin + Vector3.new(19, 6, 7),
		origin + Vector3.new(10, 6, 7),
		Color3.fromRGB(225, 68, 58)
	)
	local cableB = cable(
		model,
		"SignalCableB",
		origin + Vector3.new(7, 6, 7),
		origin + Vector3.new(3, 6, 3),
		Color3.fromRGB(225, 68, 58)
	)
	local cableBridge = nil

	local diagnostic = part(
		model,
		"DiagnosticConsole",
		Vector3.new(42, 12, 2),
		origin + Vector3.new(0, 9, -27),
		Color3.fromRGB(34, 50, 66),
		Enum.Material.Metal
	)
	local diagnosticText = label(diagnostic, "DIAGNOSTYKA OFFLINE\nNajpierw uruchom stanowisko przy wejściu.")
	glow(diagnostic, profile.accent, 1.1, 16)

	local entryConsole = control(
		model,
		"ProblemEntryConsole",
		origin + Vector3.new(0, 3, -43),
		Color3.fromRGB(72, 128, 178),
		"START\nDIAGNOZY"
	)
	local entryPrompt = nil
	local instructionBoard = part(
		model,
		"ProblemInstructionBoard",
		Vector3.new(34, 9, 2),
		origin + Vector3.new(0, 9, -38),
		Color3.fromRGB(32, 46, 58),
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. START DIAGNOZY\n2. ZRÓB 3 POMIARY\n3. WSKAŻ PRZYCZYNĘ\nPRZYKŁAD: dobry silnik + dobry sensor + przerwa przewodu → sprawdź przewód"
	)
	glow(instructionBoard, Color3.fromRGB(85, 190, 235), 1.1, 14)

	local probeVisuals = {
		SENSOR = { target = sensorLeft, text = sensorText, light = nil },
		MOTOR = { target = motor, text = motorText, light = motorLight },
		CABLE = { target = controller, text = controllerText, light = controllerLight },
	}
	local measureControls = {
		SENSOR = control(
			model,
			"ProblemMeasureControl_SENSOR",
			origin + Vector3.new(-18, 3, -17),
			Color3.fromRGB(75, 135, 190),
			"POMIAR\nSENSOR"
		),
		MOTOR = control(
			model,
			"ProblemMeasureControl_MOTOR",
			origin + Vector3.new(0, 3, -17),
			Color3.fromRGB(75, 135, 190),
			"POMIAR\nSILNIK"
		),
		CABLE = control(
			model,
			"ProblemMeasureControl_CABLE",
			origin + Vector3.new(18, 3, -17),
			Color3.fromRGB(75, 135, 190),
			"POMIAR\nPRZEWÓD"
		),
	}
	local function refreshObjective()
		if state.problemStage == 1 then
			if not state.problemEntryReady then
				state.objective = "ETAP DIAGNOZY 1/3 • Podejdź do START DIAGNOZY przy wejściu i uruchom stanowisko."
			else
				state.objective = string.format(
					"ETAP DIAGNOZY 1/3 • Pomiary %d/3. Przetestuj fotokomórkę, silnik i przewód.",
					state.problem.observedCount
				)
			end
		elseif state.problemStage == 2 then
			local nextStep = Rules.RepairOrder[state.problem.repairIndex] or "GOTOWE"
			local names = { STOP = "WYŁĄCZ NAPĘD", CONNECT = "POŁĄCZ PRZEWÓD", POWER = "WŁĄCZ ZASILANIE" }
			state.objective = "ETAP NAPRAWY 2/3 • Następny bezpieczny krok: " .. (names[nextStep] or nextStep)
		else
			state.objective = "ETAP WERYFIKACJI 3/3 • Uruchom paczkę testową i obserwuj cały cykl."
		end
		hud(remote, player, title, state.objective, state.score)
	end

	local repairPrompts = {}
	local repairControls = {}
	local diagnosisPrompts = {}
	local diagnosisControls = {}
	local measurePrompts = {}
	local loadPrompt = nil
	local loadControl = nil

	entryPrompt = prompt(entryConsole, "START DIAGNOZY", "Linia awaryjna", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or state.problemEntryReady then
			return
		end
		state.problemEntryReady = true
		entryPrompt.Enabled = false
		entryConsole.Color = Color3.fromRGB(55, 185, 110)
		entryConsole.Material = Enum.Material.Neon
		diagnostic.Color = Color3.fromRGB(44, 88, 98)
		diagnostic.Material = Enum.Material.Neon
		diagnosticText.Text = "DIAGNOSTYKA 0/3\nWykonaj pomiar sensora, silnika i przewodu."
		for _, measurePrompt in pairs(measurePrompts) do
			measurePrompt.Enabled = true
		end
		message(
			remote,
			player,
			"Stanowisko diagnostyczne uruchomione. Zbierz trzy pomiary zanim wskażesz przyczynę.",
			true
		)
		refreshObjective()
	end)

	for probeId, visual in pairs(probeVisuals) do
		local testPrompt = prompt(
			measureControls[probeId],
			"WYKONAJ POMIAR",
			Rules.Probes[probeId].label,
			function(triggeringPlayer)
				if triggeringPlayer ~= player or state.done then
					return
				end
				local alreadyObserved = state.problem.observed[probeId] == true
				local ok, result = Rules.Observe(state.problem, probeId)
				if not ok then
					return
				end
				if not alreadyObserved then
					state.score += 4
				end
				measureControls[probeId].Color = result.good and Color3.fromRGB(60, 180, 112)
					or Color3.fromRGB(220, 150, 55)
				measureControls[probeId].Material = Enum.Material.Neon
				if probeId == "SENSOR" then
					sensorBeam.Color = Color3.fromRGB(76, 224, 135)
					sensorText.Text = "FOTOKOMÓRKA\n" .. result.result
				elseif probeId == "MOTOR" then
					motor.Color = Color3.fromRGB(55, 132, 106)
					motorText.Text = "SILNIK\n" .. result.result
					motorLight.Color = Color3.fromRGB(76, 224, 135)
				else
					controllerText.Text = "PRZEWÓD SYGNAŁOWY\n" .. result.result
				end
				diagnosticText.Text = string.format(
					"DIAGNOSTYKA %d/3\nOstatni wynik: %s — %s",
					state.problem.observedCount,
					result.label,
					result.result
				)
				message(remote, player, result.label .. ": " .. result.result, result.good)
				if Rules.AllObserved(state.problem) then
					diagnosticText.Text = "POMIARY GOTOWE\nWskaż podzespół, którego wynik wyjaśnia awarię."
					for diagnosisId, pr in pairs(diagnosisPrompts) do
						pr.Enabled = true
						local diagnosisControl = diagnosisControls[diagnosisId]
						if diagnosisControl then
							diagnosisControl.Color = Color3.fromRGB(205, 145, 55)
							diagnosisControl.Material = Enum.Material.Neon
						end
					end
				end
				refreshObjective()
			end
		)
		testPrompt.Name = "DiagnosticProbe_" .. probeId
		testPrompt.Enabled = false
		measurePrompts[probeId] = testPrompt
	end

	local diagnosisChoices = {
		{ id = "SENSOR", x = -22, label = "FOTOKOMÓRKA" },
		{ id = "MOTOR", x = 0, label = "SILNIK" },
		{ id = "CABLE", x = 22, label = "PRZEWÓD" },
	}
	for _, cfg in ipairs(diagnosisChoices) do
		local pad = part(
			model,
			"DiagnosisPad_" .. cfg.id,
			Vector3.new(16, 3, 9),
			origin + Vector3.new(cfg.x, 2.2, 27),
			Color3.fromRGB(77, 64, 43),
			Enum.Material.Metal
		)
		label(pad, "PRZYCZYNA?\n" .. cfg.label, Enum.NormalId.Top)
		local diagnosisControl = control(
			model,
			"ProblemDiagnosisControl_" .. cfg.id,
			origin + Vector3.new(cfg.x, 3, 20),
			Color3.fromRGB(48, 55, 62),
			"DIAGNOZA\n" .. cfg.label
		)
		diagnosisControls[cfg.id] = diagnosisControl
		local pr = prompt(diagnosisControl, "WSKAŻ USTERKĘ", cfg.label, function(triggeringPlayer)
			if triggeringPlayer ~= player or state.done then
				return
			end
			local ok, text = Rules.Diagnose(state.problem, cfg.id)
			if not ok then
				pad.Color = Color3.fromRGB(166, 58, 55)
				diagnosisControl.Color = Color3.fromRGB(220, 70, 65)
				diagnosisControl.Material = Enum.Material.Neon
				message(remote, player, text, false)
				task.delay(0.8, function()
					if pad.Parent and state.problem.diagnosis ~= cfg.id then
						pad.Color = Color3.fromRGB(77, 64, 43)
						diagnosisControl.Color = Color3.fromRGB(48, 55, 62)
						diagnosisControl.Material = Enum.Material.SmoothPlastic
					end
				end)
				return
			end
			pad.Color = Color3.fromRGB(55, 154, 104)
			diagnosisControl.Color = Color3.fromRGB(55, 185, 110)
			diagnosisControl.Material = Enum.Material.Neon
			state.score += 20
			state.problemStage = 2
			diagnosticText.Text =
				"PRZYCZYNA POTWIERDZONA\nPrzerwany przewód sygnałowy. Zaplanuj bezpieczną naprawę."
			for _, p2 in pairs(diagnosisPrompts) do
				p2.Enabled = false
			end
			for repairId, p2 in pairs(repairPrompts) do
				p2.Enabled = true
				local repairControl = repairControls[repairId]
				if repairControl then
					repairControl.Color = Color3.fromRGB(210, 145, 50)
					repairControl.Material = Enum.Material.Neon
				end
			end
			message(remote, player, text, true)
			refreshObjective()
		end)
		pr.Enabled = false
		diagnosisPrompts[cfg.id] = pr
	end

	local repairSteps = {
		{ id = "STOP", x = -22, text = "1?\nWYŁĄCZ NAPĘD" },
		{ id = "CONNECT", x = 0, text = "2?\nPOŁĄCZ PRZEWÓD" },
		{ id = "POWER", x = 22, text = "3?\nWŁĄCZ ZASILANIE" },
	}
	for _, cfg in ipairs(repairSteps) do
		local station = part(
			model,
			"RepairStep_" .. cfg.id,
			Vector3.new(16, 5, 10),
			origin + Vector3.new(cfg.x, 3.5, 40),
			Color3.fromRGB(45, 58, 70),
			Enum.Material.Metal
		)
		label(station, cfg.text, Enum.NormalId.Top)
		local repairControl = control(
			model,
			"ProblemRepairControl_" .. cfg.id,
			origin + Vector3.new(cfg.x, 3, 33),
			Color3.fromRGB(48, 55, 62),
			"NAPRAWA\n" .. cfg.id
		)
		repairControls[cfg.id] = repairControl
		local pr = prompt(repairControl, "WYKONAJ KROK", cfg.id, function(triggeringPlayer)
			if triggeringPlayer ~= player or state.done then
				return
			end
			local ok, text = Rules.RepairStep(state.problem, cfg.id)
			if not ok then
				station.Color = Color3.fromRGB(170, 59, 53)
				repairControl.Color = Color3.fromRGB(220, 70, 65)
				repairControl.Material = Enum.Material.Neon
				state.score = math.max(0, state.score - 3)
				message(remote, player, text, false)
				task.delay(0.7, function()
					if station.Parent then
						station.Color = Color3.fromRGB(45, 58, 70)
						repairControl.Color = Color3.fromRGB(210, 145, 50)
						repairControl.Material = Enum.Material.Neon
					end
				end)
				return
			end
			station.Color = Color3.fromRGB(53, 153, 102)
			repairControl.Color = Color3.fromRGB(55, 185, 110)
			repairControl.Material = Enum.Material.Neon
			pr.Enabled = false
			state.score += 8
			if cfg.id == "STOP" then
				motorLight.Enabled = false
				motorText.Text = "SILNIK\nNAPĘD WYŁĄCZONY"
			elseif cfg.id == "CONNECT" then
				cableA.Color = Color3.fromRGB(69, 220, 132)
				cableB.Color = Color3.fromRGB(69, 220, 132)
				cableBridge = cable(
					model,
					"SignalCableRepair",
					origin + Vector3.new(10, 6, 7),
					origin + Vector3.new(7, 6, 7),
					Color3.fromRGB(69, 220, 132)
				)
				glow(cableBridge, Color3.fromRGB(69, 220, 132), 1.1, 12)
			else
				motorLight.Enabled = true
				motorLight.Color = Color3.fromRGB(69, 220, 132)
				controller.Color = Color3.fromRGB(45, 126, 88)
				controllerText.Text = "STEROWNIK\nSYGNAŁ OK"
				controllerLight.Color = Color3.fromRGB(69, 220, 132)
			end
			message(remote, player, text, true)
			if state.problem.repaired then
				state.problemStage = 3
				if loadPrompt then
					loadPrompt.Enabled = true
				end
				if loadControl then
					loadControl.Color = Color3.fromRGB(72, 145, 210)
					loadControl.Material = Enum.Material.Neon
				end
			end
			refreshObjective()
		end)
		pr.Enabled = false
		repairPrompts[cfg.id] = pr
	end

	local gateLeft = part(
		model,
		"FactoryGateL",
		Vector3.new(9, 15, 2),
		origin + Vector3.new(-5, 9, 50),
		Color3.fromRGB(155, 63, 50),
		Enum.Material.Metal
	)
	local gateRight = part(
		model,
		"FactoryGateR",
		Vector3.new(9, 15, 2),
		origin + Vector3.new(5, 9, 50),
		Color3.fromRGB(155, 63, 50),
		Enum.Material.Metal
	)
	label(gateLeft, "TEST", Enum.NormalId.Front)
	label(gateRight, "BLOKADA", Enum.NormalId.Front)

	local loadConsole = part(
		model,
		"LoadTestConsole",
		Vector3.new(18, 9, 8),
		origin + Vector3.new(25, 5.5, 52),
		Color3.fromRGB(50, 65, 80),
		Enum.Material.Metal
	)
	local loadText = label(loadConsole, "TEST LINII\nOCZEKUJE NA NAPRAWĘ")
	loadControl = control(
		model,
		"ProblemLoadTestControl",
		origin + Vector3.new(14, 3, 52),
		Color3.fromRGB(48, 55, 62),
		"TEST\nLINII"
	)
	loadPrompt = prompt(loadControl, "URUCHOM TEST", "Paczka testowa", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done then
			return
		end
		local ok, text = Rules.Verify(state.problem)
		if not ok then
			message(remote, player, text, false)
			return
		end
		loadPrompt.Enabled = false
		loadControl.Color = Color3.fromRGB(60, 185, 112)
		loadControl.Material = Enum.Material.Neon
		loadConsole.Color = Color3.fromRGB(66, 129, 88)
		loadText.Text = "TEST LINII\nCYKL W TOKU..."
		task.spawn(function()
			local checkpoints = {
				{ z = -6, duration = 1.2 },
				{ z = 18, duration = 1.8 },
				{ z = 42, duration = 1.8 },
			}
			for index, cp in ipairs(checkpoints) do
				local tween = TweenService:Create(
					crate,
					TweenInfo.new(cp.duration, Enum.EasingStyle.Linear),
					{ Position = origin + Vector3.new(0, 5.1, cp.z) }
				)
				tween:Play()
				tween.Completed:Wait()
				if index == 1 then
					sensorBeam.Color = Color3.fromRGB(80, 255, 154)
					message(remote, player, "Fotokomórka widzi paczkę. Sygnał przechodzi dalej.", true)
				elseif index == 2 then
					loadText.Text = "TEST LINII\nNAPĘD I STEROWNIK OK"
				end
			end

			TweenService:Create(gateLeft, TweenInfo.new(0.8), { Position = gateLeft.Position + Vector3.new(-8, 0, 0) })
				:Play()
			TweenService:Create(gateRight, TweenInfo.new(0.8), { Position = gateRight.Position + Vector3.new(8, 0, 0) })
				:Play()
			gateLeft.Color = Color3.fromRGB(55, 170, 105)
			gateRight.Color = Color3.fromRGB(55, 170, 105)
			crate.Color = Color3.fromRGB(68, 190, 122)
			state.score += math.max(30, 46 - state.problem.mistakes * 4)
			state.done = true
			loadText.Text = "TEST LINII ✓\nPACZKA PRZESZŁA CAŁY CYKL"
			local finale = part(
				model,
				"ProblemSolvedHologram",
				Vector3.new(44, 10, 2),
				origin + Vector3.new(0, 15, 58),
				Color3.fromRGB(55, 175, 112),
				Enum.Material.Neon
			)
			finale.CanCollide = false
			label(finale, "PROBLEM ROZWIĄZANY\nOBJAWY → DIAGNOZA → NAPRAWA → TEST")
			glow(finale, Color3.fromRGB(94, 255, 169), 2.2, 28)
			state.objective = "LINIA DZIAŁA • Naprawa została potwierdzona testem, a nie zgadywaniem."
			hud(remote, player, title, state.objective, state.score)
			message(remote, player, text .. " Problem zamknięty dopiero po teście.", true)
		end)
	end)
	loadPrompt.Enabled = false

	refreshObjective()
end

return ProblemSolvingFactory