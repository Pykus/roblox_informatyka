local SearchRace = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("SearchRaceRules"))

local C = {
	dark = Color3.fromRGB(24, 28, 38),
	track = Color3.fromRGB(48, 54, 67),
	blue = Color3.fromRGB(67, 139, 229),
	cyan = Color3.fromRGB(54, 210, 223),
	green = Color3.fromRGB(76, 210, 116),
	yellow = Color3.fromRGB(244, 204, 70),
	orange = Color3.fromRGB(237, 145, 55),
	red = Color3.fromRGB(232, 72, 75),
	purple = Color3.fromRGB(154, 89, 207),
	white = Color3.fromRGB(243, 246, 249),
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
	gui.CanvasSize = Vector2.new(900, 420)
	gui.LightInfluence = 0
	gui.Brightness = 1.15
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

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = maxText or 29
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 13
	pr.HoldDuration = 0.06
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.4
	l.Range = range or 15
	l.Parent = target
	return l
end

local function tween(target, props, seconds)
	local t = TweenService:Create(
		target,
		TweenInfo.new(seconds or 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		props
	)
	t:Play()
	return t
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

function SearchRace.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Wyścig wyszukiwania"
	state.searchRace = Rules.NewState()
	state.searchBusy = false
	state.searchEntryReady = false

	local floor = part(
		model,
		"SearchRaceFloor",
		Vector3.new(88, 1, 112),
		origin + Vector3.new(0, 0.15, 10),
		Color3.fromRGB(39, 43, 55),
		Enum.Material.SmoothPlastic
	)
	floor.CanCollide = true

	local arch = part(
		model,
		"SearchRaceArch",
		Vector3.new(70, 9, 2),
		origin + Vector3.new(0, 22, -44),
		C.purple,
		Enum.Material.Neon
	)
	label(arch, "SEARCH RACE • CEL = 71\nLINIOWE  VS  BINARNE", Enum.NormalId.Front, 31)
	light(arch, C.purple, 1.8, 22)

	local targetBoard = part(
		model,
		"SearchRaceTarget",
		Vector3.new(30, 10, 2),
		origin + Vector3.new(0, 10, -34),
		C.dark,
		Enum.Material.Metal
	)
	local targetText = label(targetBoard, "SZUKAMY: 71\nNAJPIERW START WYSZUKIWANIA", Enum.NormalId.Front, 28)

	local entryConsole = part(
		model,
		"SearchRaceEntryConsole",
		Vector3.new(14, 5, 8),
		origin + Vector3.new(0, 3.5, -43),
		C.purple,
		Enum.Material.Metal
	)
	entryConsole.CanCollide = false
	local entryText = label(entryConsole, "START\nWYSZUKIWANIA", Enum.NormalId.Front, 24)
	light(entryConsole, C.cyan, 1.3, 14)

	local instructionBoard = part(
		model,
		"SearchRaceInstructionBoard",
		Vector3.new(32, 9, 2),
		origin + Vector3.new(19, 9, -37),
		C.dark,
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	label(
		instructionBoard,
		"JAK SZUKAĆ 71?\n1. LINIOWO: sprawdzaj po kolei\n2. BINARNIE: dane muszą być uporządkowane\nPRZYKŁAD: 37 < 71 → CEL WIĘKSZY",
		Enum.NormalId.Front,
		19
	)
	light(instructionBoard, C.blue, 1.0, 13)

	local laneX = { LINEAR = -23, BINARY = 23 }
	local startZ = -23
	local spacing = 6.2
	local shelfZ = {}
	local linearShelves = {}
	local binaryShelves = {}
	local shelfColors = {}

	for i, value in ipairs(Rules.Values) do
		local z = startZ + (i - 1) * spacing
		shelfZ[i] = z
		local baseColor = i % 2 == 0 and Color3.fromRGB(73, 81, 96) or Color3.fromRGB(60, 69, 84)
		shelfColors[i] = baseColor

		local linear = part(
			model,
			"SearchLinearShelf_" .. i,
			Vector3.new(14, 5, 5),
			origin + Vector3.new(laneX.LINEAR, 3.4, z),
			baseColor,
			Enum.Material.Metal
		)
		label(linear, tostring(value), Enum.NormalId.Front, 28)
		linearShelves[i] = linear

		local binary = part(
			model,
			"SearchBinaryShelf_" .. i,
			Vector3.new(14, 5, 5),
			origin + Vector3.new(laneX.BINARY, 3.4, z),
			baseColor,
			Enum.Material.Metal
		)
		label(binary, tostring(value), Enum.NormalId.Front, 28)
		binaryShelves[i] = binary
	end

	local linearRail = part(
		model,
		"SearchLinearRail",
		Vector3.new(5, 0.7, 78),
		origin + Vector3.new(laneX.LINEAR, 1, 11),
		C.blue,
		Enum.Material.Neon
	)
	linearRail.CanCollide = false
	local binaryRail = part(
		model,
		"SearchBinaryRail",
		Vector3.new(5, 0.7, 78),
		origin + Vector3.new(laneX.BINARY, 1, 11),
		C.cyan,
		Enum.Material.Neon
	)
	binaryRail.CanCollide = false

	local linearBotStart = origin + Vector3.new(laneX.LINEAR, 7, startZ - 7)
	local binaryBotStart = origin + Vector3.new(laneX.BINARY, 7, startZ - 7)
	local linearBot = part(model, "LinearSearchBot", Vector3.new(7, 7, 7), linearBotStart, C.blue, Enum.Material.Neon)
	linearBot.Shape = Enum.PartType.Ball
	linearBot.CanCollide = false
	label(linearBot, "L", Enum.NormalId.Front, 30)
	local linearLight = light(linearBot, C.blue, 2, 16)

	local binaryBot = part(model, "BinarySearchBot", Vector3.new(7, 7, 7), binaryBotStart, C.cyan, Enum.Material.Neon)
	binaryBot.Shape = Enum.PartType.Ball
	binaryBot.CanCollide = false
	label(binaryBot, "B", Enum.NormalId.Front, 30)
	local binaryLight = light(binaryBot, C.cyan, 2, 16)

	local linearScore = part(
		model,
		"LinearSearchScore",
		Vector3.new(18, 8, 2),
		origin + Vector3.new(-30, 10, -34),
		C.dark,
		Enum.Material.Metal
	)
	local linearScoreText = label(linearScore, "LINIOWE\n0 SPRAWDZEŃ", Enum.NormalId.Front, 25)

	local binaryScore = part(
		model,
		"BinarySearchScore",
		Vector3.new(18, 8, 2),
		origin + Vector3.new(30, 10, -34),
		C.dark,
		Enum.Material.Metal
	)
	local binaryScoreText = label(binaryScore, "BINARNE\n0 SPRAWDZEŃ", Enum.NormalId.Front, 25)
	local linearNext = part(
		model,
		"LinearSearchNext",
		Vector3.new(20, 6, 8),
		origin + Vector3.new(-28, 4, -31),
		C.blue,
		Enum.Material.Metal
	)
	label(linearNext, "SKANUJ NASTĘPNY\nLINEAR", Enum.NormalId.Front, 24)

	local decisionBoard = part(
		model,
		"BinaryDecisionBoard",
		Vector3.new(32, 10, 2),
		origin + Vector3.new(0, 10, 53),
		C.dark,
		Enum.Material.Metal
	)
	local decisionText = label(decisionBoard, "BINARNE CZEKA\nNA KONIEC LINIOWEGO", Enum.NormalId.Front, 25)

	local lowerButton = part(
		model,
		"BinaryDecisionLower",
		Vector3.new(17, 5, 7),
		origin + Vector3.new(-20, 4, 54),
		C.yellow,
		Enum.Material.SmoothPlastic
	)
	label(lowerButton, "CEL MNIEJSZY", Enum.NormalId.Front, 22)

	local foundButton = part(
		model,
		"BinaryDecisionFound",
		Vector3.new(17, 5, 7),
		origin + Vector3.new(0, 4, 54),
		C.green,
		Enum.Material.SmoothPlastic
	)
	label(foundButton, "ZNALEZIONO", Enum.NormalId.Front, 23)

	local higherButton = part(
		model,
		"BinaryDecisionHigher",
		Vector3.new(17, 5, 7),
		origin + Vector3.new(20, 4, 54),
		C.orange,
		Enum.Material.SmoothPlastic
	)
	label(higherButton, "CEL WIĘKSZY", Enum.NormalId.Front, 22)

	local raceConsole = part(
		model,
		"SearchRaceConsole",
		Vector3.new(24, 7, 9),
		origin + Vector3.new(0, 4.5, 42),
		C.purple,
		Enum.Material.Metal
	)
	label(raceConsole, "FINAŁ\nURUCHOM WYŚCIG", Enum.NormalId.Front, 24)
	local racePrompt
	local entryPrompt

	local trophy = part(
		model,
		"SearchRaceTrophy",
		Vector3.new(12, 16, 12),
		origin + Vector3.new(0, 8, 62),
		Color3.fromRGB(55, 59, 70),
		Enum.Material.Metal
	)
	local trophyText = label(trophy, "CZEKAM NA WYNIK", Enum.NormalId.Front, 24)
	local trophyLight = light(trophy, C.red, 0.6, 17)

	local gate = part(
		model,
		"SearchRaceGate",
		Vector3.new(34, 18, 2),
		origin + Vector3.new(0, 9, 65),
		Color3.fromRGB(66, 70, 82),
		Enum.Material.Metal
	)
	label(gate, "META ZABLOKOWANA\nPORÓWNAJ ALGORYTMY", Enum.NormalId.Back, 24)
	local gateOpen = gate.Position + Vector3.new(0, 20, 0)

	local finishLamps = {}
	for i = 1, 6 do
		local lamp = part(
			model,
			"SearchRaceLamp_" .. i,
			Vector3.new(7, 0.7, 2.5),
			origin + Vector3.new(-30 + (i - 1) * 12, 18, 37),
			Color3.fromRGB(69, 73, 82),
			Enum.Material.Metal
		)
		finishLamps[i] = lamp
	end

	local function botPos(lane, index)
		return origin + Vector3.new(laneX[lane], 7, shelfZ[index])
	end

	local function updateHud()
		if not state.searchEntryReady then
			state.objective = "START • Uruchom START WYSZUKIWANIA przy wejściu i przeczytaj przykład."
		elseif state.searchRace.stage == 1 then
			state.objective = "ETAP 1/3 • Wyszukiwanie liniowe: sprawdzaj półki od początku, aż znajdziesz 71."
		elseif state.searchRace.stage == 2 then
			state.objective = "ETAP 2/3 • Binarne: po każdym środku wybierz CEL MNIEJSZY / WIĘKSZY / ZNALEZIONO."
		else
			state.objective = "ETAP 3/3 • Oba algorytmy gotowe. Uruchom fizyczny wyścig."
		end
		hud(remote, player, title, state.objective, state.score)
	end

	local function updateBinaryRange()
		local current = Rules.BinaryCurrent(state.searchRace)
		if not current then
			return
		end
		for i, shelf in ipairs(binaryShelves) do
			local active = i >= current.low and i <= current.high
			shelf.Transparency = active and 0 or 0.7
			shelf.Material = i == current.index and Enum.Material.Neon or Enum.Material.Metal
			shelf.Color = i == current.index and C.cyan or shelfColors[i]
		end
		decisionText.Text =
			string.format("ŚRODEK: %d\nZAKRES %d..%d\nCEL = 71", current.value, current.low, current.high)
		binaryScoreText.Text = string.format("BINARNE\n%d SPRAWDZEŃ", state.searchRace.binaryChecks)
	end
	local lowerPrompt, higherPrompt, foundPrompt
	local linearPrompt = prompt(linearNext, "SKANUJ", "następna półka", function(who)
		if who ~= player or state.done or state.searchBusy or state.searchRace.stage ~= 1 then
			return
		end
		state.searchBusy = true
		local ok, result = Rules.LinearNext(state.searchRace)
		if not ok then
			state.searchBusy = false
			message(remote, player, result, false)
			return
		end

		tween(linearBot, { Position = botPos("LINEAR", result.index) }, 0.28).Completed:Wait()
		local shelf = linearShelves[result.index]
		shelf.Color = result.found and C.green or C.blue
		shelf.Material = Enum.Material.Neon
		linearScoreText.Text = string.format("LINIOWE\n%d SPRAWDZEŃ", result.checks)
		state.score += result.found and 30 or 4

		if result.found then
			linearLight.Color = C.green
			targetText.Text = string.format("LINIOWE: %d KROKÓW\nTERAZ BINARNE", result.checks)
			message(remote, player, "Liniowe znalazło 71 dopiero po przejściu kolejnych półek.", true)
			linearPrompt.Enabled = false
			lowerPrompt.Enabled = true
			higherPrompt.Enabled = true
			foundPrompt.Enabled = true
			local current = Rules.BinaryCurrent(state.searchRace)
			tween(binaryBot, { Position = botPos("BINARY", current.index) }, 0.55)
			updateBinaryRange()
		else
			message(remote, player, string.format("Sprawdzono %d — to nie 71.", result.value), false)
		end
		state.searchBusy = false
		updateHud()
	end)
	linearPrompt.Enabled = false

	local function binaryDecision(decision)
		if state.done or state.searchBusy or state.searchRace.stage ~= 2 then
			return
		end
		state.searchBusy = true
		local ok, result = Rules.BinaryDecision(state.searchRace, decision)
		if not ok then
			decisionBoard.Color = C.red
			decisionBoard.Material = Enum.Material.Neon
			message(remote, player, "DEBUG BINARNE: " .. tostring(result), false)
			state.score = math.max(0, state.score - 5)
			state.searchBusy = false
			updateHud()
			return
		end

		state.score += result.found and 45 or 12
		binaryScoreText.Text = string.format("BINARNE\n%d SPRAWDZEŃ", result.checks)
		if result.found then
			binaryLight.Color = C.green
			decisionBoard.Color = C.green
			decisionBoard.Material = Enum.Material.Neon
			decisionText.Text = string.format("71 ZNALEZIONE!\nBINARNE: %d SPRAWDZENIA", result.checks)
			targetText.Text = string.format(
				"LINIOWE %d  VS  BINARNE %d\nOSZCZĘDZONE: %d",
				state.searchRace.linearChecks,
				state.searchRace.binaryChecks,
				state.searchRace.linearChecks - state.searchRace.binaryChecks
			)
			lowerPrompt.Enabled = false
			higherPrompt.Enabled = false
			foundPrompt.Enabled = false
			racePrompt.Enabled = true
			message(remote, player, "Binarne odrzucało połowę zakresu po każdym porównaniu.", true)
		else
			decisionBoard.Color = C.dark
			decisionBoard.Material = Enum.Material.Metal
			local current = Rules.BinaryCurrent(state.searchRace)
			tween(binaryBot, { Position = botPos("BINARY", current.index) }, 0.48).Completed:Wait()
			updateBinaryRange()
		end
		state.searchBusy = false
		updateHud()
	end

	lowerPrompt = prompt(lowerButton, "WYBIERZ", "CEL MNIEJSZY", function(who)
		if who == player then
			binaryDecision("LOWER")
		end
	end)
	higherPrompt = prompt(higherButton, "WYBIERZ", "CEL WIĘKSZY", function(who)
		if who == player then
			binaryDecision("HIGHER")
		end
	end)
	foundPrompt = prompt(foundButton, "WYBIERZ", "ZNALEZIONO", function(who)
		if who == player then
			binaryDecision("FOUND")
		end
	end)
	lowerPrompt.Enabled = false
	higherPrompt.Enabled = false
	foundPrompt.Enabled = false
	local function animateLinearRace()
		linearBot.Position = linearBotStart
		for i = 1, 10 do
			local move = tween(linearBot, { Position = botPos("LINEAR", i) }, 0.23)
			move.Completed:Wait()
			linearShelves[i].Color = i == 10 and C.green or C.blue
			linearShelves[i].Material = Enum.Material.Neon
		end
	end

	local function animateBinaryRace()
		binaryBot.Position = binaryBotStart
		for _, index in ipairs(Rules.BinaryPath()) do
			local move = tween(binaryBot, { Position = botPos("BINARY", index) }, 0.42)
			move.Completed:Wait()
			binaryShelves[index].Color = index == 10 and C.green or C.cyan
			binaryShelves[index].Material = Enum.Material.Neon
		end
	end

	local function finale()
		local ok, result = Rules.Complete(state.searchRace)
		if not ok then
			state.searchBusy = false
			message(remote, player, result, false)
			return
		end
		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += 180
		trophy.Color = C.green
		trophy.Material = Enum.Material.Neon
		trophyText.Text = string.format(
			"BINARNE WYGRYWA\n%d vs %d\n-%d SPRAWDZEŃ",
			result.binaryChecks,
			result.linearChecks,
			result.saved
		)
		trophyLight.Color = C.green
		trophyLight.Brightness = 3
		tween(gate, { Position = gateOpen }, 1.1)
		for i, lamp in ipairs(finishLamps) do
			task.delay((i - 1) * 0.1, function()
				lamp.Color = i % 2 == 0 and C.cyan or C.purple
				lamp.Material = Enum.Material.Neon
				light(lamp, lamp.Color, 1.3, 14)
			end)
		end
		remote:FireClient(player, {
			kind = "objective",
			text = string.format(
				"Wyścig zakończony: liniowe %d sprawdzeń, binarne %d. Binarne wygrało.",
				result.linearChecks,
				result.binaryChecks
			),
			score = state.score,
		})
		message(
			remote,
			player,
			"Sukces: uporządkowane dane pozwoliły za każdym krokiem odrzucić połowę zakresu.",
			true
		)
		state.searchBusy = false
		updateHud()
	end

	racePrompt = prompt(raceConsole, "START WYŚCIGU", "LINEAR vs BINARY", function(who)
		if who ~= player or state.done or state.searchBusy or not Rules.CanRace(state.searchRace) then
			return
		end
		state.searchBusy = true
		racePrompt.Enabled = false
		targetText.Text = "WYŚCIG W TOKU\n10 KROKÓW vs 4 KROKI"
		task.spawn(animateLinearRace)
		task.spawn(animateBinaryRace)
		task.delay(0.9, finale)
	end)
	racePrompt.Enabled = false

	entryPrompt = prompt(entryConsole, "START WYSZUKIWANIA", "Search Race", function(who)
		if who ~= player or state.done or state.searchEntryReady then
			return
		end
		state.searchEntryReady = true
		entryPrompt.Enabled = false
		entryConsole.Color = C.green
		entryConsole.Material = Enum.Material.Neon
		entryText.Text = "SYSTEM\nAKTYWNY"
		targetText.Text = "SZUKAMY: 71\nETAP 1 • LINIOWO"
		linearPrompt.Enabled = true
		message(remote, player, "Najpierw wyszukiwanie liniowe: sprawdzaj półki po kolei.", true)
		updateHud()
	end)

	state.objective = "START • Uruchom START WYSZUKIWANIA przy wejściu i przeczytaj przykład."
	hud(remote, player, title, state.objective, state.score)
	message(remote, player, "START WYSZUKIWANIA uruchomi pierwszy tor. Potem porównasz go z binarnym.", true)
	updateHud()
end

return SearchRace