local TweenService = game:GetService("TweenService")

local MessageLab = {}
local Rules = require(script.Parent:WaitForChild("MessageLabRules"))
local PythonSubset = require(script.Parent:WaitForChild("PythonSubset"))

local C = {
	floor = Color3.fromRGB(217, 211, 191),
	wall = Color3.fromRGB(238, 232, 211),
	ink = Color3.fromRGB(35, 45, 55),
	blue = Color3.fromRGB(64, 145, 220),
	cyan = Color3.fromRGB(70, 205, 215),
	green = Color3.fromRGB(65, 200, 118),
	red = Color3.fromRGB(225, 78, 78),
	orange = Color3.fromRGB(235, 155, 58),
	purple = Color3.fromRGB(150, 104, 210),
	white = Color3.fromRGB(250, 250, 246),
}

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(target, text, face, minSize, textColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = textColor or C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.48
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize or 18
	constraint.MaxTextSize = 34
	constraint.Parent = txt
	return txt
end

local function tween(instance, properties, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		properties
	)
	tw:Play()
	return tw
end

local function setHud(ctx, objective)
	ctx.state.objective = objective
	ctx.remote:FireClient(ctx.player, {
		kind = "hud",
		title = ctx.mission.name or ctx.lesson.topic,
		objective = objective,
		score = ctx.state.score,
	})
end

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function stageInfo(ctx, intro)
	local stage = Rules.Current(ctx.rules)
	if not stage then
		ctx.consoleRemote:FireClient(ctx.player, {
			kind = "output",
			text = "MESSAGE LAB ONLINE • wszystkie trzy komunikaty przetworzone.",
			good = true,
		})
		return
	end

	ctx.consoleRemote:FireClient(ctx.player, {
		kind = "open",
		title = string.format("MESSAGE LAB • ETAP %d/3 • %s", ctx.rules.stage, stage.id),
		challenge = stage.challenge,
		starter = stage.starter,
		output = intro or "Uruchom kod. Wynik print() pojawi się na ekranie stacji.",
	})
end

local function capsule(parent, name, position, color)
	local body = part(parent, name, Vector3.new(3.6, 6, 3.6), position, color, Enum.Material.SmoothPlastic)
	body.Shape = Enum.PartType.Cylinder
	body.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	body.CanCollide = false
	local capA = part(
		parent,
		name .. "_CapA",
		Vector3.new(1, 4.2, 4.2),
		position + Vector3.new(-3, 0, 0),
		C.white,
		Enum.Material.Metal
	)
	capA.Shape = Enum.PartType.Cylinder
	capA.CFrame = CFrame.new(capA.Position) * CFrame.Angles(0, 0, math.rad(90))
	capA.CanCollide = false
	local capB = capA:Clone()
	capB.Name = name .. "_CapB"
	capB.Position = position + Vector3.new(3, 0, 0)
	capB.Parent = parent
	return body
end

local function resetCapsule(ctx)
	ctx.capsule.Transparency = 0
	ctx.capsule.Position = ctx.capsuleStart
	ctx.capsule.Color = C.orange
	ctx.preview.Text = "WEJŚCIE\n" .. (Rules.Current(ctx.rules) and Rules.Current(ctx.rules).input or "gotowe")
	ctx.preview.TextColor3 = C.white
end

local function animateResult(ctx, ok, result)
	local stageIndex = ctx.rules.stage
	if ok then
		stageIndex -= 1
	end
	local target = ctx.stationTargets[math.clamp(stageIndex, 1, 3)]
	tween(ctx.capsule, { Position = target }, 0.22).Completed:Wait()
	ctx.capsule.Color = ok and C.green or C.red
	local lines = result.values or {}
	if #lines == 0 then
		ctx.preview.Text = ok and "OK" or "BRAK WYJŚCIA"
	else
		ctx.preview.Text = "WYJŚCIE\n" .. table.concat(lines, "\n")
	end
	ctx.preview.TextColor3 = ok and C.green or C.red
end

local function lightStage(ctx)
	for index, lamp in ipairs(ctx.stageLamps) do
		local done = index < ctx.rules.stage or ctx.rules.completed
		lamp.Color = done and C.green or C.orange
		lamp.Material = done and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
	if ctx.stageMonitorText then
		if ctx.rules.completed then
			ctx.stageMonitorText.Text = "ETAPY\n3/3 OK"
		else
			local stage = Rules.Current(ctx.rules)
			ctx.stageMonitorText.Text = string.format("ETAP %d/3\n%s", ctx.rules.stage, stage and stage.id or "GOTOWE")
		end
	end
	if ctx.pipelineRack then
		ctx.pipelineRack.Color = ctx.rules.completed and C.green or (ctx.rules.stage > 1 and C.cyan or C.ink)
		ctx.pipelineRack.Material = ctx.rules.stage > 1 and Enum.Material.Neon or Enum.Material.Metal
	end
end

function MessageLab.Build(model, origin, player, lesson, mission, remote, state, accent, consoleRemote)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		consoleRemote = consoleRemote,
		rules = Rules.NewState(),
		stageLamps = {},
		stationTargets = {},
	}

	part(
		model,
		"MessageLabFloor",
		Vector3.new(78, 1, 68),
		origin + Vector3.new(0, -0.5, -8),
		C.floor,
		Enum.Material.Concrete
	)
	part(
		model,
		"MessageLabBackWall",
		Vector3.new(78, 20, 2),
		origin + Vector3.new(0, 10, -41),
		C.wall,
		Enum.Material.Brick
	)
	local header = part(
		model,
		"MessageLabHeader",
		Vector3.new(42, 8, 1),
		origin + Vector3.new(0, 14, -39.8),
		C.blue,
		Enum.Material.SmoothPlastic
	)
	label(header, "MESSAGE LAB\nnapisy w Pythonie", Enum.NormalId.Front, 24)

	-- Pneumatic message tube creates a silhouette unlike the previous rail/factory worlds.
	for index = 0, 6 do
		local tube = part(
			model,
			"MessageTube_" .. index,
			Vector3.new(6, 6, 6),
			origin + Vector3.new(-27 + index * 9, 5, -10),
			index % 2 == 0 and C.cyan or C.blue,
			Enum.Material.Glass
		)
		tube.Shape = Enum.PartType.Ball
		tube.Transparency = 0.32
		tube.CanCollide = false
	end

	local stationDefs = {
		{ id = "CLEAN", x = -22, color = C.cyan, subtitle = "strip() + lower()" },
		{ id = "REPLACE", x = 0, color = C.purple, subtitle = "replace()" },
		{ id = "SLICE", x = 22, color = C.blue, subtitle = "[a:b] + len()" },
	}
	for index, def in ipairs(stationDefs) do
		local base = part(
			model,
			"MessageStation_" .. def.id,
			Vector3.new(17, 3, 15),
			origin + Vector3.new(def.x, 1.5, -22),
			C.white,
			Enum.Material.SmoothPlastic
		)
		local archLeft = part(
			model,
			def.id .. "_ArchLeft",
			Vector3.new(2, 11, 2),
			origin + Vector3.new(def.x - 6, 7, -22),
			def.color,
			Enum.Material.Neon
		)
		local archRight = part(
			model,
			def.id .. "_ArchRight",
			Vector3.new(2, 11, 2),
			origin + Vector3.new(def.x + 6, 7, -22),
			def.color,
			Enum.Material.Neon
		)
		local archTop = part(
			model,
			def.id .. "_ArchTop",
			Vector3.new(14, 2, 2),
			origin + Vector3.new(def.x, 12, -22),
			def.color,
			Enum.Material.Neon
		)
		archLeft.CanCollide = false
		archRight.CanCollide = false
		archTop.CanCollide = false
		local sign = part(
			model,
			def.id .. "_Sign",
			Vector3.new(13, 5, 1),
			origin + Vector3.new(def.x, 8.5, -29.5),
			C.ink,
			Enum.Material.SmoothPlastic
		)
		label(sign, def.id .. "\n" .. def.subtitle, Enum.NormalId.Front, 18)
		local lamp = part(
			model,
			"MessageStageLamp_" .. index,
			Vector3.new(4, 4, 2),
			origin + Vector3.new(def.x, 4, -29),
			C.orange,
			Enum.Material.SmoothPlastic
		)
		lamp.CanCollide = false
		table.insert(ctx.stageLamps, lamp)
		table.insert(ctx.stationTargets, origin + Vector3.new(def.x, 5, -10))
		if index == 1 then
			for brush = -1, 1, 2 do
				local roller = part(
					model,
					"CleanBrush_" .. tostring(brush),
					Vector3.new(3, 8, 3),
					origin + Vector3.new(def.x + brush * 3.5, 5, -22),
					C.cyan,
					Enum.Material.Fabric
				)
				roller.Shape = Enum.PartType.Cylinder
				roller.CFrame = CFrame.new(roller.Position) * CFrame.Angles(math.rad(90), 0, 0)
				roller.CanCollide = false
			end
		elseif index == 2 then
			for lane = -1, 1, 2 do
				local pipe = part(
					model,
					"ReplacePipe_" .. tostring(lane),
					Vector3.new(3, 9, 3),
					origin + Vector3.new(def.x + lane * 3.2, 5, -22),
					C.purple,
					Enum.Material.Metal
				)
				pipe.Shape = Enum.PartType.Cylinder
				pipe.CanCollide = false
			end
		else
			local laser = part(
				model,
				"SliceLaser",
				Vector3.new(12, 0.45, 0.45),
				origin + Vector3.new(def.x, 6, -22),
				C.red,
				Enum.Material.Neon
			)
			laser.CanCollide = false
		end
	end

	local cleanScanner = part(
		model,
		"MessageCleanScanner",
		Vector3.new(7, 5, 6),
		origin + Vector3.new(-22, 2.5, -32),
		C.cyan,
		Enum.Material.Metal
	)
	cleanScanner.CanCollide = false
	local replaceConsole = part(
		model,
		"MessageReplaceConsole",
		Vector3.new(8, 5, 6),
		origin + Vector3.new(0, 2.5, -32),
		C.purple,
		Enum.Material.Metal
	)
	replaceConsole.CanCollide = false
	local sliceScanner = part(
		model,
		"MessageSliceScanner",
		Vector3.new(7, 5, 6),
		origin + Vector3.new(22, 2.5, -32),
		C.blue,
		Enum.Material.Metal
	)
	sliceScanner.CanCollide = false

	local previewBoard = part(
		model,
		"MessagePreviewBoard",
		Vector3.new(30, 11, 1),
		origin + Vector3.new(-20, 11, 16),
		C.ink,
		Enum.Material.SmoothPlastic
	)
	ctx.preview = label(previewBoard, "WEJŚCIE\n  SERVER-07  ", Enum.NormalId.Front, 20)
	local previewMonitor = part(
		model,
		"MessagePreviewMonitor",
		Vector3.new(9, 6, 3),
		origin + Vector3.new(-20, 3, 20),
		C.ink,
		Enum.Material.Metal
	)
	previewMonitor.CanCollide = false
	previewMonitor.CanTouch = false

	local operatorDesk = part(
		model,
		"MessageOperatorDesk",
		Vector3.new(16, 4, 8),
		origin + Vector3.new(20, 2, 29),
		C.wall,
		Enum.Material.WoodPlanks
	)
	operatorDesk.CanCollide = false
	operatorDesk.CanTouch = false
	local operatorKeyboard = part(
		model,
		"MessageOperatorKeyboard",
		Vector3.new(6, 0.8, 2.4),
		origin + Vector3.new(18, 4.4, 28),
		C.ink,
		Enum.Material.Metal
	)
	operatorKeyboard.CanCollide = false
	operatorKeyboard.CanTouch = false
	local operatorMouse = part(
		model,
		"MessageOperatorMouse",
		Vector3.new(2, 0.9, 1.6),
		origin + Vector3.new(25, 4.45, 28),
		C.ink,
		Enum.Material.Metal
	)
	operatorMouse.CanCollide = false
	operatorMouse.CanTouch = false

	local stageMonitor = part(
		model,
		"MessageStageMonitor",
		Vector3.new(9, 6, 3),
		origin + Vector3.new(8, 7, 28),
		C.ink,
		Enum.Material.Metal
	)
	stageMonitor.CanCollide = false
	stageMonitor.CanTouch = false
	ctx.stageMonitorText = label(stageMonitor, "ETAP 1/3\nCLEAN", Enum.NormalId.Front, 18)

	ctx.pipelineRack = part(
		model,
		"MessagePipelineRack",
		Vector3.new(7, 10, 5),
		origin + Vector3.new(31, 5, 20),
		C.ink,
		Enum.Material.Metal
	)
	ctx.pipelineRack.CanCollide = false
	ctx.pipelineRack.CanTouch = false

	local archiveMonitor = part(
		model,
		"MessageArchiveMonitor",
		Vector3.new(9, 6, 3),
		origin + Vector3.new(34, 7, 29),
		C.ink,
		Enum.Material.Metal
	)
	archiveMonitor.CanCollide = false
	archiveMonitor.CanTouch = false
	ctx.archiveMonitor = archiveMonitor
	ctx.archiveMonitorText = label(archiveMonitor, "ARCHIWUM\nLOCKED", Enum.NormalId.Front, 18)

	local recipeBoard = part(
		model,
		"MessageRecipeBoard",
		Vector3.new(30, 11, 1),
		origin + Vector3.new(20, 11, 16),
		C.ink,
		Enum.Material.SmoothPlastic
	)
	label(recipeBoard, "PIPELINE\n1 CLEAN • 2 REPLACE • 3 SLICE\nKOD → LIVE PREVIEW", Enum.NormalId.Front, 19)

	ctx.capsuleStart = origin + Vector3.new(-33, 5, -10)
	ctx.capsule = capsule(model, "MessageCapsule", ctx.capsuleStart, C.orange)

	local finalRing = part(
		model,
		"MessageLabFinalRing",
		Vector3.new(12, 12, 12),
		origin + Vector3.new(0, 8, 27),
		C.red,
		Enum.Material.Glass
	)
	finalRing.Shape = Enum.PartType.Ball
	finalRing.Transparency = 0.35
	finalRing.CanCollide = false
	ctx.finalRing = finalRing
	ctx.finalBoard = label(finalRing, "LAB OFFLINE\n0/3", Enum.NormalId.Front, 19)

	lightStage(ctx)
	stageInfo(ctx)
	setHud(ctx, "ETAP 1/3 • Oczyść komunikat: strip() + lower() → server-07.")
	return ctx
