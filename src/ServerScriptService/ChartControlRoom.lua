local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("ChartControlRules"))

local ChartControlRoom = {}

local C = {
	floor = Color3.fromRGB(31, 37, 46),
	wall = Color3.fromRGB(53, 63, 76),
	dark = Color3.fromRGB(19, 24, 31),
	blue = Color3.fromRGB(67, 151, 235),
	green = Color3.fromRGB(69, 216, 120),
	yellow = Color3.fromRGB(244, 191, 62),
	red = Color3.fromRGB(231, 76, 79),
	purple = Color3.fromRGB(153, 98, 225),
	white = Color3.fromRGB(248, 250, 252),
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

function ChartControlRoom.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = { player = player, lesson = lesson, mission = mission, remote = remote, state = state, rules = Rules.NewState(), bars = {} }

	part(model, "ChartControlFloor", Vector3.new(84, 1, 76), origin + Vector3.new(0, -0.5, -7), C.floor, Enum.Material.Metal)
	part(model, "ChartControlBackWall", Vector3.new(84, 20, 2), origin + Vector3.new(0, 10, -45), C.wall, Enum.Material.Metal)
	local sign = part(model, "ChartControlSign", Vector3.new(42, 7, 1), origin + Vector3.new(0, 14, -43.8), C.purple, Enum.Material.Neon)
	label(sign, "CHART CONTROL ROOM\nzakres • typ • opis • wniosek", Enum.NormalId.Front, 20)

	local desk = part(model, "ChartOperatorDesk", Vector3.new(18, 4, 8), origin + Vector3.new(-24, 2, -31), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local scanner = part(model, "ChartRangeScanner", Vector3.new(9, 5, 7), origin + Vector3.new(-24, 3, -40), C.blue, Enum.Material.Metal)
	scanner:SetAttribute("Important3DPlaceholder", true)
	label(scanner, "START\nZAKRES DANYCH", Enum.NormalId.Front, 17)

	local monitor = part(model, "ChartPreviewMonitor", Vector3.new(18, 11, 2), origin + Vector3.new(23, 9, -31), C.dark, Enum.Material.Metal)
	monitor:SetAttribute("Important3DPlaceholder", true)
	local monitorText = label(monitor, "WYKRES\nczeka na dane", Enum.NormalId.Front, 18)

	local chartBase = part(model, "ChartPhysicalBase", Vector3.new(42, 1, 20), origin + Vector3.new(0, 0.5, -5), C.dark, Enum.Material.Metal)
	local values = { 4, 8, 6 }
	local colors = { C.blue, C.green, C.yellow }
	for index, value in ipairs(values) do
		local bar = part(
			model,
			"ChartBar_" .. index,
			Vector3.new(8, 0.5, 8),
			origin + Vector3.new(-12 + (index - 1) * 12, 1, -5),
			colors[index],
			Enum.Material.Neon
		)
		bar.CanCollide = false
		ctx.bars[index] = { part = bar, value = value }
		label(bar, string.char(64 + index) .. "\n" .. value, Enum.NormalId.Top, 16)
	end

	local typeColumn = part(model, "ChartTypeControl_Column", Vector3.new(10, 4, 7), origin + Vector3.new(-14, 2, 15), C.blue, Enum.Material.Metal)
	local typePie = part(model, "ChartTypeControl_Pie", Vector3.new(10, 4, 7), origin + Vector3.new(-2, 2, 15), C.red, Enum.Material.Metal)
	local titleControl = part(model, "ChartTitleControl", Vector3.new(10, 4, 7), origin + Vector3.new(10, 2, 15), C.purple, Enum.Material.Metal)
	local labelsControl = part(model, "ChartLabelsControl", Vector3.new(10, 4, 7), origin + Vector3.new(22, 2, 15), C.yellow, Enum.Material.Metal)
	local compareControl = part(model, "ChartCompareControl", Vector3.new(10, 4, 7), origin + Vector3.new(-8, 2, 27), C.green, Enum.Material.Metal)
	local publishConsole = part(model, "ChartPublishConsole", Vector3.new(12, 7, 8), origin + Vector3.new(15, 3.5, 29), C.dark, Enum.Material.Metal)
	for _, p in ipairs({ typeColumn, typePie, titleControl, labelsControl, compareControl, publishConsole }) do p:SetAttribute("Important3DPlaceholder", true) end
	label(typeColumn, "KOLUMNY", Enum.NormalId.Top, 16)
	label(typePie, "KOŁOWY", Enum.NormalId.Top, 16)
	label(titleControl, "TYTUŁ", Enum.NormalId.Top, 16)
	label(labelsControl, "ETYKIETY", Enum.NormalId.Top, 16)
	label(compareControl, "ODCZYTAJ\nWNIOSEK", Enum.NormalId.Top, 16)
	local publishText = label(publishConsole, "PUBLIKUJ\nWYKRES", Enum.NormalId.Front, 17)

	local function raiseBars()
		for index, data in ipairs(ctx.bars) do
			local h = data.value * 1.25
			TweenService:Create(data.part, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
				Size = Vector3.new(8, h, 8),
				Position = origin + Vector3.new(-12 + (index - 1) * 12, 1 + h * 0.5, -5),
			}):Play()
		end
	end

	local function act(action, value)
		local ok, result = Rules.Apply(ctx.rules, action, value)
		if ok then ctx.state.score += 17 else ctx.state.score = math.max(0, ctx.state.score - 3) end
		message(ctx, result.message, ok)
		if action == "range" and ok then
			scanner.Color = C.green
			monitorText.Text = "ZAKRES\nA:B:C + wartości"
		elseif action == "type" and ok then
			typeColumn.Color = C.green
			raiseBars()
			monitorText.Text = "WYKRES KOLUMNOWY\nA=4 • B=8 • C=6"
		elseif action == "title" and ok then
			titleControl.Color = C.green
			monitorText.Text = "SPRZEDAŻ W 3 KATEGORIACH\nA=4 • B=8 • C=6"
		elseif action == "labels" and ok then
			labelsControl.Color = C.green
			for _, data in ipairs(ctx.bars) do data.part.Material = Enum.Material.Neon end
		elseif action == "compare" and ok then
			compareControl.Color = C.green
			monitorText.Text = "WNIOSEK\nB ma najwyższą wartość: 8"
		elseif action == "publish" and ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 75
			publishConsole.Color = C.green
			publishConsole.Material = Enum.Material.Neon
			publishText.Text = string.format("OPUBLIKOWANO\n%d%%", Rules.Efficiency(ctx.rules))
			sign.Color = C.green
		end

		if ctx.rules.completed then
			setHud(ctx, "ETAP 2/3 • Wykres gotowy. Przejdź do RDZENIA MISJI.")
		elseif not ctx.rules.range then
			setHud(ctx, "ETAP 1/3 • Wybierz poprawny zakres danych.")
		elseif not ctx.rules.chartType then
			setHud(ctx, "ETAP 1/3 • Dobierz typ wykresu do porównania kategorii.")
		elseif not ctx.rules.labels then
			setHud(ctx, "ETAP 1/3 • Dodaj tytuł i etykiety.")
		elseif not ctx.rules.compared then
			setHud(ctx, "ETAP 1/3 • Odczytaj wniosek z wykresu.")
		else
			setHud(ctx, "ETAP 1/3 • Opublikuj gotowy wykres.")
		end
	end

	prompt(scanner, "ZAZNACZ KATEGORIE + WARTOŚCI", "ZAKRES DANYCH • START", function(triggerPlayer) if triggerPlayer == player then act("range", "sales") end end)
	prompt(typeColumn, "WYBIERZ", "WYKRES KOLUMNOWY", function(triggerPlayer) if triggerPlayer == player then act("type", "column") end end)
	prompt(typePie, "WYBIERZ", "WYKRES KOŁOWY", function(triggerPlayer) if triggerPlayer == player then act("type", "pie") end end)
	prompt(titleControl, "DODAJ", "TYTUŁ WYKRESU", function(triggerPlayer) if triggerPlayer == player then act("title") end end)
	prompt(labelsControl, "WŁĄCZ", "ETYKIETY DANYCH", function(triggerPlayer) if triggerPlayer == player then act("labels") end end)
	prompt(compareControl, "PORÓWNAJ", "WNIOSEK Z DANYCH", function(triggerPlayer) if triggerPlayer == player then act("compare") end end)
	prompt(publishConsole, "PUBLIKUJ", "GOTOWY WYKRES", function(triggerPlayer) if triggerPlayer == player then act("publish") end end)

	setHud(ctx, "ETAP 1/3 • ZACZNIJ: zeskanuj poprawny zakres danych.")
	return ctx
end

return ChartControlRoom
