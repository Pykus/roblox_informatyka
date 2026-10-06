local TweenService = game:GetService("TweenService")

local DataImportDock = {}
local Rules = require(script.Parent:WaitForChild("DataImportDockRules"))

local C = {
	concrete = Color3.fromRGB(112, 118, 122),
	steel = Color3.fromRGB(56, 67, 75),
	dark = Color3.fromRGB(28, 36, 42),
	blue = Color3.fromRGB(52, 145, 208),
	orange = Color3.fromRGB(232, 137, 48),
	cyan = Color3.fromRGB(53, 205, 210),
	green = Color3.fromRGB(55, 205, 112),
	red = Color3.fromRGB(225, 72, 68),
	yellow = Color3.fromRGB(240, 190, 62),
	white = Color3.fromRGB(242, 247, 248),
	paper = Color3.fromRGB(225, 235, 230),
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
	gui.Brightness = 2
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = textColor or C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.48
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
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.GamepadKeyCode = Enum.KeyCode.ButtonX
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.HoldDuration = 0.12
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function tween(instance, props, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		props
	)
	tw:Play()
	return tw
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

local function stageRows(ctx)
	if ctx.rules.stage >= 3 then
		return Rules.TxtRows
	end
	return Rules.CsvRows
end

local function setCell(ctx, index, position, text, color)
	local cell = ctx.cells[index]
	cell.part.Position = position
	cell.part.Color = color or C.paper
	cell.part.Material = Enum.Material.SmoothPlastic
	cell.part.Transparency = 0
	cell.label.Text = text
end

local function alignPreview(ctx)
	local rows = stageRows(ctx)
	local base = ctx.origin + Vector3.new(-12, 3.1, 10)
	local index = 0
	for row = 1, 3 do
		for col = 1, 3 do
			index += 1
			setCell(ctx, index, base + Vector3.new((col - 1) * 12, 0, (row - 1) * 7), rows[row][col], C.paper)
		end
	end
	ctx.previewHeader.Color = C.green
	ctx.previewHeader.Material = Enum.Material.Neon
	ctx.previewTitle.Text = ctx.rules.stage >= 3 and "PREVIEW TXT • 3 × 3" or "PREVIEW CSV • 3 × 3"
end

local function scatterPreview(ctx, problem)
	local rows = stageRows(ctx)
	local base = ctx.origin + Vector3.new(-12, 3.1, 10)
	local index = 0
	for row = 1, 3 do
		for col = 1, 3 do
			index += 1
			local offset
			if problem == "HEADER" and row == 1 then
				offset = Vector3.new((col - 1) * 12, 5, -5)
			else
				offset = Vector3.new(
					(col - 1) * 8 + ((row + col) % 2) * 6,
					((row + col) % 3) * 1.2,
					(row - 1) * 5 + ((row * col) % 2) * 5
				)
			end
			setCell(ctx, index, base + offset, rows[row][col], problem == "HEADER" and C.orange or C.red)
			tween(ctx.cells[index].part, { Orientation = Vector3.new(0, (index % 3 - 1) * 12, (index % 2) * 7) }, 0.16)
		end
	end
	ctx.previewHeader.Color = C.red
	ctx.previewHeader.Material = Enum.Material.Neon
	ctx.previewTitle.Text = problem == "HEADER" and "PREVIEW • NAGŁÓWEK JAK DANE" or "PREVIEW • ROZSYPANE KOLUMNY"
end

local function updateFormatBoards(ctx)
	ctx.separatorText.Text = "SEPARATOR\n" .. ctx.rules.delimiter
	ctx.headerText.Text = "NAGŁÓWKI\n" .. (ctx.rules.headers and "TAK" or "NIE")
end

local function updateTypeBoards(ctx)
	for index, board in ipairs(ctx.typeBoards) do
		board.label.Text = string.format("%s\n%s", Rules.Columns[index], ctx.rules.types[index])
		board.part.Color = ctx.rules.types[index] == Rules.ExpectedTypes[index] and C.green or C.yellow
	end
end

local function updateStageLights(ctx)
	for index, lamp in ipairs(ctx.stageLights) do
		if index < ctx.rules.stage then
			lamp.Color = C.green
			lamp.Material = Enum.Material.Neon
		elseif index == ctx.rules.stage then
			lamp.Color = C.yellow
			lamp.Material = Enum.Material.Neon
		else
			lamp.Color = C.steel
			lamp.Material = Enum.Material.Metal
		end
	end
end

local function updatePromptState(ctx)
	local formatActive = ctx.entryReady and (ctx.rules.stage == 1 or ctx.rules.stage == 3)
	ctx.separatorPrompt.Enabled = formatActive
	ctx.headerPrompt.Enabled = formatActive
	ctx.formatPrompt.Enabled = formatActive

	local typesActive = ctx.entryReady and ctx.rules.stage == 2
	for _, pr in ipairs(ctx.typePrompts) do
		pr.Enabled = typesActive
	end
	ctx.typesPrompt.Enabled = typesActive
end

local function showSource(ctx)
	if ctx.rules.stage >= 3 then
		ctx.csvContainer.Transparency = 0.45
		ctx.txtContainer.Transparency = 0
		ctx.sourceTitle.Text = "AKTYWNY ŁADUNEK: events.txt"
		ctx.sourceData.Text = "101|OK|08:15\n102|WARN|08:16\n103|OK|08:18\n(brak nagłówka)"
	else
		ctx.csvContainer.Transparency = 0
		ctx.txtContainer.Transparency = 0.45
		ctx.sourceTitle.Text = "AKTYWNY ŁADUNEK: sprzedaz.csv"
		ctx.sourceData.Text = "produkt;sztuki;cena\nrobot;4;129.50\nsensor;12;39.90"
	end
end

local function finishDock(ctx)
	ctx.state.done = true
	ctx.state.score += 90
	ctx.finalGate.Color = C.green
	ctx.finalGate.Material = Enum.Material.Neon
	ctx.finalText.Text = "MAGAZYN DANYCH ONLINE\nCSV + TXT PRZYJĘTE"
	ctx.beacon.Color = C.green
	ctx.beacon.Material = Enum.Material.Neon
	tween(ctx.finalGate, { Position = ctx.finalGate.Position + Vector3.new(0, 10, 0) }, 0.7)
	message(
		ctx,
		string.format(
			"Import zakończony. Format + typy + drugi plik poprawne. Efektywność %d%%.",
			Rules.Efficiency(ctx.rules)
		),
		true
	)
	setHud(ctx, "ETAP 3/3 • Import zakończony. Przejdź do świecącego RDZENIA MISJI.")
end

function DataImportDock.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		origin = origin,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		entryReady = false,
		cells = {},
		typeBoards = {},
		typePrompts = {},
		stageLights = {},
	}

	part(
		model,
		"DataDockFloor",
		Vector3.new(84, 1, 76),
		origin + Vector3.new(0, -0.5, -4),
		C.concrete,
		Enum.Material.Concrete
	)
	local back = part(
		model,
		"DataDockBackWall",
		Vector3.new(84, 18, 2),
		origin + Vector3.new(0, 9, 32),
		C.dark,
		Enum.Material.Metal
	)
	label(back, "DATA IMPORT DOCK\nFORMAT → TYPY → IMPORT", Enum.NormalId.Front, 24)

	local entryConsole = part(
		model,
		"DataDockEntryConsole",
		Vector3.new(16, 7, 7),
		origin + Vector3.new(-13, 4, -44),
		C.yellow,
		Enum.Material.Metal
	)
	entryConsole.CanCollide = false
	entryConsole.CanTouch = false
	local entryText = label(entryConsole, "PRZYJMIJ DANE\nDOK OFFLINE", Enum.NormalId.Front, 22)

	local instructionBoard = part(
		model,
		"DataDockInstructionBoard",
		Vector3.new(30, 10, 1.2),
		origin + Vector3.new(16, 7, -44),
		C.dark,
		Enum.Material.Metal
	)
	label(
		instructionBoard,
		"CO ZROBIĆ\nCSV: separator ; + nagłówki TAK\nTXT: separator | + nagłówki NIE\nPotem dopasuj typy kolumn.",
		Enum.NormalId.Front,
		20
	)
	instructionBoard.CanCollide = false
	instructionBoard.CanTouch = false

	local entryPrompt
	entryPrompt = prompt(entryConsole, "PRZYJMIJ DANE", "terminal przyjęcia", function(triggeringPlayer)
		if triggeringPlayer ~= player or ctx.entryReady or ctx.state.done then
			return
		end
		ctx.entryReady = true
		entryPrompt.Enabled = false
		entryConsole.Color = C.green
		entryConsole.Material = Enum.Material.Neon
		entryText.Text = "DOK ONLINE\nCSV GOTOWY DO USTAWIEŃ"
		updatePromptState(ctx)
		setHud(ctx, "ETAP 1/3 • sprzedaz.csv: ustaw separator ; oraz NAGŁÓWKI=TAK, potem TESTUJ.")
		message(ctx, "Ładunek przyjęty. Najpierw ustaw format CSV: separator ; i nagłówki TAK.", true)
	end)

	ctx.csvContainer = part(
		model,
		"DataDockCSVContainer",
		Vector3.new(20, 10, 13),
		origin + Vector3.new(-27, 5, -22),
		C.blue,
		Enum.Material.Metal
	)
	label(ctx.csvContainer, "CSV\nsprzedaz.csv", Enum.NormalId.Front, 20)
	ctx.txtContainer = part(
		model,
		"DataDockTXTContainer",
		Vector3.new(20, 10, 13),
		origin + Vector3.new(27, 5, -22),
		C.orange,
		Enum.Material.Metal
	)
	label(ctx.txtContainer, "TXT\nevents.txt", Enum.NormalId.Front, 20)

	local sourceBoard = part(
		model,
		"DataDockManifest",
		Vector3.new(30, 10, 1),
		origin + Vector3.new(0, 10, -31),
		C.dark,
		Enum.Material.Metal
	)
	ctx.sourceTitle = label(sourceBoard, "AKTYWNY ŁADUNEK", Enum.NormalId.Front, 18)
	local sourceDataBoard = part(
		model,
		"DataDockSourceData",
		Vector3.new(30, 8, 1),
		origin + Vector3.new(0, 3.5, -31),
		C.steel,
		Enum.Material.Metal
	)
	ctx.sourceData = label(sourceDataBoard, "", Enum.NormalId.Front, 18)

	local separatorBoard = part(
		model,
		"DataDockSeparator",
		Vector3.new(11, 8, 5),
		origin + Vector3.new(-14, 4, -13),
		C.yellow,
		Enum.Material.Metal
	)
	ctx.separatorText = label(separatorBoard, "", Enum.NormalId.Front, 20)
	local separatorControl = part(
		model,
		"DataDockSeparatorControl",
		Vector3.new(2.8, 1.2, 2.8),
		separatorBoard.Position + Vector3.new(0, 4.9, 0),
		C.yellow,
		Enum.Material.Metal
	)
	separatorControl.CanCollide = false
	ctx.separatorPrompt = prompt(separatorControl, "ZMIEŃ", "Separator importu", function(triggeringPlayer)
		if triggeringPlayer ~= player then
			return
		end
		local ok, msg = Rules.CycleDelimiter(ctx.rules)
		updateFormatBoards(ctx)
		if ok then
			message(ctx, msg, true)
		end
	end)

	local headerBoard = part(
		model,
		"DataDockHeaders",
		Vector3.new(11, 8, 5),
		origin + Vector3.new(0, 4, -13),
		C.cyan,
		Enum.Material.Metal
	)
	ctx.headerText = label(headerBoard, "", Enum.NormalId.Front, 20)
	local headerControl = part(
		model,
		"DataDockHeaderControl",
		Vector3.new(2.8, 1.2, 2.8),
		headerBoard.Position + Vector3.new(0, 4.9, 0),
		C.cyan,
		Enum.Material.Metal
	)
	headerControl.CanCollide = false
	ctx.headerPrompt = prompt(headerControl, "PRZEŁĄCZ", "Nagłówki", function(triggeringPlayer)
		if triggeringPlayer ~= player then
			return
		end
		local ok, msg = Rules.ToggleHeaders(ctx.rules)
		updateFormatBoards(ctx)
		if ok then
			message(ctx, msg, true)
		end
	end)

	local importBoard = part(
		model,
		"DataDockImport",
		Vector3.new(11, 8, 5),
		origin + Vector3.new(14, 4, -13),
		C.blue,
		Enum.Material.Metal
	)
	label(importBoard, "IMPORT\nTEST", Enum.NormalId.Front, 20)
	local importScanner = part(
		model,
		"DataDockImportScanner",
		Vector3.new(6, 4, 4),
		importBoard.Position + Vector3.new(0, 5.5, 0),
		C.blue,
		Enum.Material.Metal
	)
	importScanner.CanCollide = false
	ctx.formatPrompt = prompt(importScanner, "TESTUJ", "Import pliku", function(triggeringPlayer)
		if triggeringPlayer ~= player then
			return
		end
		local ok, msg, result = Rules.ValidateFormat(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			scatterPreview(ctx, result)
			message(ctx, msg, false)
			return
		end

		state.score += 35
		alignPreview(ctx)
		message(ctx, msg, true)
		if result == "CSV_OK" then
			setHud(ctx, "ETAP 2/3 • Ustaw typy: produkt=TEKST, sztuki=LICZBA, cena=DECIMAL.")
		else
			finishDock(ctx)
		end
		updateStageLights(ctx)
		updatePromptState(ctx)
	end)

	for index, column in ipairs(Rules.Columns) do
		local x = -19 + (index - 1) * 19
		local board = part(
			model,
			"DataDockType_" .. index,
			Vector3.new(15, 8, 4),
			origin + Vector3.new(x, 4, 2),
			C.yellow,
			Enum.Material.Metal
		)
		local txt = label(board, column, Enum.NormalId.Front, 18)
		table.insert(ctx.typeBoards, { part = board, label = txt })
		local typeControl = part(
			model,
			"DataDockTypeControl_" .. index,
			Vector3.new(2.8, 1.2, 2.8),
			board.Position + Vector3.new(0, 4.9, 0),
			C.yellow,
			Enum.Material.Metal
		)
		typeControl.CanCollide = false
		local pr = prompt(typeControl, "ZMIEŃ TYP", column, function(triggeringPlayer)
			if triggeringPlayer ~= player then
				return
			end
			local ok, msg = Rules.CycleType(ctx.rules, index)
			if ok then
				updateTypeBoards(ctx)
				message(ctx, msg, true)
			end
		end)
		table.insert(ctx.typePrompts, pr)
	end

	local typeValidate = part(
		model,
		"DataDockValidateTypes",
		Vector3.new(16, 5, 4),
		origin + Vector3.new(0, 2.5, 10),
		C.blue,
		Enum.Material.Metal
	)
	label(typeValidate, "SPRAWDŹ TYPY", Enum.NormalId.Front, 18)
	local typeValidateConsole = part(
		model,
		"DataDockTypeValidateConsole",
		Vector3.new(8, 5, 5),
		typeValidate.Position + Vector3.new(0, 4.5, 5),
		C.blue,
		Enum.Material.Metal
	)
	typeValidateConsole.CanCollide = false
	ctx.typesPrompt = prompt(typeValidateConsole, "WERYFIKUJ", "Typy kolumn", function(triggeringPlayer)
		if triggeringPlayer ~= player then
			return
		end
		local ok, msg, badColumn = Rules.ValidateTypes(ctx.rules)
		if not ok then
			state.score = math.max(0, state.score - 5)
			if badColumn and ctx.typeBoards[badColumn] then
				ctx.typeBoards[badColumn].part.Color = C.red
			end
			message(ctx, msg, false)
			return
		end
		state.score += 35
		showSource(ctx)
		scatterPreview(ctx, "SCATTER")
		updateFormatBoards(ctx)
		updateStageLights(ctx)
		updatePromptState(ctx)
		message(ctx, msg, true)
		setHud(ctx, "ETAP 3/3 • events.txt używa | i NIE ma nagłówka. Ustaw import i TESTUJ.")
	end)

	ctx.previewHeader = part(
		model,
		"DataDockPreviewHeader",
		Vector3.new(38, 5, 3),
		origin + Vector3.new(0, 9, 22),
		C.red,
		Enum.Material.Neon
	)
	ctx.previewTitle = label(ctx.previewHeader, "PREVIEW IMPORTU", Enum.NormalId.Front, 20)
	for row = 1, 3 do
		for col = 1, 3 do
			local p = part(
				model,
				string.format("DataDockCell_%d_%d", row, col),
				Vector3.new(10, 4, 5),
				origin + Vector3.new(0, 3, 18),
				C.red,
				Enum.Material.SmoothPlastic
			)
			p.CanCollide = false
			local txt = label(p, "?", Enum.NormalId.Top, 18, C.dark)
			table.insert(ctx.cells, { part = p, label = txt })
		end
	end

	for index = 1, 3 do
		local lamp = part(
			model,
			"DataDockStage_" .. index,
			Vector3.new(5, 5, 2),
			origin + Vector3.new(25 + index * 6, 10, 17),
			C.steel,
			Enum.Material.Metal
		)
		label(lamp, tostring(index), Enum.NormalId.Front, 20)
		lamp.CanCollide = false
		table.insert(ctx.stageLights, lamp)
	end

	ctx.finalGate = part(
		model,
		"DataDockWarehouseGate",
		Vector3.new(28, 12, 2),
		origin + Vector3.new(0, 6, 31),
		C.red,
		Enum.Material.Metal
	)
	ctx.finalText = label(ctx.finalGate, "MAGAZYN DANYCH\nOFFLINE", Enum.NormalId.Front, 20)
	ctx.beacon = part(
		model,
		"DataDockBeacon",
		Vector3.new(6, 6, 6),
		origin + Vector3.new(0, 10, 26),
		accent,
		Enum.Material.Glass
	)
	ctx.beacon.Shape = Enum.PartType.Ball
	ctx.beacon.CanCollide = false

	updateFormatBoards(ctx)
	updateTypeBoards(ctx)
	showSource(ctx)
	scatterPreview(ctx, "SCATTER")
	updateStageLights(ctx)
	updatePromptState(ctx)
	setHud(ctx, "ETAP START • Użyj PRZYJMIJ DANE przy wejściu i przeczytaj instrukcję CSV/TXT.")
end

return DataImportDock