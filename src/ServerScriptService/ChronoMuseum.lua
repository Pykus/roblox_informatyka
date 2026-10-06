local TweenService = game:GetService("TweenService")

local ChronoMuseum = {}
local Rules = require(script.Parent:WaitForChild("ChronoMuseumRules"))

local C = {
	marble = Color3.fromRGB(228, 220, 198),
	bronze = Color3.fromRGB(151, 102, 60),
	dark = Color3.fromRGB(38, 43, 48),
	cyan = Color3.fromRGB(80, 205, 235),
	gold = Color3.fromRGB(245, 193, 71),
	green = Color3.fromRGB(75, 230, 130),
	red = Color3.fromRGB(238, 85, 75),
	white = Color3.fromRGB(248, 247, 240),
	blue = Color3.fromRGB(76, 136, 225),
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

local function label(target, text, face, minSize)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.45
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize or 18
	constraint.MaxTextSize = 34
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
	l.Brightness = brightness or 1.5
	l.Range = range or 16
	l.Shadows = false
	l.Parent = target
	return l
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

local function setPromptGroup(prompts, enabled)
	for _, pr in ipairs(prompts) do
		pr.Enabled = enabled
	end
end

local function tween(instance, goal, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	tw:Play()
	return tw
end

local function makeTransistor(model, base)
	local body = part(
		model,
		"ChronoTransistorBody",
		Vector3.new(6, 7, 3),
		base + Vector3.new(0, 5.5, 0),
		C.dark,
		Enum.Material.Metal
	)
	body.CanCollide = false
	for index, x in ipairs({ -2, 0, 2 }) do
		local leg = part(
			model,
			"ChronoTransistorLeg_" .. index,
			Vector3.new(0.7, 5, 0.7),
			base + Vector3.new(x, 1.8, 0),
			C.bronze,
			Enum.Material.Metal
		)
		leg.CanCollide = false
	end
	local glow = part(
		model,
		"ChronoTransistorGlow",
		Vector3.new(3.8, 2.2, 0.5),
		base + Vector3.new(0, 6, -1.75),
		C.red,
		Enum.Material.Neon
	)
	glow.CanCollide = false
	return glow
end

local function makeArpanet(model, base)
	local hub =
		part(model, "ChronoARPANETHub", Vector3.new(3, 3, 3), base + Vector3.new(0, 4, 0), C.blue, Enum.Material.Neon)
	hub.Shape = Enum.PartType.Ball
	hub.CanCollide = false
	for index, offset in ipairs({
		Vector3.new(-4, 4, -3),
		Vector3.new(4, 4, -3),
		Vector3.new(-4, 4, 3),
		Vector3.new(4, 4, 3),
	}) do
		local node = part(
			model,
			"ChronoARPANETNode_" .. index,
			Vector3.new(2.2, 2.2, 2.2),
			base + offset,
			C.red,
			Enum.Material.Neon
		)
		node.Shape = Enum.PartType.Ball
		node.CanCollide = false
	end
	return hub
end

local function makeMicrochip(model, base)
	local chip =
		part(model, "ChronoMicrochip", Vector3.new(8, 1.4, 8), base + Vector3.new(0, 4, 0), C.dark, Enum.Material.Metal)
	chip.CanCollide = false
	for index = -3, 3 do
		if index ~= 0 then
			local pinA = part(
				model,
				"ChronoChipPinA_" .. tostring(index),
				Vector3.new(0.6, 0.5, 2.1),
				base + Vector3.new(index, 4, -5),
				C.bronze,
				Enum.Material.Metal
			)
			local pinB = part(
				model,
				"ChronoChipPinB_" .. tostring(index),
				Vector3.new(0.6, 0.5, 2.1),
				base + Vector3.new(index, 4, 5),
				C.bronze,
				Enum.Material.Metal
			)
			pinA.CanCollide = false
			pinB.CanCollide = false
		end
	end
	local core =
		part(model, "ChronoChipCore", Vector3.new(3, 0.7, 3), base + Vector3.new(0, 5, 0), C.red, Enum.Material.Neon)
	core.CanCollide = false
	return core
end

local function makeWeb(model, base)
	local frame = part(
		model,
		"ChronoWebFrame",
		Vector3.new(10, 7, 1),
		base + Vector3.new(0, 5, 0),
		C.dark,
		Enum.Material.SmoothPlastic
	)
	frame.CanCollide = false
	local screen = part(
		model,
		"ChronoWebScreen",
		Vector3.new(8.6, 5.5, 0.4),
		base + Vector3.new(0, 5, -0.75),
		C.red,
		Enum.Material.Neon
	)
	screen.CanCollide = false
	label(screen, "<html>\nWWW\n</html>", Enum.NormalId.Front, 18)
	return screen
end

local function updateYearDisplay(ctx, id)
	local exhibit = Rules.Exhibits[id]
	local year = Rules.CurrentYear(ctx.rules, id)
	ctx.yearLabels[id].Text = string.format("%s\nROK: %d", exhibit.label, year)
	ctx.yearLabels[id].TextColor3 = year == exhibit.year and C.green or C.white
end

local function activateLivingExhibit(ctx, id)
	local artifact = ctx.artifacts[id]
	artifact.Color = C.green
	artifact.Material = Enum.Material.Neon
	local l = light(artifact, C.green, 1.8, 14)
	l.Name = "ChronoStableLight_" .. id
	tween(artifact, { Transparency = 0.08 }, 0.22)
end

local function allStable(ctx)
	if not Rules.AllStabilized(ctx.rules) then
		return
	end
	setPromptGroup(ctx.cyclePrompts, false)
	setPromptGroup(ctx.stabilizePrompts, false)
	setPromptGroup(ctx.scanPrompts, true)
	ctx.orderBoard.Text = "ETAP 2/3 • SKANUJ OD NAJSTARSZEGO\n? → ? → ? → ?"
	ctx.clockStatus.Text = "CZAS USTABILIZOWANY\nUSTAL CHRONOLOGIĘ"
	hud(ctx, "ETAP 2/3 • Zeskanuj 4 kamienie milowe od najstarszego do najnowszego.")
	message(ctx, "Wszystkie kapsuły stabilne. Teraz odbuduj chronologię.", true)
end

local function finish(ctx)
	local ok, why = Rules.Synchronize(ctx.rules)
	if not ok then
		ctx.state.score = math.max(0, ctx.state.score - 4)
		ctx.clockStatus.Text = "SYNCHRONIZACJA ODRZUCONA"
		message(ctx, why, false)
		return
	end

	ctx.syncPrompt.Enabled = false
	ctx.state.score += 90
	ctx.state.done = true
	ctx.clockStatus.Text = "CHRONOLOGIA ONLINE\n1947 → 1969 → 1971 → 1991"
	ctx.clockStatus.TextColor3 = C.green

	for index, ring in ipairs(ctx.clockRings) do
		ring.Color = C.green
		ring.Material = Enum.Material.Neon
		tween(ring, {
			Position = ring.Position + Vector3.new(0, index * 0.8, 0),
			Transparency = 0.08,
		}, 0.24)
	end
	for _, beam in ipairs(ctx.finalBeams) do
		beam.Color = C.green
		beam.Material = Enum.Material.Neon
		beam.Transparency = 0.12
	end
	for _, lampPart in ipairs(ctx.podLamps) do
		lampPart.Color = C.green
		lampPart.Material = Enum.Material.Neon
	end

	hud(ctx, "ETAP 2/3 • Chronologia naprawiona. Przejdź do oznaczonego RDZENIA MISJI.")
	message(
		ctx,
		string.format("Muzeum czasu działa. Efektywność stabilizacji: %d%%.", Rules.Efficiency(ctx.rules)),
		true
	)
end

function ChronoMuseum.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		cyclePrompts = {},
		stabilizePrompts = {},
		scanPrompts = {},
		scanPromptById = {},
		scanParts = {},
		yearLabels = {},
		artifacts = {},
		clockRings = {},
		finalBeams = {},
		podLamps = {},
		entryReady = false,
	}

	part(
		model,
		"ChronoRotundaFloor",
		Vector3.new(82, 1, 82),
		origin + Vector3.new(0, -0.5, 4),
		C.marble,
		Enum.Material.Marble
	)
	local back = part(
		model,
		"ChronoMuseumHeader",
		Vector3.new(48, 10, 1),
		origin + Vector3.new(0, 13, -35),
		C.dark,
		Enum.Material.SmoothPlastic
	)
	label(back, "MUZEUM PO AWARII CZASU\nNAPRAW CHRONOLOGIĘ INFORMATYKI", Enum.NormalId.Front, 22)

	local instructionBoard = part(
		model,
		"ChronoInstructionBoard",
		Vector3.new(24, 9, 1.2),
		origin + Vector3.new(33, 6, -33.5),
		C.dark,
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	instructionBoard.CanTouch = false
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. Uruchom TIME SYNC przy wejściu\n2. Ustaw rok kapsuły i STABILIZUJ\n3. SKANUJ od najstarszego\n4. Na końcu SYNCHRONIZUJ\n\nGOTOWE ODPOWIEDZI\nTRANSISTOR 1947 • ARPANET 1969\nMIKROPROCESOR 1971 • WWW 1991\nKOLEJNOŚĆ: 1947 → 1969 → 1971 → 1991",
		Enum.NormalId.Front,
		18
	)

	local clockBase = part(
		model,
		"ChronoClockBase",
		Vector3.new(20, 3, 20),
		origin + Vector3.new(0, 1.5, 5),
		C.bronze,
		Enum.Material.Metal
	)
	clockBase.Shape = Enum.PartType.Cylinder
	clockBase.CFrame = CFrame.new(clockBase.Position) * CFrame.Angles(0, 0, math.rad(90))

	for index, diameter in ipairs({ 16, 12, 8 }) do
		local ring = part(
			model,
			"ChronoClockRing_" .. index,
			Vector3.new(1, diameter, diameter),
			origin + Vector3.new(0, 5 + index * 1.4, 5),
			C.red,
			Enum.Material.Glass
		)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.rad(90))
		ring.Transparency = 0.38
		ring.CanCollide = false
		table.insert(ctx.clockRings, ring)
	end

	local clockBoard = part(
		model,
		"ChronoClockStatus",
		Vector3.new(24, 8, 1),
		origin + Vector3.new(0, 15, 16),
		C.dark,
		Enum.Material.Metal
	)
	ctx.clockStatus = label(clockBoard, "ZEGAR BAZOWY OFFLINE\n4 KAPSUŁY ODŁĄCZONE", Enum.NormalId.Front, 19)
	local orderBoard = part(
		model,
		"ChronoOrderBoard",
		Vector3.new(34, 8, 1),
		origin + Vector3.new(0, 15, -9),
		C.dark,
		Enum.Material.Metal
	)
	ctx.orderBoard = label(orderBoard, "ETAP START • TIME SYNC PRZY WEJŚCIU", Enum.NormalId.Front, 18)

	local podDefs = {
		{ id = "TRANSISTOR", pos = Vector3.new(-26, 0, -18), builder = makeTransistor },
		{ id = "ARPANET", pos = Vector3.new(26, 0, -18), builder = makeArpanet },
		{ id = "MICROCHIP", pos = Vector3.new(-26, 0, 28), builder = makeMicrochip },
		{ id = "WWW", pos = Vector3.new(26, 0, 28), builder = makeWeb },
	}

	for podIndex, def in ipairs(podDefs) do
		local basePos = origin + def.pos
		local pedestal = part(
			model,
			"ChronoPod_" .. def.id,
			Vector3.new(18, 2, 16),
			basePos + Vector3.new(0, 1, 0),
			C.white,
			Enum.Material.Marble
		)
		local glass = part(
			model,
			"ChronoGlass_" .. def.id,
			Vector3.new(14, 12, 12),
			basePos + Vector3.new(0, 7, 0),
			C.cyan,
			Enum.Material.Glass
		)
		glass.Transparency = 0.78
		glass.CanCollide = false
		local lampPart = part(
			model,
			"ChronoPodLamp_" .. def.id,
			Vector3.new(4, 1, 4),
			basePos + Vector3.new(0, 13.5, 0),
			C.red,
			Enum.Material.Neon
		)
		lampPart.CanCollide = false
		table.insert(ctx.podLamps, lampPart)

		local yearBoard = part(
			model,
			"ChronoYearBoard_" .. def.id,
			Vector3.new(15, 6, 1),
			basePos + Vector3.new(0, 8, -8.4),
			C.dark,
			Enum.Material.Metal
		)
		ctx.yearLabels[def.id] = label(yearBoard, "", Enum.NormalId.Front, 18)
		updateYearDisplay(ctx, def.id)

		ctx.artifacts[def.id] = def.builder(model, basePos)

		local dial = part(
			model,
			"ChronoDial_" .. def.id,
			Vector3.new(5, 5, 2),
			basePos + Vector3.new(-5, 3.5, 8.3),
			C.gold,
			Enum.Material.Metal
		)
		local stabilize = part(
			model,
			"ChronoStabilizer_" .. def.id,
			Vector3.new(5, 5, 2),
			basePos + Vector3.new(5, 3.5, 8.3),
			C.blue,
			Enum.Material.Metal
		)
		local scan = part(
			model,
			"ChronoScanner_" .. def.id,
			Vector3.new(8, 3, 2),
			basePos + Vector3.new(0, 8.5, 8.3),
			C.cyan,
			Enum.Material.Neon
		)
		label(dial, "OBRÓĆ\nROK", Enum.NormalId.Front, 16)
		label(stabilize, "STABILIZUJ", Enum.NormalId.Front, 16)
		label(scan, "SKAN", Enum.NormalId.Front, 16)
		ctx.scanParts[def.id] = scan

		local dialControl = part(
			model,
			"ChronoDialControl_" .. def.id,
			Vector3.new(4, 3, 4),
			basePos + Vector3.new(-5, 3.4, 12),
			C.gold,
			Enum.Material.Metal
		)
		dialControl.CanCollide = false
		dialControl.CanTouch = false
		local stabilizeControl = part(
			model,
			"ChronoStabilizeControl_" .. def.id,
			Vector3.new(4, 3, 4),
			basePos + Vector3.new(5, 3.4, 12),
			C.blue,
			Enum.Material.Metal
		)
		stabilizeControl.CanCollide = false
		stabilizeControl.CanTouch = false
		local scanControl = part(
			model,
			"ChronoScanControl_" .. def.id,
			Vector3.new(5, 3, 4),
			basePos + Vector3.new(0, 7.8, 12),
			C.cyan,
			Enum.Material.Metal
		)
		scanControl.CanCollide = false
		scanControl.CanTouch = false

		local cyclePrompt = prompt(dialControl, "OBRÓĆ", "PIERŚCIEŃ ROKU", function(p)
			if p ~= player or not ctx.entryReady or ctx.rules.stabilized[def.id] then
				return
			end
			Rules.CycleYear(ctx.rules, def.id)
			updateYearDisplay(ctx, def.id)
			tween(dial, { Orientation = dial.Orientation + Vector3.new(0, 0, 45) }, 0.12)
		end)
		cyclePrompt.Enabled = false
		table.insert(ctx.cyclePrompts, cyclePrompt)

		local stabilizePrompt
		stabilizePrompt = prompt(stabilizeControl, "STABILIZUJ", Rules.Exhibits[def.id].label, function(p)
			if p ~= player or not ctx.entryReady or ctx.rules.stabilized[def.id] then
				return
			end
			local ok, why = Rules.Stabilize(ctx.rules, def.id)
			if not ok then
				ctx.state.score = math.max(0, ctx.state.score - 4)
				stabilize.Color = C.red
				message(ctx, why, false)
				tween(stabilize, { Color = C.blue }, 0.28)
				return
			end
			ctx.state.score += 20
			cyclePrompt.Enabled = false
			stabilizePrompt.Enabled = false
			stabilize.Color = C.green
			activateLivingExhibit(ctx, def.id)
			message(ctx, why, true)
			allStable(ctx)
		end)
		stabilizePrompt.Enabled = false
		table.insert(ctx.stabilizePrompts, stabilizePrompt)

		local scanPrompt
		scanPrompt = prompt(scanControl, "SKANUJ", Rules.Exhibits[def.id].label, function(p)
			if p ~= player or not ctx.entryReady or not Rules.AllStabilized(ctx.rules) then
				return
			end
			local ok, why = Rules.Scan(ctx.rules, def.id)
			if not ok then
				ctx.state.score = math.max(0, ctx.state.score - 4)
				ctx.orderBoard.Text = "SEKWENCJA ZEROWANA\nZACZNIJ OD NAJSTARSZEGO"
				for scanId, scanPromptToReset in pairs(ctx.scanPromptById) do
					scanPromptToReset.Enabled = true
					ctx.scanParts[scanId].Color = C.cyan
				end
				message(ctx, why, false)
				return
			end
			ctx.state.score += 15
			scan.Color = C.green
			scanPrompt.Enabled = false
			local labels = {}
			for index = 1, ctx.rules.scanIndex do
				local scanned = Rules.Order[index]
				table.insert(labels, tostring(Rules.Exhibits[scanned].year))
			end
			ctx.orderBoard.Text =
				string.format("ETAP 2/3 • CHRONOLOGIA %d/4\n%s", ctx.rules.scanIndex, table.concat(labels, " → "))
			message(ctx, why, true)
			if Rules.ScanComplete(ctx.rules) then
				ctx.syncPrompt.Enabled = true
				ctx.clockStatus.Text = "ETAP 3/3\nSYNCHRONIZUJ ZEGAR"
				hud(ctx, "ETAP 3/3 • Uruchom centralny zegar i zsynchronizuj muzeum.")
			end
		end)
		scanPrompt.Enabled = false
		table.insert(ctx.scanPrompts, scanPrompt)
		ctx.scanPromptById[def.id] = scanPrompt

		local clockPoint = origin + Vector3.new(0, 5, 5)
		local podPoint = basePos + Vector3.new(0, 5, 0)
		local midpoint = (clockPoint + podPoint) * 0.5
		local distance = (podPoint - clockPoint).Magnitude
		local beam = part(
			model,
			"ChronoFinalBeam_" .. podIndex,
			Vector3.new(1, 1, distance),
			midpoint,
			C.red,
			Enum.Material.Glass
		)
		beam.Transparency = 1
		beam.CanCollide = false
		beam.CFrame = CFrame.lookAt(midpoint, podPoint)
		table.insert(ctx.finalBeams, beam)
	end

	setPromptGroup(ctx.cyclePrompts, false)
	setPromptGroup(ctx.stabilizePrompts, false)

	local entrySync = part(
		model,
		"ChronoTimeSyncConsole",
		Vector3.new(10, 6, 7),
		origin + Vector3.new(0, 4, -42),
		C.bronze,
		Enum.Material.Metal
	)
	entrySync.CanCollide = false
	entrySync.CanTouch = false
	local entrySyncText = label(entrySync, "TIME SYNC\nZEGAR BAZOWY: OFFLINE", Enum.NormalId.Front, 18)
	local entrySyncPrompt
	entrySyncPrompt = prompt(entrySync, "SYNCHRONIZUJ START", "Zegar bazowy muzeum", function(p)
		if p ~= player or ctx.entryReady or state.done then
			return
		end
		ctx.entryReady = true
		entrySyncPrompt.Enabled = false
		entrySync.Color = C.green
		entrySync.Material = Enum.Material.Neon
		entrySyncText.Text = "TIME SYNC ✓\nKAPSUŁY AKTYWNE"
		ctx.clockStatus.Text = "ZEGAR BAZOWY ONLINE\n4 ANOMALIE DO NAPRAWY"
		ctx.clockStatus.TextColor3 = C.cyan
		ctx.orderBoard.Text = "ETAP 1/3 • USTABILIZUJ 4 KAPSUŁY"
		setPromptGroup(ctx.cyclePrompts, true)
		setPromptGroup(ctx.stabilizePrompts, true)
		hud(ctx, "ETAP 1/3 • Obróć rok każdej kapsuły i ustabilizuj 4 kamienie milowe.")
		message(ctx, "Zegar bazowy zsynchronizowany. Pokrętła i stabilizatory kapsuł są aktywne.", true)
	end)
	ctx.entrySync = entrySync
	ctx.entrySyncPrompt = entrySyncPrompt

	local syncConsole = part(
		model,
		"ChronoSyncConsole",
		Vector3.new(10, 5, 6),
		origin + Vector3.new(0, 3, 24),
		C.bronze,
		Enum.Material.Metal
	)
	label(syncConsole, "SYNCHRONIZUJ\nCHRONOLOGIĘ", Enum.NormalId.Front, 18)
	ctx.syncPrompt = prompt(syncConsole, "SYNCHRONIZUJ", "CENTRALNY ZEGAR", function(p)
		if p ~= player then
			return
		end
		finish(ctx)
	end)
	ctx.syncPrompt.Enabled = false

	hud(ctx, "ETAP START • Uruchom TIME SYNC przy wejściu, aby zasilić kapsuły czasu.")
	message(ctx, "Awaria czasu odłączyła kapsuły. Najpierw zsynchronizuj zegar bazowy przy wejściu.", true)
end

return ChronoMuseum