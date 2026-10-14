local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("ClipchampStudioRules"))

local ClipchampStudio = {}

local C = {
	floor = Color3.fromRGB(27, 30, 37),
	wall = Color3.fromRGB(48, 52, 62),
	dark = Color3.fromRGB(18, 21, 27),
	blue = Color3.fromRGB(77, 152, 236),
	purple = Color3.fromRGB(145, 93, 226),
	green = Color3.fromRGB(67, 214, 119),
	yellow = Color3.fromRGB(240, 188, 62),
	red = Color3.fromRGB(233, 74, 82),
	white = Color3.fromRGB(247, 249, 252),
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

function ClipchampStudio.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		clips = {},
		timelineSlots = {},
	}

	part(model, "ClipchampFloor", Vector3.new(84, 1, 76), origin + Vector3.new(0, -0.5, -7), C.floor, Enum.Material.Metal)
	part(model, "ClipchampBackWall", Vector3.new(84, 20, 2), origin + Vector3.new(0, 10, -45), C.wall, Enum.Material.Metal)
	local sign = part(model, "ClipchampSign", Vector3.new(42, 7, 1), origin + Vector3.new(0, 14, -43.8), C.purple, Enum.Material.Neon)
	label(sign, "CLIPCHAMP STUDIO\nimport • timeline • audio • export", Enum.NormalId.Front, 20)

	local desk = part(model, "ClipchampOperatorDesk", Vector3.new(19, 4, 8), origin + Vector3.new(-24, 2, -31), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local laptop = part(model, "ClipchampLaptop", Vector3.new(8, 5, 3), origin + Vector3.new(-24, 5, -31), C.blue, Enum.Material.Metal)
	laptop:SetAttribute("Important3DPlaceholder", true)
	label(laptop, "START\nIMPORTUJ 3 ZDJĘCIA", Enum.NormalId.Front, 16)
	local speaker = part(model, "ClipchampSpeaker", Vector3.new(6, 8, 5), origin + Vector3.new(24, 4, -31), C.dark, Enum.Material.Metal)
	speaker:SetAttribute("Important3DPlaceholder", true)

	local preview = part(model, "ClipchampPreviewScreen", Vector3.new(26, 14, 2), origin + Vector3.new(12, 10, 8), C.dark, Enum.Material.Metal)
	preview:SetAttribute("Important3DPlaceholder", true)
	local previewText = label(preview, "PREVIEW\nczeka na montaż", Enum.NormalId.Front, 18)

	local mediaPositions = { -20, -7, 6 }
	for index = 1, 3 do
		local clip = part(
			model,
			"ClipchampPhotoClip_" .. index,
			Vector3.new(10, 7, 1),
			origin + Vector3.new(mediaPositions[index], 10, -11),
			index == 1 and C.blue or (index == 2 and C.yellow or C.purple),
			Enum.Material.SmoothPlastic
		)
		clip.Transparency = 0.15
		local txt = label(clip, "ZDJĘCIE " .. index, Enum.NormalId.Front, 17)
		ctx.clips[index] = { part = clip, text = txt }

		local importControl = part(
			model,
			"ClipchampImportControl_" .. index,
			Vector3.new(7, 3, 6),
			origin + Vector3.new(mediaPositions[index], 2, -22),
			clip.Color,
			Enum.Material.Neon
		)
		importControl:SetAttribute("Important3DPlaceholder", true)
		label(importControl, "IMPORT\n" .. index, Enum.NormalId.Top, 16)
		prompt(importControl, "IMPORTUJ", "BIBLIOTEKA MEDIÓW", function(triggerPlayer)
			if triggerPlayer ~= player then return end
			local ok, result = Rules.Apply(ctx.rules, "import", index)
			if ok then
				ctx.state.score += 12
				clip.Material = Enum.Material.Neon
			else
				ctx.state.score = math.max(0, ctx.state.score - 3)
			end
			message(ctx, result.message, ok)
			setHud(ctx, ctx.rules.stage == 1 and "ETAP 1/3 • Zaimportuj wszystkie 3 zdjęcia." or "ETAP 1/3 • Ułóż klipy 1→2→3 na timeline.")
		end)
	end

	local timeline = part(model, "ClipchampTimeline", Vector3.new(48, 2, 12), origin + Vector3.new(-4, 1, 23), C.dark, Enum.Material.Metal)
	label(timeline, "TIMELINE  |  1  →  2  →  3", Enum.NormalId.Top, 18)
	for index = 1, 3 do
		ctx.timelineSlots[index] = origin + Vector3.new(-18 + (index - 1) * 14, 4, 23)
		local timelineControl = part(
			model,
			"ClipchampTimelineControl_" .. index,
			Vector3.new(8, 3, 6),
			origin + Vector3.new(-18 + (index - 1) * 14, 2, 12),
			C.blue,
			Enum.Material.Neon
		)
		timelineControl:SetAttribute("Important3DPlaceholder", true)
		label(timelineControl, "DODAJ KLIP\n" .. index, Enum.NormalId.Top, 16)
		prompt(timelineControl, "NA TIMELINE", "KLIP " .. index, function(triggerPlayer)
			if triggerPlayer ~= player then return end
			local ok, result = Rules.Apply(ctx.rules, "timeline", index)
			if ok then
				ctx.state.score += 14
				TweenService:Create(ctx.clips[index].part, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					Position = ctx.timelineSlots[index],
				}):Play()
			else
				ctx.state.score = math.max(0, ctx.state.score - 3)
			end
			message(ctx, result.message, ok)
			setHud(ctx, #ctx.rules.order < 3 and "ETAP 1/3 • Ułóż klipy 1→2→3 na timeline." or "ETAP 1/3 • Dodaj przejście.")
		end)
	end

	local transition = part(model, "ClipchampTransitionControl", Vector3.new(10, 4, 7), origin + Vector3.new(-21, 2, 35), C.purple, Enum.Material.Metal)
	local audio = part(model, "ClipchampAudioControl", Vector3.new(10, 4, 7), origin + Vector3.new(-9, 2, 35), C.yellow, Enum.Material.Metal)
	local play = part(model, "ClipchampPreviewControl", Vector3.new(10, 4, 7), origin + Vector3.new(3, 2, 35), C.blue, Enum.Material.Metal)
	local exporter = part(model, "ClipchampExportConsole", Vector3.new(12, 7, 9), origin + Vector3.new(20, 3.5, 35), C.dark, Enum.Material.Metal)
	for _, p in ipairs({ transition, audio, play, exporter }) do p:SetAttribute("Important3DPlaceholder", true) end
	label(transition, "PRZEJŚCIE", Enum.NormalId.Top, 16)
	label(audio, "AUDIO", Enum.NormalId.Top, 16)
	label(play, "PLAY", Enum.NormalId.Top, 16)
	local exportText = label(exporter, "EKSPORT\n1080p", Enum.NormalId.Front, 17)

	local function act(action)
		local ok, result = Rules.Apply(ctx.rules, action)
		if ok then ctx.state.score += 16 else ctx.state.score = math.max(0, ctx.state.score - 3) end
		message(ctx, result.message, ok)
		if action == "transition" and ok then
			transition.Color = C.green
			transition.Material = Enum.Material.Neon
		elseif action == "audio" and ok then
			audio.Color = C.green
			audio.Material = Enum.Material.Neon
			speaker.Color = C.green
		elseif action == "preview" and ok then
			play.Color = C.green
			preview.Material = Enum.Material.Neon
			preview.Color = C.blue
			previewText.Text = "PREVIEW\n1 → 2 → 3 • audio"
			task.spawn(function()
				for index = 1, 3 do
					local clip = ctx.clips[index].part
					local old = clip.Color
					clip.Color = C.green
					task.wait(0.25)
					clip.Color = old
				end
			end)
		elseif action == "export" and ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 75
			exporter.Color = C.green
			exporter.Material = Enum.Material.Neon
			exportText.Text = string.format("FILM GOTOWY\n%d%%", Rules.Efficiency(ctx.rules))
			sign.Color = C.green
		end
		if ctx.rules.completed then
			setHud(ctx, "ETAP 2/3 • Film gotowy. Przejdź do RDZENIA MISJI.")
		elseif #ctx.rules.order < 3 then
			setHud(ctx, "ETAP 1/3 • Ułóż klipy 1→2→3 na timeline.")
		elseif not ctx.rules.transition then
			setHud(ctx, "ETAP 1/3 • Dodaj przejście.")
		elseif not ctx.rules.audio then
			setHud(ctx, "ETAP 1/3 • Dodaj ścieżkę audio.")
		elseif not ctx.rules.previewed then
			setHud(ctx, "ETAP 1/3 • Obejrzyj pełny preview.")
		else
			setHud(ctx, "ETAP 1/3 • Eksportuj film.")
		end
	end

	prompt(laptop, "OTWÓRZ PROJEKT", "CLIPCHAMP • START", function(triggerPlayer)
		if triggerPlayer == player then
			message(ctx, "Projekt To się wydarzyło w… otwarty. Zaimportuj trzy zdjęcia.", true)
			setHud(ctx, "ETAP 1/3 • Zaimportuj 3 zdjęcia do biblioteki mediów.")
		end
	end)
	prompt(transition, "DODAJ", "PRZEJŚCIE", function(triggerPlayer) if triggerPlayer == player then act("transition") end end)
	prompt(audio, "DODAJ", "ŚCIEŻKA AUDIO", function(triggerPlayer) if triggerPlayer == player then act("audio") end end)
	prompt(play, "ODTWÓRZ", "PREVIEW FILMU", function(triggerPlayer) if triggerPlayer == player then act("preview") end end)
	prompt(exporter, "EKSPORTUJ", "FILM 1080p", function(triggerPlayer) if triggerPlayer == player then act("export") end end)

	setHud(ctx, "ETAP 1/3 • ZACZNIJ: otwórz projekt Clipchamp i zaimportuj 3 zdjęcia.")
	return ctx
end

return ClipchampStudio
