local TweenService = game:GetService("TweenService")

local PCEmergencyRoom = {}
local Rules = require(script.Parent:WaitForChild("PCEmergencyRoomRules"))

local C = {
	floor = Color3.fromRGB(208, 222, 224),
	wall = Color3.fromRGB(238, 245, 244),
	dark = Color3.fromRGB(31, 48, 54),
	steel = Color3.fromRGB(91, 111, 119),
	teal = Color3.fromRGB(49, 190, 178),
	blue = Color3.fromRGB(63, 145, 214),
	amber = Color3.fromRGB(242, 177, 62),
	green = Color3.fromRGB(65, 213, 122),
	red = Color3.fromRGB(231, 78, 72),
	white = Color3.fromRGB(246, 250, 250),
}

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(target, text, face, minSize, maxSize)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -10, 1, -10)
	txt.Position = UDim2.fromOffset(5, 5)
	txt.BackgroundTransparency = 0.12
	txt.BackgroundColor3 = C.dark
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.5
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize or 18
	constraint.MaxTextSize = maxSize or 32
	constraint.Parent = txt
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
	if callback then
		pr.Triggered:Connect(callback)
	end
	return pr
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.8
	l.Range = range or 16
	l.Shadows = false
	l.Parent = target
	return l
end

local function tween(instance, goal, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	tw:Play()
	return tw
end

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, { kind = "message", text = text, good = good })
end

local function hud(ctx, objective)
	ctx.state.objective = objective
	ctx.remote:FireClient(ctx.player, {
		kind = "hud",
		title = ctx.mission.name or ctx.lesson.topic,
		objective = objective,
		score = ctx.state.score,
	})
end

local function metricsText(patient)
	return string.format(
		"CPU %d%% • DYSK %d%%\nSTEROWNIK: %s",
		patient.metrics.cpu,
		patient.metrics.disk,
		patient.metrics.driver
	)
end

local function setPromptGroup(group, enabled)
	for _, pr in pairs(group) do
		if pr and pr.Parent then
			pr.Enabled = enabled
		end
	end
end

local function updateToolRack(ctx)
	for toolId, toolPart in pairs(ctx.toolParts) do
		local selected = ctx.rules.selectedTool == toolId
		toolPart.Color = selected and C.teal or C.steel
		toolPart.Material = selected and Enum.Material.Neon or Enum.Material.Metal
	end
	if ctx.rules.selectedTool then
		local tool = Rules.Tools[ctx.rules.selectedTool]
		ctx.toolStatus.Text = "WYBRANE NARZĘDZIE\n" .. tool.label
		ctx.toolStatus.TextColor3 = C.teal
	else
		ctx.toolStatus.Text = "WÓZEK SERWISOWY\nwybierz narzędzie po triage"
		ctx.toolStatus.TextColor3 = C.white
	end
end

local function runServiceArm(ctx, patientId)
	local arm = ctx.serviceArms[patientId]
	local home = ctx.serviceArmHomes[patientId]
	if not arm or not home then
		return
	end
	tween(arm, { Position = home - Vector3.new(0, 3.2, 0), Color = C.amber }, 0.16).Completed:Wait()
	tween(arm, { Position = home, Color = C.teal }, 0.2)
end

local function enterRepairStage(ctx)
	setPromptGroup(ctx.scanPrompts, false)
	setPromptGroup(ctx.toolPrompts, true)
	setPromptGroup(ctx.repairPrompts, true)
	ctx.stageSign.Text = "ETAP 2/3 • NAPRAWA\nWybierz narzędzie → zastosuj przy właściwym komputerze."
	ctx.stageSign.TextColor3 = C.amber
	hud(ctx, "ETAP 2/3 • Dobierz narzędzie do danych diagnostycznych i napraw 3 komputery.")
	message(ctx, "Triage zakończony. Teraz dane mają prowadzić do naprawy, nie zgadywanie.", true)
end

