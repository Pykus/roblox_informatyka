local TimelineMuseum = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rules = require(script.Parent:WaitForChild("TimelineMuseumRules"))
local VisualThemes = require(script.Parent:WaitForChild("VisualThemes"))

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
	txt.TextColor3 = Color3.fromRGB(248, 246, 235)
	txt.TextStrokeTransparency = 0.6
	txt.Parent = gui

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = 42
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
	if callback then
		pr.Triggered:Connect(callback)
	end
	return pr
end

local function glow(target, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.4
	light.Range = range or 15
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

		local pivot = semantic:GetPivot()
		local positionOffset = source.CFrame:PointToObjectSpace(pivot.Position)
		local rotationOffset = source.CFrame.Rotation:ToObjectSpace(pivot.Rotation)
		while source.Parent and semantic.Parent do
			semantic:PivotTo(source.CFrame * CFrame.new(positionOffset) * rotationOffset)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function pulse(target, color)
	local old = target.Color
	target.Color = color
	TweenService:Create(target, TweenInfo.new(0.35), { Color = old }):Play()
end

local function setPromptGroup(prompts, enabled)
	for _, pr in ipairs(prompts) do
		pr.Enabled = enabled
	end
end

local function artifactPart(model, name, size, offset, color, material)
	local root = model.PrimaryPart
	local p = part(model, name, size, root.Position + offset, color, material)
	p.CanCollide = false
	return p
end

local function createArtifact(parent, id, basePos)
	local model = Instance.new("Model")
	model.Name = "Artifact_" .. id
	model.Parent = parent
	local root = part(model, "Root", Vector3.new(1, 1, 1), basePos, Color3.new(1, 1, 1))
	root.Transparency = 1
	root.CanCollide = false
	model.PrimaryPart = root

	if id == "ENIAC" then
		local cabinet = artifactPart(
			model,
			"TimelineArtifact_ENIAC",
			Vector3.new(9, 8, 3),
			Vector3.new(0, 4, 0),
			Color3.fromRGB(58, 70, 62),
			Enum.Material.Metal
		)
		for x = -3, 3, 2 do
			artifactPart(
				model,
				"Tube_" .. tostring(x),
				Vector3.new(0.8, 1.7, 0.7),
				Vector3.new(x, 4, -1.8),
				Color3.fromRGB(255, 150, 55),
				Enum.Material.Neon
			)
		end
		label(cabinet, "ENIAC\n1946")
		followSemanticVisual(cabinet)
	elseif id == "PC" then
		local case = artifactPart(
			model,
			"Case",
			Vector3.new(7, 4, 6),
			Vector3.new(0, 2, 1),
			Color3.fromRGB(210, 197, 165),
			Enum.Material.SmoothPlastic
		)
		local monitor = artifactPart(
			model,
			"TimelineArtifact_PC",
			Vector3.new(7, 6, 2),
			Vector3.new(0, 7, -1),
			Color3.fromRGB(198, 188, 160),
			Enum.Material.SmoothPlastic
		)
		local screen = artifactPart(
			model,
			"Screen",
			Vector3.new(5.4, 4.2, 0.3),
			Vector3.new(0, 7, -2.15),
			Color3.fromRGB(60, 120, 95),
			Enum.Material.Glass
		)
		screen.Transparency = 0.12
		label(monitor, "IBM PC\n1981")
		followSemanticVisual(monitor)
		case.CanCollide = false
	else
		local body = artifactPart(
			model,
			"TimelineArtifact_PHONE",
			Vector3.new(5, 9, 0.8),
			Vector3.new(0, 4.5, 0),
			Color3.fromRGB(28, 31, 36),
			Enum.Material.Metal
		)
		local screen = artifactPart(
			model,
			"Glass",
			Vector3.new(4.3, 7.7, 0.25),
			Vector3.new(0, 4.7, -0.55),
			Color3.fromRGB(65, 150, 205),
			Enum.Material.Glass
		)
		screen.Transparency = 0.08
		label(body, "SMARTFON\n2007")
		followSemanticVisual(body)
	end
	return model
end

local function moveArtifact(model, position)
	model:PivotTo(CFrame.new(position))
end

local function createEraArch(parent, origin, era, z, color)
	local base = part(
		parent,
		"EraBase_" .. era,
		Vector3.new(22, 2, 17),
		origin + Vector3.new(-18, 1, z),
		Color3.fromRGB(85, 72, 57),
		Enum.Material.WoodPlanks
	)
	local sign = part(
		parent,
		"EraSign_" .. era,
		Vector3.new(20, 9, 1),
		origin + Vector3.new(-18, 8, z + 8),
		Color3.fromRGB(73, 62, 52),
		Enum.Material.Wood
	)
	local signText = label(sign, era .. "\nOCZEKUJE NA EKSPONAT")
	signText.TextColor3 = Color3.fromRGB(235, 220, 188)
	local lamp = part(
		parent,
		"EraLamp_" .. era,
		Vector3.new(3, 3, 3),
		origin + Vector3.new(-29, 8, z),
		Color3.fromRGB(70, 65, 58),
		Enum.Material.Metal
	)
	local light = glow(lamp, color, 0.15, 18)
	local displayTable = part(
		parent,
		"TimelineEraDisplay_" .. era,
		Vector3.new(12, 2, 10),
		origin + Vector3.new(-18, 2.2, z),
		Color3.fromRGB(118, 94, 66),
		Enum.Material.Wood
	)
	displayTable.CanCollide = false
	return {
		base = base,
		sign = sign,
		signText = signText,
		lamp = lamp,
		light = light,
		position = origin + Vector3.new(-18, 3, z),
	}
end

local function lightEra(display, text)
	display.base.Material = Enum.Material.Neon
	display.base.Color = Color3.fromRGB(175, 126, 58)
	display.sign.Material = Enum.Material.Neon
	display.sign.Color = Color3.fromRGB(86, 120, 105)
	display.signText.Text = text
	display.lamp.Material = Enum.Material.Neon
	display.lamp.Color = Color3.fromRGB(255, 198, 85)
	display.light.Brightness = 2.5
end

local function followPlatform(player, platform, target)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local tween = TweenService:Create(platform, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Position = target,
	})
	tween:Play()
	while tween.PlaybackState == Enum.PlaybackState.Playing do
		if root and root.Parent then
			root.CFrame =
				CFrame.new(platform.Position + Vector3.new(0, 4.3, 0), platform.Position + Vector3.new(0, 4.3, 1))
		end
		task.wait(0.04)
	end
	if root and root.Parent then
		root.CFrame = CFrame.new(target + Vector3.new(0, 4.3, 0), target + Vector3.new(0, 4.3, 1))
	end
