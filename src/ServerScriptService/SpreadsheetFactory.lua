local SpreadsheetFactory = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("SpreadsheetFactoryRules"))

local C = {
	floor = Color3.fromRGB(71, 76, 82),
	dark = Color3.fromRGB(28, 33, 40),
	steel = Color3.fromRGB(104, 112, 120),
	blue = Color3.fromRGB(70, 139, 226),
	cyan = Color3.fromRGB(55, 207, 221),
	green = Color3.fromRGB(75, 206, 112),
	yellow = Color3.fromRGB(241, 196, 66),
	red = Color3.fromRGB(229, 74, 70),
	orange = Color3.fromRGB(236, 139, 55),
	white = Color3.fromRGB(244, 247, 249),
}

local ROW_LABEL = {
	BATTERY = "BATERIE",
	SENSOR = "CZUJNIKI",
	CABLE = "KABLE",
}

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function label(target, text, face, maxText)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 440)
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 0.04
	txt.BackgroundColor3 = C.dark
	txt.TextColor3 = C.white
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = txt

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = maxText or 32
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 13
	pr.HoldDuration = 0.08
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.5
	l.Range = range or 18
	l.Parent = target
	return l
end

local function message(remote, player, text, good)
	remote:FireClient(player, { kind = "message", text = text, good = good })
end

local function hud(remote, player, title, objective, score)
	remote:FireClient(player, {
		kind = "hud",
		title = title,
		objective = objective,
		score = score or 0,
	})
end

