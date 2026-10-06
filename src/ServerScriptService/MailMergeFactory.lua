local TweenService = game:GetService("TweenService")

local MailMergeFactory = {}
local Rules = require(script.Parent:WaitForChild("MailMergeRules"))

local C = {
	floor = Color3.fromRGB(224, 218, 198),
	wall = Color3.fromRGB(244, 239, 220),
	wood = Color3.fromRGB(146, 103, 68),
	ink = Color3.fromRGB(42, 46, 54),
	blue = Color3.fromRGB(65, 145, 225),
	cyan = Color3.fromRGB(70, 205, 215),
	green = Color3.fromRGB(65, 195, 112),
	red = Color3.fromRGB(225, 78, 72),
	orange = Color3.fromRGB(235, 154, 58),
	purple = Color3.fromRGB(148, 105, 205),
	paper = Color3.fromRGB(252, 249, 232),
	white = Color3.fromRGB(252, 252, 248),
}

local FIELD_COLORS = {
	IMIE = C.blue,
	KLASA = C.orange,
	MIASTO = C.purple,
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

local function label(target, text, face, minSize, color)
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
	txt.TextColor3 = color or C.ink
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.62
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

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.GamepadKeyCode = Enum.KeyCode.ButtonX
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.HoldDuration = 0.15
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function tween(instance, props, duration)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		props
	)
	t:Play()
	return t
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

local function setPrompts(prompts, enabled)
	for _, pr in ipairs(prompts) do
		pr.Enabled = enabled
	end
end

local function cableBetween(parent, name, a, b, color)
	local delta = b - a
	local cable = part(parent, name, Vector3.new(0.55, 0.55, delta.Magnitude), (a + b) * 0.5, color, Enum.Material.Neon)
	cable.CanCollide = false
	cable.CanTouch = false
	cable.CanQuery = false
	cable.CFrame = CFrame.lookAt((a + b) * 0.5, b)
	return cable
end

local function mappingText(ctx, slot)
	local placeholder = Rules.Expected[slot]
	local source = ctx.rules.mapping[slot]
	return string.format("<<%s>>\n← %s", placeholder, source)
end

local function updateMapping(ctx)
	for slot = 1, 3 do
		local source = ctx.rules.mapping[slot]
		ctx.slotTexts[slot].Text = mappingText(ctx, slot)
		ctx.slotPads[slot].Color = FIELD_COLORS[source]
		local control = ctx.mappingControls[slot]
		if control then
			control.Color = FIELD_COLORS[source]
			control.Material = Enum.Material.Neon
		end
		if ctx.cables[slot] then
			ctx.cables[slot]:Destroy()
		end
		ctx.cables[slot] = cableBetween(
			ctx.model,
			"MailMergeCable_" .. slot,
			ctx.sourceAnchors[source],
			ctx.slotAnchors[slot],
			FIELD_COLORS[source]
		)
	end
	ctx.mappingStatus.Text = string.format(
		"MAPOWANIE\nIMIE←%s   KLASA←%s   MIASTO←%s",
		ctx.rules.mapping[1],
		ctx.rules.mapping[2],
		ctx.rules.mapping[3]
	)
	ctx.mappingStatus.TextColor3 = C.white
end

local function updateStageLights(ctx)
	for index, lamp in ipairs(ctx.stageLights) do
		local done = ctx.rules.stage > index or ctx.rules.completed
		lamp.Color = done and C.green or C.orange
		lamp.Material = done and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end

local function moveRecordToPreview(ctx, index)
	local card = ctx.recordCards[index]
	if not card then
		return
	end
	local home = ctx.recordHomes[index]
	tween(card, { Position = ctx.previewTray.Position + Vector3.new(0, 2.3, 0) }, 0.24).Completed:Wait()
	task.wait(0.1)
	tween(card, { Position = home }, 0.22)
end

