local TweenService = game:GetService("TweenService")

local SequenceReactor = {}
local Rules = require(script.Parent:WaitForChild("SequenceReactorRules"))

local C = {
	floor = Color3.fromRGB(218, 232, 242),
	glass = Color3.fromRGB(177, 225, 244),
	frame = Color3.fromRGB(86, 120, 151),
	dark = Color3.fromRGB(23, 42, 62),
	cyan = Color3.fromRGB(68, 207, 235),
	blue = Color3.fromRGB(76, 139, 235),
	purple = Color3.fromRGB(157, 104, 224),
	green = Color3.fromRGB(72, 222, 139),
	yellow = Color3.fromRGB(247, 195, 72),
	red = Color3.fromRGB(238, 86, 82),
	white = Color3.fromRGB(245, 249, 252),
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
	txt.TextStrokeTransparency = 0.45
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
	pr.MaxActivationDistance = 14
	pr.HoldDuration = 0.15
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function tween(instance, goal, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	tw:Play()
	return tw
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

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function setPromptGroup(prompts, enabled)
	for _, pr in ipairs(prompts) do
		pr.Enabled = enabled
	end
end

local function stageLamp(ctx, stage, passed)
	local lamp = ctx.stageLamps[stage]
	if not lamp then
		return
	end
	lamp.Color = passed and C.green or C.yellow
	lamp.Material = passed and Enum.Material.Neon or Enum.Material.SmoothPlastic
end

local function updateTutorialBoard(ctx)
	local values = ctx.rules.tutorialValues
	ctx.tutorialValues.Text = "CIĄG\n" .. table.concat(values, "  →  ")
	ctx.tutorialRule.Text = string.format("REGUŁA\n+%d", ctx.rules.tutorialRule)
end

local function updateRepairCells(ctx)
	for index, cell in ipairs(ctx.repairCells) do
		local value = ctx.rules.repairValues[index]
		ctx.repairLabels[index].Text = tostring(value)
		local scanControl = ctx.repairScanControls[index]
		if ctx.rules.scannedIndex == index then
			local good = value == Rules.Repair.expected[index]
			cell.Color = good and C.green or C.red
			cell.Material = Enum.Material.Neon
			if scanControl then
				scanControl.Color = good and C.green or C.red
				scanControl.Material = Enum.Material.Neon
			end
		else
			cell.Color = C.blue
			cell.Material = Enum.Material.Glass
			if scanControl then
				scanControl.Color = C.frame
				scanControl.Material = Enum.Material.Metal
			end
		end
	end
end

local function updateGeneratorBoards(ctx)
	ctx.generatorLabels.start.Text = string.format("START\n%d", ctx.rules.generator.start)
	ctx.generatorLabels.step.Text = string.format("KROK\n+%d", ctx.rules.generator.step)
	ctx.generatorLabels.count.Text = string.format("N\n%d", ctx.rules.generator.count)
end

local function enterStage2(ctx)
	setPromptGroup(ctx.tutorialPrompts, false)
	setPromptGroup(ctx.repairPrompts, true)
	stageLamp(ctx, 1, true)
	hud(ctx, "ETAP 2/3 • Skanuj ciąg 5, 9, 13, 18, 21. Znajdź i napraw element łamiący regułę +4.")
	message(ctx, "Ręczne generowanie działa. Teraz znajdź uszkodzony element ciągu.", true)
end

local function enterStage3(ctx)
	setPromptGroup(ctx.repairPrompts, false)
	setPromptGroup(ctx.generatorPrompts, true)
	stageLamp(ctx, 2, true)
	hud(ctx, "ETAP 3/3 • Ustaw START=2, KROK=5, N=5 i uruchom generator mostu.")
	message(ctx, "Ciąg naprawiony. Generator parametrów odblokowany.", true)
end

local function finish(ctx, values)
	setPromptGroup(ctx.generatorPrompts, false)
	stageLamp(ctx, 3, true)
	ctx.reactorOrb.Color = C.green
	ctx.reactorOrb.Material = Enum.Material.Neon
	ctx.finalBeam.Color = C.green
	ctx.finalBeam.Material = Enum.Material.Neon
	ctx.bridgeLabel.Text = "MOST CIĄGU ONLINE\n" .. table.concat(values, " • ")

	for index, platform in ipairs(ctx.bridgePlatforms) do
		ctx.bridgeLabels[index].Text = tostring(values[index])
		tween(platform, { Position = ctx.bridgeTargets[index] }, 0.18)
		task.wait(0.08)
	end

	ctx.state.score += 90
	ctx.state.done = true
	hud(ctx, "ETAP 2/3 • Sequence Reactor online. Przejdź do oznaczonego RDZENIA MISJI.")
	message(ctx, string.format("Most zbudowany. Efektywność generatora: %d%%.", Rules.Efficiency(ctx.rules)), true)
end

function SequenceReactor.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		tutorialPrompts = {},
		repairPrompts = {},
		generatorPrompts = {},
		repairCells = {},
		repairLabels = {},
		repairScanControls = {},
		generatorLabels = {},
		stageLamps = {},
		bridgePlatforms = {},
		bridgeTargets = {},
		bridgeLabels = {},
	}

	part(
		model,
		"SequenceReactorFloor",
		Vector3.new(78, 1, 112),
		origin + Vector3.new(0, -0.5, 10),
		C.floor,
		Enum.Material.SmoothPlastic
	)
	part(
		model,
		"SequenceReactorBack",
		Vector3.new(78, 18, 2),
		origin + Vector3.new(0, 9, -44),
		C.glass,
		Enum.Material.Glass
	)

	for index = 1, 4 do
		local column = part(
			model,
			"SequenceReactorColumn_" .. index,
			Vector3.new(3, 18, 3),
			origin + Vector3.new(index % 2 == 0 and 34 or -34, 9, -36 + (index - 1) * 27),
			C.frame,
			Enum.Material.Metal
		)
		column.Shape = Enum.PartType.Cylinder
	end

	local title = part(
		model,
		"SequenceReactorTitle",
		Vector3.new(46, 8, 1),
		origin + Vector3.new(0, 12, -42.5),
		C.dark,
		Enum.Material.SmoothPlastic
	)
	label(title, "SEQUENCE REACTOR\nreguła → iteracja → generator", Enum.NormalId.Front, 22)

	for stage = 1, 3 do
		local lamp = part(
			model,
			"SequenceStageLamp_" .. stage,
			Vector3.new(5, 5, 2),
			origin + Vector3.new(-9 + stage * 9, 13, -33),
			C.yellow,
			Enum.Material.SmoothPlastic
		)
		label(lamp, tostring(stage), Enum.NormalId.Front, 20)
		lamp.CanCollide = false
		table.insert(ctx.stageLamps, lamp)
	end

	-- Stage 1: derive the rule and generate three next values.
	local tutorialBoard = part(
		model,
		"SequenceTutorialBoard",
		Vector3.new(34, 9, 1),
		origin + Vector3.new(-18, 9, -27),
		C.dark,
		Enum.Material.SmoothPlastic
	)
	ctx.tutorialValues = label(tutorialBoard, "", Enum.NormalId.Front, 19)

	local overviewScreen = part(
		model,
		"SequenceReactorOverviewScreen",
		Vector3.new(14, 8, 1),
		origin + Vector3.new(27, 10, -35),
		C.frame,
		Enum.Material.Metal
	)
	overviewScreen.CanCollide = false

	local ruleDial = part(
		model,
		"SequenceRuleDial",
		Vector3.new(10, 8, 2),
		origin + Vector3.new(18, 6, -27),
		C.purple,
		Enum.Material.Glass
	)
	ctx.tutorialRule = label(ruleDial, "", Enum.NormalId.Front, 20)

	local ruleMinus = part(
		model,
		"SequenceRuleMinus",
		Vector3.new(7, 2, 7),
		origin + Vector3.new(-10, 1, -41),
		C.blue,
		Enum.Material.Neon
	)
	label(ruleMinus, "- KROK", Enum.NormalId.Top, 18)
	local rulePlus = part(
		model,
		"SequenceRulePlus",
		Vector3.new(7, 2, 7),
		origin + Vector3.new(0, 1, -41),
		C.cyan,
		Enum.Material.Neon
	)
	label(rulePlus, "+ KROK", Enum.NormalId.Top, 18)
	local nextLever = part(
		model,
		"SequenceNextLever",
		Vector3.new(9, 5, 4),
		origin + Vector3.new(12, 3, -41),
		C.yellow,
		Enum.Material.Metal
	)
	label(nextLever, "NASTĘPNY", Enum.NormalId.Front, 18)

	table.insert(
		ctx.tutorialPrompts,
		prompt(ruleMinus, "ZMNIEJSZ", "REGUŁA", function(who)
			if who ~= player or ctx.rules.stage ~= 1 then
				return
			end
			Rules.AdjustTutorialRule(ctx.rules, -1)
			updateTutorialBoard(ctx)
		end)
	)
	table.insert(
		ctx.tutorialPrompts,
		prompt(rulePlus, "ZWIĘKSZ", "REGUŁA", function(who)
			if who ~= player or ctx.rules.stage ~= 1 then
				return
			end
			Rules.AdjustTutorialRule(ctx.rules, 1)
			updateTutorialBoard(ctx)
		end)
	)
	table.insert(
		ctx.tutorialPrompts,
		prompt(nextLever, "GENERUJ", "NASTĘPNY WYRAZ", function(who)
			if who ~= player or ctx.rules.stage ~= 1 then
				return
			end
			local ok, result = Rules.TutorialNext(ctx.rules)
			if not ok then
				state.score = math.max(0, state.score - 5)
				message(ctx, result.message, false)
				return
			end
			state.score += 20
			updateTutorialBoard(ctx)
			tween(nextLever, { Color = C.green }, 0.12)
			if result.finished then
				enterStage2(ctx)
			else
				message(ctx, result.message, true)
			end
		end)
	)
	updateTutorialBoard(ctx)

	-- Stage 2: scan and repair the corrupted arithmetic sequence.
	local repairTitle = part(
		model,
		"SequenceRepairTitle",
		Vector3.new(32, 7, 1),
		origin + Vector3.new(0, 9, -5),
		C.dark,
		Enum.Material.SmoothPlastic
	)
	label(repairTitle, "SKANER AWARII\nreguła +4", Enum.NormalId.Front, 20)

	local repairScanner = part(
		model,
		"SequenceRepairScanner",
		Vector3.new(8, 7, 7),
		origin + Vector3.new(-27, 4, 20),
		C.frame,
		Enum.Material.Metal
	)
	repairScanner.CanCollide = false

	for index, value in ipairs(ctx.rules.repairValues) do
		local x = (index - 3) * 12
		local cell = part(
			model,
			"SequenceRepairCell_" .. index,
			Vector3.new(7, 7, 7),
			origin + Vector3.new(x, 4, 7),
			C.blue,
			Enum.Material.Glass
		)
		cell.Shape = Enum.PartType.Ball
		local txt = label(cell, tostring(value), Enum.NormalId.Front, 22)
		table.insert(ctx.repairCells, cell)
		table.insert(ctx.repairLabels, txt)

		local scanControl = part(
			model,
			"SequenceRepairScanControl_" .. index,
			Vector3.new(5, 2, 5),
			origin + Vector3.new(x, 1, 14),
			C.frame,
			Enum.Material.Metal
		)
		scanControl.CanCollide = false
		scanControl.CanTouch = false
		label(scanControl, "SCAN " .. index, Enum.NormalId.Top, 18)
		table.insert(ctx.repairScanControls, scanControl)

		local pr = prompt(scanControl, "SKANUJ", "ELEMENT " .. index, function(who)
			if who ~= player or ctx.rules.stage ~= 2 then
				return
			end
			local _, scan = Rules.ScanRepairCell(ctx.rules, index)
			updateRepairCells(ctx)
			message(ctx, scan.message, not scan.faulty)
			hud(
				ctx,
				scan.faulty
						and string.format("ETAP 2/3 • Anomalia w elemencie %d. Użyj ±1 przy konsoli i TEST.", index)
					or "ETAP 2/3 • Ten element jest zgodny. Skanuj dalej."
			)
		end)
		pr.Enabled = false
		table.insert(ctx.repairPrompts, pr)
	end

	local repairMinus = part(
		model,
		"SequenceRepairMinus",
		Vector3.new(8, 2, 8),
		origin + Vector3.new(-12, 1, 20),
		C.blue,
		Enum.Material.Neon
	)
	label(repairMinus, "-1", Enum.NormalId.Top, 22)
	local repairPlus = part(
		model,
		"SequenceRepairPlus",
		Vector3.new(8, 2, 8),
		origin + Vector3.new(0, 1, 20),
		C.cyan,
		Enum.Material.Neon
	)
	label(repairPlus, "+1", Enum.NormalId.Top, 22)
	local repairTest = part(
		model,
		"SequenceRepairTest",
		Vector3.new(10, 5, 5),
		origin + Vector3.new(15, 3, 20),
		C.yellow,
		Enum.Material.Metal
	)
	label(repairTest, "TEST", Enum.NormalId.Front, 20)

	for _, data in ipairs({
		{ repairMinus, -1, "NAPRAW -1" },
		{ repairPlus, 1, "NAPRAW +1" },
	}) do
		local pr = prompt(data[1], data[3], "WYBRANY ELEMENT", function(who)
			if who ~= player or ctx.rules.stage ~= 2 then
				return
			end
			local ok, value = Rules.AdjustRepair(ctx.rules, data[2])
			if not ok then
				message(ctx, value, false)
				return
			end
			updateRepairCells(ctx)
			message(ctx, "Nowa wartość zeskanowanego elementu: " .. value, true)
		end)
		pr.Enabled = false
		table.insert(ctx.repairPrompts, pr)
	end
	local repairTestPrompt = prompt(repairTest, "SPRAWDŹ", "CIĄG +4", function(who)
		if who ~= player or ctx.rules.stage ~= 2 then
			return
		end
		local ok, result = Rules.VerifyRepair(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			message(ctx, result.message, false)
			return
		end
		state.score += 45
		updateRepairCells(ctx)
		enterStage3(ctx)
	end)
	repairTestPrompt.Enabled = false
	table.insert(ctx.repairPrompts, repairTestPrompt)

	-- Stage 3: parameterized generator raises a physical bridge.
	local generatorBoard = part(
		model,
		"SequenceGeneratorBoard",
		Vector3.new(44, 8, 1),
		origin + Vector3.new(0, 10, 34),
		C.dark,
		Enum.Material.SmoothPlastic
	)
	label(generatorBoard, "GENERATOR n-WYRAZOWY\nCEL: START=2 • KROK=5 • N=5", Enum.NormalId.Front, 20)

	local generatorConsole = part(
		model,
		"SequenceGeneratorControlConsole",
		Vector3.new(10, 7, 8),
		origin + Vector3.new(27, 4, 43),
		C.frame,
		Enum.Material.Metal
	)
	generatorConsole.CanCollide = false

	local keys = { "start", "step", "count" }
	local names = { start = "START", step = "KROK", count = "N" }
	for index, key in ipairs(keys) do
		local x = (index - 2) * 18
		local display = part(
			model,
			"SequenceGenerator_" .. key,
			Vector3.new(13, 8, 2),
			origin + Vector3.new(x, 7, 43),
			C.purple,
			Enum.Material.Glass
		)
		ctx.generatorLabels[key] = label(display, "", Enum.NormalId.Front, 20)

		local minus = part(
			model,
			"SequenceGeneratorMinus_" .. key,
			Vector3.new(6, 2, 6),
			origin + Vector3.new(x - 4, 1, 51),
			C.blue,
			Enum.Material.Neon
		)
		label(minus, "-", Enum.NormalId.Top, 22)
		local plus = part(
			model,
			"SequenceGeneratorPlus_" .. key,
			Vector3.new(6, 2, 6),
			origin + Vector3.new(x + 4, 1, 51),
			C.cyan,
			Enum.Material.Neon
		)
		label(plus, "+", Enum.NormalId.Top, 22)

		for _, data in ipairs({
			{ minus, -1 },
			{ plus, 1 },
		}) do
			local pr = prompt(data[1], data[2] < 0 and "ZMNIEJSZ" or "ZWIĘKSZ", names[key], function(who)
				if who ~= player or ctx.rules.stage ~= 3 then
					return
				end
				Rules.AdjustGenerator(ctx.rules, key, data[2])
				updateGeneratorBoards(ctx)
			end)
			pr.Enabled = false
			table.insert(ctx.generatorPrompts, pr)
		end
	end

	local generate = part(
		model,
		"SequenceGenerateButton",
		Vector3.new(16, 5, 8),
		origin + Vector3.new(0, 3, 61),
		C.yellow,
		Enum.Material.Metal
	)
	label(generate, "GENERUJ\nMOST", Enum.NormalId.Front, 20)
	local generatePrompt = prompt(generate, "URUCHOM", "GENERATOR CIĄGU", function(who)
		if who ~= player or ctx.rules.stage ~= 3 then
			return
		end
		local ok, result = Rules.Generate(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			message(ctx, result.message, false)
			return
		end
		finish(ctx, result.values)
	end)
	generatePrompt.Enabled = false
	table.insert(ctx.generatorPrompts, generatePrompt)
	updateGeneratorBoards(ctx)

	ctx.reactorOrb = part(
		model,
		"SequenceReactorOrb",
		Vector3.new(9, 9, 9),
		origin + Vector3.new(-27, 9, 63),
		C.purple,
		Enum.Material.Glass
	)
	ctx.reactorOrb.Shape = Enum.PartType.Ball
	ctx.reactorOrb.CanCollide = false
	ctx.finalBeam = part(
		model,
		"SequenceReactorBeam",
		Vector3.new(4, 14, 4),
		origin + Vector3.new(27, 7, 63),
		C.cyan,
		Enum.Material.Glass
	)
	ctx.finalBeam.Shape = Enum.PartType.Cylinder
	ctx.finalBeam.CanCollide = false

	local bridgeSign = part(
		model,
		"SequenceBridgeSign",
		Vector3.new(40, 7, 1),
		origin + Vector3.new(0, 11, 69),
		C.dark,
		Enum.Material.SmoothPlastic
	)
	ctx.bridgeLabel = label(bridgeSign, "MOST CIĄGU OFFLINE", Enum.NormalId.Front, 19)

	for index = 1, 5 do
		local x = (index - 3) * 11
		local low = origin + Vector3.new(x, -5, 76)
		local target = origin + Vector3.new(x, 2.5, 76)
		local platform =
			part(model, "SequenceBridgePlatform_" .. index, Vector3.new(9, 1.5, 12), low, C.glass, Enum.Material.Glass)
		local txt = label(platform, "?", Enum.NormalId.Top, 20)
		platform.CanCollide = true
		table.insert(ctx.bridgePlatforms, platform)
		table.insert(ctx.bridgeTargets, target)
		table.insert(ctx.bridgeLabels, txt)
	end

	setPromptGroup(ctx.repairPrompts, false)
	setPromptGroup(ctx.generatorPrompts, false)
	hud(ctx, "ETAP 1/3 • Odczytaj regułę ciągu 4, 7, 10. Ustaw KROK i wygeneruj trzy następne wartości.")
	return ctx
end

return SequenceReactor