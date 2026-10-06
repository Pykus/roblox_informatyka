local LanguagePort = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rules = require(script.Parent:WaitForChild("LanguagePortRules"))

local C = {
	sky = Color3.fromRGB(96, 177, 221),
	water = Color3.fromRGB(55, 149, 194),
	concrete = Color3.fromRGB(194, 187, 169),
	wood = Color3.fromRGB(151, 111, 72),
	steel = Color3.fromRGB(104, 113, 119),
	dark = Color3.fromRGB(42, 47, 51),
	white = Color3.fromRGB(246, 244, 234),
	yellow = Color3.fromRGB(241, 186, 55),
	orange = Color3.fromRGB(229, 126, 48),
	red = Color3.fromRGB(215, 70, 65),
	green = Color3.fromRGB(73, 174, 103),
	python = Color3.fromRGB(66, 122, 161),
	javascript = Color3.fromRGB(235, 202, 58),
	c = Color3.fromRGB(89, 104, 155),
	csharp = Color3.fromRGB(116, 79, 151),
}

local DOCKS = {
	PYTHON = { x = -30, color = C.python, label = "PYTHON\nDANE • AUTOMATYZACJA" },
	JAVASCRIPT = { x = -10, color = C.javascript, label = "JAVASCRIPT\nPRZEGLĄDARKA • UI" },
	C = { x = 10, color = C.c, label = "C\nSPRZĘT • EMBEDDED" },
	CSHARP = { x = 30, color = C.csharp, label = "C#\nUNITY • APLIKACJE" },
}

