local TweenService = game:GetService("TweenService")

local ConversionMachine = {}
local Rules = require(script.Parent:WaitForChild("ConversionMachineRules"))

local C = {
	concrete = Color3.fromRGB(154, 145, 129),
	brick = Color3.fromRGB(214, 205, 187),
	wood = Color3.fromRGB(126, 91, 60),
	steel = Color3.fromRGB(91, 88, 82),
	orange = Color3.fromRGB(231, 132, 54),
	blue = Color3.fromRGB(55, 136, 176),
	green = Color3.fromRGB(68, 205, 122),
	red = Color3.fromRGB(224, 82, 66),
	yellow = Color3.fromRGB(243, 191, 63),
	white = Color3.fromRGB(248, 244, 235),
	dark = Color3.fromRGB(46, 49, 52),
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
	gui.PixelsPerStud = 32
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.4
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

local function prompt(target, actionText, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = actionText
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 18
	pr.HoldDuration = 0
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function tween(instance, goal, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	tw:Play()
	return tw
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

local function setPrompts(prompts, enabled)
	for _, pr in ipairs(prompts) do
		pr.Enabled = enabled
	end
end

local function moveCore(ctx, target)
	tween(ctx.numberCore, { Position = target }, 0.55)
end

local function updateBinary(ctx)
	local selected = ctx.rules.selectedRemainder
	ctx.binaryBoard.Text = string.format(
		"WEJŚCIE: %d\n%d : 2 = ?   RESZTA: %s",
		Rules.BinarySource,
		ctx.rules.binaryCurrent,
		selected == nil and "?" or tostring(selected)
	)
	for index, cell in ipairs(ctx.remainderCells) do
		local remainder = ctx.rules.remainders[index]
		ctx.remainderLabels[index].Text = remainder == nil and "?" or tostring(remainder)
		cell.Color = remainder == nil and C.steel or (remainder == 1 and C.orange or C.blue)
		cell.Material = remainder == nil and Enum.Material.Metal or Enum.Material.Neon
	end
	ctx.binaryOutput.Text = #ctx.rules.remainders > 0 and ("CZYTAJ OD DOŁU\n" .. Rules.BinaryText(ctx.rules))
		or "STOS RESZT\n—"
end

local function enterHex(ctx)
	setPrompts(ctx.binaryPrompts, false)
	setPrompts(ctx.hexPrompts, false)
	setPrompts(ctx.hexQuotientPrompts, true)
	ctx.stageLamp1.Color = C.green
	ctx.stageLamp1.Material = Enum.Material.Neon
	moveCore(ctx, ctx.hexCorePosition)
	hud(ctx, "ETAP 2/3 • Najpierw ustaw ILORAZ = 3. Potem maszyna odblokuje RESZTĘ = 10(A).")
	message(ctx, "BIN gotowe: 58₁₀ = 111010₂. Teraz wykonaj dzielenie przez 16 krok po kroku.", true)
end

local function updateHex(ctx)
	ctx.hexBoard.Text = string.format(
		"58 = %d×16 + %d\nWYJŚCIE HEX: %X%X",
		ctx.rules.hexQuotient,
		ctx.rules.hexRemainder,
		ctx.rules.hexQuotient,
		ctx.rules.hexRemainder
	)
end

local function enterReverse(ctx)
	setPrompts(ctx.hexPrompts, false)
	setPrompts(ctx.reversePrompts, false)
	setPrompts(ctx.reverseAdjustPrompts, true)
	ctx.stageLamp2.Color = C.green
	ctx.stageLamp2.Material = Enum.Material.Neon
	moveCore(ctx, ctx.reverseCorePosition)
	hud(ctx, "ETAP 3/3 • Ustaw D = 13. Gdy trafisz 13, odblokuje się przycisk PRZELICZ.")
	message(ctx, "HEX gotowe: 58₁₀ = 3A₁₆. Teraz sprawdź 2D₁₆ → DEC.", true)
end

local function updateReverse(ctx)
	ctx.reverseBoard.Text =
		string.format("2D₁₆\n2×16 + D(%d) = %d", ctx.rules.reverseLow, Rules.ReverseValue(ctx.rules))
end

local function finish(ctx)
	setPrompts(ctx.reversePrompts, false)
	ctx.stageLamp3.Color = C.green
	ctx.stageLamp3.Material = Enum.Material.Neon
	ctx.numberCore.Color = C.green
	ctx.numberCore.Material = Enum.Material.Neon
	moveCore(ctx, ctx.finalCorePosition)
	ctx.finalBoard.Text = "CONVERSION LINE ONLINE\n58₁₀ = 111010₂ = 3A₁₆\n2D₁₆ = 45₁₀"
	ctx.finalGate.Color = C.green
	ctx.finalGate.Material = Enum.Material.Neon
	ctx.finalGate.CanCollide = false
	tween(ctx.finalGate, { Position = ctx.finalGate.Position + Vector3.new(0, 14, 0) }, 0.55)
	ctx.state.score += 100
	ctx.state.done = true
	hud(ctx, "ETAP 2/3 • Conversion Machine działa. Przejdź do oznaczonego RDZENIA MISJI.")
	message(ctx, string.format("Linia konwersji gotowa • efektywność %d%%.", Rules.Efficiency(ctx.rules)), true)
end

function ConversionMachine.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		binaryPrompts = {},
		binaryChoicePrompts = {},
		hexPrompts = {},
		hexQuotientPrompts = {},
		hexRemainderPrompts = {},
		reversePrompts = {},
		reverseAdjustPrompts = {},
		remainderCells = {},
		remainderLabels = {},
	}

	part(
		model,
		"ConversionFloor",
		Vector3.new(78, 1, 118),
		origin + Vector3.new(0, -0.5, 10),
		C.concrete,
		Enum.Material.Concrete
	)
	part(
		model,
		"ConversionBackWall",
		Vector3.new(78, 17, 2),
		origin + Vector3.new(0, 8.5, -44),
		C.brick,
		Enum.Material.Brick
	)

	local title = part(
		model,
		"ConversionTitle",
		Vector3.new(52, 8, 2),
		origin + Vector3.new(0, 11, -42),
		C.dark,
		Enum.Material.Metal
	)
	label(title, "CONVERSION MACHINE\nDZIEL • ZAPISZ RESZTY • SPRAWDŹ", Enum.NormalId.Front, 21)

	for stage = 1, 3 do
		local lamp = part(
			model,
			"ConversionStageLamp_" .. stage,
			Vector3.new(5, 5, 2),
			origin + Vector3.new(-9 + stage * 9, 13, -32),
			C.yellow,
			Enum.Material.SmoothPlastic
		)
		label(lamp, tostring(stage), Enum.NormalId.Front, 20)
		lamp.CanCollide = false
		ctx["stageLamp" .. stage] = lamp
	end

	-- Moving number core ties all machines together.
	ctx.binaryCorePosition = origin + Vector3.new(-28, 6, -24)
	ctx.hexCorePosition = origin + Vector3.new(-28, 6, 16)
	ctx.reverseCorePosition = origin + Vector3.new(-28, 6, 52)
	-- Keep the moving number core beside the shared mission core so the final interaction stays visible.
	ctx.finalCorePosition = origin + Vector3.new(-18, 7, 76)
	ctx.numberCore =
		part(model, "ConversionNumberCore", Vector3.new(8, 8, 8), ctx.binaryCorePosition, C.orange, Enum.Material.Glass)
	ctx.numberCore.Shape = Enum.PartType.Ball
	ctx.numberCore.CanCollide = false
	label(ctx.numberCore, "58", Enum.NormalId.Front, 22)

	-- Stage 1: repeated division by 2.
	local divider = part(
		model,
		"BinaryDividerMachine",
		Vector3.new(38, 10, 8),
		origin + Vector3.new(7, 7, -25),
		C.wood,
		Enum.Material.WoodPlanks
	)
	ctx.binaryBoard = label(divider, "", Enum.NormalId.Front, 19)

	local remainder0 = part(
		model,
		"BinaryRemainder0",
		Vector3.new(9, 3, 9),
		origin + Vector3.new(-4, 2, -35),
		C.blue,
		Enum.Material.Metal
	)
	label(remainder0, "RESZTA 0", Enum.NormalId.Top, 18)
	remainder0.CanCollide = false
	remainder0.CanTouch = false
	local remainder1 = part(
		model,
		"BinaryRemainder1",
		Vector3.new(9, 3, 9),
		origin + Vector3.new(8, 2, -35),
		C.orange,
		Enum.Material.Metal
	)
	label(remainder1, "RESZTA 1", Enum.NormalId.Top, 18)
	remainder1.CanCollide = false
	remainder1.CanTouch = false
	local crank = part(
		model,
		"BinaryDivisionCrank",
		Vector3.new(11, 6, 5),
		origin + Vector3.new(22, 4, -35),
		C.yellow,
		Enum.Material.Metal
	)
	label(crank, "KROK ÷2", Enum.NormalId.Front, 19)
	crank.CanCollide = false
	crank.CanTouch = false

	local binaryConsole = part(
		model,
		"BinaryConversionConsole",
		Vector3.new(8, 5, 7),
		origin + Vector3.new(-18, 3, -34),
		C.dark,
		Enum.Material.Metal
	)
	binaryConsole.CanCollide = false
	local binaryGuide = part(
		model,
		"BinaryGuide",
		Vector3.new(17, 8, 1),
		origin + Vector3.new(-22, 7, -38),
		C.dark,
		Enum.Material.Metal
	)
	binaryGuide.CanCollide = false
	label(binaryGuide, "1 • WYBIERZ RESZTĘ 0/1\n2 • OBRÓĆ ÷2\nPOWTARZAJ DO ZERA", Enum.NormalId.Front, 18)

	local function chooseBinaryRemainder(value)
		Rules.SelectRemainder(ctx.rules, value)
		updateBinary(ctx)
		setPrompts(ctx.binaryChoicePrompts, false)
		ctx.binaryCrankPrompt.Enabled = true
		hud(ctx, string.format("ETAP 1/3 • Wybrano resztę %d. Teraz użyj KROK ÷2.", value))
	end

	for _, data in ipairs({ { remainder0, 0 }, { remainder1, 1 } }) do
		local pr = prompt(data[1], "WYBIERZ", "RESZTA " .. data[2], function(who)
			if who == player and ctx.rules.stage == 1 then
				chooseBinaryRemainder(data[2])
			end
		end)
		table.insert(ctx.binaryPrompts, pr)
		table.insert(ctx.binaryChoicePrompts, pr)
	end

	ctx.binaryCrankPrompt = prompt(crank, "OBRÓĆ", "DZIELARKA ÷2", function(who)
		if who ~= player or ctx.rules.stage ~= 1 then
			return
		end
		local ok, result = Rules.BinaryStep(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			ctx.binaryCrankPrompt.Enabled = false
			setPrompts(ctx.binaryChoicePrompts, true)
			updateBinary(ctx)
			hud(ctx, "ETAP 1/3 • Wybierz poprawną resztę 0 lub 1 i spróbuj KROK ÷2 ponownie.")
			message(ctx, result.message, false)
			return
		end
		state.score += 10
		updateBinary(ctx)
		tween(crank, { Color = C.green }, 0.1)
		if result.finished then
			enterHex(ctx)
		else
			ctx.binaryCrankPrompt.Enabled = false
			setPrompts(ctx.binaryChoicePrompts, true)
			hud(
				ctx,
				string.format("ETAP 1/3 • Teraz %d÷2. Najpierw wybierz resztę 0 lub 1.", ctx.rules.binaryCurrent)
			)
			message(ctx, result.message, true)
		end
	end)
	ctx.binaryCrankPrompt.Enabled = false
	table.insert(ctx.binaryPrompts, ctx.binaryCrankPrompt)

	for index = 1, 6 do
		local cell = part(
			model,
			"BinaryRemainderCell_" .. index,
			Vector3.new(5, 5, 3),
			origin + Vector3.new(31, 3 + (index - 1) * 5.5, -31),
			C.steel,
			Enum.Material.Metal
		)
		local txt = label(cell, "?", Enum.NormalId.Front, 20)
		cell.CanCollide = false
		table.insert(ctx.remainderCells, cell)
		table.insert(ctx.remainderLabels, txt)
	end
	local outputBoard = part(
		model,
		"BinaryConversionOutput",
		Vector3.new(22, 9, 2),
		origin + Vector3.new(-17, 10, -6),
		C.dark,
		Enum.Material.Metal
	)
	ctx.binaryOutput = label(outputBoard, "STOS RESZT\n—", Enum.NormalId.Front, 19)
	updateBinary(ctx)

	-- Stage 2: decimal 58 to hexadecimal by quotient/remainder.
	local hexMachine = part(
		model,
		"HexDividerMachine",
		Vector3.new(42, 11, 8),
		origin + Vector3.new(7, 7, 15),
		C.steel,
		Enum.Material.Metal
	)
	ctx.hexBoard = label(hexMachine, "", Enum.NormalId.Front, 19)
	local hexConsole = part(
		model,
		"HexConversionConsole",
		Vector3.new(8, 5, 7),
		origin + Vector3.new(-18, 3, 3),
		C.dark,
		Enum.Material.Metal
	)
	hexConsole.CanCollide = false
	local hexGuide =
		part(model, "HexGuide", Vector3.new(18, 8, 1), origin + Vector3.new(-22, 7, 0), C.dark, Enum.Material.Metal)
	hexGuide.CanCollide = false
	label(hexGuide, "1 • ILORAZ = 3\n2 • RESZTA = 10 (A)\n3 • SPRAWDŹ ÷16", Enum.NormalId.Front, 18)

	for _, cfg in ipairs({
		{ key = "quotient", x = -5, title = "ILORAZ" },
		{ key = "remainder", x = 16, title = "RESZTA" },
	}) do
		for _, data in ipairs({ { -1, -5 }, { 1, 5 } }) do
			local button = part(
				model,
				"HexAdjust_" .. cfg.key .. "_" .. (data[1] < 0 and "Minus" or "Plus"),
				Vector3.new(7, 2, 7),
				origin + Vector3.new(cfg.x + data[2], 1, 3),
				data[1] < 0 and C.blue or C.orange,
				Enum.Material.Neon
			)
			label(button, data[1] < 0 and "-" or "+", Enum.NormalId.Top, 22)
			button.CanCollide = false
			button.CanTouch = false
			local pr = prompt(button, data[1] < 0 and "ZMNIEJSZ" or "ZWIĘKSZ", cfg.title, function(who)
				if who ~= player or ctx.rules.stage ~= 2 then
					return
				end
				Rules.AdjustHex(ctx.rules, cfg.key, data[1])
				updateHex(ctx)
			end)
			pr.Enabled = false
			table.insert(ctx.hexPrompts, pr)
		end
	end
	local hexValidate = part(
		model,
		"HexConversionValidate",
		Vector3.new(13, 5, 7),
		origin + Vector3.new(29, 3, 3),
		C.yellow,
		Enum.Material.Metal
	)
	label(hexValidate, "SPRAWDŹ\n÷16", Enum.NormalId.Front, 18)
	hexValidate.CanCollide = false
	hexValidate.CanTouch = false
	local hexValidatePrompt = prompt(hexValidate, "SPRAWDŹ", "58 → HEX", function(who)
		if who ~= player or ctx.rules.stage ~= 2 then
			return
		end
		local ok, result = Rules.ValidateHex(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			message(ctx, result.message, false)
			return
		end
		state.score += 45
		updateHex(ctx)
		enterReverse(ctx)
	end)
	hexValidatePrompt.Enabled = false
	table.insert(ctx.hexPrompts, hexValidatePrompt)
	setPrompts(ctx.hexPrompts, false)
	updateHex(ctx)

	-- Stage 3: reverse HEX -> DEC place-value verifier.
	local reverseMachine = part(
		model,
		"HexPlaceValueAssembler",
		Vector3.new(42, 11, 8),
		origin + Vector3.new(7, 7, 50),
		C.wood,
		Enum.Material.WoodPlanks
	)
	ctx.reverseBoard = label(reverseMachine, "", Enum.NormalId.Front, 19)
	local reverseConsole = part(
		model,
		"ReverseConversionConsole",
		Vector3.new(8, 5, 7),
		origin + Vector3.new(-18, 3, 38),
		C.dark,
		Enum.Material.Metal
	)
	reverseConsole.CanCollide = false
	local reverseGuide = part(
		model,
		"ReverseGuide",
		Vector3.new(18, 8, 1),
		origin + Vector3.new(-22, 7, 35),
		C.dark,
		Enum.Material.Metal
	)
	reverseGuide.CanCollide = false
	label(reverseGuide, "2D₁₆ → DEC\nUSTAW D = 13\nPOTEM PRZELICZ", Enum.NormalId.Front, 18)

	local reverseMinus =
		part(model, "ReverseHexMinus", Vector3.new(8, 2, 8), origin + Vector3.new(0, 1, 38), C.blue, Enum.Material.Neon)
	label(reverseMinus, "D -1", Enum.NormalId.Top, 20)
	reverseMinus.CanCollide = false
	reverseMinus.CanTouch = false
	local reversePlus = part(
		model,
		"ReverseHexPlus",
		Vector3.new(8, 2, 8),
		origin + Vector3.new(12, 1, 38),
		C.orange,
		Enum.Material.Neon
	)
	label(reversePlus, "D +1", Enum.NormalId.Top, 20)
	reversePlus.CanCollide = false
	reversePlus.CanTouch = false
	for _, data in ipairs({ { reverseMinus, -1 }, { reversePlus, 1 } }) do
		local pr = prompt(data[1], data[2] < 0 and "ZMNIEJSZ" or "ZWIĘKSZ", "WARTOŚĆ CYFRY D", function(who)
			if who ~= player or ctx.rules.stage ~= 3 then
				return
			end
			Rules.AdjustReverseLow(ctx.rules, data[2])
			updateReverse(ctx)
		end)
		pr.Enabled = false
		table.insert(ctx.reversePrompts, pr)
	end
	local reverseValidate = part(
		model,
		"ReverseConversionValidate",
		Vector3.new(15, 5, 7),
		origin + Vector3.new(28, 3, 38),
		C.yellow,
		Enum.Material.Metal
	)
	label(reverseValidate, "PRZELICZ\n2D", Enum.NormalId.Front, 18)
	reverseValidate.CanCollide = false
	reverseValidate.CanTouch = false
	local reversePrompt = prompt(reverseValidate, "PRZELICZ", "HEX → DEC", function(who)
		if who ~= player or ctx.rules.stage ~= 3 then
			return
		end
		local ok, result = Rules.ValidateReverse(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			message(ctx, result.message, false)
			return
		end
		state.score += 45
		updateReverse(ctx)
		message(ctx, result.message, true)
		finish(ctx)
	end)
	reversePrompt.Enabled = false
	table.insert(ctx.reversePrompts, reversePrompt)
	setPrompts(ctx.reversePrompts, false)
	updateReverse(ctx)

	ctx.finalBoardPart = part(
		model,
		"ConversionFinalBoard",
		Vector3.new(48, 8, 2),
		origin + Vector3.new(0, 20, 76),
		C.dark,
		Enum.Material.Metal
	)
	ctx.finalBoard = label(ctx.finalBoardPart, "CONVERSION LINE OFFLINE", Enum.NormalId.Front, 19)
	ctx.finalGate = part(
		model,
		"ConversionFinalGate",
		Vector3.new(30, 15, 4),
		origin + Vector3.new(0, 7.5, 86),
		C.red,
		Enum.Material.Metal
	)
	label(ctx.finalGate, "WYJŚCIE MASZYNY\nZABLOKOWANE", Enum.NormalId.Front, 20)

	hud(
		ctx,
		"ETAP 1/3 • Podejdź do panelu 0/1. Wybierz resztę z 58÷2, potem użyj KROK ÷2. Powtarzaj aż do zera."
	)
	return ctx
end

return ConversionMachine