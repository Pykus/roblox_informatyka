local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("KlekiStudioRules"))

local KlekiStudio = {}

local C = {
	floor = Color3.fromRGB(238, 232, 218),
	wall = Color3.fromRGB(214, 202, 185),
	dark = Color3.fromRGB(39, 46, 54),
	cyan = Color3.fromRGB(43, 210, 218),
	magenta = Color3.fromRGB(239, 84, 171),
	yellow = Color3.fromRGB(245, 194, 66),
	green = Color3.fromRGB(75, 220, 125),
	red = Color3.fromRGB(232, 76, 76),
	white = Color3.fromRGB(250, 250, 248),
	ink = Color3.fromRGB(26, 31, 37),
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

local function pulse(target, color)
	local original = target.Color
	target.Color = color
	TweenService:Create(
		target,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Color = original }
	):Play()
end

local function makeStroke(model, name, position, rotation, color)
	local stroke = part(model, name, Vector3.new(13, 0.35, 1.2), position, color, Enum.Material.Neon)
	stroke.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
	stroke.Transparency = 1
	stroke.CanCollide = false
	return stroke
end

function KlekiStudio.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		baseVisuals = {},
		overlayVisuals = {},
	}

	part(model, "KlekiStudioFloor", Vector3.new(78, 1, 72), origin + Vector3.new(0, -0.5, -8), C.floor, Enum.Material.WoodPlanks)
	part(model, "KlekiStudioBackWall", Vector3.new(78, 18, 2), origin + Vector3.new(0, 9, -43), C.wall, Enum.Material.Brick)

	local sign = part(model, "KlekiStudioSign", Vector3.new(34, 7, 1), origin + Vector3.new(0, 13, -41.8), C.dark, Enum.Material.Metal)
	label(sign, "KLEKI STUDIO\nwarstwy • kolor • eksport", Enum.NormalId.Front, 20)

	local desk = part(model, "KlekiOperatorDesk", Vector3.new(18, 4, 8), origin + Vector3.new(-18, 2, -31), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local tablet = part(model, "KlekiArtistTablet", Vector3.new(8, 1, 6), origin + Vector3.new(-18, 5, -31), C.cyan, Enum.Material.Glass)
	tablet:SetAttribute("Important3DPlaceholder", true)
	local tabletText = label(tablet, "START\nPĘDZEL", Enum.NormalId.Top, 18)

	local monitor = part(model, "KlekiPreviewMonitor", Vector3.new(12, 8, 2), origin + Vector3.new(17, 8, -30), C.dark, Enum.Material.Metal)
	monitor:SetAttribute("Important3DPlaceholder", true)
	local monitorText = label(monitor, "PODGLĄD KLEKI\nwarstwa 1", Enum.NormalId.Front, 18)

	local canvasFrame = part(model, "KlekiCanvasFrame", Vector3.new(36, 18, 1), origin + Vector3.new(0, 9, -8), C.dark, Enum.Material.Wood)
	local canvas = part(model, "KlekiCanvas", Vector3.new(32, 14, 0.55), origin + Vector3.new(0, 9, -7.4), C.white, Enum.Material.SmoothPlastic)
	canvas.CanCollide = false

	local cyanControl = part(model, "KlekiPaletteControl_Cyan", Vector3.new(5, 3, 5), origin + Vector3.new(-12, 2, -20), C.cyan, Enum.Material.Neon)
	local magentaControl = part(model, "KlekiPaletteControl_Magenta", Vector3.new(5, 3, 5), origin + Vector3.new(-5, 2, -20), C.magenta, Enum.Material.Neon)
	cyanControl:SetAttribute("Important3DPlaceholder", true)
	magentaControl:SetAttribute("Important3DPlaceholder", true)
	label(cyanControl, "TURKUS", Enum.NormalId.Top, 16)
	label(magentaControl, "RÓŻ", Enum.NormalId.Top, 16)

	local strokeControl = part(model, "KlekiStrokeControl", Vector3.new(8, 3, 5), origin + Vector3.new(4, 2, -20), C.yellow, Enum.Material.Neon)
	strokeControl:SetAttribute("Important3DPlaceholder", true)
	label(strokeControl, "RYSUJ", Enum.NormalId.Top, 18)

	local layerControl = part(model, "KlekiLayerControl", Vector3.new(7, 3, 5), origin + Vector3.new(13, 2, -20), C.dark, Enum.Material.Metal)
	layerControl:SetAttribute("Important3DPlaceholder", true)
	label(layerControl, "+ WARSTWA", Enum.NormalId.Top, 16)

	local visibilityControl = part(model, "KlekiVisibilityControl", Vector3.new(8, 3, 5), origin + Vector3.new(22, 2, -20), C.dark, Enum.Material.Metal)
	visibilityControl:SetAttribute("Important3DPlaceholder", true)
	label(visibilityControl, "OKO\nON/OFF", Enum.NormalId.Top, 16)

	local printer = part(model, "KlekiExportPrinter", Vector3.new(10, 7, 8), origin + Vector3.new(0, 3.5, 20), C.dark, Enum.Material.Metal)
	printer:SetAttribute("Important3DPlaceholder", true)
	local printerText = label(printer, "EKSPORT\nPNG", Enum.NormalId.Front, 18)

	ctx.baseVisuals = {
		makeStroke(model, "KlekiBaseStroke_1", origin + Vector3.new(-6, 10, -6.9), -20, C.cyan),
		makeStroke(model, "KlekiBaseStroke_2", origin + Vector3.new(4, 8, -6.85), 18, C.cyan),
		makeStroke(model, "KlekiBaseStroke_3", origin + Vector3.new(1, 12, -6.8), 4, C.cyan),
	}
	ctx.overlayVisuals = {
		makeStroke(model, "KlekiOverlayStroke_1", origin + Vector3.new(-2, 7, -6.65), 60, C.magenta),
		makeStroke(model, "KlekiOverlayStroke_2", origin + Vector3.new(7, 11, -6.6), -52, C.magenta),
	}

	local function updateHud()
		if ctx.rules.completed then
			setHud(ctx, "ETAP 2/3 • Grafika gotowa. Przejdź do RDZENIA MISJI.")
		elseif ctx.rules.stage == 1 then
			if ctx.rules.tool ~= "brush" then
				setHud(ctx, "ETAP 1/3 • ZACZNIJ: podejdź do TABLETU i wybierz PĘDZEL.")
			elseif ctx.rules.color ~= "cyan" then
				setHud(ctx, "ETAP 1/3 • Wybierz turkusowy kolor.")
			else
				setHud(ctx, string.format("ETAP 1/3 • Narysuj szkic: %d/3 kreski.", ctx.rules.baseStrokes))
			end
		else
			if not ctx.rules.layerCreated then
				setHud(ctx, "ETAP 1/3 • Dodaj WARSTWĘ 2.")
			elseif ctx.rules.color ~= "magenta" then
				setHud(ctx, "ETAP 1/3 • Ustaw różowy kolor dla WARSTWY 2.")
			elseif ctx.rules.overlayStrokes < 2 then
				setHud(ctx, string.format("ETAP 1/3 • Warstwa 2: %d/2 kreski.", ctx.rules.overlayStrokes))
			elseif not ctx.rules.visibilityChecked then
				setHud(ctx, "ETAP 1/3 • Użyj OKO ON/OFF i porównaj warstwy.")
			else
				setHud(ctx, "ETAP 1/3 • Wyeksportuj pracę w drukarce/eksporcie PNG.")
			end
		end
	end

	local function act(action, value)
		local ok, result = Rules.Apply(ctx.rules, action, value)
		if ok then
			ctx.state.score += 15
			message(ctx, result.message, true)
		else
			ctx.state.score = math.max(0, ctx.state.score - 3)
			message(ctx, result.message, false)
		end
		if action == "stroke" and ok then
			if ctx.rules.stage == 1 then
				local index = math.min(ctx.rules.baseStrokes, #ctx.baseVisuals)
				ctx.baseVisuals[index].Transparency = 0
			else
				local index = math.min(ctx.rules.overlayStrokes, #ctx.overlayVisuals)
				if index > 0 then
					ctx.overlayVisuals[index].Transparency = 0
				end
			end
			pulse(canvasFrame, ok and C.green or C.red)
		elseif action == "visibility" and ok then
			for _, stroke in ipairs(ctx.overlayVisuals) do
				stroke.Transparency = stroke.Transparency == 1 and 0 or 1
			end
			task.delay(0.45, function()
				for _, stroke in ipairs(ctx.overlayVisuals) do
					stroke.Transparency = 0
				end
			end)
			monitorText.Text = "PODGLĄD KLEKI\nWARSTWA 2 sprawdzona"
		elseif action == "export" and ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 70
			canvasFrame.Material = Enum.Material.Neon
			canvasFrame.Color = C.green
			printer.Material = Enum.Material.Neon
			printer.Color = C.green
			printerText.Text = "EKSPORT GOTOWY\n2 WARSTWY"
			monitorText.Text = string.format("KLEKI • GOTOWE\nEFEKTYWNOŚĆ %d%%", Rules.Efficiency(ctx.rules))
		end
		updateHud()
	end

	prompt(tablet, "WYBIERZ PĘDZEL", "TABLET KLEKI • START", function(triggerPlayer)
		if triggerPlayer == player then
			tabletText.Text = "PĘDZEL\nAKTYWNY"
			act("tool", "brush")
		end
	end)
	prompt(cyanControl, "USTAW TURKUS", "PALETA KLEKI", function(triggerPlayer)
		if triggerPlayer == player then act("color", "cyan") end
	end)
	prompt(magentaControl, "USTAW RÓŻ", "PALETA KLEKI", function(triggerPlayer)
		if triggerPlayer == player then act("color", "magenta") end
	end)
	prompt(strokeControl, "NAMALUJ KRESKĘ", "PŁÓTNO KLEKI", function(triggerPlayer)
		if triggerPlayer == player then act("stroke") end
	end)
	prompt(layerControl, "DODAJ WARSTWĘ", "PANEL WARSTW", function(triggerPlayer)
		if triggerPlayer == player then act("layer") end
	end)
	prompt(visibilityControl, "PRZEŁĄCZ WIDOCZNOŚĆ", "OKO WARSTWY", function(triggerPlayer)
		if triggerPlayer == player then act("visibility") end
	end)
	prompt(printer, "EKSPORTUJ", "EKSPORT PNG", function(triggerPlayer)
		if triggerPlayer == player then act("export") end
	end)

	updateHud()
	return ctx
end

return KlekiStudio