local function enterVerifyStage(ctx)
	setPromptGroup(ctx.toolPrompts, false)
	setPromptGroup(ctx.repairPrompts, false)
	setPromptGroup(ctx.verifyPrompts, true)
	ctx.rules.selectedTool = nil
	updateToolRack(ctx)
	ctx.stageSign.Text = "ETAP 3/3 • TEST PO NAPRAWIE\nUruchom test na każdym stanowisku."
	ctx.stageSign.TextColor3 = C.blue
	hud(ctx, "ETAP 3/3 • Naprawa to nie koniec: wykonaj test na wszystkich 3 komputerach.")
	message(ctx, "Wszystkie naprawy wykonane. Teraz potwierdź, że objawy naprawdę zniknęły.", true)
end

local function finishClinic(ctx)
	ctx.state.done = true
	ctx.state.score += 80
	ctx.stageSign.Text =
		string.format("PC EMERGENCY ROOM • WSZYSTKIE SYSTEMY OK\nEfektywność %d%%", Rules.Efficiency(ctx.rules))
	ctx.stageSign.TextColor3 = C.green
	ctx.finalGate.Color = C.green
	ctx.finalGate.Material = Enum.Material.Neon
	ctx.finalGateLight.Color = C.green
	ctx.finalGateLight.Brightness = 3.2
	tween(ctx.finalGate, { Position = ctx.finalGateHome + Vector3.new(0, 11, 0) }, 0.7)
	for _, beacon in ipairs(ctx.ceilingBeacons) do
		beacon.Color = C.green
		beacon.Material = Enum.Material.Neon
	end
	hud(ctx, "ETAP 3/3 • Serwis zakończony. Przejdź do oznaczonego RDZENIA MISJI.")
	message(
		ctx,
		string.format(
			"Trzy komputery sprawne. Diagnostyka → naprawa → test, efektywność %d%%.",
			Rules.Efficiency(ctx.rules)
		),
		true
	)
end