end

function TimelineMuseum.Run(model, origin, player, lesson, mission, remote, state, accent)
	local profile = VisualThemes.Get(mission)
	accent = profile.accent
	state.museumStage = 1
	state.timeline = Rules.NewState()
	local entryReady = false

	local title = mission.name or lesson.topic
	local brief = part(
		model,
		"TimelineBrief",
		Vector3.new(72, 11, 2),
		origin + Vector3.new(0, 9, -42),
		Color3.fromRGB(82, 67, 52),
		Enum.Material.Wood
	)
	brief.CanCollide = false
	label(brief, "MUZEUM W CZASIE\n1. USTAW EKSPONATY   2. PRZEJEDŹ OŚ CZASU I SKANUJ   3. URUCHOM ARCHIWUM")
	glow(brief, accent, 1.2, 17)
	local depot = part(
		model,
		"MuseumDepot",
		Vector3.new(66, 1, 22),
		origin + Vector3.new(0, 0.8, -24),
		Color3.fromRGB(112, 91, 65),
		Enum.Material.WoodPlanks
	)
	depot.CanCollide = true
	local depotSign = part(
		model,
		"DepotSign",
		Vector3.new(26, 8, 1),
		origin + Vector3.new(0, 7, -34),
		Color3.fromRGB(70, 59, 49),
		Enum.Material.Wood
	)
	label(depotSign, "MAGAZYN EKSPONATÓW\nZAŁADUJ JEDEN NA WÓZEK")
	local depotShelf = part(
		model,
		"TimelineDepotShelf",
		Vector3.new(12, 9, 4),
		origin + Vector3.new(28, 5, -29),
		Color3.fromRGB(92, 76, 58),
		Enum.Material.Wood
	)
	depotShelf.CanCollide = false

	local cart = part(
		model,
		"ExhibitCart",
		Vector3.new(18, 3, 12),
		origin + Vector3.new(0, 2.3, -15),
		Color3.fromRGB(75, 88, 94),
		Enum.Material.Metal
	)
	label(cart, "WÓZEK MUZEALNY", Enum.NormalId.Top)
	for _, x in ipairs({ -7, 7 }) do
		for _, z in ipairs({ -4, 4 }) do
			local wheel = part(
				model,
				"CartWheel",
				Vector3.new(2, 2, 1.5),
				cart.Position + Vector3.new(x, -2, z),
				Color3.fromRGB(35, 38, 42),
				Enum.Material.Metal
			)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.Orientation = Vector3.new(0, 0, 90)
			wheel.CanCollide = false
		end
	end
	local eraDisplays = {
		["1946"] = createEraArch(model, origin, "1946", 2, Color3.fromRGB(255, 153, 73)),
		["1981"] = createEraArch(model, origin, "1981", 28, Color3.fromRGB(96, 195, 143)),
		["2007"] = createEraArch(model, origin, "2007", 54, Color3.fromRGB(72, 172, 235)),
	}
	local eraPrompts = {}
	local artifactModels = {}
	local artifactPrompts = {}
	local artifactLayout = {
		{ id = "ENIAC", x = -24 },
		{ id = "PC", x = 0 },
		{ id = "PHONE", x = 24 },
	}

	local function unlockRide()
		state.museumStage = 2
		setPromptGroup(artifactPrompts, false)
		setPromptGroup(eraPrompts, false)
		state.score += 20
		state.objective =
			"ETAP MUZEUM 2/3 • Wejdź na platformę czasu. Jedź kolejno 1946 → 1981 → 2007 i skanuj każdy przystanek."
		hud(remote, player, title, state.objective, state.score)
		message(remote, player, "Chronologia gotowa. Platforma czasu została odblokowana.", true)
	end

	for _, cfg in ipairs(artifactLayout) do
		local artifact = Rules.GetArtifact(cfg.id)
		local artifactModel = createArtifact(model, cfg.id, origin + Vector3.new(cfg.x, 3, -25))
		artifactModels[cfg.id] = artifactModel
		local root = artifactModel.PrimaryPart
		local pr
		pr = prompt(root, "ZAŁADUJ", artifact.label, function(p)
			if p ~= player or state.museumStage ~= 1 or not entryReady then
				return
			end
			local ok, why = Rules.Load(state.timeline, cfg.id)
			if not ok then
				message(remote, player, why, false)
				return
			end
			moveArtifact(artifactModel, cart.Position + Vector3.new(0, 4, 0))
			pr.Enabled = false
			message(remote, player, artifact.label .. " jest na wózku. Teraz wybierz właściwą epokę.", true)
		end)
		table.insert(artifactPrompts, pr)
	end

	for _, era in ipairs(Rules.Eras) do
		local display = eraDisplays[era]
		local pr
		pr = prompt(display.base, "USTAW EKSPONAT", "Rok " .. era, function(p)
			if p ~= player or state.museumStage ~= 1 or not entryReady then
				return
			end
			local ok, why, id = Rules.Place(state.timeline, era)
			if not ok then
				state.score = math.max(0, state.score - 3)
				pulse(display.base, Color3.fromRGB(215, 67, 62))
				message(remote, player, why .. " Spójrz na wygląd i przeznaczenie urządzenia.", false)
				return
			end
			local artifact = Rules.GetArtifact(id)
			moveArtifact(artifactModels[id], display.position + Vector3.new(0, 1.5, 0))
			lightEra(display, era .. "\n" .. artifact.label)
			pr.Enabled = false
			state.score += 15
			message(remote, player, artifact.label .. " → " .. era .. ". Chronologia pasuje.", true)
			if Rules.AllPlaced(state.timeline) then
				unlockRide()
			else
				state.objective = string.format(
					"ETAP MUZEUM 1/3 • Ustaw eksponaty chronologicznie. Gotowe: %d/3.",
					state.timeline.placedCount
				)
				hud(remote, player, title, state.objective, state.score)
			end
		end)
		table.insert(eraPrompts, pr)
	end

	setPromptGroup(artifactPrompts, false)
	setPromptGroup(eraPrompts, false)

	local entryScanner = part(
		model,
		"TimelineEntryScanner",
		Vector3.new(9, 5, 6),
		origin + Vector3.new(0, 3.5, -42),
		Color3.fromRGB(76, 91, 101),
		Enum.Material.Metal
	)
	entryScanner.CanCollide = false
	entryScanner.CanTouch = false
	local entryText = label(entryScanner, "WEJŚCIE DO MUZEUM\nZESKANUJ BILET")
	local entryPrompt
	entryPrompt = prompt(entryScanner, "ZESKANUJ BILET", "Wejście do muzeum", function(p)
		if p ~= player or entryReady or state.done then
			return
		end
		entryReady = true
		entryPrompt.Enabled = false
		entryScanner.Color = Color3.fromRGB(71, 173, 118)
		entryScanner.Material = Enum.Material.Neon
		entryText.Text = "BILET OK ✓\nMAGAZYN OTWARTY"
		setPromptGroup(artifactPrompts, true)
		setPromptGroup(eraPrompts, true)
		state.objective =
			"ETAP MUZEUM 1/3 • Załaduj eksponat na wózek i ustaw go przy właściwym roku: 1946, 1981 lub 2007."
		hud(remote, player, title, state.objective, state.score)
		message(remote, player, "Bilet potwierdzony. Magazyn eksponatów i stanowiska epok są aktywne.", true)
	end)

	local rail = part(
		model,
		"TimeRail",
		Vector3.new(10, 0.6, 95),
		origin + Vector3.new(22, 0.5, 12),
		Color3.fromRGB(74, 72, 67),
		Enum.Material.Metal
	)
	rail.CanCollide = false
	local platform = part(
		model,
		"TimePlatform",
		Vector3.new(18, 2, 14),
		origin + Vector3.new(22, 2, -18),
		Color3.fromRGB(81, 112, 122),
		Enum.Material.Metal
	)
	local platformText = label(platform, "PLATFORMA CZASU\nZABLOKOWANA", Enum.NormalId.Top)
	local travelPrompt = prompt(platform, "NASTĘPNA EPOKA", "Platforma czasu", nil)
	travelPrompt.Enabled = false
	local scanPrompt = prompt(platform, "SKANUJ", "Eksponat przy przystanku", nil)
	scanPrompt.Enabled = false

	local stopPositions = {
		["1946"] = origin + Vector3.new(22, 2, 2),
		["1981"] = origin + Vector3.new(22, 2, 28),
		["2007"] = origin + Vector3.new(22, 2, 54),
	}
	local currentEra = nil
	local moving = false
	local archivePrompt

	local function unlockArchive()
		state.museumStage = 3
		travelPrompt.Enabled = false
		scanPrompt.Enabled = false
		archivePrompt.Enabled = true
		platformText.Text = "TRASA UKOŃCZONA\n1946 → 1981 → 2007"
		state.score += 25
		state.objective = "ETAP MUZEUM 3/3 • Podejdź do konsoli ARCHIWUM i uruchom całą wystawę."
		hud(remote, player, title, state.objective, state.score)
		message(remote, player, "Trzy epoki połączone. Archiwum główne czeka na uruchomienie.", true)
	end

	travelPrompt.Triggered:Connect(function(p)
		if p ~= player or state.museumStage ~= 2 or moving or scanPrompt.Enabled then
			return
		end
		local era, why = Rules.NextRideEra(state.timeline)
		if not era then
			message(remote, player, why or "Brak kolejnego przystanku.", false)
			return
		end
		moving = true
		travelPrompt.Enabled = false
		platformText.Text = "PODRÓŻ DO " .. era
		followPlatform(player, platform, stopPositions[era])
		local ok = Rules.Arrive(state.timeline, era)
		if ok then
			currentEra = era
			platformText.Text = era .. "\nZESKANUJ EKSPONAT"
			scanPrompt.Enabled = true
			message(remote, player, "Przystanek " .. era .. ". Zeskanuj eksponat, zanim ruszysz dalej.", true)
		end
		moving = false
	end)

	scanPrompt.Triggered:Connect(function(p)
		if p ~= player or state.museumStage ~= 2 or not currentEra then
			return
		end
		local ok, why = Rules.Scan(state.timeline, currentEra)
		if not ok then
			message(remote, player, why, false)
			return
		end
		local id, artifact = Rules.ArtifactForEra(currentEra)
		local display = eraDisplays[currentEra]
		display.light.Brightness = 4
		display.lamp.Color = Color3.fromRGB(255, 225, 120)
		display.signText.Text = currentEra .. "\n" .. artifact.label .. "\nZESKANOWANO"
		state.score += 12
		scanPrompt.Enabled = false
		message(remote, player, currentEra .. ": " .. artifact.detail .. ". Zapisano w osi czasu.", true)
		if Rules.RouteComplete(state.timeline) then
			unlockArchive()
		else
			travelPrompt.Enabled = true
			platformText.Text = currentEra .. " ✓\nNASTĘPNA EPOKA"
		end
	end)
	local archive = part(
		model,
		"ArchiveConsole",
		Vector3.new(24, 10, 5),
		origin + Vector3.new(0, 7, 62),
		Color3.fromRGB(72, 61, 50),
		Enum.Material.Metal
	)
	local archiveText = label(archive, "ARCHIWUM\nZABLOKOWANE")
	for _, side in ipairs({ -1, 1 }) do
		local cabinet = part(
			model,
			side < 0 and "TimelineArchiveCabinet_Left" or "TimelineArchiveCabinet_Right",
			Vector3.new(9, 11, 5),
			origin + Vector3.new(side * 25, 6, 62),
			Color3.fromRGB(76, 64, 52),
			Enum.Material.Wood
		)
		cabinet.CanCollide = false
	end
	local doorLeft = part(
		model,
		"ArchiveDoorLeft",
		Vector3.new(18, 25, 3),
		origin + Vector3.new(-9, 13, 70),
		Color3.fromRGB(80, 67, 55),
		Enum.Material.Wood
	)
	local doorRight = part(
		model,
		"ArchiveDoorRight",
		Vector3.new(18, 25, 3),
		origin + Vector3.new(9, 13, 70),
		Color3.fromRGB(80, 67, 55),
		Enum.Material.Wood
	)
	local timelineBeam = part(
		model,
		"TimelineBeam",
		Vector3.new(62, 0.7, 3),
		origin + Vector3.new(0, 15, 60),
		Color3.fromRGB(80, 72, 63),
		Enum.Material.Metal
	)
	timelineBeam.CanCollide = false

	archivePrompt = prompt(archive, "URUCHOM", "Archiwum muzeum", function(p)
		if p ~= player or state.done then
			return
		end
		if state.museumStage ~= 3 or not Rules.RouteComplete(state.timeline) then
			message(remote, player, "Najpierw przejedź i zeskanuj całą oś czasu.", false)
			return
		end
		state.score += 55
		state.done = true
		archivePrompt.Enabled = false
		archive.Material = Enum.Material.Neon
		archive.Color = Color3.fromRGB(63, 178, 117)
		archiveText.Text = "ARCHIWUM ONLINE\n1946 → 1981 → 2007"
		timelineBeam.Material = Enum.Material.Neon
		timelineBeam.Color = Color3.fromRGB(255, 190, 72)
		glow(timelineBeam, timelineBeam.Color, 3.2, 40)
		TweenService:Create(
			doorLeft,
			TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = doorLeft.Position + Vector3.new(-18, 0, 0) }
		):Play()
		TweenService:Create(
			doorRight,
			TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = doorRight.Position + Vector3.new(18, 0, 0) }
		):Play()
		for _, era in ipairs(Rules.Eras) do
			local display = eraDisplays[era]
			display.base.Material = Enum.Material.Neon
			display.light.Brightness = 4
		end
		message(
			remote,
			player,
			"Muzeum działa! Od komputera zajmującego salę, przez komputer osobisty, po smartfon — rozwój widać jako ciąg zmian.",
			true
		)
	end)
	archivePrompt.Enabled = false
	task.spawn(function()
		while model.Parent and not state.done do
			if state.museumStage == 1 then
				local carrying = state.timeline.carrying
				platformText.Text = carrying and ("WÓZEK: " .. carrying .. "\nUSTAW NA EPOCE")
					or "PLATFORMA CZASU\nNAJPIERW USTAW EKSPONATY"
			elseif state.museumStage == 2 and not moving and not scanPrompt.Enabled then
				travelPrompt.Enabled = true
			end
			task.wait(0.25)
		end
	end)

	state.objective = "ETAP START • Zeskanuj bilet przy wejściu do muzeum."
	hud(remote, player, title, state.objective, state.score)
end

return TimelineMuseum