end

function MessageLab.Reset(ctx)
	resetCapsule(ctx)
	stageInfo(ctx, "Stacja zresetowana. Etap pozostaje ten sam — popraw kod i uruchom ponownie.")
end

function MessageLab.Execute(ctx, source)
	local plan, parseError = PythonSubset.Parse(source)
	if not plan then
		ctx.rules.errors += 1
		ctx.preview.Text = "BŁĄD SKŁADNI"
		ctx.preview.TextColor3 = C.red
		ctx.consoleRemote:FireClient(ctx.player, {
			kind = "output",
			text = "Błąd składni: " .. parseError,
			good = false,
		})
		message(ctx, "DEBUG NAPISU • " .. parseError, false)
		return false
	end

	resetCapsule(ctx)
	local ok, result = Rules.Analyze(ctx.rules, source, plan)
	animateResult(ctx, ok, result)

	if not ok then
		ctx.state.score = math.max(0, ctx.state.score - 5)
		ctx.consoleRemote:FireClient(ctx.player, { kind = "output", text = result.message, good = false })
		message(ctx, result.message, false)
		setHud(ctx, string.format("ETAP %d/3 • Popraw kod bez restartu misji.", ctx.rules.stage))
		return false
	end

	ctx.state.score += 45
	lightStage(ctx)
	ctx.consoleRemote:FireClient(ctx.player, { kind = "output", text = result.message, good = true })

	if result.completed then
		ctx.state.done = true
		ctx.state.score += 80
		ctx.finalRing.Color = C.green
		ctx.finalRing.Material = Enum.Material.Neon
		ctx.finalRing.Transparency = 0.08
		ctx.finalBoard.Text = "MESSAGE LAB ONLINE\n3/3"
		ctx.archiveMonitor.Color = C.green
		ctx.archiveMonitor.Material = Enum.Material.Neon
		ctx.archiveMonitorText.Text = "ARCHIWUM\nREADY"
		message(
			ctx,
			string.format("Wszystkie komunikaty gotowe • efektywność %d%%.", Rules.Efficiency(ctx.rules)),
			true
		)
		ctx.consoleRemote:FireClient(ctx.player, {
			kind = "output",
			text = "SUKCES • Message Lab online. Rdzeń misji jest gotowy.",
			good = true,
		})
		setHud(ctx, "ETAP 2/3 • Message Lab online. Przejdź do świecącego RDZENIA MISJI.")
		return true
	end

	local nextStage = Rules.Current(ctx.rules)
	message(ctx, result.message .. " Następna stacja.", true)
	stageInfo(ctx, "Poprzednia stacja działa. Zmodyfikuj starter dla kolejnego komunikatu.")
	setHud(ctx, string.format("ETAP %d/3 • %s", ctx.rules.stage, nextStage.challenge))
	return true
end

return MessageLab