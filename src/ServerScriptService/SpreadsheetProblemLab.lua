local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("SpreadsheetProblemRules"))

local SpreadsheetProblemLab = {}

local C = {
	floor = Color3.fromRGB(54, 63, 70),
	wall = Color3.fromRGB(79, 91, 101),
	dark = Color3.fromRGB(28, 34, 39),
	blue = Color3.fromRGB(62, 151, 230),
	green = Color3.fromRGB(68, 215, 120),
	yellow = Color3.fromRGB(239, 188, 62),
	red = Color3.fromRGB(231, 75, 75),
	white = Color3.fromRGB(247, 249, 250),
	orange = Color3.fromRGB(236, 130, 48),
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

function SpreadsheetProblemLab.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = { player = player, lesson = lesson, mission = mission, remote = remote, state = state, rules = Rules.NewState() }

	part(model, "SpreadsheetProblemFloor", Vector3.new(84, 1, 76), origin + Vector3.new(0, -0.5, -7), C.floor, Enum.Material.Concrete)
	part(model, "SpreadsheetProblemBackWall", Vector3.new(84, 20, 2), origin + Vector3.new(0, 10, -45), C.wall, Enum.Material.Metal)
	local sign = part(model, "SpreadsheetProblemSign", Vector3.new(44, 7, 1), origin + Vector3.new(0, 14, -43.8), C.blue, Enum.Material.Neon)
	label(sign, "SPREADSHEET PROBLEM LAB\nDANE → FORMUŁA → WHAT‑IF", Enum.NormalId.Front, 20)

	local desk = part(model, "SpreadsheetProblemDesk", Vector3.new(18, 4, 8), origin + Vector3.new(-24, 2, -31), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local laptop = part(model, "SpreadsheetProblemLaptop", Vector3.new(8, 5, 3), origin + Vector3.new(-24, 5, -31), C.blue, Enum.Material.Metal)
	laptop:SetAttribute("Important3DPlaceholder", true)
	label(laptop, "START\nPROBLEM W ARKUSZU", Enum.NormalId.Front, 16)

	local formulaConsole = part(model, "SpreadsheetFormulaConsole", Vector3.new(12, 7, 8), origin + Vector3.new(21, 3.5, -28), C.dark, Enum.Material.Metal)
	formulaConsole:SetAttribute("Important3DPlaceholder", true)
	local formulaText = label(formulaConsole, "FORMUŁA\n—", Enum.NormalId.Front, 18)

	local monitor = part(model, "SpreadsheetResultMonitor", Vector3.new(16, 10, 2), origin + Vector3.new(21, 9, -39), C.dark, Enum.Material.Metal)
	monitor:SetAttribute("Important3DPlaceholder", true)
	local resultText = label(monitor, "WYNIK\nczeka na dane", Enum.NormalId.Front, 18)

	local inputDefs = {
		{ key = "students", text = "UCZNIOWIE\n24", x = -18, color = C.blue },
		{ key = "price", text = "CENA\n35 zł", x = -5, color = C.orange },
		{ key = "discount", text = "RABAT\n10%", x = 8, color = C.yellow },
	}
	for _, info in ipairs(inputDefs) do
		local control = part(
			model,
			"SpreadsheetInputControl_" .. info.key,
			Vector3.new(9, 4, 7),
			origin + Vector3.new(info.x, 2, -20),
			info.color,
			Enum.Material.Neon
		)
		control:SetAttribute("Important3DPlaceholder", true)
		label(control, info.text, Enum.NormalId.Top, 16)
		prompt(control, "WPROWADŹ", "DANE WEJŚCIOWE", function(triggerPlayer)
			if triggerPlayer ~= player then return end
			local ok, result = Rules.Apply(ctx.rules, "input", info.key)
			if ok then ctx.state.score += 15 else ctx.state.score = math.max(0, ctx.state.score - 3) end
			message(ctx, result.message, ok)
			resultText.Text = string.format("DANE\n%d/3 gotowe", (ctx.rules.inputs.students and 1 or 0) + (ctx.rules.inputs.price and 1 or 0) + (ctx.rules.inputs.discount and 1 or 0))
			setHud(ctx, ctx.rules.stage == 1 and "ETAP 1/3 • Wprowadź 3 dane wejściowe." or "ETAP 1/3 • Zbuduj formułę kosztu.")
		end)
	end

	local formula = part(model, "SpreadsheetFormulaControl", Vector3.new(10, 4, 7), origin + Vector3.new(-17, 2, 15), C.blue, Enum.Material.Metal)
	local whatif = part(model, "SpreadsheetWhatIfControl", Vector3.new(10, 4, 7), origin + Vector3.new(-5, 2, 15), C.yellow, Enum.Material.Metal)
	local check = part(model, "SpreadsheetCheckControl", Vector3.new(10, 4, 7), origin + Vector3.new(7, 2, 15), C.green, Enum.Material.Metal)
	for _, p in ipairs({ formula, whatif, check }) do p:SetAttribute("Important3DPlaceholder", true) end
	label(formula, "FORMUŁA", Enum.NormalId.Top, 17)
	label(whatif, "WHAT‑IF", Enum.NormalId.Top, 17)
	label(check, "SPRAWDŹ", Enum.NormalId.Top, 17)

	local outputGate = part(model, "SpreadsheetProblemOutputGate", Vector3.new(22, 10, 2), origin + Vector3.new(0, 5, 30), C.red, Enum.Material.Metal)
	local gateText = label(outputGate, "MODEL NIEGOTOWY", Enum.NormalId.Front, 18)

	local function act(action)
		local ok, result = Rules.Apply(ctx.rules, action)
		if ok then ctx.state.score += 18 else ctx.state.score = math.max(0, ctx.state.score - 3) end
		message(ctx, result.message, ok)
		if action == "formula" and ok then
			formula.Color = C.green
			formulaText.Text = "FORMUŁA\n24 × 35 × (1−10%)"
			resultText.Text = "WYNIK\n756 zł"
		elseif action == "whatif" and ok then
			whatif.Color = C.green
			resultText.Text = "WHAT‑IF\nrabat 20% → 672 zł"
			TweenService:Create(monitor, TweenInfo.new(0.3), { Color = C.blue }):Play()
		elseif action == "check" and ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 70
			check.Color = C.green
			outputGate.Color = C.green
			outputGate.Material = Enum.Material.Neon
			gateText.Text = string.format("MODEL DZIAŁA\n%d%%", Rules.Efficiency(ctx.rules))
			sign.Color = C.green
		end
		if ctx.rules.completed then
			setHud(ctx, "ETAP 2/3 • Model arkusza gotowy. Przejdź do RDZENIA MISJI.")
		elseif not ctx.rules.formula then
			setHud(ctx, "ETAP 1/3 • Zbuduj formułę kosztu.")
		elseif not ctx.rules.whatIf then
			setHud(ctx, "ETAP 1/3 • Zmień rabat i wykonaj WHAT‑IF.")
		else
			setHud(ctx, "ETAP 1/3 • Zweryfikuj model.")
		end
	end

	prompt(laptop, "OTWÓRZ ARKUSZ", "PROBLEM LAB • START", function(triggerPlayer)
		if triggerPlayer == player then
			message(ctx, "Problem: policz koszt dla 24 uczniów, ceny 35 zł i rabatu 10%.", true)
			setHud(ctx, "ETAP 1/3 • Wprowadź uczniów, cenę i rabat.")
		end
	end)
	prompt(formula, "ZBUDUJ FORMUŁĘ", "SILNIK FORMUŁ", function(triggerPlayer) if triggerPlayer == player then act("formula") end end)
	prompt(whatif, "ZMIEŃ RABAT", "WHAT‑IF", function(triggerPlayer) if triggerPlayer == player then act("whatif") end end)
	prompt(check, "ZWERYFIKUJ", "MODEL ARKUSZA", function(triggerPlayer) if triggerPlayer == player then act("check") end end)

	setHud(ctx, "ETAP 1/3 • ZACZNIJ: otwórz arkusz i zidentyfikuj 3 dane wejściowe.")
	return ctx
end

return SpreadsheetProblemLab