local function buildPatientBay(ctx, patientId, index, base)
	local patient = Rules.Patients[patientId]
	local bay = part(
		ctx.model,
		"PCEmergencyBay_" .. patientId,
		Vector3.new(22, 1, 26),
		base + Vector3.new(0, -0.1, 0),
		Color3.fromRGB(222, 233, 232),
		Enum.Material.SmoothPlastic
	)
	bay.CanCollide = true

	local divider = part(
		ctx.model,
		"PCEmergencyDivider_" .. patientId,
		Vector3.new(1, 13, 26),
		base + Vector3.new(11, 6.5, 0),
		C.wall,
		Enum.Material.SmoothPlastic
	)
	divider.CanCollide = true

	local desk = part(
		ctx.model,
		"PCEmergencyDesk_" .. patientId,
		Vector3.new(17, 2, 9),
		base + Vector3.new(0, 2.2, -5),
		C.steel,
		Enum.Material.Metal
	)
	desk.CanCollide = true

	-- Unique semantic anchor per patient keeps all three physical PCs independently verifiable.
	local semanticPC = part(
		ctx.model,
		"PCEmergencyPC_" .. patientId,
		Vector3.new(8, 8, 8),
		base + Vector3.new(-3, 7, -5),
		C.dark,
		Enum.Material.Metal
	)
	semanticPC.CanCollide = false

	local screen = part(
		ctx.model,
		"PCEmergencyStatus_" .. patientId,
		Vector3.new(14, 8, 1),
		base + Vector3.new(0, 9, -11),
		C.dark,
		Enum.Material.Metal
	)
	local screenText = label(
		screen,
		patient.label .. "\nOBJAW: " .. patient.symptom .. "\n[zeskanuj diagnostykę]",
		Enum.NormalId.Front,
		18,
		28
	)
	ctx.screenTexts[patientId] = screenText

	local statusLed = part(
		ctx.model,
		"PCEmergencyLED_" .. patientId,
		Vector3.new(1.3, 1.3, 1.3),
		base + Vector3.new(7, 7, -10.2),
		C.red,
		Enum.Material.Neon
	)
	statusLed.Shape = Enum.PartType.Ball
	statusLed.CanCollide = false
	ctx.statusLeds[patientId] = statusLed
	ctx.statusLights[patientId] = light(statusLed, C.red, 1.8, 10)

	local scanner = part(
		ctx.model,
		"PCEmergencyScanner_" .. patientId,
		Vector3.new(7, 2.5, 5),
		base + Vector3.new(-5, 2.2, 7),
		C.blue,
		Enum.Material.Neon
	)
	label(scanner, "TRIAGE\nSCAN", Enum.NormalId.Top, 18, 25)
	local scanPrompt
	scanPrompt = prompt(scanner, "SKANUJ", patient.label, function(who)
		if who ~= ctx.player or ctx.state.done or not ctx.entryReady then
			return
		end
		local ok, info = Rules.Scan(ctx.rules, patientId)
		if not ok then
			message(ctx, info, false)
			return
		end
		scanPrompt.Enabled = false
		ctx.state.score += 10
		screenText.Text = patient.label .. "\n" .. metricsText(patient) .. "\n" .. patient.symptom
		screenText.TextColor3 = C.amber
		statusLed.Color = C.amber
		ctx.statusLights[patientId].Color = C.amber
		message(ctx, patient.label .. ": " .. metricsText(patient), true)
		hud(
			ctx,
			string.format(
				"ETAP 1/3 • Triage %d/3. Zeskanuj każdy komputer przed naprawą.",
				Rules.ScanCount(ctx.rules)
			)
		)
		if Rules.AllScanned(ctx.rules) then
			enterRepairStage(ctx)
		end
	end)
	ctx.scanPrompts[patientId] = scanPrompt

	local applyConsole = part(
		ctx.model,
		"PCEmergencyRepairConsole_" .. patientId,
		Vector3.new(7, 2.5, 5),
		base + Vector3.new(5, 2.2, 7),
		C.steel,
		Enum.Material.Metal
	)
	label(applyConsole, "SERWIS\nZASTOSUJ", Enum.NormalId.Top, 18, 25)
	local repairPrompt
	repairPrompt = prompt(applyConsole, "ZASTOSUJ", patient.label, function(who)
		if who ~= ctx.player or ctx.state.done then
			return
		end
		local ok, result = Rules.ApplyRepair(ctx.rules, patientId)
		updateToolRack(ctx)
		if not ok then
			ctx.state.score = math.max(0, ctx.state.score - 5)
			screenText.TextColor3 = C.red
			screenText.Text = patient.label .. "\n" .. metricsText(patient) .. "\n" .. result.reason
			statusLed.Color = C.red
			ctx.statusLights[patientId].Color = C.red
			message(ctx, result.reason, false)
			return
		end
		if result.already then
			return
		end
		runServiceArm(ctx, patientId)
		ctx.state.score += 30
		repairPrompt.Enabled = false
		screenText.TextColor3 = C.amber
		screenText.Text = patient.label .. "\nNAPRAWA WYKONANA\n" .. patient.repair .. "\nCzeka na test."
		statusLed.Color = C.amber
		ctx.statusLights[patientId].Color = C.amber
		message(ctx, patient.label .. ": naprawa wykonana. Jeszcze jej nie uznajemy — potrzebny test.", true)
		hud(
			ctx,
			string.format(
				"ETAP 2/3 • Naprawiono %d/3 komputerów. Dobierz następne narzędzie.",
				Rules.RepairCount(ctx.rules)
			)
		)
		if Rules.AllRepaired(ctx.rules) then
			enterVerifyStage(ctx)
		end
	end)
	repairPrompt.Enabled = false
	ctx.repairPrompts[patientId] = repairPrompt

	local verifyPad = part(
		ctx.model,
		"PCEmergencyVerify_" .. patientId,
		Vector3.new(6, 1.2, 5),
		base + Vector3.new(0, 1, 12),
		C.blue,
		Enum.Material.SmoothPlastic
	)
	label(verifyPad, "TEST", Enum.NormalId.Top, 19, 26)
	local verifyPrompt
	verifyPrompt = prompt(verifyPad, "URUCHOM TEST", patient.label, function(who)
		if who ~= ctx.player or ctx.state.done then
			return
		end
		local ok, result = Rules.Verify(ctx.rules, patientId)
		if not ok then
			message(ctx, result, false)
			return
		end
		if ctx.rules.verified[patientId] then
			verifyPrompt.Enabled = false
			screenText.TextColor3 = C.green
			screenText.Text = patient.label .. "\nTEST: OK\nCPU / DYSK / STEROWNIK W NORMIE"
			statusLed.Color = C.green
			ctx.statusLights[patientId].Color = C.green
			ctx.statusLights[patientId].Brightness = 2.5
			ctx.state.score += 20
			tween(verifyPad, { Color = C.green }, 0.25)
			message(ctx, patient.label .. ": test OK.", true)
			hud(
				ctx,
				string.format(
					"ETAP 3/3 • Testy %d/3. Potwierdź działanie każdego komputera.",
					Rules.VerifyCount(ctx.rules)
				)
			)
			if Rules.AllVerified(ctx.rules) then
				finishClinic(ctx)
			end
		end
	end)
	verifyPrompt.Enabled = false
	ctx.verifyPrompts[patientId] = verifyPrompt

	local armHome = base + Vector3.new(0, 12.5, -3)
	local arm = part(
		ctx.model,
		"PCEmergencyServiceArm_" .. patientId,
		Vector3.new(1.5, 7, 1.5),
		armHome,
		C.teal,
		Enum.Material.Metal
	)
	arm.CanCollide = false
	ctx.serviceArms[patientId] = arm
	ctx.serviceArmHomes[patientId] = armHome

	local beacon = part(
		ctx.model,
		"PCEmergencyCeilingBeacon_" .. patientId,
		Vector3.new(5, 0.7, 5),
		base + Vector3.new(0, 16, -2),
		index % 2 == 0 and C.blue or C.teal,
		Enum.Material.Neon
	)
	beacon.CanCollide = false
	table.insert(ctx.ceilingBeacons, beacon)
