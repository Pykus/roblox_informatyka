local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("SchoolNewsroomRules"))

local SchoolNewsroom = {}

local C = {
	floor = Color3.fromRGB(197, 190, 173),
	wall = Color3.fromRGB(92, 83, 72),
	dark = Color3.fromRGB(36, 38, 42),
	cream = Color3.fromRGB(247, 241, 222),
	red = Color3.fromRGB(206, 71, 67),
	blue = Color3.fromRGB(64, 145, 220),
	green = Color3.fromRGB(71, 211, 119),
	yellow = Color3.fromRGB(235, 187, 61),
	white = Color3.fromRGB(249, 249, 247),
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
	gui.Brightness = 1.2
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34
	gui.Parent = target
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = textColor or C.white
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

local function flash(target, color)
	local original = target.Color
	target.Color = color
	TweenService:Create(target, TweenInfo.new(0.32), { Color = original }):Play()
end

function SchoolNewsroom.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
	}

	part(model, "SchoolNewsFloor", Vector3.new(82, 1, 74), origin + Vector3.new(0, -0.5, -7), C.floor, Enum.Material.WoodPlanks)
	part(model, "SchoolNewsBackWall", Vector3.new(82, 20, 2), origin + Vector3.new(0, 10, -44), C.wall, Enum.Material.Brick)
	local sign = part(model, "SchoolNewsSign", Vector3.new(40, 7, 1), origin + Vector3.new(0, 14, -42.8), C.red, Enum.Material.Neon)
	label(sign, "SZKOLNA REDAKCJA\n2 strony • grafika • druk", Enum.NormalId.Front, 20)

	local desk = part(model, "SchoolNewsOperatorDesk", Vector3.new(18, 4, 8), origin + Vector3.new(-24, 2, -31), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local laptop = part(model, "SchoolNewsLayoutLaptop", Vector3.new(8, 5, 3), origin + Vector3.new(-24, 5, -31), C.blue, Enum.Material.Metal)
	laptop:SetAttribute("Important3DPlaceholder", true)
	label(laptop, "START\nOKŁADKA", Enum.NormalId.Front, 17)
	local scanner = part(model, "SchoolNewsPhotoScanner", Vector3.new(9, 4, 7), origin + Vector3.new(-24, 3, -40), C.yellow, Enum.Material.Metal)
	scanner:SetAttribute("Important3DPlaceholder", true)
	label(scanner, "SKANER\nZDJĘCIE", Enum.NormalId.Front, 17)

	local page1 = part(model, "SchoolNewsPage1", Vector3.new(24, 16, 1), origin + Vector3.new(-14, 9, -7), C.cream, Enum.Material.SmoothPlastic)
	local page2 = part(model, "SchoolNewsPage2", Vector3.new(24, 16, 1), origin + Vector3.new(14, 9, -7), C.cream, Enum.Material.SmoothPlastic)
	local page1Text = label(page1, "STRONA 1\n—", Enum.NormalId.Front, 18, C.dark)
	local page2Text = label(page2, "STRONA 2\n—", Enum.NormalId.Front, 18, C.dark)

	local preview = part(model, "SchoolNewsPreviewMonitor", Vector3.new(16, 10, 2), origin + Vector3.new(23, 8, -31), C.dark, Enum.Material.Metal)
	preview:SetAttribute("Important3DPlaceholder", true)
	local previewText = label(preview, "PODGLĄD DRUKU\nczeka", Enum.NormalId.Front, 17)

	local printer = part(model, "SchoolNewsPrinter", Vector3.new(12, 8, 9), origin + Vector3.new(22, 4, 20), C.dark, Enum.Material.Metal)
	printer:SetAttribute("Important3DPlaceholder", true)
	local printerText = label(printer, "DRUKARKA\n2 STRONY", Enum.NormalId.Front, 17)

	local controls = {
		{ action = "cover", name = "SchoolNewsControl_Cover", text = "OKŁADKA", pos = Vector3.new(-18, 2, 13), color = C.red },
		{ action = "article", name = "SchoolNewsControl_Article", text = "ARTYKUŁ", pos = Vector3.new(-8, 2, 13), color = C.blue },
		{ action = "photo", name = "SchoolNewsControl_Photo", text = "ZDJĘCIE", pos = Vector3.new(2, 2, 13), color = C.yellow },
		{ action = "page2", name = "SchoolNewsControl_Page2", text = "+ STRONA", pos = Vector3.new(12, 2, 13), color = C.blue },
		{ action = "header", name = "SchoolNewsControl_Header", text = "NAGŁÓWEK", pos = Vector3.new(-13, 2, 23), color = C.dark },
		{ action = "numbers", name = "SchoolNewsControl_Numbers", text = "NUMERY", pos = Vector3.new(-2, 2, 23), color = C.dark },
	}
	for _, info in ipairs(controls) do
		local button = part(model, info.name, Vector3.new(8, 3, 6), origin + info.pos, info.color, Enum.Material.Neon)
		button:SetAttribute("Important3DPlaceholder", true)
		label(button, info.text, Enum.NormalId.Top, 16)
		prompt(button, "ZASTOSUJ", "EDYTOR GAZETKI", function(triggerPlayer)
			if triggerPlayer ~= player then return end
			local ok, result = Rules.Apply(ctx.rules, info.action)
			if ok then ctx.state.score += 14 else ctx.state.score = math.max(0, ctx.state.score - 3) end
			message(ctx, result.message, ok)
			if info.action == "cover" and ok then
				page1Text.Text = "SZKOLNE ECHO\nWYDANIE SPECJALNE"
			elseif info.action == "article" and ok then
				page1Text.Text ..= "\n• Artykuł: wydarzenia"
			elseif info.action == "photo" and ok then
				page1Text.Text ..= "\n[ZDJĘCIE + PODPIS]"
			elseif info.action == "page2" and ok then
				page2Text.Text = "STRONA 2\nKRONIKA KLASY"
			elseif info.action == "header" and ok then
				page2Text.Text ..= "\nSZKOLNE ECHO"
			elseif info.action == "numbers" and ok then
				page1Text.Text ..= "\n1 / 2"
				page2Text.Text ..= "\n2 / 2"
			end
			flash(info.action == "photo" and scanner or button, ok and C.green or C.red)
			if ctx.rules.stage == 1 then
				setHud(ctx, "ETAP 1/3 • Zbuduj kompletną stronę 1 i dodaj stronę 2.")
			elseif not ctx.rules.pageNumbers then
				setHud(ctx, "ETAP 1/3 • Ustaw nagłówek i numery stron.")
			else
				setHud(ctx, "ETAP 1/3 • Sprawdź PODGLĄD DRUKU.")
			end
		end)
	end

	prompt(laptop, "UTWÓRZ OKŁADKĘ", "EDYTOR TEKSTU • START", function(triggerPlayer)
		if triggerPlayer ~= player then return end
		local ok, result = Rules.Apply(ctx.rules, "cover")
		if ok then
			ctx.state.score += 14
			page1Text.Text = "SZKOLNE ECHO\nWYDANIE SPECJALNE"
		end
		message(ctx, result.message, ok)
		setHud(ctx, "ETAP 1/3 • Dodaj artykuł i zeskanowane zdjęcie.")
	end)

	prompt(preview, "SPRAWDŹ 2 STRONY", "PODGLĄD DRUKU", function(triggerPlayer)
		if triggerPlayer ~= player then return end
		local ok, result = Rules.Apply(ctx.rules, "preview")
		if ok then
			ctx.state.score += 16
			preview.Color = C.green
			preview.Material = Enum.Material.Neon
			previewText.Text = "PODGLĄD OK\n1/2 + 2/2"
		end
		message(ctx, result.message, ok)
		setHud(ctx, ok and "ETAP 1/3 • Wydrukuj finalną gazetkę." or "ETAP 1/3 • Dokończ strukturę obu stron.")
	end)

	prompt(printer, "DRUKUJ GAZETKĘ", "DRUKARKA", function(triggerPlayer)
		if triggerPlayer ~= player then return end
		local ok, result = Rules.Apply(ctx.rules, "print")
		if ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 75
			printer.Color = C.green
			printer.Material = Enum.Material.Neon
			printerText.Text = string.format("WYDRUK GOTOWY\n%d%%", Rules.Efficiency(ctx.rules))
			sign.Color = C.green
			TweenService:Create(page1, TweenInfo.new(0.35), { Position = page1.Position + Vector3.new(0, 2, 0) }):Play()
			TweenService:Create(page2, TweenInfo.new(0.35), { Position = page2.Position + Vector3.new(0, 2, 0) }):Play()
		end
		message(ctx, result.message, ok)
		setHud(ctx, ok and "ETAP 2/3 • Gazetka gotowa. Przejdź do RDZENIA MISJI." or "ETAP 1/3 • Najpierw wykonaj podgląd.")
	end)

	setHud(ctx, "ETAP 1/3 • ZACZNIJ: utwórz OKŁADKĘ na laptopie redakcji.")
	return ctx
end

return SchoolNewsroom
