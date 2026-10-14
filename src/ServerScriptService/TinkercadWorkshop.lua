local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("TinkercadWorkshopRules"))

local TinkercadWorkshop = {}

local C = {
	floor = Color3.fromRGB(220, 226, 231),
	wall = Color3.fromRGB(178, 190, 202),
	dark = Color3.fromRGB(39, 47, 58),
	orange = Color3.fromRGB(244, 142, 52),
	blue = Color3.fromRGB(61, 160, 232),
	green = Color3.fromRGB(70, 217, 122),
	purple = Color3.fromRGB(151, 95, 220),
	white = Color3.fromRGB(247, 250, 252),
	red = Color3.fromRGB(230, 75, 75),
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

function TinkercadWorkshop.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		shapes = {},
	}

	part(model, "TinkercadFloor", Vector3.new(82, 1, 74), origin + Vector3.new(0, -0.5, -7), C.floor, Enum.Material.SmoothPlastic)
	part(model, "TinkercadBackWall", Vector3.new(82, 19, 2), origin + Vector3.new(0, 9.5, -44), C.wall, Enum.Material.Brick)
	local sign = part(model, "TinkercadSign", Vector3.new(42, 7, 1), origin + Vector3.new(0, 14, -42.8), C.orange, Enum.Material.Neon)
	label(sign, "TINKERCAD WORKSHOP\nprymitywy → wyrównanie → grupa", Enum.NormalId.Front, 20)

	local desk = part(model, "TinkercadOperatorDesk", Vector3.new(18, 4, 8), origin + Vector3.new(-22, 2, -31), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local laptop = part(model, "TinkercadLaptop", Vector3.new(8, 5, 3), origin + Vector3.new(-22, 5, -31), C.blue, Enum.Material.Metal)
	laptop:SetAttribute("Important3DPlaceholder", true)
	label(laptop, "START\nDODAJ 3 BRYŁY", Enum.NormalId.Front, 17)

	local rack = part(model, "TinkercadShapeRack", Vector3.new(22, 11, 5), origin + Vector3.new(22, 5.5, -31), C.dark, Enum.Material.Metal)
	rack:SetAttribute("Important3DPlaceholder", true)

	local plate = part(model, "TinkercadBuildPlate", Vector3.new(34, 1, 30), origin + Vector3.new(0, 0.5, -7), Color3.fromRGB(90, 102, 112), Enum.Material.Metal)
	label(plate, "POLE ROBOCZE", Enum.NormalId.Top, 18)

	local boxShape = part(model, "TinkercadPrimitiveBox", Vector3.new(8, 6, 8), origin + Vector3.new(-8, 4, -7), C.orange, Enum.Material.SmoothPlastic)
	boxShape.Transparency = 1
	local cylinderShape = part(model, "TinkercadPrimitiveCylinder", Vector3.new(6, 8, 6), origin + Vector3.new(0, 5, -7), C.blue, Enum.Material.SmoothPlastic)
	cylinderShape.Shape = Enum.PartType.Cylinder
	cylinderShape.Transparency = 1
	local wedgeShape = Instance.new("WedgePart")
	wedgeShape.Name = "TinkercadPrimitiveWedge"
	wedgeShape.Anchored = true
	wedgeShape.Size = Vector3.new(8, 6, 8)
	wedgeShape.Position = origin + Vector3.new(8, 4, -7)
	wedgeShape.Color = C.purple
	wedgeShape.Material = Enum.Material.SmoothPlastic
	wedgeShape.Transparency = 1
	wedgeShape.Parent = model
	ctx.shapes = { box = boxShape, cylinder = cylinderShape, wedge = wedgeShape }

	local shapeControls = {
		{ key = "box", x = -12, text = "SZEŚCIAN", color = C.orange },
		{ key = "cylinder", x = 0, text = "CYLINDER", color = C.blue },
		{ key = "wedge", x = 12, text = "KLIN", color = C.purple },
	}
	for _, info in ipairs(shapeControls) do
		local control = part(
			model,
			"TinkercadShapeControl_" .. info.key,
			Vector3.new(8, 3, 6),
			origin + Vector3.new(info.x, 2, -23),
			info.color,
			Enum.Material.Neon
		)
		control:SetAttribute("Important3DPlaceholder", true)
		label(control, "DODAJ\n" .. info.text, Enum.NormalId.Top, 16)
		prompt(control, "PRZECIĄGNIJ NA STÓŁ", info.text, function(triggerPlayer)
			if triggerPlayer ~= player then return end
			local ok, result = Rules.Apply(ctx.rules, "place", info.key)
			if ok then
				ctx.state.score += 18
				ctx.shapes[info.key].Transparency = 0
				local target = ctx.shapes[info.key]
				target.Position += Vector3.new(0, 5, 0)
				TweenService:Create(target, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
					Position = target.Position - Vector3.new(0, 5, 0),
				}):Play()
			else
				ctx.state.score = math.max(0, ctx.state.score - 3)
			end
			message(ctx, result.message, ok)
			if ctx.rules.stage == 1 then
				setHud(ctx, "ETAP 1/3 • Dodaj sześcian, cylinder i klin na pole robocze.")
			else
				setHud(ctx, "ETAP 1/3 • Wyrównaj model do wspólnej osi.")
			end
		end)
	end

	local align = part(model, "TinkercadAlignControl", Vector3.new(10, 4, 7), origin + Vector3.new(-18, 2, 18), C.blue, Enum.Material.Metal)
	local group = part(model, "TinkercadGroupControl", Vector3.new(10, 4, 7), origin + Vector3.new(-6, 2, 18), C.purple, Enum.Material.Metal)
	local scale = part(model, "TinkercadScaleControl", Vector3.new(10, 4, 7), origin + Vector3.new(6, 2, 18), C.orange, Enum.Material.Metal)
	local exporter = part(model, "TinkercadExportPrinter", Vector3.new(11, 7, 9), origin + Vector3.new(20, 3.5, 20), C.dark, Enum.Material.Metal)
	for _, p in ipairs({ align, group, scale, exporter }) do
		p:SetAttribute("Important3DPlaceholder", true)
	end
	label(align, "WYRÓWNAJ", Enum.NormalId.Top, 17)
	label(group, "GRUPUJ", Enum.NormalId.Top, 17)
	label(scale, "SKALA", Enum.NormalId.Top, 17)
	local exportText = label(exporter, "EKSPORT\nMODEL 3D", Enum.NormalId.Front, 17)

	local function updateHud()
		if ctx.rules.completed then
			setHud(ctx, "ETAP 2/3 • Model 3D gotowy. Przejdź do RDZENIA MISJI.")
		elseif ctx.rules.stage == 1 then
			setHud(ctx, "ETAP 1/3 • ZACZNIJ: dodaj 3 różne prymitywy na pole robocze.")
		elseif not ctx.rules.aligned then
			setHud(ctx, "ETAP 1/3 • Wyrównaj wszystkie bryły.")
		elseif not ctx.rules.grouped then
			setHud(ctx, "ETAP 1/3 • Zgrupuj bryły w jeden model.")
		elseif not ctx.rules.scaled then
			setHud(ctx, "ETAP 1/3 • Ustaw poprawną skalę modelu.")
		else
			setHud(ctx, "ETAP 1/3 • Wyeksportuj gotowy model 3D.")
		end
	end

	local function act(action)
		local ok, result = Rules.Apply(ctx.rules, action)
		if ok then
			ctx.state.score += 18
			message(ctx, result.message, true)
		else
			ctx.state.score = math.max(0, ctx.state.score - 3)
			message(ctx, result.message, false)
		end
		if action == "align" and ok then
			TweenService:Create(boxShape, TweenInfo.new(0.25), { Position = origin + Vector3.new(-7, 4, -7) }):Play()
			TweenService:Create(cylinderShape, TweenInfo.new(0.25), { Position = origin + Vector3.new(0, 5, -7) }):Play()
			TweenService:Create(wedgeShape, TweenInfo.new(0.25), { Position = origin + Vector3.new(7, 4, -7) }):Play()
			align.Color = C.green
		elseif action == "group" and ok then
			for _, shape in pairs(ctx.shapes) do shape.Material = Enum.Material.Neon end
			group.Color = C.green
		elseif action == "scale" and ok then
			for _, shape in pairs(ctx.shapes) do
				shape.Size *= 0.82
			end
			scale.Color = C.green
		elseif action == "export" and ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 75
			exporter.Color = C.green
			exporter.Material = Enum.Material.Neon
			exportText.Text = string.format("MODEL GOTOWY\n%d%%", Rules.Efficiency(ctx.rules))
			sign.Color = C.green
		end
		updateHud()
	end

	prompt(laptop, "OTWÓRZ PROJEKT", "TINKERCAD • START", function(triggerPlayer)
		if triggerPlayer == player then
			message(ctx, "Pole robocze gotowe. Dodaj trzy różne bryły z półki.", true)
			updateHud()
		end
	end)
	prompt(align, "WYRÓWNAJ", "NARZĘDZIE ALIGN", function(triggerPlayer)
		if triggerPlayer == player then act("align") end
	end)
	prompt(group, "ZGRUPUJ", "NARZĘDZIE GROUP", function(triggerPlayer)
		if triggerPlayer == player then act("group") end
	end)
	prompt(scale, "USTAW SKALĘ", "UCHWYTY SKALI", function(triggerPlayer)
		if triggerPlayer == player then act("scale") end
	end)
	prompt(exporter, "EKSPORTUJ", "MODEL 3D", function(triggerPlayer)
		if triggerPlayer == player then act("export") end
	end)

	updateHud()
	return ctx
end

return TinkercadWorkshop
