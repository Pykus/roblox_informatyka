local SportsNewsroom = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("SportsNewsroomRules"))

local C = {
	dark = Color3.fromRGB(27, 31, 40),
	blue = Color3.fromRGB(55, 126, 224),
	cyan = Color3.fromRGB(50, 205, 222),
	green = Color3.fromRGB(70, 206, 116),
	yellow = Color3.fromRGB(242, 198, 66),
	orange = Color3.fromRGB(235, 137, 52),
	purple = Color3.fromRGB(154, 93, 214),
	red = Color3.fromRGB(226, 72, 75),
	white = Color3.fromRGB(244, 247, 249),
	grass = Color3.fromRGB(65, 142, 81),
}

local FACT_DATA = {
	SCORE = { title = "WYNIK", value = "FALCONS 3 : 1 COMETS" },
	SHOTS = { title = "STRZAŁY", value = "12 : 6" },
	POSSESSION = { title = "POSIADANIE", value = "58% : 42%" },
	FOULS = { title = "FAULE", value = "4 : 7" },
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

local function label(target, text, face, maxText)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 440)
	gui.LightInfluence = 0
	gui.Brightness = 1.15
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 0.05
	txt.BackgroundColor3 = C.dark
	txt.TextColor3 = C.white
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 16
	constraint.MaxTextSize = maxText or 30
	constraint.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText or ""
	pr.MaxActivationDistance = 13
	pr.HoldDuration = 0.08
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.5
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
function SportsNewsroom.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Reporter szkolnego sportu"
	state.sportsNews = Rules.NewState()
	state.sportsBusy = false

	local floor = part(
		model,
		"SportsNewsroomFloor",
		Vector3.new(92, 1, 112),
		origin + Vector3.new(0, 0.2, 10),
		Color3.fromRGB(56, 61, 71),
		Enum.Material.SmoothPlastic
	)
	floor.CanCollide = true

	local header = part(
		model,
		"SportsNewsroomHeader",
		Vector3.new(70, 9, 2),
		origin + Vector3.new(0, 22, -44),
		C.blue,
		Enum.Material.Neon
	)
	label(header, "SPORTS NEWSROOM\nDANE → NOTATKA → WYKRES → ZDJĘCIE → PUBLIKACJA", Enum.NormalId.Front, 29)
	light(header, C.blue, 1.8, 24)

	local field = part(
		model,
		"SportsFieldWindow",
		Vector3.new(76, 0.7, 34),
		origin + Vector3.new(0, 0.8, 48),
		C.grass,
		Enum.Material.Grass
	)
	field.CanCollide = true
	for i = -3, 3 do
		part(
			model,
			"SportsFieldLine_" .. (i + 4),
			Vector3.new(0.35, 0.15, 32),
			origin + Vector3.new(i * 10, 1.2, 48),
			C.white,
			Enum.Material.Neon
		).CanCollide =
			false
	end

	local scoreTower = part(
		model,
		"SportsScoreTower",
		Vector3.new(34, 12, 2),
		origin + Vector3.new(0, 10, 63),
		C.dark,
		Enum.Material.Metal
	)
	local scoreTowerText = label(scoreTower, "FALCONS 3 : 1 COMETS\nKONIEC MECZU", Enum.NormalId.Back, 29)

	local dataWall = part(
		model,
		"SportsDataWall",
		Vector3.new(72, 13, 2),
		origin + Vector3.new(0, 9, -33),
		Color3.fromRGB(45, 51, 64),
		Enum.Material.Metal
	)
	label(dataWall, "TELEMETRIA MECZU • ZESKANUJ FAKTY DO NOTATNIKA", Enum.NormalId.Front, 27)

	local notebook = part(
		model,
		"SportsReporterNotebook",
		Vector3.new(31, 19, 2),
		origin + Vector3.new(-29, 12, -5),
		Color3.fromRGB(237, 229, 201),
		Enum.Material.SmoothPlastic
	)
	local notebookText = label(notebook, Rules.NoteText(state.sportsNews), Enum.NormalId.Front, 21)
	notebookText.BackgroundColor3 = Color3.fromRGB(245, 239, 214)
	notebookText.TextColor3 = Color3.fromRGB(39, 43, 50)

	local factPanels = {}
	local factControls = {}
	local factOrder = { "SCORE", "SHOTS", "POSSESSION", "FOULS" }
	for i, factId in ipairs(factOrder) do
		local row = math.floor((i - 1) / 2)
		local col = (i - 1) % 2
		local data = FACT_DATA[factId]
		local panel = part(
			model,
			"SportsStat_" .. factId,
			Vector3.new(27, 7, 2),
			origin + Vector3.new(-16 + col * 32, 13 - row * 9, -24),
			i % 2 == 0 and C.cyan or C.blue,
			Enum.Material.SmoothPlastic
		)
		label(panel, data.title .. "\n" .. data.value, Enum.NormalId.Front, 25)
		factPanels[factId] = panel

		local scanControl = part(
			model,
			"SportsFactScanControl_" .. factId,
			Vector3.new(5, 3, 4),
			panel.Position + Vector3.new(0, -2.1, -4),
			i % 2 == 0 and C.cyan or C.blue,
			Enum.Material.Metal
		)
		scanControl.CanCollide = false
		scanControl.CanTouch = false
		factControls[factId] = scanControl
	end

	local stageBoard = part(
		model,
		"SportsNewsStatus",
		Vector3.new(33, 10, 2),
		origin + Vector3.new(29, 10, -5),
		C.dark,
		Enum.Material.Metal
	)
	local stageText = label(stageBoard, "ETAP 1/3\nZBIERZ 4 FAKTY", Enum.NormalId.Front, 27)
	local chartBase = part(
		model,
		"SportsChartBase",
		Vector3.new(35, 1, 18),
		origin + Vector3.new(0, 1.3, 11),
		Color3.fromRGB(78, 84, 94),
		Enum.Material.Metal
	)
	chartBase.CanCollide = true

	local chartBack = part(
		model,
		"SportsChartBack",
		Vector3.new(34, 21, 2),
		origin + Vector3.new(0, 11, 20),
		C.dark,
		Enum.Material.Metal
	)
	label(chartBack, "STRZAŁY\nFALCONS vs COMETS", Enum.NormalId.Back, 24)

	local chartHome = part(
		model,
		"SportsChartFalcons",
		Vector3.new(8, 9, 6),
		origin + Vector3.new(-8, 5.5, 11),
		C.blue,
		Enum.Material.Neon
	)
	local chartAway = part(
		model,
		"SportsChartComets",
		Vector3.new(8, 9, 6),
		origin + Vector3.new(8, 5.5, 11),
		C.orange,
		Enum.Material.Neon
	)
	local chartHomeText = label(chartHome, "FALCONS\n9", Enum.NormalId.Front, 22)
	local chartAwayText = label(chartAway, "COMETS\n9", Enum.NormalId.Front, 22)

	local function chartButton(name, text, pos, color)
		local p = part(model, name, Vector3.new(8, 4, 6), pos, color, Enum.Material.SmoothPlastic)
		label(p, text, Enum.NormalId.Front, 20)
		return p
	end

	local function semanticControl(name, pos, color, size)
		local control = part(model, name, size or Vector3.new(4, 3, 4), pos, color, Enum.Material.Metal)
		control.CanCollide = false
		control.CanTouch = false
		return control
	end

	local homeMinus = chartButton("SportsChartHomeMinus", "F -", origin + Vector3.new(-14, 3, 25), C.red)
	local homePlus = chartButton("SportsChartHomePlus", "F +", origin + Vector3.new(-4, 3, 25), C.green)
	local awayMinus = chartButton("SportsChartAwayMinus", "C -", origin + Vector3.new(4, 3, 25), C.red)
	local awayPlus = chartButton("SportsChartAwayPlus", "C +", origin + Vector3.new(14, 3, 25), C.green)
	local homeMinusControl = semanticControl("SportsChartControl_HomeMinus", origin + Vector3.new(-14, 3, 20), C.red)
	local homePlusControl = semanticControl("SportsChartControl_HomePlus", origin + Vector3.new(-4, 3, 20), C.green)
	local awayMinusControl = semanticControl("SportsChartControl_AwayMinus", origin + Vector3.new(4, 3, 20), C.red)
	local awayPlusControl = semanticControl("SportsChartControl_AwayPlus", origin + Vector3.new(14, 3, 20), C.green)

	local validateChart = part(
		model,
		"SportsChartValidate",
		Vector3.new(20, 5, 7),
		origin + Vector3.new(0, 3.5, 31),
		C.yellow,
		Enum.Material.Metal
	)
	label(validateChart, "SPRAWDŹ WYKRES", Enum.NormalId.Front, 23)
	local validateChartControl =
		semanticControl("SportsChartValidateControl", origin + Vector3.new(0, 3.5, 26), C.yellow, Vector3.new(6, 3, 5))

	local cameraTrack = part(
		model,
		"SportsCameraTrack",
		Vector3.new(48, 0.7, 4),
		origin + Vector3.new(0, 11, 35),
		Color3.fromRGB(82, 88, 98),
		Enum.Material.Metal
	)
	cameraTrack.CanCollide = false

	local cameraPositions = {
		origin + Vector3.new(-18, 13, 35),
		origin + Vector3.new(0, 13, 35),
		origin + Vector3.new(18, 13, 35),
	}
	local cameraDrone =
		part(model, "SportsCameraDrone", Vector3.new(9, 5, 7), cameraPositions[1], C.cyan, Enum.Material.Metal)
	cameraDrone.CanCollide = false
	light(cameraDrone, C.cyan, 1.5, 17)
	label(cameraDrone, "CAM", Enum.NormalId.Front, 21)

	local cameraLens = part(
		model,
		"SportsCameraLens",
		Vector3.new(3, 3, 2),
		cameraPositions[1] + Vector3.new(0, 0, -4),
		Color3.fromRGB(25, 29, 35),
		Enum.Material.Glass
	)
	cameraLens.CanCollide = false

	local cameraLeft = chartButton("SportsCameraLeft", "← KAMERA", origin + Vector3.new(-16, 3.5, 39), C.blue)
	local cameraRight = chartButton("SportsCameraRight", "KAMERA →", origin + Vector3.new(16, 3.5, 39), C.blue)
	local cameraLeftControl = semanticControl("SportsCameraControl_Left", origin + Vector3.new(-16, 3.5, 34), C.blue)
	local cameraRightControl = semanticControl("SportsCameraControl_Right", origin + Vector3.new(16, 3.5, 34), C.blue)

	local captureConsole = part(
		model,
		"SportsPhotoCapture",
		Vector3.new(21, 6, 8),
		origin + Vector3.new(0, 4, 39),
		C.purple,
		Enum.Material.Metal
	)
	label(captureConsole, "ZRÓB ZDJĘCIE", Enum.NormalId.Front, 24)
	local captureControl =
		semanticControl("SportsPhotoCaptureControl", origin + Vector3.new(0, 3.5, 34), C.purple, Vector3.new(5, 3, 5))

	local flash = part(
		model,
		"SportsPhotoFlash",
		Vector3.new(5, 5, 2),
		origin + Vector3.new(0, 13, 31),
		C.white,
		Enum.Material.Neon
	)
	flash.Transparency = 1
	light(flash, C.white, 0, 24)
	local photoPreview = part(
		model,
		"SportsPhotoPreview",
		Vector3.new(30, 17, 2),
		origin + Vector3.new(-28, 11, 48),
		Color3.fromRGB(48, 53, 61),
		Enum.Material.Metal
	)
	local photoText = label(photoPreview, "MATERIAŁ FOTO\nBRAK ZDJĘCIA", Enum.NormalId.Front, 25)

	local broadcastDesk = part(
		model,
		"SportsBroadcastDesk",
		Vector3.new(28, 7, 10),
		origin + Vector3.new(28, 4.5, 48),
		C.blue,
		Enum.Material.Metal
	)
	label(broadcastDesk, "PUBLIKUJ REPORTAŻ", Enum.NormalId.Front, 24)

	local broadcastWall = part(
		model,
		"SportsBroadcastWall",
		Vector3.new(54, 18, 2),
		origin + Vector3.new(0, 12, 64),
		Color3.fromRGB(51, 55, 64),
		Enum.Material.Metal
	)
	local broadcastText = label(broadcastWall, "SPORTS LIVE\nCZEKAM NA MATERIAŁ", Enum.NormalId.Back, 30)

	local ticker = part(
		model,
		"SportsTicker",
		Vector3.new(54, 4, 2),
		origin + Vector3.new(0, 2.5, 63.8),
		Color3.fromRGB(77, 81, 90),
		Enum.Material.Metal
	)
	local tickerText = label(ticker, "OFFLINE", Enum.NormalId.Back, 22)

	local gate = part(
		model,
		"SportsNewsroomGate",
		Vector3.new(36, 18, 2),
		origin + Vector3.new(0, 9, 67),
		Color3.fromRGB(67, 71, 78),
		Enum.Material.Metal
	)
	label(gate, "EMISJA ZABLOKOWANA", Enum.NormalId.Back, 24)
	local gateOpen = gate.Position + Vector3.new(0, 20, 0)

	local studioLights = {}
	for i = 1, 6 do
		local lamp = part(
			model,
			"SportsStudioLight_" .. i,
			Vector3.new(8, 0.7, 2.5),
			origin + Vector3.new(-30 + (i - 1) * 12, 18, 43),
			Color3.fromRGB(72, 75, 82),
			Enum.Material.Metal
		)
		studioLights[i] = lamp
	end

	local chartPrompts = {}
	local publishPrompt
	local capturePrompt

	local function updateNotebook()
		notebookText.Text = Rules.NoteText(state.sportsNews)
	end

	local function updateChart()
		local home = state.sportsNews.chart.HOME
		local away = state.sportsNews.chart.AWAY
		local homeHeight = 3 + home * 0.9
		local awayHeight = 3 + away * 0.9
		chartHome.Size = Vector3.new(8, homeHeight, 6)
		chartAway.Size = Vector3.new(8, awayHeight, 6)
		chartHome.Position = origin + Vector3.new(-8, 1.8 + homeHeight / 2, 11)
		chartAway.Position = origin + Vector3.new(8, 1.8 + awayHeight / 2, 11)
		chartHomeText.Text = "FALCONS\n" .. tostring(home)
		chartAwayText.Text = "COMETS\n" .. tostring(away)
	end

	local function updateHud()
		hud(remote, player, title, state.objective, state.score)
	end

	local function setChartEnabled(enabled)
		for _, pr in ipairs(chartPrompts) do
			pr.Enabled = enabled
		end
	end
	for _, factId in ipairs(factOrder) do
		local panel = factPanels[factId]
		local scanControl = factControls[factId]
		prompt(scanControl, "SKANUJ", FACT_DATA[factId].title, function(who)
			if who ~= player or state.done then
				return
			end
			local ok, result = Rules.ScanFact(state.sportsNews, factId)
			if not ok then
				message(remote, player, result, false)
				return
			end

			panel.Color = C.green
			panel.Material = Enum.Material.Neon
			state.score += 15
			updateNotebook()
			local count = Rules.ScannedCount(state.sportsNews)
			stageText.Text = string.format("ETAP 1/3\nNOTATKA %d/4", count)
			message(remote, player, "Do notatnika trafiło: " .. result, true)

			if state.sportsNews.stage == 2 then
				state.objective = "ETAP 2/3 • Z danych STRZAŁY ustaw wykres FALCONS=12, COMETS=6."
				stageBoard.Color = C.yellow
				stageText.Text = "ETAP 2/3\nKALIBRUJ WYKRES STRZAŁÓW"
				setChartEnabled(true)
				message(remote, player, "Notatka gotowa. Teraz przepisz dane na wykres, nie na oko.", true)
			end
			updateHud()
		end)
	end

	local function adjustChart(side, delta)
		if state.done then
			return
		end
		local ok, result = Rules.AdjustChart(state.sportsNews, side, delta)
		if not ok then
			message(remote, player, result, false)
			return
		end
		state.score += 2
		updateChart()
		stageText.Text =
			string.format("ETAP 2/3\nF %d • C %d", state.sportsNews.chart.HOME, state.sportsNews.chart.AWAY)
		updateHud()
	end

	table.insert(
		chartPrompts,
		prompt(homeMinusControl, "−1", "Falcons", function(who)
			if who == player then
				adjustChart("HOME", -1)
			end
		end)
	)
	table.insert(
		chartPrompts,
		prompt(homePlusControl, "+1", "Falcons", function(who)
			if who == player then
				adjustChart("HOME", 1)
			end
		end)
	)
	table.insert(
		chartPrompts,
		prompt(awayMinusControl, "−1", "Comets", function(who)
			if who == player then
				adjustChart("AWAY", -1)
			end
		end)
	)
	table.insert(
		chartPrompts,
		prompt(awayPlusControl, "+1", "Comets", function(who)
			if who == player then
				adjustChart("AWAY", 1)
			end
		end)
	)
	table.insert(
		chartPrompts,
		prompt(validateChartControl, "SPRAWDŹ", "wykres strzałów", function(who)
			if who ~= player or state.done then
				return
			end
			local ok, result = Rules.ValidateChart(state.sportsNews)
			if not ok then
				state.score = math.max(0, state.score - 5)
				stageBoard.Color = C.red
				stageText.Text = "DEBUG WYKRESU\n" .. result
				message(remote, player, result, false)
				updateHud()
				return
			end

			state.score += 70
			stageBoard.Color = C.green
			stageText.Text = "ETAP 3/3\nUSTAW KADR I ZRÓB ZDJĘCIE"
			chartHome.Color = C.green
			chartAway.Color = C.green
			setChartEnabled(false)
			capturePrompt.Enabled = true
			state.objective = "ETAP 3/3 • Ustaw kamerę centralnie, aby objąć wynik i wykres, potem zrób zdjęcie."
			message(remote, player, result .. " Materiał graficzny gotowy.", true)
			updateHud()
		end)
	)

	setChartEnabled(false)
	local function moveCamera(delta)
		if state.done then
			return
		end
		local ok, result = Rules.MoveCamera(state.sportsNews, delta)
		if not ok then
			message(remote, player, result, false)
			return
		end
		local target = cameraPositions[result]
		tween(cameraDrone, { Position = target }, 0.4)
		tween(cameraLens, { Position = target + Vector3.new(0, 0, -4) }, 0.4)
		stageText.Text = string.format("ETAP 3/3\nKAMERA POZYCJA %d/3", result)
		message(
			remote,
			player,
			result == 2 and "Kadr centralny obejmuje wynik i wykres." or "Kadr jest przesunięty.",
			result == 2
		)
	end

	prompt(cameraLeftControl, "PRZESUŃ", "kamera w lewo", function(who)
		if who == player then
			moveCamera(-1)
		end
	end)
	prompt(cameraRightControl, "PRZESUŃ", "kamera w prawo", function(who)
		if who == player then
			moveCamera(1)
		end
	end)

	capturePrompt = prompt(captureControl, "FOTO", "materiał reporterski", function(who)
		if who ~= player or state.done then
			return
		end
		local ok, result = Rules.Capture(state.sportsNews)
		if not ok then
			state.score = math.max(0, state.score - 5)
			stageBoard.Color = C.red
			stageText.Text = "DEBUG KADRU\nUSTAW KAMERĘ CENTRALNIE"
			message(remote, player, result, false)
			updateHud()
			return
		end

		state.score += 80
		flash.Transparency = 0
		local flashLight = flash:FindFirstChildOfClass("PointLight")
		if flashLight then
			flashLight.Brightness = 5
		end
		task.delay(0.18, function()
			flash.Transparency = 1
			if flashLight then
				flashLight.Brightness = 0
			end
		end)

		photoPreview.Color = C.green
		photoPreview.Material = Enum.Material.Neon
		photoText.Text = "FOTO GOTOWE\nFALCONS 3:1 COMETS\nSTRZAŁY 12:6"
		stageBoard.Color = C.green
		stageText.Text = "MATERIAŁ KOMPLETNY\nPUBLIKUJ REPORTAŻ"
		state.objective = "Materiał kompletny • Przejdź do biurka transmisyjnego i opublikuj reportaż."
		publishPrompt.Enabled = true
		message(remote, player, result .. " Masz notatkę, wykres i zdjęcie.", true)
		updateHud()
	end)
	capturePrompt.Enabled = false

	publishPrompt = prompt(broadcastDesk, "PUBLIKUJ", "Sports Live", function(who)
		if who ~= player or state.done or state.sportsBusy then
			return
		end
		local ok, result = Rules.Publish(state.sportsNews)
		if not ok then
			message(remote, player, result, false)
			return
		end

		state.sportsBusy = true
		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += result.efficiency
		header.Color = C.green
		header.Material = Enum.Material.Neon
		stageBoard.Color = C.green
		stageBoard.Material = Enum.Material.Neon
		stageText.Text = string.format("SPORTS LIVE ONLINE\nEFEKTYWNOŚĆ %d%%", result.efficiency)
		broadcastWall.Color = C.blue
		broadcastWall.Material = Enum.Material.Neon
		broadcastText.Text = "SPORTS LIVE\nFALCONS 3 : 1 COMETS\nSTRZAŁY 12 : 6"
		ticker.Color = C.red
		ticker.Material = Enum.Material.Neon
		tickerText.Text = "PILNE • FALCONS WYGRYWAJĄ 3:1 • 12 STRZAŁÓW DO 6"

		for i, lamp in ipairs(studioLights) do
			task.delay((i - 1) * 0.1, function()
				lamp.Color = i % 2 == 0 and C.blue or C.cyan
				lamp.Material = Enum.Material.Neon
				light(lamp, lamp.Color, 1.4, 15)
			end)
		end
		tween(cameraDrone, { Position = origin + Vector3.new(0, 18, 43) }, 0.8)
		tween(cameraLens, { Position = origin + Vector3.new(0, 18, 39) }, 0.8)
		tween(gate, { Position = gateOpen }, 1.1)

		state.objective = string.format(
			"Reportaż opublikowany: 4 fakty, poprawny wykres, zdjęcie; błędy redakcyjne %d.",
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
			"Transmisja ruszyła. Dobra publikacja opiera się na danych, wizualizacji i materiale zdjęciowym.",
			true
		)
		updateHud()
	end)
	publishPrompt.Enabled = false

	updateChart()
	state.objective = "ETAP 1/3 • Zeskanuj 4 fakty z telemetrii meczu do notatnika reportera."
	updateHud()
	message(remote, player, "Najpierw zbierz fakty. Dopiero potem buduj wykres i materiał do transmisji.", true)
end

return SportsNewsroom