local function tween(target, props, seconds)
	local t = TweenService:Create(
		target,
		TweenInfo.new(seconds or 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		props
	)
	t:Play()
	return t
end

function SpreadsheetFactory.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Fabryka arkusza"
	state.sheetFactory = Rules.NewState()
	state.sheetBusy = false
	state.sheetEntryReady = false

	local formulaPrompts = {}
	local runPrompt
	local minusPrompt
	local plusPrompt
	local syncPrompt

	local function updatePromptStage()
		local stage = state.sheetFactory.stage
		for _, pr in ipairs(formulaPrompts) do
			pr.Enabled = state.sheetEntryReady and stage == 1
		end
		if runPrompt then
			runPrompt.Enabled = state.sheetEntryReady and stage == 1
		end
		if minusPrompt then
			minusPrompt.Enabled = state.sheetEntryReady and stage == 3
		end
		if plusPrompt then
			plusPrompt.Enabled = state.sheetEntryReady and stage == 3
		end
		if syncPrompt then
			syncPrompt.Enabled = state.sheetEntryReady and stage == 3
		end
	end

	local floor = part(
		model,
		"SpreadsheetFactoryFloor",
		Vector3.new(88, 1, 112),
		origin + Vector3.new(0, 0.2, 10),
		C.floor,
		Enum.Material.DiamondPlate
	)
	floor.CanCollide = true

	local entryConsole = part(
		model,
		"SpreadsheetEntryConsole",
		Vector3.new(16, 7, 7),
		origin + Vector3.new(-13, 4, -44),
		C.yellow,
		Enum.Material.Metal
	)
	entryConsole.CanCollide = false
	entryConsole.CanTouch = false
	local entryText = label(entryConsole, "START ARKUSZA\nLINIA OFFLINE", Enum.NormalId.Front, 24)
	local entryLight = light(entryConsole, C.red, 1.2, 14)

	local instructionBoard = part(
		model,
		"SpreadsheetInstructionBoard",
		Vector3.new(28, 10, 1.2),
		origin + Vector3.new(16, 7, -44),
		C.dark,
		Enum.Material.Metal
	)
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. Napraw D2:D5\n2. URUCHOM produkcję\n3. Ustaw B4 tak, by D5=80\nPRZYKŁAD: D2=B2*C2 • D5=SUM(D2:D4)",
		Enum.NormalId.Front,
		20
	)
	instructionBoard.CanCollide = false
	instructionBoard.CanTouch = false

	local entryPrompt
	entryPrompt = prompt(entryConsole, "START ARKUSZA", "panel wejściowy", function(who)
		if who ~= player or state.done or state.sheetEntryReady then
			return
		end
		state.sheetEntryReady = true
		state.objective = "ETAP 1/3 • Napraw D2:D5. Wartość = ILOŚĆ × CENA; suma = SUM(D2:D4)."
		entryConsole.Color = C.green
		entryConsole.Material = Enum.Material.Neon
		entryText.Text = "ARKUSZ ONLINE\nNAPRAW D2:D5"
		entryLight.Color = C.green
		entryLight.Brightness = 2.2
		entryPrompt.Enabled = false
		updatePromptStage()
		hud(remote, player, title, state.objective, state.score)
		message(remote, player, "Panel uruchomiony. Zacznij od D2: B2*C2, potem napraw D3:D5.", true)
	end)

	local back = part(
		model,
		"SpreadsheetFactoryBackWall",
		Vector3.new(84, 20, 2),
		origin + Vector3.new(0, 10, 64),
		C.steel,
		Enum.Material.Metal
	)
	local headerText = label(back, "SPREADSHEET FACTORY • KOMÓRKI STERUJĄ MASZYNAMI", Enum.NormalId.Back, 29)
	headerText.TextColor3 = C.cyan

	local board = part(
		model,
		"SpreadsheetMainBoard",
		Vector3.new(68, 22, 2),
		origin + Vector3.new(0, 12, -38),
		C.dark,
		Enum.Material.Metal
	)
	label(board, "ARKUSZ PRODUKCJI", Enum.NormalId.Front, 34)
	local tableHeader = part(
		model,
		"SpreadsheetHeaderRow",
		Vector3.new(64, 4, 1),
		origin + Vector3.new(0, 17, -36.8),
		C.blue,
		Enum.Material.SmoothPlastic
	)
	label(tableHeader, "A PRODUKT     B ILOŚĆ     C CENA     D WARTOŚĆ", Enum.NormalId.Front, 25)

	local rowY = { BATTERY = 12.2, SENSOR = 7.5, CABLE = 2.8 }
	local rowIndex = { BATTERY = 2, SENSOR = 3, CABLE = 4 }
	local rowPanels = {}
	local formulaText = {}
	local valueText = {}

	for _, row in ipairs(Rules.Rows) do
		local idx = rowIndex[row]
		local panel = part(
			model,
			"SpreadsheetRow_" .. row,
			Vector3.new(64, 4.2, 1),
			origin + Vector3.new(0, rowY[row], -36.7),
			Color3.fromRGB(51, 58, 67),
			Enum.Material.SmoothPlastic
		)
		rowPanels[row] = panel
		local q = state.sheetFactory.quantities[row]
		local price = state.sheetFactory.prices[row]
		valueText[row] = label(
			panel,
			string.format("%s      B%d=%d      C%d=%d      D%d=—", ROW_LABEL[row], idx, q, idx, price, idx),
			Enum.NormalId.Front,
			23
		)
	end

	local totalPanel = part(
		model,
		"SpreadsheetTotalRow",
		Vector3.new(64, 4.2, 1),
		origin + Vector3.new(0, -1.9, -36.7),
		Color3.fromRGB(43, 50, 59),
		Enum.Material.SmoothPlastic
	)
	local totalText = label(totalPanel, "D5 SUMA = —     CEL FABRYKI = 80", Enum.NormalId.Front, 24)

	local formulaDesk = part(
		model,
		"FormulaRepairDesk",
		Vector3.new(72, 1, 28),
		origin + Vector3.new(0, 1, -17),
		Color3.fromRGB(77, 84, 91),
		Enum.Material.Metal
	)
	formulaDesk.CanCollide = true

	local socketOrder = { "D2", "D3", "D4", "D5" }
	local candidates = {
		D2 = { "B2*C2", "B2+C2" },
		D3 = { "B3*C3", "B2*C3" },
		D4 = { "B4*C4", "B4+C4" },
		D5 = { "SUM(D2:D4)", "SUM(B2:C4)" },
	}
	local socketPosX = { -27, -9, 9, 27 }
	local sockets = {}

	for i, cell in ipairs(socketOrder) do
		local socket = part(
			model,
			"FormulaSocket_" .. cell,
			Vector3.new(14, 4.5, 6),
			origin + Vector3.new(socketPosX[i], 3.7, -22),
			C.dark,
			Enum.Material.Metal
		)
		sockets[cell] = socket
		formulaText[cell] = label(socket, cell .. "\nPUSTA", Enum.NormalId.Front, 23)

		for optionIndex, formula in ipairs(candidates[cell]) do
			local chip = part(
				model,
				string.format("FormulaChip_%s_%d", cell, optionIndex),
				Vector3.new(14, 3.5, 5),
				origin + Vector3.new(socketPosX[i], 3.2, -13 + (optionIndex - 1) * 6),
				optionIndex == 1 and C.cyan or C.orange,
				Enum.Material.SmoothPlastic
			)
			label(chip, formula, Enum.NormalId.Front, 20)
			local formulaControl = part(
				model,
				string.format("SpreadsheetFormulaControl_%s_%d", cell, optionIndex),
				Vector3.new(4, 2.6, 4),
				chip.Position + Vector3.new(0, 3.2, 0),
				optionIndex == 1 and C.cyan or C.orange,
				Enum.Material.Metal
			)
			formulaControl.CanCollide = false
			formulaControl.CanTouch = false
			local formulaPrompt = prompt(formulaControl, "WSTAW DO " .. cell, formula, function(who)
				if who ~= player or state.done or state.sheetBusy or state.sheetFactory.stage ~= 1 then
					return
				end
				local ok, reason = Rules.InstallFormula(state.sheetFactory, cell, formula)
				formulaText[cell].Text = cell .. "\n=" .. formula
				socket.Color = ok and C.green or C.red
				socket.Material = Enum.Material.Neon
				formulaControl.Color = ok and C.green or C.red
				formulaControl.Material = Enum.Material.Neon
				if ok then
					state.score += 15
					message(remote, player, cell .. " liczy poprawnie. Wynik od razu trafia do arkusza.", true)
				else
					message(remote, player, reason, false)
				end
				task.defer(function()
					-- refreshed below after all UI helpers are initialized
				end)
			end)
			formulaPrompt.Enabled = false
			table.insert(formulaPrompts, formulaPrompt)
		end
	end
	local runConsole = part(
		model,
		"SpreadsheetRunConsole",
		Vector3.new(24, 6, 8),
		origin + Vector3.new(0, 4, 1),
		C.green,
		Enum.Material.Metal
	)
	label(runConsole, "URUCHOM PRODUKCJĘ", Enum.NormalId.Front, 27)
	local runControl = part(
		model,
		"SpreadsheetRunControl",
		Vector3.new(5, 3, 5),
		origin + Vector3.new(0, 3.2, 7),
		C.green,
		Enum.Material.Metal
	)
	runControl.CanCollide = false
	runControl.CanTouch = false

	local conveyor = part(
		model,
		"SpreadsheetConveyor",
		Vector3.new(18, 1.2, 55),
		origin + Vector3.new(0, 1, 31),
		Color3.fromRGB(54, 61, 68),
		Enum.Material.DiamondPlate
	)
	conveyor.CanCollide = true
	for z = 8, 54, 7 do
		part(
			model,
			"SpreadsheetRoller_" .. z,
			Vector3.new(16, 0.4, 1),
			origin + Vector3.new(0, 1.7, z),
			C.steel,
			Enum.Material.Metal
		).CanCollide =
			false
	end

	local hopperX = { BATTERY = -29, SENSOR = -20, CABLE = -11 }
	local hopperColor = { BATTERY = C.yellow, SENSOR = C.cyan, CABLE = C.orange }
	local hoppers = {}
	local hopperFill = {}
	local pistons = {}
	for _, row in ipairs(Rules.Rows) do
		local shell = part(
			model,
			"Hopper_" .. row,
			Vector3.new(7, 16, 9),
			origin + Vector3.new(hopperX[row], 8, 26),
			Color3.fromRGB(66, 72, 79),
			Enum.Material.Metal
		)
		shell.Transparency = 0.2
		local fill = part(
			model,
			"HopperFill_" .. row,
			Vector3.new(5.5, 1, 7),
			origin + Vector3.new(hopperX[row], 1.8, 26),
			hopperColor[row],
			Enum.Material.Neon
		)
		fill.CanCollide = false
		hopperFill[row] = fill
		hoppers[row] = shell
		local piston = part(
			model,
			"FactoryPiston_" .. row,
			Vector3.new(4, 10, 4),
			origin + Vector3.new(hopperX[row], 13, 39),
			C.steel,
			Enum.Material.Metal
		)
		pistons[row] = piston
		label(shell, ROW_LABEL[row], Enum.NormalId.Front, 19)
	end

	local subtotalTower = part(
		model,
		"SpreadsheetSubtotalTower",
		Vector3.new(14, 18, 12),
		origin + Vector3.new(29, 9, 25),
		Color3.fromRGB(50, 58, 67),
		Enum.Material.Metal
	)
	local subtotalText = label(subtotalTower, "WYNIK\n—", Enum.NormalId.Front, 27)
	local subtotalLight = light(subtotalTower, C.red, 1.2, 16)

	local quantityConsole = part(
		model,
		"SpreadsheetQuantityConsole",
		Vector3.new(30, 8, 10),
		origin + Vector3.new(26, 5, 45),
		C.blue,
		Enum.Material.Metal
	)
	local quantityText = label(quantityConsole, "B4 KABLE = 7\nCEL SUMY: 80", Enum.NormalId.Front, 26)
	local minusButton = part(
		model,
		"SpreadsheetQtyMinus",
		Vector3.new(8, 5, 7),
		origin + Vector3.new(20, 4, 54),
		C.red,
		Enum.Material.SmoothPlastic
	)
	label(minusButton, "-1", Enum.NormalId.Front, 30)
	local minusControl = part(
		model,
		"SpreadsheetQtyMinusControl",
		Vector3.new(4, 3, 4),
		minusButton.Position + Vector3.new(0, 4.2, 0),
		C.red,
		Enum.Material.Metal
	)
	minusControl.CanCollide = false
	minusControl.CanTouch = false
	local plusButton = part(
		model,
		"SpreadsheetQtyPlus",
		Vector3.new(8, 5, 7),
		origin + Vector3.new(32, 4, 54),
		C.green,
		Enum.Material.SmoothPlastic
	)
	label(plusButton, "+1", Enum.NormalId.Front, 30)
	local plusControl = part(
		model,
		"SpreadsheetQtyPlusControl",
		Vector3.new(4, 3, 4),
		plusButton.Position + Vector3.new(0, 4.2, 0),
		C.green,
		Enum.Material.Metal
	)
	plusControl.CanCollide = false
	plusControl.CanTouch = false

	local syncConsole = part(
		model,
		"SpreadsheetSyncConsole",
		Vector3.new(20, 6, 8),
		origin + Vector3.new(0, 4, 58),
		C.cyan,
		Enum.Material.Metal
	)
	label(syncConsole, "SYNC 80\nZASIL FABRYKĘ", Enum.NormalId.Front, 24)
	local syncControl = part(
		model,
		"SpreadsheetSyncControl",
		Vector3.new(5, 3, 5),
		origin + Vector3.new(0, 3.2, 52),
		C.cyan,
		Enum.Material.Metal
	)
	syncControl.CanCollide = false
	syncControl.CanTouch = false

	local generator = part(
		model,
		"SpreadsheetFactoryGenerator",
		Vector3.new(18, 15, 14),
		origin + Vector3.new(-25, 7.5, 53),
		Color3.fromRGB(48, 54, 61),
		Enum.Material.Metal
	)
	local generatorText = label(generator, "GENERATOR\nOFFLINE", Enum.NormalId.Front, 25)
	local generatorLight = light(generator, C.red, 1.4, 18)

	local gate = part(
		model,
		"SpreadsheetFactoryGate",
		Vector3.new(34, 18, 2),
		origin + Vector3.new(0, 9, 65),
		Color3.fromRGB(62, 68, 74),
		Enum.Material.Metal
	)
	label(gate, "MAGAZYN WYSYŁKOWY\nZABLOKOWANY", Enum.NormalId.Back, 25)
	local gateOpen = gate.Position + Vector3.new(0, 20, 0)
	local factoryLights = {}
	for i = 1, 7 do
		local lamp = part(
			model,
			"SpreadsheetFactoryLamp_" .. i,
			Vector3.new(7, 0.7, 3),
			origin + Vector3.new(-36 + (i - 1) * 12, 17, 32),
			Color3.fromRGB(70, 75, 80),
			Enum.Material.Metal
		)
		factoryLights[i] = lamp
	end

	local refresh

	local function previewCell(cell)
		local value = Rules.FormulaValue(state.sheetFactory, cell)
		return value and tostring(value) or "—"
	end

	local function setFill(row, value)
		local fill = hopperFill[row]
		local height = math.clamp(value / 5, 1, 13)
		tween(fill, {
			Size = Vector3.new(5.5, height, 7),
			Position = origin + Vector3.new(hopperX[row], 1.3 + height / 2, 26),
		}, 0.4)
	end

	refresh = function()
		for _, row in ipairs(Rules.Rows) do
			local idx = rowIndex[row]
			local q = state.sheetFactory.quantities[row]
			local price = state.sheetFactory.prices[row]
			local cell = "D" .. idx
			valueText[row].Text = string.format(
				"%s      B%d=%d      C%d=%d      D%d=%s",
				ROW_LABEL[row],
				idx,
				q,
				idx,
				price,
				idx,
				previewCell(cell)
			)
			local realTotal = Rules.RowTotal(state.sheetFactory, row)
			if Rules.FormulaCorrect(state.sheetFactory, cell) then
				setFill(row, realTotal)
			end
		end

		totalText.Text = string.format("D5 SUMA = %s     CEL FABRYKI = %d", previewCell("D5"), Rules.TargetBudget)
		quantityText.Text = string.format(
			"B4 KABLE = %d\nD4 = %d • D5 = %d\nCEL SUMY: %d",
			state.sheetFactory.quantities.CABLE,
			Rules.RowTotal(state.sheetFactory, "CABLE"),
			Rules.GrandTotal(state.sheetFactory),
			Rules.TargetBudget
		)
		subtotalText.Text =
			string.format("SUMA LIVE\n%d / %d", Rules.GrandTotal(state.sheetFactory), Rules.TargetBudget)
		if Rules.TargetReached(state.sheetFactory) then
			subtotalTower.Color = C.green
			subtotalTower.Material = Enum.Material.Neon
			subtotalLight.Color = C.green
			syncControl.Color = C.green
			syncControl.Material = Enum.Material.Neon
		else
			subtotalTower.Color = Color3.fromRGB(50, 58, 67)
			subtotalTower.Material = Enum.Material.Metal
			subtotalLight.Color = C.red
			syncControl.Color = C.cyan
			syncControl.Material = Enum.Material.Metal
		end
		runControl.Material = state.sheetFactory.stage >= 2 and Enum.Material.Neon or Enum.Material.Metal
		updatePromptStage()
		local cableQty = state.sheetFactory.quantities.CABLE
		minusControl.Material = cableQty > 8 and Enum.Material.Neon or Enum.Material.Metal
		plusControl.Material = cableQty < 8 and Enum.Material.Neon or Enum.Material.Metal
		hud(remote, player, title, state.objective, state.score)
	end

	-- Replace the deferred placeholders in formula chip handlers with real refresh hooks.
	for _, cell in ipairs(socketOrder) do
		for _, formula in ipairs(candidates[cell]) do
			-- prompts already own the interaction; UI refresh is picked up by the heartbeat loop below.
		end
	end

	task.spawn(function()
		while model.Parent and not state.done do
			refresh()
			task.wait(0.2)
		end
	end)

	local function animateProduction()
		state.sheetBusy = true
		state.objective = "ETAP 2/3 • Arkusz steruje fizyczną linią. Obserwuj D2:D5 i maszyny."
		refresh()

		local crateStart = origin + Vector3.new(0, 3.5, 6)
		local crateEnd = origin + Vector3.new(0, 3.5, 52)
		for i, row in ipairs(Rules.Rows) do
			local piston = pistons[row]
			local original = piston.Position
			tween(piston, { Position = original + Vector3.new(0, -5, 0) }, 0.22).Completed:Wait()
			tween(piston, { Position = original }, 0.22)

			local crate = part(
				model,
				"SpreadsheetProductCrate_" .. row,
				Vector3.new(7, 5, 7),
				crateStart,
				hopperColor[row],
				Enum.Material.Metal
			)
			crate.CanCollide = false
			label(
				crate,
				string.format("%s\n%d", ROW_LABEL[row], Rules.RowTotal(state.sheetFactory, row)),
				Enum.NormalId.Front,
				20
			)
			local move = tween(crate, { Position = crateEnd + Vector3.new(0, 0, (i - 2) * 3) }, 0.9)
			move.Completed:Wait()
			state.score += 25
		end

		Rules.FinishProduction(state.sheetFactory)
		state.sheetBusy = false
		state.objective = "ETAP 3/3 • Zmień B4 tak, aby D5 automatycznie osiągnęło 80, potem SYNC."
		message(
			remote,
			player,
			"Produkcja gotowa. Teraz zmień jedną komórkę wejściową i obserwuj przeliczenie całego arkusza.",
			true
		)
		refresh()
	end
	runPrompt = prompt(runControl, "URUCHOM", "linia arkusza", function(who)
		if who ~= player or state.done or state.sheetBusy then
			return
		end
		local broken = Rules.FirstBrokenFormula(state.sheetFactory)
		if broken then
			state.score = math.max(0, state.score - 5)
			message(remote, player, "DEBUG W ARKUSZU: " .. broken .. " ma błędną albo pustą formułę.", false)
			return
		end
		local ok, result = Rules.StartProduction(state.sheetFactory)
		if not ok then
			message(remote, player, result, false)
			return
		end
		state.score += 40
		task.spawn(animateProduction)
	end)

	minusPrompt = prompt(minusControl, "ZMNIEJSZ", "B4 -1", function(who)
		if who ~= player or state.done or state.sheetBusy then
			return
		end
		local ok, result = Rules.AdjustQuantity(state.sheetFactory, "CABLE", -1)
		if not ok then
			message(remote, player, result, false)
			return
		end
		state.score += 5
		refresh()
	end)

	plusPrompt = prompt(plusControl, "ZWIĘKSZ", "B4 +1", function(who)
		if who ~= player or state.done or state.sheetBusy then
			return
		end
		local ok, result = Rules.AdjustQuantity(state.sheetFactory, "CABLE", 1)
		if not ok then
			message(remote, player, result, false)
			return
		end
		state.score += 5
		refresh()
	end)

	syncPrompt = prompt(syncControl, "SYNC", "budżet 80", function(who)
		if who ~= player or state.done or state.sheetBusy then
			return
		end
		local ok, reason = Rules.Complete(state.sheetFactory)
		if not ok then
			message(remote, player, "DEBUG SUMY: " .. reason, false)
			return
		end

		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += 180
		state.objective = "Fabryka online: formuły i dane wejściowe poprawnie sterują linią."

		generator.Color = C.green
		generator.Material = Enum.Material.Neon
		generatorText.Text = "GENERATOR\nONLINE • D5=80"
		generatorLight.Color = C.green
		generatorLight.Brightness = 3
		for i, lamp in ipairs(factoryLights) do
			task.delay((i - 1) * 0.1, function()
				lamp.Color = C.cyan
				lamp.Material = Enum.Material.Neon
				light(lamp, C.cyan, 1.4, 15)
			end)
		end
		tween(gate, { Position = gateOpen }, 1.1)
		conveyor.Color = C.cyan
		conveyor.Material = Enum.Material.Neon

		remote:FireClient(player, {
			kind = "objective",
			text = state.objective,
			score = state.score,
		})
		message(
			remote,
			player,
			"Sukces: zmiana B4 przeliczyła D4 i D5, a wynik 80 uruchomił prawdziwą fabrykę.",
			true
		)
		refresh()
	end)

	state.objective = "ETAP START • Uruchom żółty START ARKUSZA przy wejściu i przeczytaj przykład."
	updatePromptStage()
	hud(remote, player, title, state.objective, state.score)
	message(
		remote,
		player,
		"Najpierw uruchom panel wejściowy. Potem arkusz odsłoni aktywne komórki i sterowanie.",
		true
	)
	refresh()
end

return SpreadsheetFactory