local PROJECT_COLORS = {
	DATA = Color3.fromRGB(67, 151, 199),
	WEB = Color3.fromRGB(237, 160, 60),
	DEVICE = Color3.fromRGB(89, 167, 118),
	GAME = Color3.fromRGB(155, 96, 177),
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
	gui.Brightness = 1.08
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

local function followSemanticVisual(source)
	task.spawn(function()
		local root = source.Parent
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

		local pivot = semantic:GetPivot()
		local yOffset = pivot.Position.Y - source.Position.Y
		local rotationOffset = source.CFrame.Rotation:ToObjectSpace(pivot.Rotation)
		local offset = CFrame.new(0, yOffset, 0) * rotationOffset
		while source.Parent and semantic.Parent do
			semantic:PivotTo(source.CFrame * offset)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.3
	l.Range = range or 17
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
function LanguagePort.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Języki programowania"
	state.languagePort = Rules.NewState()
	state.languageBusy = false

	local floor = part(
		model,
		"LanguagePortQuay",
		Vector3.new(92, 1, 82),
		origin + Vector3.new(0, 0.25, 0),
		C.concrete,
		Enum.Material.Concrete
	)
	floor.CanCollide = true

	local water = part(
		model,
		"LanguagePortWater",
		Vector3.new(92, 1, 38),
		origin + Vector3.new(0, -0.2, 59),
		C.water,
		Enum.Material.Glass
	)
	water.Transparency = 0.18
	water.CanCollide = false

	for i = -4, 4 do
		local stripe = part(
			model,
			"LanguagePortQuayStripe_" .. (i + 5),
			Vector3.new(7, 0.15, 2),
			origin + Vector3.new(i * 10, 0.85, 34),
			i % 2 == 0 and C.yellow or C.dark,
			Enum.Material.SmoothPlastic
		)
		stripe.CanCollide = false
	end

	local header = part(
		model,
		"LanguagePortHeader",
		Vector3.new(72, 10, 2),
		origin + Vector3.new(0, 23, -39),
		C.white,
		Enum.Material.Concrete
	)
	label(
		header,
		"LANGUAGE PORT\nDOBIERAJ TECHNOLOGIĘ DO WYMAGAŃ • NIE MA JEDNEGO „NAJLEPSZEGO” JĘZYKA",
		Enum.NormalId.Front,
		27,
		C.white,
		C.dark
	)

	local statusBoard = part(
		model,
		"LanguagePortStatus",
		Vector3.new(34, 11, 2),
		origin + Vector3.new(-27, 11, -28),
		C.white,
		Enum.Material.WoodPlanks
	)
	local statusText =
		label(statusBoard, "KONTENER 1/4\nNAJPIERW SKAN MANIFESTU", Enum.NormalId.Front, 26, C.white, C.dark)

	local rationaleBoard = part(
		model,
		"LanguagePortRationale",
		Vector3.new(34, 15, 2),
		origin + Vector3.new(27, 13, -26),
		C.white,
		Enum.Material.WoodPlanks
	)
	local rationaleText = label(
		rationaleBoard,
		"DYSPozytornia\nKażdy język ma inne mocne zastosowania.",
		Enum.NormalId.Front,
		23,
		C.white,
		C.dark
	)

	local entryApron = part(
		model,
		"LanguagePortEntryApron",
		Vector3.new(30, 1, 18),
		origin + Vector3.new(0, 0.7, -43),
		C.concrete,
		Enum.Material.Concrete
	)
	entryApron.CanCollide = true

	local scannerBase = part(
		model,
		"LanguagePortScannerBase",
		Vector3.new(24, 1.2, 16),
		origin + Vector3.new(0, 1.4, -43),
		C.steel,
		Enum.Material.Metal
	)
	scannerBase.CanCollide = true

	local scannerLeft = part(
		model,
		"LanguagePortScannerLeft",
		Vector3.new(2, 15, 2),
		origin + Vector3.new(-11, 8, -43),
		C.yellow,
		Enum.Material.Metal
	)
	local scannerRight = part(
		model,
		"LanguagePortScannerRight",
		Vector3.new(2, 15, 2),
		origin + Vector3.new(11, 8, -43),
		C.yellow,
		Enum.Material.Metal
	)
	local scannerTop = part(
		model,
		"LanguagePortScannerTop",
		Vector3.new(24, 2, 2),
		origin + Vector3.new(0, 15, -43),
		C.yellow,
		Enum.Material.Metal
	)
	local scannerBeam = part(
		model,
		"LanguagePortScannerBeam",
		Vector3.new(20, 10, 0.5),
		origin + Vector3.new(0, 7.5, -43),
		C.sky,
		Enum.Material.ForceField
	)
	scannerBeam.Transparency = 0.72
	scannerBeam.CanCollide = false
	local scannerLight = light(scannerTop, C.yellow, 0.8, 16)

	local manifestBoard = part(
		model,
		"LanguagePortManifest",
		Vector3.new(35, 12, 2),
		origin + Vector3.new(0, 11, -27),
		C.white,
		Enum.Material.SmoothPlastic
	)
	local manifestText =
		label(manifestBoard, "SKANER MANIFESTU\nZESKANUJ BIEŻĄCY KONTENER", Enum.NormalId.Front, 23, C.white, C.dark)
	local yardPositions = {
		origin + Vector3.new(-30, 4, -28),
		origin + Vector3.new(-10, 4, -28),
		origin + Vector3.new(10, 4, -28),
		origin + Vector3.new(30, 4, -28),
	}
	local scannerPosition = origin + Vector3.new(0, 5, -43)
	local cargoParts = {}
	local cargoLabels = {}

	for i, project in ipairs(Rules.Projects) do
		local cargo = part(
			model,
			"LanguageCargo_" .. project.id,
			Vector3.new(16, 8, 10),
			yardPositions[i],
			PROJECT_COLORS[project.id],
			Enum.Material.Metal
		)
		cargo.CanCollide = false
		cargoParts[project.id] = cargo
		cargoLabels[project.id] = label(
			cargo,
			string.format("ŁADUNEK %02d\n%s\nMANIFEST ZAMKNIĘTY", i, project.title),
			Enum.NormalId.Front,
			22,
			PROJECT_COLORS[project.id],
			C.white
		)
		followSemanticVisual(cargo)
	end

	local dockPrompts = {}
	local dockPads = {}
	local dockControls = {}
	local dockLights = {}
	local routedPositions = {}

	for _, language in ipairs(Rules.Languages) do
		local info = DOCKS[language]
		local x = info.x
		local pad = part(
			model,
			"LanguageDock_" .. language,
			Vector3.new(17, 1, 18),
			origin + Vector3.new(x, 1, 18),
			Color3.fromRGB(173, 168, 153),
			Enum.Material.Concrete
		)
		pad.CanCollide = true
		dockPads[language] = pad
		routedPositions[language] = origin + Vector3.new(x, 5, 18)

		local dockControl = part(
			model,
			"LanguageDockControl_" .. language,
			Vector3.new(4.5, 4, 4.5),
			origin + Vector3.new(x, 3, 8),
			info.color,
			Enum.Material.Metal
		)
		dockControl.CanCollide = false
		dockControl.CanTouch = false
		dockControls[language] = dockControl

		local sign = part(
			model,
			"LanguageDockSign_" .. language,
			Vector3.new(16, 9, 2),
			origin + Vector3.new(x, 9, 29),
			info.color,
			Enum.Material.SmoothPlastic
		)
		label(sign, info.label, Enum.NormalId.Back, 22, info.color, C.white)
		dockLights[language] = light(sign, info.color, 0.45, 12)

		local craneBase = part(
			model,
			"LanguageCraneBase_" .. language,
			Vector3.new(2, 18, 2),
			origin + Vector3.new(x - 7, 10, 19),
			C.yellow,
			Enum.Material.Metal
		)
		local craneArm = part(
			model,
			"LanguageCraneArm_" .. language,
			Vector3.new(15, 2, 2),
			origin + Vector3.new(x, 18, 19),
			C.yellow,
			Enum.Material.Metal
		)
		craneBase.CanCollide = false
		craneArm.CanCollide = false
	end

	local inspectionBay = part(
		model,
		"LanguageInspectionBay",
		Vector3.new(20, 1, 14),
		origin + Vector3.new(0, 1, 36),
		Color3.fromRGB(160, 150, 135),
		Enum.Material.Concrete
	)
	inspectionBay.CanCollide = true

	local inspectionSign = part(
		model,
		"LanguageInspectionSign",
		Vector3.new(20, 8, 2),
		origin + Vector3.new(0, 8, 43),
		C.red,
		Enum.Material.SmoothPlastic
	)
	local inspectionText =
		label(inspectionSign, "KONTROLA ZGODNOŚCI\nBRAK ALARMÓW", Enum.NormalId.Back, 23, C.red, C.white)
	local inspectionLight = light(inspectionSign, C.red, 0.3, 13)

	local launchConsole = part(
		model,
		"LanguagePortLaunchConsole",
		Vector3.new(25, 7, 9),
		origin + Vector3.new(0, 4.5, 50),
		C.orange,
		Enum.Material.WoodPlanks
	)
	label(launchConsole, "ODPRAWA STATKU\n4 DOKI WYMAGANE", Enum.NormalId.Front, 24, C.orange, C.white)

	local shipHull = part(
		model,
		"LanguagePortShip",
		Vector3.new(68, 7, 18),
		origin + Vector3.new(0, 3, 62),
		Color3.fromRGB(229, 224, 206),
		Enum.Material.SmoothPlastic
	)
	shipHull.CanCollide = false

	local shipDeck = part(
		model,
		"LanguagePortShipDeck",
		Vector3.new(52, 2, 15),
		origin + Vector3.new(0, 7, 62),
		C.wood,
		Enum.Material.WoodPlanks
	)
	shipDeck.CanCollide = false

	local shipBridge = part(
		model,
		"LanguagePortShipBridge",
		Vector3.new(15, 12, 12),
		origin + Vector3.new(-22, 13, 62),
		C.white,
		Enum.Material.SmoothPlastic
	)
	shipBridge.CanCollide = false
	label(shipBridge, "CODE CARGO", Enum.NormalId.Front, 21, C.white, C.dark)

	local beacon = part(
		model,
		"LanguagePortBeacon",
		Vector3.new(7, 22, 7),
		origin + Vector3.new(37, 11, 59),
		Color3.fromRGB(235, 225, 199),
		Enum.Material.Concrete
	)
	beacon.CanCollide = false
	local beaconTop = part(
		model,
		"LanguagePortBeaconTop",
		Vector3.new(10, 5, 10),
		origin + Vector3.new(37, 23, 59),
		C.red,
		Enum.Material.Glass
	)
	beaconTop.CanCollide = false
	local beaconLight = light(beaconTop, C.red, 0.25, 16)
	local scanPrompt
	local launchPrompt

	local function currentProject()
		return Rules.CurrentProject(state.languagePort)
	end

	local function updateHud()
		hud(remote, player, title, state.objective, state.score)
	end

	local function setDockPrompts(enabled)
		for _, pr in pairs(dockPrompts) do
			pr.Enabled = enabled
		end
	end

	local function highlightCurrent()
		for _, project in ipairs(Rules.Projects) do
			local cargo = cargoParts[project.id]
			if
				state.languagePort.index <= #Rules.Projects
				and Rules.Projects[state.languagePort.index].id == project.id
			then
				cargo.Material = Enum.Material.SmoothPlastic
				cargo.Color = PROJECT_COLORS[project.id]:Lerp(C.white, 0.18)
				local l = cargo:FindFirstChild("ActiveCargoLight")
				if not l then
					l = Instance.new("PointLight")
					l.Name = "ActiveCargoLight"
					l.Color = C.yellow
					l.Brightness = 1.2
					l.Range = 12
					l.Parent = cargo
				end
			elseif not state.languagePort.routed[project.id] then
				cargo.Material = Enum.Material.Metal
				cargo.Color = PROJECT_COLORS[project.id]
				local l = cargo:FindFirstChild("ActiveCargoLight")
				if l then
					l:Destroy()
				end
			end
		end
	end

	local function setStatusForCurrent()
		local project = currentProject()
		if not project then
			statusText.Text = "KONTENERY 4/4\nGOTOWE DO ODPRAWY"
			manifestText.Text = "WSZYSTKIE MANIFESTY ZGODNE\nURUCHOM ODPRAWĘ STATKU"
			return
		end

		statusText.Text = string.format(
			"KONTENER %d/4\n%s\n%s",
			state.languagePort.index,
			project.title,
			state.languagePort.scanned and "WYBIERZ DOK" or "ZESKANUJ MANIFEST"
		)
		if not state.languagePort.scanned then
			manifestText.Text = "SKANER MANIFESTU\nŁADUNEK: " .. project.title .. "\nZESKANUJ, ABY POZNAĆ WYMAGANIA"
		end
	end

	local function resetInspection()
		inspectionSign.Color = C.red
		inspectionText.Text = "KONTROLA ZGODNOŚCI\nBRAK ALARMÓW"
		inspectionLight.Brightness = 0.3
	end

	local function animateTo(partToMove, target)
		local raised = target + Vector3.new(0, 7, 0)
		tween(partToMove, { Position = raised }, 0.35).Completed:Wait()
		tween(partToMove, { Position = target }, 0.38).Completed:Wait()
	end

	scanPrompt = prompt(scannerBase, "SKANUJ MANIFEST", "bieżący kontener", function(who)
		if who ~= player or state.done or state.languageBusy then
			return
		end
		local ok, projectOrReason = Rules.ScanCurrent(state.languagePort)
		if not ok then
			message(remote, player, projectOrReason, false)
			return
		end

		state.languageBusy = true
		local project = projectOrReason
		local cargo = cargoParts[project.id]
		tween(cargo, { Position = scannerPosition }, 0.55).Completed:Wait()
		scannerBeam.Transparency = 0.35
		scannerBeam.Color = C.sky
		scannerLight.Color = C.sky
		scannerLight.Brightness = 1.8
		cargoLabels[project.id].Text = project.title .. "\nMANIFEST OTWARTY"
		manifestText.Text = Rules.ManifestText(project)
		rationaleText.Text = "DYSPozytornia\nPrzeczytaj wymagania i wybierz dok, który najlepiej do nich pasuje."
		statusText.Text = string.format("KONTENER %d/4\n%s\nWYBIERZ DOK", state.languagePort.index, project.title)
		state.objective = "Manifest otwarty • skieruj projekt do właściwego języka na podstawie zastosowania."
		state.score += 8
		setDockPrompts(true)
		scanPrompt.Enabled = false
		state.languageBusy = false
		updateHud()
	end)

	for _, language in ipairs(Rules.Languages) do
		local dockControl = dockControls[language]
		dockPrompts[language] = prompt(dockControl, "WYŚLIJ DO DOKU", language, function(who)
			if who ~= player or state.done or state.languageBusy then
				return
			end

			local project = currentProject()
			if not project then
				return
			end
			local cargo = cargoParts[project.id]
			local ok, result = Rules.RouteCurrent(state.languagePort, language)
			if not ok then
				state.score = math.max(0, state.score - 6)
				inspectionSign.Color = C.red
				inspectionSign.Material = Enum.Material.Neon
				inspectionText.Text = "ALARM ZGODNOŚCI\n" .. language .. " ≠ WYMAGANIA"
				inspectionLight.Brightness = 2.4
				rationaleText.Text = "DLACZEGO NIE?\n" .. tostring(result)
				statusText.Text = "DEBUG PORTU\nSPRÓBUJ PONOWNIE Z TYM SAMYM ŁADUNKIEM"
				local start = cargo.Position
				tween(cargo, { Position = start + Vector3.new(2.5, 0, 0) }, 0.09)
				task.wait(0.1)
				tween(cargo, { Position = start - Vector3.new(2.5, 0, 0) }, 0.09)
				task.wait(0.1)
				tween(cargo, { Position = start }, 0.09)
				message(remote, player, tostring(result), false)
				updateHud()
				task.delay(1.1, function()
					if not state.done then
						resetInspection()
					end
				end)
				return
			end

			state.languageBusy = true
			setDockPrompts(false)
			resetInspection()
			local dock = DOCKS[language]
			local target = routedPositions[language]
			tween(cargo, { Position = scannerPosition + Vector3.new(0, 7, 0) }, 0.25).Completed:Wait()
			tween(cargo, { Position = target + Vector3.new(0, 7, 0) }, 0.55).Completed:Wait()
			tween(cargo, { Position = target }, 0.3).Completed:Wait()
			cargo.Color = dock.color
			cargo.Material = Enum.Material.SmoothPlastic
			cargoLabels[project.id].Text = project.title .. "\n→ " .. language
			dockLights[language].Brightness = 1.8
			rationaleText.Text = "TRAFIONY DOK\n" .. project.reason
			scannerBeam.Transparency = 0.72
			scannerLight.Color = C.yellow
			scannerLight.Brightness = 0.8
			state.score += 35

			if result.stage == "LAUNCH" then
				statusText.Text = "KONTENERY 4/4\nWSZYSTKIE TRAFIŁY DO WŁAŚCIWYCH DOKÓW"
				manifestText.Text = "PORT GOTOWY\nODPRAWA STATKU ODBLOKOWANA"
				state.objective = "Cztery projekty dopasowane • uruchom odprawę statku."
				launchPrompt.Enabled = true
				scanPrompt.Enabled = false
				message(
					remote,
					player,
					"Wszystkie cztery projekty są w odpowiednich dokach. Czas wysłać statek.",
					true
				)
			else
				highlightCurrent()
				setStatusForCurrent()
				state.objective = "Następny ładunek czeka • zeskanuj manifest, zanim wybierzesz język."
				scanPrompt.Enabled = true
				message(remote, player, project.title .. " poprawnie skierowany do " .. language .. ".", true)
			end
			state.languageBusy = false
			updateHud()
		end)
	end

	setDockPrompts(false)
	launchPrompt = prompt(launchConsole, "ODPRAW STATEK", "Code Cargo", function(who)
		if who ~= player or state.done or state.languageBusy then
			return
		end

		local ok, result = Rules.Launch(state.languagePort)
		if not ok then
			message(remote, player, result, false)
			return
		end

		state.languageBusy = true
		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += result.efficiency
		launchPrompt.Enabled = false

		header.Color = C.sky
		header.Material = Enum.Material.SmoothPlastic
		statusBoard.Color = C.green
		statusText.Text = string.format("PORT ONLINE\n4/4 ŁADUNKI • EFEKTYWNOŚĆ %d%%", result.efficiency)
		manifestBoard.Color = C.white
		manifestText.Text = "WSPÓLNA LEKCJA\nJĘZYK DOBIERAMY DO ZADANIA, ŚRODOWISKA I OGRANICZEŃ."
		rationaleBoard.Color = C.green
		rationaleText.Text =
			"ODPRAWA ZAKOŃCZONA\nPython ≠ JavaScript ≠ C ≠ C#\nKażdy ma sens w innym kontekście."
		beaconTop.Color = C.green
		beaconTop.Material = Enum.Material.Neon
		beaconLight.Color = C.green
		beaconLight.Brightness = 3
		beaconLight.Range = 34

		for _, language in ipairs(Rules.Languages) do
			local dock = DOCKS[language]
			local cargoProject
			for _, project in ipairs(Rules.Projects) do
				if project.language == language then
					cargoProject = project
					break
				end
			end
			if cargoProject then
				local cargo = cargoParts[cargoProject.id]
				local deckTarget = origin + Vector3.new(dock.x * 0.62, 10, 62)
				task.spawn(function()
					tween(cargo, { Position = cargo.Position + Vector3.new(0, 8, 0) }, 0.35).Completed:Wait()
					tween(cargo, { Position = deckTarget }, 0.65).Completed:Wait()
				end)
			end
		end

		task.delay(1.2, function()
			tween(shipHull, { Position = shipHull.Position + Vector3.new(0, 0, 36) }, 1.8)
			tween(shipDeck, { Position = shipDeck.Position + Vector3.new(0, 0, 36) }, 1.8)
			tween(shipBridge, { Position = shipBridge.Position + Vector3.new(0, 0, 36) }, 1.8)
			for _, project in ipairs(Rules.Projects) do
				local cargo = cargoParts[project.id]
				tween(cargo, { Position = cargo.Position + Vector3.new(0, 0, 36) }, 1.8)
			end
		end)

		state.objective =
			string.format("Language Port ukończony: 4 zastosowania dopasowane, błędy %d.", result.errors)
		remote:FireClient(player, {
			kind = "objective",
			text = state.objective,
			score = state.score,
		})
		message(
			remote,
			player,
			"Statek odpłynął. W programowaniu wybór języka wynika z zastosowania i ograniczeń projektu.",
			true
		)
		updateHud()
		state.languageBusy = false
	end)
	launchPrompt.Enabled = false

	highlightCurrent()
	setStatusForCurrent()
	state.objective = "KONTENER 1/4 • Podejdź do skanera i otwórz manifest pierwszego projektu."
	updateHud()
	message(
		remote,
		player,
		"To nie ranking języków. Skanuj wymagania projektu i kieruj ładunek do technologii, która do nich pasuje.",
		true
	)
end

return LanguagePort