end

function PCEmergencyRoom.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		screenTexts = {},
		statusLeds = {},
		statusLights = {},
		scanPrompts = {},
		repairPrompts = {},
		verifyPrompts = {},
		toolPrompts = {},
		toolParts = {},
		serviceArms = {},
		serviceArmHomes = {},
		ceilingBeacons = {},
		entryReady = false,
	}

	local floor = part(
		model,
		"PCEmergencyFloor",
		Vector3.new(92, 1, 80),
		origin + Vector3.new(0, -0.5, -2),
		C.floor,
		Enum.Material.SmoothPlastic
	)
	floor.CanCollide = true
	part(
		model,
		"PCEmergencyBackWall",
		Vector3.new(92, 19, 2),
		origin + Vector3.new(0, 9.5, -39),
		C.wall,
		Enum.Material.SmoothPlastic
	)
	local header = part(
		model,
		"PCEmergencyHeader",
		Vector3.new(48, 8, 1),
		origin + Vector3.new(0, 14, -37.8),
		C.dark,
		Enum.Material.Metal
	)
	ctx.stageSign = label(header, "PC EMERGENCY ROOM\nETAP START • PRZYJĘCIE SPRZĘTU", Enum.NormalId.Front, 20, 32)

	local instructionBoard = part(
		model,
		"PCEmergencyInstructionBoard",
		Vector3.new(24, 8, 1.2),
		origin + Vector3.new(32, 5.5, -37.2),
		C.dark,
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	instructionBoard.CanTouch = false
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. ZAREJESTRUJ sprzęt\n2. SKANUJ 3 komputery\n3. Wybierz narzędzie i ZASTOSUJ\n4. Po naprawach uruchom TEST\n\nGOTOWE ODPOWIEDZI\nCPU 96% → MENEDŻER ZADAŃ\nDYSK 98% → OCZYSZCZANIE\nSTEROWNIK BŁĄD → COFNIJ STEROWNIK",
		Enum.NormalId.Front,
		18,
		25
	)

	for index, patientId in ipairs(Rules.PatientOrder) do
		local x = ({ -27, 0, 27 })[index]
		buildPatientBay(ctx, patientId, index, origin + Vector3.new(x, 0, -8))
	end
	setPromptGroup(ctx.scanPrompts, false)

	local checkIn = part(
		model,
		"PCEmergencyCheckIn",
		Vector3.new(10, 5, 7),
		origin + Vector3.new(0, 3.5, -42),
		C.blue,
		Enum.Material.Metal
	)
	checkIn.CanCollide = false
	checkIn.CanTouch = false
	local checkInText = label(checkIn, "PRZYJĘCIE SPRZĘTU\nZAREJESTRUJ 3 PACJENTÓW", Enum.NormalId.Front, 18, 26)
	local checkInPrompt
	checkInPrompt = prompt(checkIn, "ZAREJESTRUJ", "PC Emergency Room", function(who)
		if who ~= player or state.done or ctx.entryReady then
			return
		end
		ctx.entryReady = true
		checkInPrompt.Enabled = false
		checkIn.Color = C.green
		checkIn.Material = Enum.Material.Neon
		checkInText.Text = "PRZYJĘCIE OK ✓\nTRIAGE ODBLOKOWANY"
		ctx.stageSign.Text = "PC EMERGENCY ROOM\nETAP 1/3 • TRIAGE: zeskanuj 3 komputery"
		ctx.stageSign.TextColor3 = C.blue
		setPromptGroup(ctx.scanPrompts, true)
		hud(ctx, "ETAP 1/3 • Triage: zeskanuj wszystkie 3 komputery i porównaj CPU, dysk oraz sterownik.")
		message(ctx, "Sprzęt zarejestrowany. Stanowiska TRIAGE są aktywne.", true)
	end)
	ctx.checkIn = checkIn
	ctx.checkInPrompt = checkInPrompt

	local rack = part(
		model,
		"PCEmergencyToolCart",
		Vector3.new(54, 3, 12),
		origin + Vector3.new(0, 2, 18),
		C.dark,
		Enum.Material.Metal
	)
	rack.CanCollide = true
	ctx.toolStatus = label(rack, "WÓZEK SERWISOWY\nwybierz narzędzie po triage", Enum.NormalId.Front, 17, 28)

	for index, toolId in ipairs(Rules.ToolOrder) do
		local tool = Rules.Tools[toolId]
		local x = ({ -18, 0, 18 })[index]
		local toolPart = part(
			model,
			"PCEmergencyTool_" .. toolId,
			Vector3.new(13, 4, 8),
			origin + Vector3.new(x, 5.5, 18),
			C.steel,
			Enum.Material.Metal
		)
		label(toolPart, tool.label .. "\n" .. tool.short, Enum.NormalId.Top, 18, 25)
		ctx.toolParts[toolId] = toolPart
		local pr
		pr = prompt(toolPart, "WYBIERZ", tool.label, function(who)
			if who ~= player or state.done then
				return
			end
			local ok, result = Rules.SelectTool(ctx.rules, toolId)
			if not ok then
				message(ctx, result, false)
				return
			end
			updateToolRack(ctx)
			message(ctx, "Wybrano: " .. result.label .. ". Podejdź do komputera, którego dane pasują.", true)
		end)
		pr.Enabled = false
		ctx.toolPrompts[toolId] = pr
	end

	ctx.finalGateHome = origin + Vector3.new(0, 6, 36)
	ctx.finalGate =
		part(model, "PCEmergencyExitGate", Vector3.new(26, 12, 2), ctx.finalGateHome, C.red, Enum.Material.Metal)
	ctx.finalGateLight = light(ctx.finalGate, C.red, 1.5, 18)
	label(ctx.finalGate, "SERWIS ZAMKNIĘTY\n3 PACJENTÓW DO WERYFIKACJI", Enum.NormalId.Front, 18, 28)

	updateToolRack(ctx)
	setPromptGroup(ctx.scanPrompts, false)
	setPromptGroup(ctx.toolPrompts, false)
	setPromptGroup(ctx.repairPrompts, false)
	setPromptGroup(ctx.verifyPrompts, false)
	hud(ctx, "ETAP START • Zarejestruj sprzęt w CHECK-IN przy wejściu, aby otworzyć TRIAGE.")
end

return PCEmergencyRoom