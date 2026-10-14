local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("StopMotionStudioRules"))

local StopMotionStudio = {}

local C = {
	floor = Color3.fromRGB(78, 83, 90),
	wall = Color3.fromRGB(40, 44, 52),
	dark = Color3.fromRGB(24, 28, 34),
	blue = Color3.fromRGB(70, 160, 235),
	yellow = Color3.fromRGB(244, 192, 66),
	green = Color3.fromRGB(73, 220, 125),
	red = Color3.fromRGB(231, 78, 78),
	white = Color3.fromRGB(245, 247, 250),
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

local function label(target, text, face, minSize)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34
	gui.Parent = target
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.38
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = minSize or 18
	limit.MaxTextSize = 32
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = objectText
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.HoldDuration = 0.08
	p.Parent = target
	p.Triggered:Connect(callback)
	return p
end

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, { kind = "message", text = text, good = good })
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

function StopMotionStudio.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		thumbnails = {},
	}

	part(model, "StopMotionFloor", Vector3.new(80, 1, 74), origin + Vector3.new(0, -0.5, -7), C.floor, Enum.Material.Concrete)
	part(model, "StopMotionBackWall", Vector3.new(80, 19, 2), origin + Vector3.new(0, 9.5, -44), C.wall, Enum.Material.Metal)
	local sign = part(model, "StopMotionSign", Vector3.new(42, 7, 1), origin + Vector3.new(0, 14, -42.8), C.blue, Enum.Material.Neon)
	label(sign, "STOP‑MOTION STUDIO\nmały ruch • zdjęcie • mały ruch", Enum.NormalId.Front, 20)

	local desk = part(model, "StopMotionOperatorDesk", Vector3.new(18, 4, 8), origin + Vector3.new(-22, 2, -30), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local camera = part(model, "StopMotionCamera", Vector3.new(8, 7, 6), origin + Vector3.new(-22, 5, -38), C.blue, Enum.Material.Metal)
	camera:SetAttribute("Important3DPlaceholder", true)
	label(camera, "START\nKLATKA 1", Enum.NormalId.Front, 18)

	local robot = part(model, "StopMotionRobot", Vector3.new(7, 9, 6), origin + Vector3.new(0, 4.5, -14), C.yellow, Enum.Material.Metal)
	robot:SetAttribute("Important3DPlaceholder", true)

	local stage = part(model, "StopMotionStage", Vector3.new(34, 1, 22), origin + Vector3.new(0, 0.5, -14), C.dark, Enum.Material.SmoothPlastic)
	local track = part(model, "StopMotionTrack", Vector3.new(28, 0.4, 3), origin + Vector3.new(0, 1.2, -14), C.blue, Enum.Material.Neon)
	track.CanCollide = false

	for index = 1, 4 do
		local thumb = part(
			model,
			"StopMotionThumbnail_" .. index,
			Vector3.new(10, 7, 1),
			origin + Vector3.new(-18 + (index - 1) * 12, 11, 2),
			C.dark,
			Enum.Material.Metal
		)
		local txt = label(thumb, "KLATKA " .. index .. "\n—", Enum.NormalId.Front, 17)
		ctx.thumbnails[index] = { part = thumb, text = txt }
	end

	local shutterControls = {}
	for index = 1, 4 do
		local button = part(
			model,
			"StopMotionShutterControl_" .. index,
			Vector3.new(6, 3, 6),
			origin + Vector3.new(-18 + (index - 1) * 12, 2, -28),
			index == 1 and C.green or C.dark,
			Enum.Material.Neon
		)
		button:SetAttribute("Important3DPlaceholder", true)
		label(button, "KLATKA\n" .. index, Enum.NormalId.Top, 16)
		shutterControls[index] = button
	end

	local timing = part(model, "StopMotionTimingControl", Vector3.new(10, 4, 7), origin + Vector3.new(-16, 2, 17), C.yellow, Enum.Material.Metal)
	timing:SetAttribute("Important3DPlaceholder", true)
	label(timing, "TEMPO\n4 KL./S", Enum.NormalId.Top, 17)

	local preview = part(model, "StopMotionPreviewScreen", Vector3.new(22, 12, 2), origin + Vector3.new(5, 9, 18), C.dark, Enum.Material.Metal)
	preview:SetAttribute("Important3DPlaceholder", true)
	local previewText = label(preview, "PODGLĄD\nczeka na 4 klatki", Enum.NormalId.Front, 18)

	local export = part(model, "StopMotionExportConsole", Vector3.new(10, 6, 8), origin + Vector3.new(24, 3, 18), C.dark, Enum.Material.Metal)
	export:SetAttribute("Important3DPlaceholder", true)
	local exportText = label(export, "EKSPORT\nGIF/MP4", Enum.NormalId.Front, 17)

	local function updateHud()
		if ctx.rules.completed then
			setHud(ctx, "ETAP 2/3 • Animacja gotowa. Przejdź do RDZENIA MISJI.")
		elseif ctx.rules.stage == 1 then
			setHud(ctx, string.format("ETAP 1/3 • Zrób klatkę %d/4 w prawidłowej kolejności.", ctx.rules.nextFrame))
		elseif not ctx.rules.timing then
			setHud(ctx, "ETAP 1/3 • Ustaw tempo 4 kl./s.")
		elseif not ctx.rules.previewed then
			setHud(ctx, "ETAP 1/3 • Uruchom PODGLĄD animacji.")
		else
			setHud(ctx, "ETAP 1/3 • Wyeksportuj gotową animację.")
		end
	end

	local function animatePose(frameNo)
		local target = origin + Vector3.new(-9 + (frameNo - 1) * 6, 4.5, -14)
		TweenService:Create(robot, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { Position = target }):Play()
	end

	local function act(action, value)
		local ok, result = Rules.Apply(ctx.rules, action, value)
		if ok then
			ctx.state.score += 16
			message(ctx, result.message, true)
		else
			ctx.state.score = math.max(0, ctx.state.score - 3)
			message(ctx, result.message, false)
		end
		if action == "capture" and ok then
			local thumb = ctx.thumbnails[value]
			thumb.part.Color = C.blue
			thumb.part.Material = Enum.Material.Neon
			thumb.text.Text = "KLATKA " .. value .. "\nZAPISANA"
			animatePose(value + 1)
		elseif action == "timing" and ok then
			timing.Color = C.green
			timing.Material = Enum.Material.Neon
		elseif action == "preview" and ok then
			preview.Material = Enum.Material.Neon
			preview.Color = C.blue
			previewText.Text = "PODGLĄD\n1 → 2 → 3 → 4"
			task.spawn(function()
				for cycle = 1, 2 do
					for frameNo = 1, 4 do
						animatePose(frameNo)
						task.wait(0.16)
					end
				end
			end)
		elseif action == "export" and ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 70
			export.Material = Enum.Material.Neon
			export.Color = C.green
			exportText.Text = string.format("EKSPORT GOTOWY\n%d%%", Rules.Efficiency(ctx.rules))
			sign.Color = C.green
		end
		updateHud()
	end

	for index, button in ipairs(shutterControls) do
		prompt(button, "ZRÓB ZDJĘCIE", "KLATKA " .. index, function(triggerPlayer)
			if triggerPlayer == player then act("capture", index) end
		end)
	end
	prompt(timing, "USTAW 4 KL./S", "TEMPO ANIMACJI", function(triggerPlayer)
		if triggerPlayer == player then act("timing", "medium") end
	end)
	prompt(preview, "ODTWÓRZ", "PODGLĄD STOP‑MOTION", function(triggerPlayer)
		if triggerPlayer == player then act("preview") end
	end)
	prompt(export, "EKSPORTUJ", "FINALNA ANIMACJA", function(triggerPlayer)
		if triggerPlayer == player then act("export") end
	end)

	updateHud()
	return ctx
end

return StopMotionStudio