local function finish(ctx, letters)
	ctx.state.done = true
	ctx.state.score += 100
	updateStageLights(ctx)
	setPrompts(ctx.previewPrompts, false)
	ctx.printPrompt.Enabled = false
	ctx.printerLight.Color = C.green
	ctx.printerLight.Material = Enum.Material.Neon
	ctx.finalGate.Color = C.green
	ctx.finalGate.Material = Enum.Material.Neon
	ctx.finalLabel.Text = string.format("SERIA GOTOWA\n3 LISTY • %d%%", Rules.Efficiency(ctx.rules))

	for index, text in ipairs(letters) do
		local sheet = ctx.outputSheets[index]
		sheet.Transparency = 0
		ctx.outputTexts[index].Text = text
		tween(sheet, { Position = ctx.outputTargets[index] }, 0.18 + index * 0.03)
		task.wait(0.08)
	end

	tween(ctx.finalGate, { Position = ctx.finalGate.Position + Vector3.new(0, 12, 0) }, 0.45)
	message(ctx, "Korespondencja seryjna gotowa: jeden szablon + dane → trzy różne listy.", true)
	setHud(ctx, "ETAP 2/3 • Seria wydrukowana. Przejdź do świecącego RDZENIA MISJI.")
end

function MailMergeFactory.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		mappingPrompts = {},
		mappingControls = {},
		previewPrompts = {},
		previewControls = {},
		slotPads = {},
		slotTexts = {},
		cables = {},
		stageLights = {},
		recordCards = {},
		recordHomes = {},
		outputSheets = {},
		outputTexts = {},
		outputTargets = {},
		sourceAnchors = {},
		slotAnchors = {},
		intakeCards = {},
		intakeReady = false,
	}

	part(
		model,
		"MailMergeFloor",
		Vector3.new(80, 1, 78),
		origin + Vector3.new(0, -0.5, -6),
		C.floor,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"MailMergeBackWall",
		Vector3.new(80, 18, 2),
		origin + Vector3.new(0, 9, -43),
		C.wall,
		Enum.Material.Brick
	)

	local header = part(
		model,
		"MailMergeHeader",
		Vector3.new(46, 8, 1),
		origin + Vector3.new(0, 13, -41.7),
		C.blue,
		Enum.Material.SmoothPlastic
	)
	label(header, "MAIL MERGE FACTORY\ndane → szablon → podgląd → druk", Enum.NormalId.Front, 22, C.white)

	local intakeCrate = part(
		model,
		"MailMergeIntakeCrate",
		Vector3.new(16, 5, 11),
		origin + Vector3.new(0, 2.5, -44),
		C.wood,
		Enum.Material.WoodPlanks
	)
	intakeCrate.CanCollide = false
	intakeCrate.CanTouch = false
	local intakeText = label(intakeCrate, "DANE WEJŚCIOWE\n3 REKORDY", Enum.NormalId.Front, 20, C.white)

	local sampleLetter = part(
		model,
		"MailMergeSampleLetter",
		Vector3.new(22, 9, 1),
		origin + Vector3.new(24, 7, -39),
		C.paper,
		Enum.Material.SmoothPlastic
	)
	sampleLetter.CanCollide = false
	sampleLetter.CanTouch = false
	label(
		sampleLetter,
		"PRZYKŁAD MAPOWANIA\n<<IMIE>> ← IMIE\n<<KLASA>> ← KLASA\n<<MIASTO>> ← MIASTO",
		Enum.NormalId.Front,
		18,
		C.ink
	)

	for index, record in ipairs(Rules.Records) do
		local intakeCard = part(
			model,
			"MailMergeIntakeCard_" .. index,
			Vector3.new(4.5, 0.45, 7),
			origin + Vector3.new(-5 + (index - 1) * 5, 5.4 + index * 0.08, -44),
			C.paper,
			Enum.Material.SmoothPlastic
		)
		intakeCard.CanCollide = false
		intakeCard.CanTouch = false
		label(intakeCard, record.IMIE, Enum.NormalId.Top, 18, C.ink)
		table.insert(ctx.intakeCards, intakeCard)
	end

	-- Stage 1: data columns and template sockets.
	local dataDesk = part(
		model,
		"MailMergeDataDesk",
		Vector3.new(32, 3, 14),
		origin + Vector3.new(-20, 1.5, -25),
		C.wood,
		Enum.Material.Wood
	)
	label(dataDesk, "ŹRÓDŁO DANYCH", Enum.NormalId.Top, 18, C.white)

	local sourceX = { -29, -20, -11 }
	for index, field in ipairs(Rules.Fields) do
		local column = part(
			model,
			"MailMergeSource_" .. field,
			Vector3.new(7, 8, 2),
			origin + Vector3.new(sourceX[index], 7, -27),
			FIELD_COLORS[field],
			Enum.Material.SmoothPlastic
		)
		label(
			column,
			field
				.. "\n"
				.. Rules.Records[1][field]
				.. "\n"
				.. Rules.Records[2][field]
				.. "\n"
				.. Rules.Records[3][field],
			Enum.NormalId.Front,
			18,
			C.white
		)
		ctx.sourceAnchors[field] = column.Position + Vector3.new(0, -5, 4)
	end

	local templateDesk = part(
		model,
		"MailMergeTemplateDesk",
		Vector3.new(42, 3, 14),
		origin + Vector3.new(13, 1.5, -16),
		C.paper,
		Enum.Material.SmoothPlastic
	)
	label(templateDesk, "SZABLON LISTU", Enum.NormalId.Top, 18, C.ink)

	local templateBoard = part(
		model,
		"MailMergeTemplateBoard",
		Vector3.new(40, 12, 1),
		origin + Vector3.new(13, 10, -22),
		C.paper,
		Enum.Material.SmoothPlastic
	)
	label(
		templateBoard,
		"Cześć <<IMIE>>!\nKlasa <<KLASA>> jedzie na warsztaty\nw mieście <<MIASTO>>.",
		Enum.NormalId.Front,
		18,
		C.ink
	)

	local slotX = { -1, 13, 27 }
	for slot, placeholder in ipairs(Rules.Expected) do
		local pad = part(
			model,
			"MailMergeSlot_" .. placeholder,
			Vector3.new(10, 2, 8),
			origin + Vector3.new(slotX[slot], 3.5, -10),
			C.orange,
			Enum.Material.Metal
		)
		local txt = label(pad, "", Enum.NormalId.Top, 18, C.white)
		table.insert(ctx.slotPads, pad)
		table.insert(ctx.slotTexts, txt)
		ctx.slotAnchors[slot] = pad.Position + Vector3.new(0, 3, -3)
		local control = part(
			model,
			"MailMergeMappingControl_" .. slot,
			Vector3.new(4, 2.6, 4),
			pad.Position + Vector3.new(0, 3.4, 0),
			C.orange,
			Enum.Material.Metal
		)
		control.CanCollide = false
		control.CanTouch = false
		ctx.mappingControls[slot] = control
		table.insert(
			ctx.mappingPrompts,
			prompt(control, "ZMIEŃ KOLUMNĘ", "Mapowanie " .. placeholder, function(who)
				if who ~= player or state.done then
					return
				end
				if not ctx.intakeReady then
					message(ctx, "Najpierw odbierz skrzynkę DANE WEJŚCIOWE przy wejściu.", false)
					return
				end
				local ok, msg = Rules.CycleMapping(ctx.rules, slot)
				if ok then
					updateMapping(ctx)
					message(ctx, msg, true)
				else
					message(ctx, msg, false)
				end
			end)
		)
	end

	local mappingConsole = part(
		model,
		"MailMergeMappingConsole",
		Vector3.new(18, 7, 3),
		origin + Vector3.new(29, 6, -2),
		C.ink,
		Enum.Material.Metal
	)
	ctx.mappingStatus = label(mappingConsole, "", Enum.NormalId.Front, 18, C.white)
	local validatePrompt
	validatePrompt = prompt(mappingConsole, "SPRAWDŹ MAPOWANIE", "Kontroler szablonu", function(who)
		if who ~= player or state.done then
			return
		end
		if not ctx.intakeReady then
			message(ctx, "Najpierw odbierz skrzynkę DANE WEJŚCIOWE przy wejściu.", false)
			return
		end
		local ok, msg = Rules.ValidateMapping(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			ctx.mappingStatus.TextColor3 = C.red
			message(ctx, msg, false)
			return
		end
		state.score += 45
		ctx.mappingStatus.TextColor3 = C.green
		for _, control in ipairs(ctx.mappingControls) do
			control.Color = C.green
			control.Material = Enum.Material.Neon
		end
		setPrompts(ctx.mappingPrompts, false)
		validatePrompt.Enabled = false
		setPrompts(ctx.previewPrompts, true)
		for _, control in ipairs(ctx.previewControls) do
			control.Material = Enum.Material.Neon
		end
		updateStageLights(ctx)
		message(ctx, msg, true)
		setHud(ctx, "ETAP 2/3 • Podejdź do trzech kart rekordów i sprawdź każdy PODGLĄD.")
	end)
	table.insert(ctx.mappingPrompts, validatePrompt)

	-- Stage 2: three physical data cards and live merged preview.
	ctx.previewTray = part(
		model,
		"MailMergePreviewTray",
		Vector3.new(26, 2, 14),
		origin + Vector3.new(0, 2, 13),
		C.cyan,
		Enum.Material.Glass
	)
	local previewBoard = part(
		model,
		"MailMergePreviewBoard",
		Vector3.new(40, 11, 1),
		origin + Vector3.new(0, 11, 20),
		C.ink,
		Enum.Material.Metal
	)
	ctx.previewText = label(previewBoard, "PODGLĄD\nczeka na rekord", Enum.NormalId.Front, 18, C.white)

	local cardX = { -27, 0, 27 }
	for index, record in ipairs(Rules.Records) do
		local home = origin + Vector3.new(cardX[index], 4, 5)
		local card = part(
			model,
			"MailMergeRecord_" .. index,
			Vector3.new(15, 1.2, 10),
			home,
			C.paper,
			Enum.Material.SmoothPlastic
		)
		label(
			card,
			string.format("REKORD %d\n%s | %s | %s", index, record.IMIE, record.KLASA, record.MIASTO),
			Enum.NormalId.Top,
			17,
			C.ink
		)
		ctx.recordCards[index] = card
		ctx.recordHomes[index] = home
		local previewControl = part(
			model,
			"MailMergePreviewControl_" .. index,
			Vector3.new(4, 2.6, 4),
			home + Vector3.new(0, 2.8, 0),
			C.cyan,
			Enum.Material.Metal
		)
		previewControl.CanCollide = false
		previewControl.CanTouch = false
		ctx.previewControls[index] = previewControl
		local pr = prompt(previewControl, "PODGLĄD", "Rekord " .. index, function(who)
			if who ~= player or state.done then
				return
			end
			local ok, msg, rendered = Rules.Preview(ctx.rules, index)
			if not ok then
				message(ctx, msg, false)
				return
			end
			moveRecordToPreview(ctx, index)
			ctx.previewControls[index].Color = C.green
			ctx.previewControls[index].Material = Enum.Material.Neon
			ctx.previewText.Text = string.format("PODGLĄD %d/3\n%s", ctx.rules.previewCount, rendered)
			state.score += 20
			message(ctx, msg, true)
			if ctx.rules.stage == 3 then
				setPrompts(ctx.previewPrompts, false)
				ctx.printPrompt.Enabled = true
				ctx.printPad.Color = C.green
				ctx.printPad.Material = Enum.Material.Neon
				ctx.printControl.Color = C.green
				ctx.printControl.Material = Enum.Material.Neon
				updateStageLights(ctx)
				setHud(ctx, "ETAP 3/3 • Wszystkie podglądy gotowe. Uruchom DRUK SERII.")
			end
		end)
		pr.Enabled = false
		table.insert(ctx.previewPrompts, pr)
	end

	-- Stage 3: printer and physical output conveyor.
	local printer = part(
		model,
		"MailMergePrinter",
		Vector3.new(24, 15, 18),
		origin + Vector3.new(22, 7.5, 24),
		C.white,
		Enum.Material.Metal
	)
	label(printer, "DRUKARKA SERYJNA", Enum.NormalId.Front, 20, C.ink)
	ctx.printerLight = part(
		model,
		"MailMergePrinterLight",
		Vector3.new(5, 5, 2),
		origin + Vector3.new(22, 13, 14.5),
		C.red,
		Enum.Material.Neon
	)
	ctx.printerLight.CanCollide = false

	local printButton = part(
		model,
		"MailMergePrintButton",
		Vector3.new(8, 3, 8),
		origin + Vector3.new(22, 3, 11),
		Color3.fromRGB(76, 110, 91),
		Enum.Material.Metal
	)
	ctx.printPad = printButton
	ctx.printControl = part(
		model,
		"MailMergePrintControl",
		Vector3.new(4.5, 2.8, 4.5),
		printButton.Position + Vector3.new(0, 3.4, 0),
		Color3.fromRGB(76, 110, 91),
		Enum.Material.Metal
	)
	ctx.printControl.CanCollide = false
	ctx.printControl.CanTouch = false
	ctx.printPrompt = prompt(ctx.printControl, "DRUKUJ SERIĘ", "3 rekordy", function(who)
		if who ~= player or state.done then
			return
		end
		local ok, msg, letters = Rules.PrintBatch(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			message(ctx, msg, false)
			return
		end
		finish(ctx, letters)
	end)
	ctx.printPrompt.Enabled = false

	local outputBelt = part(
		model,
		"MailMergeOutputConveyor",
		Vector3.new(44, 2, 12),
		origin + Vector3.new(-8, 1, 31),
		C.wood,
		Enum.Material.Metal
	)
	for index = 1, 3 do
		local sheet = part(
			model,
			"MailMergeOutputLetter_" .. index,
			Vector3.new(12, 0.5, 8),
			origin + Vector3.new(20, 4, 24),
			C.paper,
			Enum.Material.SmoothPlastic
		)
		sheet.Transparency = 1
		sheet.CanCollide = false
		ctx.outputSheets[index] = sheet
		ctx.outputTexts[index] = label(sheet, "", Enum.NormalId.Top, 18, C.ink)
		ctx.outputTargets[index] = origin + Vector3.new(-21 + (index - 1) * 13, 3.2, 31)
	end

	ctx.finalGate = part(
		model,
		"MailMergeFinalGate",
		Vector3.new(24, 12, 2),
		origin + Vector3.new(0, 6, 43),
		C.red,
		Enum.Material.Metal
	)
	ctx.finalLabel = label(ctx.finalGate, "DRUK ZABLOKOWANY\nMAPOWANIE + 3 PODGLĄDY", Enum.NormalId.Front, 18, C.white)

	for index = 1, 3 do
		local lamp = part(
			model,
			"MailMergeStageLamp_" .. index,
			Vector3.new(5, 5, 2),
			origin + Vector3.new(-8 + index * 8, 14, 35),
			C.orange,
			Enum.Material.SmoothPlastic
		)
		label(lamp, tostring(index), Enum.NormalId.Front, 20, C.white)
		lamp.CanCollide = false
		table.insert(ctx.stageLights, lamp)
	end

	updateMapping(ctx)
	updateStageLights(ctx)
	setPrompts(ctx.mappingPrompts, false)

	local intakePrompt
	intakePrompt = prompt(intakeCrate, "ODBIERZ DANE", "Kartoteka • 3 rekordy", function(who)
		if who ~= player or ctx.intakeReady or state.done then
			return
		end
		ctx.intakeReady = true
		intakePrompt.Enabled = false
		intakeCrate.Color = C.green
		intakeCrate.Material = Enum.Material.Neon
		intakeText.Text = "DANE ODEBRANE\n3/3 REKORDY"
		for index, card in ipairs(ctx.intakeCards) do
			local target = dataDesk.Position + Vector3.new(-8 + (index - 1) * 8, 2.1 + index * 0.12, 0)
			task.delay((index - 1) * 0.08, function()
				if card.Parent then
					tween(card, { Position = target }, 0.38)
				end
			end)
		end
		setPrompts(ctx.mappingPrompts, true)
		setHud(ctx, "ETAP 1/3 • Dane są na biurku. Popraw <<IMIE>>, <<KLASA>>, <<MIASTO>> i SPRAWDŹ MAPOWANIE.")
		message(
			ctx,
			"Kartoteka odebrana. Użyj przykładu przy wejściu: placeholder ma wskazywać kolumnę o tej samej nazwie.",
			true
		)
	end)

	setHud(ctx, "ETAP START • Odbierz skrzynkę DANE WEJŚCIOWE przy wejściu. Potem popraw mapowanie pól szablonu.")
	message(ctx, "Zacznij od skrzynki z 3 rekordami. Obok masz przykład: <<IMIE>> ← IMIE.", true)
end

return MailMergeFactory