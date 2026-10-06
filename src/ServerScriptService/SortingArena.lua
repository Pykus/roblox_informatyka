local SortingArena = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rules = require(script.Parent:WaitForChild("SortingArenaRules"))

local C = {
	dark = Color3.fromRGB(31, 35, 43),
	steel = Color3.fromRGB(84, 94, 104),
	track = Color3.fromRGB(55, 60, 69),
	blue = Color3.fromRGB(64, 138, 226),
	cyan = Color3.fromRGB(54, 210, 223),
	green = Color3.fromRGB(73, 207, 118),
	yellow = Color3.fromRGB(242, 199, 66),
	orange = Color3.fromRGB(236, 143, 55),
	red = Color3.fromRGB(229, 73, 76),
	purple = Color3.fromRGB(154, 92, 207),
	white = Color3.fromRGB(244, 247, 249),
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
	gui.CanvasSize = Vector2.new(900, 430)
	gui.LightInfluence = 0
	gui.Brightness = 1.15
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 0.05
	txt.BackgroundColor3 = C.dark
	txt.TextColor3 = C.white
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 16
	constraint.MaxTextSize = maxText or 30
	constraint.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText or ""
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
	l.Brightness = brightness or 1.6
	l.Range = range or 18
	l.Parent = target
	return l
end
local function message(remote, player, text, good)
	remote:FireClient(player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function hud(remote, player, title, objective, score)
	remote:FireClient(player, {
		kind = "hud",
		title = title,
		objective = objective,
		score = score or 0,
	})
end

local function tween(target, goal, seconds, style, direction)
	local t = TweenService:Create(
		target,
		TweenInfo.new(seconds or 0.45, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.InOut),
		goal
	)
	t:Play()
	return t
end

local function missionRoot(instance)
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") and string.sub(current.Name, 1, 8) == "Mission_" then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function followSemanticVisual(source)
	task.spawn(function()
		local root = missionRoot(source)
		if not root then
			return
		end
		local semantic = nil
		for _ = 1, 100 do
			semantic = root:FindFirstChild("Semantic_" .. source.Name)
			if semantic and semantic:IsA("Model") then
				break
			end
			task.wait(0.05)
		end
		if not semantic or not semantic:IsA("Model") then
			return
		end

		local offset = source.CFrame:ToObjectSpace(semantic:GetPivot())
		while source.Parent and semantic.Parent do
			semantic:PivotTo(source.CFrame * offset)
			RunService.Heartbeat:Wait()
		end
	end)
end

function SortingArena.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Sortowanie na czas"
	state.sortArena = Rules.NewState()
	state.sortBusy = false
	local entryReady = false

	local floor = part(
		model,
		"SortingArenaFloor",
		Vector3.new(92, 1, 112),
		origin + Vector3.new(0, 0.2, 10),
		Color3.fromRGB(92, 86, 76),
		Enum.Material.Concrete
	)
	floor.CanCollide = true

	local header = part(
		model,
		"SortingArenaHeader",
		Vector3.new(70, 9, 2),
		origin + Vector3.new(0, 22, -44),
		C.orange,
		Enum.Material.Metal
	)
	label(header, "SORTER ARENA • BUBBLE SORT\nPORÓWNAJ → ZOSTAW LUB ZAMIEŃ", Enum.NormalId.Front, 30)
	light(header, C.orange, 1.7, 24)

	local instructionBoard = part(
		model,
		"SortingInstructionBoard",
		Vector3.new(28, 10, 2),
		origin + Vector3.new(27, 8, -39),
		C.dark,
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. KALIBRUJ SORTER\n2. Porównuj sąsiadów\nPRZYKŁAD: 42 > 17 → ZAMIEŃ\nGdy lewa ≤ prawa → ZOSTAW",
		Enum.NormalId.Front,
		24
	)

	local conveyor = part(
		model,
		"SortingConveyor",
		Vector3.new(78, 1.2, 24),
		origin + Vector3.new(0, 1, 8),
		C.track,
		Enum.Material.DiamondPlate
	)
	conveyor.CanCollide = true

	for i = -5, 5 do
		local roller = part(
			model,
			"SortingRoller_" .. (i + 6),
			Vector3.new(2.5, 1.4, 22),
			origin + Vector3.new(i * 7, 1.8, 8),
			Color3.fromRGB(109, 115, 119),
			Enum.Material.Metal
		)
		roller.Shape = Enum.PartType.Cylinder
		roller.CFrame = CFrame.new(roller.Position) * CFrame.Angles(math.rad(90), 0, 0)
		roller.CanCollide = false
	end

	local statusBoard = part(
		model,
		"SortingStatusBoard",
		Vector3.new(40, 10, 2),
		origin + Vector3.new(0, 10, -32),
		C.dark,
		Enum.Material.Metal
	)
	local statusText = label(statusBoard, "RUNDA 1/2 • TRENING\nSPRAWDŹ PIERWSZĄ PARĘ", Enum.NormalId.Front, 27)

	local statsBoard = part(
		model,
		"SortingStatsBoard",
		Vector3.new(22, 10, 2),
		origin + Vector3.new(-31, 10, -32),
		C.dark,
		Enum.Material.Metal
	)
	local statsText = label(statsBoard, "PORÓWNANIA 0\nZAMIANY 0\nBŁĘDY 0", Enum.NormalId.Front, 24)

	local historyBoard = part(
		model,
		"SortingHistoryBoard",
		Vector3.new(26, 15, 2),
		origin + Vector3.new(31, 12, -28),
		C.dark,
		Enum.Material.Metal
	)
	local historyText = label(historyBoard, "HISTORIA OPERACJI\n—", Enum.NormalId.Front, 22)
	local slotX = { -28, -14, 0, 14, 28 }
	local slotPositions = {}
	for i, x in ipairs(slotX) do
		slotPositions[i] = origin + Vector3.new(x, 5.2, 8)
		local slot = part(
			model,
			"SortingSlot_" .. i,
			Vector3.new(11, 0.7, 12),
			origin + Vector3.new(x, 2.15, 8),
			Color3.fromRGB(125, 118, 101),
			Enum.Material.Metal
		)
		label(slot, tostring(i), Enum.NormalId.Top, 18)
	end

	local allPackages = {}
	local packageParts = {}
	local packageLabels = {}
	local packageValues = {}

	for i = 1, 5 do
		local crate = part(
			model,
			"SorterPackage_" .. i,
			Vector3.new(10, 7, 10),
			slotPositions[i],
			C.steel,
			Enum.Material.WoodPlanks
		)
		crate.CanCollide = false
		local txt = label(crate, "?", Enum.NormalId.Front, 34)
		light(crate, C.yellow, 0.35, 9)
		allPackages[i] = crate
		packageLabels[crate] = txt
		followSemanticVisual(crate)
	end

	local scannerLeft = part(
		model,
		"SortingScannerLeft",
		Vector3.new(2, 13, 2),
		origin + Vector3.new(-8, 8, 8),
		C.cyan,
		Enum.Material.Neon
	)
	local scannerRight = part(
		model,
		"SortingScannerRight",
		Vector3.new(2, 13, 2),
		origin + Vector3.new(8, 8, 8),
		C.cyan,
		Enum.Material.Neon
	)
	local scannerTop = part(
		model,
		"SortingScannerTop",
		Vector3.new(18, 2, 2),
		origin + Vector3.new(0, 14, 8),
		C.cyan,
		Enum.Material.Neon
	)
	local scannerBeam = part(
		model,
		"SortingScannerBeam",
		Vector3.new(14, 0.5, 11),
		origin + Vector3.new(0, 8, 8),
		C.cyan,
		Enum.Material.ForceField
	)
	scannerBeam.Transparency = 0.55
	scannerBeam.CanCollide = false
	local scannerLight = light(scannerTop, C.cyan, 1.8, 20)
	followSemanticVisual(scannerTop)

	local keepButton = part(
		model,
		"SortingDecisionKeep",
		Vector3.new(20, 6, 8),
		origin + Vector3.new(-14, 4, -18),
		C.green,
		Enum.Material.SmoothPlastic
	)
	label(keepButton, "ZOSTAW\nLEWA ≤ PRAWA", Enum.NormalId.Front, 23)
	local keepControl = part(
		model,
		"SortingDecisionKeepControl",
		Vector3.new(6, 3, 6),
		origin + Vector3.new(-14, 3, -11),
		C.green,
		Enum.Material.SmoothPlastic
	)
	keepControl.CanCollide = false
	keepControl.CanTouch = false
	label(keepControl, "ZOSTAW", Enum.NormalId.Front, 20)

	local swapButton = part(
		model,
		"SortingDecisionSwap",
		Vector3.new(20, 6, 8),
		origin + Vector3.new(14, 4, -18),
		C.orange,
		Enum.Material.SmoothPlastic
	)
	label(swapButton, "ZAMIEŃ\nLEWA > PRAWA", Enum.NormalId.Front, 23)
	local swapControl = part(
		model,
		"SortingDecisionSwapControl",
		Vector3.new(6, 3, 6),
		origin + Vector3.new(14, 3, -11),
		C.orange,
		Enum.Material.SmoothPlastic
	)
	swapControl.CanCollide = false
	swapControl.CanTouch = false
	label(swapControl, "ZAMIEŃ", Enum.NormalId.Front, 20)

	local speedConsole = part(
		model,
		"SortingSpeedConsole",
		Vector3.new(24, 7, 9),
		origin + Vector3.new(-22, 4.5, 35),
		C.purple,
		Enum.Material.Metal
	)
	label(speedConsole, "RUNDA 2\nSPEED BATCH", Enum.NormalId.Front, 25)
	local speedControl = part(
		model,
		"SortingSpeedControl",
		Vector3.new(6, 3, 6),
		origin + Vector3.new(-22, 3, 29),
		C.dark,
		Enum.Material.Metal
	)
	speedControl.CanCollide = false
	speedControl.CanTouch = false
	label(speedControl, "SPEED", Enum.NormalId.Front, 19)

	local earlyStopBeacon = part(
		model,
		"SortingEarlyStopBeacon",
		Vector3.new(8, 14, 8),
		origin + Vector3.new(0, 7, 39),
		Color3.fromRGB(69, 73, 82),
		Enum.Material.Metal
	)
	label(earlyStopBeacon, "EARLY\nSTOP", Enum.NormalId.Front, 22)
	local earlyLight = light(earlyStopBeacon, C.red, 0.4, 12)

	local productionConsole = part(
		model,
		"SortingProductionConsole",
		Vector3.new(24, 7, 9),
		origin + Vector3.new(22, 4.5, 35),
		C.blue,
		Enum.Material.Metal
	)
	label(productionConsole, "AUTO PRODUKCJA\nURUCHOM", Enum.NormalId.Front, 24)
	local productionControl = part(
		model,
		"SortingProductionControl",
		Vector3.new(6, 3, 6),
		origin + Vector3.new(22, 3, 29),
		C.dark,
		Enum.Material.Metal
	)
	productionControl.CanCollide = false
	productionControl.CanTouch = false
	label(productionControl, "AUTO", Enum.NormalId.Front, 19)
	local efficiencyBoard = part(
		model,
		"SortingEfficiencyBoard",
		Vector3.new(34, 10, 2),
		origin + Vector3.new(0, 10, 49),
		C.dark,
		Enum.Material.Metal
	)
	local efficiencyText = label(efficiencyBoard, "EFEKTYWNOŚĆ\nCZEKAM NA SPEED BATCH", Enum.NormalId.Front, 25)

	local gate = part(
		model,
		"SortingArenaGate",
		Vector3.new(36, 18, 2),
		origin + Vector3.new(0, 9, 65),
		Color3.fromRGB(69, 72, 78),
		Enum.Material.Metal
	)
	label(gate, "WYSYŁKA ZABLOKOWANA\nPOSORTUJ PACZKI", Enum.NormalId.Back, 24)
	local gateOpen = gate.Position + Vector3.new(0, 20, 0)

	local shippingLane = part(
		model,
		"SortingShippingLane",
		Vector3.new(70, 1, 13),
		origin + Vector3.new(0, 1, 53),
		Color3.fromRGB(73, 77, 84),
		Enum.Material.DiamondPlate
	)
	shippingLane.CanCollide = true

	local lamps = {}
	for i = 1, 6 do
		local lamp = part(
			model,
			"SortingArenaLamp_" .. i,
			Vector3.new(8, 0.7, 2.5),
			origin + Vector3.new(-30 + (i - 1) * 12, 18, 46),
			Color3.fromRGB(72, 75, 82),
			Enum.Material.Metal
		)
		lamps[i] = lamp
	end

	local keepPrompt
	local swapPrompt
	local speedPrompt
	local productionPrompt

	local function currentRoundName()
		if state.sortArena.stage == 1 then
			return "TRENING"
		elseif state.sortArena.stage == 2 then
			return "SPEED"
		end
		return "PRODUKCJA"
	end

	local function updateHistory()
		local lines = { "HISTORIA OPERACJI" }
		for _, entry in ipairs(state.sortArena.history) do
			local op = entry.decision == "SWAP" and "ZAMIEŃ" or "ZOSTAW"
			table.insert(lines, string.format("%d : %d → %s", entry.left, entry.right, op))
		end
		if #lines == 1 then
			table.insert(lines, "—")
		end
		historyText.Text = table.concat(lines, "\n")
	end

	local function updateStats()
		statsText.Text = string.format(
			"%s • PASS %d\nPORÓWNANIA %d\nZAMIANY %d • BŁĘDY %d",
			currentRoundName(),
			state.sortArena.pass,
			state.sortArena.comparisons,
			state.sortArena.swaps,
			state.sortArena.errors
		)
	end

	local function updateHud()
		hud(remote, player, title, state.objective, state.score)
	end

	local function resetPackages(values)
		packageParts = {}
		for i, crate in ipairs(allPackages) do
			crate.Position = slotPositions[i]
			crate.Color = C.steel
			crate.Material = Enum.Material.WoodPlanks
			packageParts[i] = crate
			packageValues[crate] = values[i]
			packageLabels[crate].Text = tostring(values[i])
		end
	end
	local function setScanner(index)
		if not index then
			scannerBeam.Transparency = 1
			return
		end
		local centerX = (slotPositions[index].X + slotPositions[index + 1].X) / 2
		local topPos = Vector3.new(centerX, origin.Y + 14, origin.Z + 8)
		local leftPos = Vector3.new(centerX - 8, origin.Y + 8, origin.Z + 8)
		local rightPos = Vector3.new(centerX + 8, origin.Y + 8, origin.Z + 8)
		tween(scannerTop, { Position = topPos }, 0.25)
		tween(scannerLeft, { Position = leftPos }, 0.25)
		tween(scannerRight, { Position = rightPos }, 0.25)
		tween(scannerBeam, { Position = Vector3.new(centerX, origin.Y + 8, origin.Z + 8) }, 0.25)
		scannerBeam.Transparency = 0.55

		for i, crate in ipairs(packageParts) do
			if i == index then
				crate.Color = C.yellow
				crate.Material = Enum.Material.Neon
			elseif i == index + 1 then
				crate.Color = C.cyan
				crate.Material = Enum.Material.Neon
			else
				crate.Color = C.steel
				crate.Material = Enum.Material.WoodPlanks
			end
		end

		local pair = Rules.CurrentPair(state.sortArena)
		if pair then
			statusText.Text = string.format(
				"%s • PASS %d\nPORÓWNAJ: %d  ?  %d",
				currentRoundName(),
				pair.pass,
				pair.left,
				pair.right
			)
		end
	end

	local function animateKeep()
		scannerLight.Color = C.green
		scannerBeam.Color = C.green
		task.wait(0.3)
		scannerLight.Color = C.cyan
		scannerBeam.Color = C.cyan
	end

	local function animateSwap(index)
		local leftPart = packageParts[index]
		local rightPart = packageParts[index + 1]
		local leftPos = slotPositions[index]
		local rightPos = slotPositions[index + 1]
		local lift = 5

		local a = tween(leftPart, { Position = leftPos + Vector3.new(0, lift, 0) }, 0.22)
		local b = tween(rightPart, { Position = rightPos + Vector3.new(0, 2, 0) }, 0.22)
		a.Completed:Wait()
		b.Completed:Wait()

		local c = tween(leftPart, { Position = rightPos + Vector3.new(0, lift, 0) }, 0.34)
		local d = tween(rightPart, { Position = leftPos + Vector3.new(0, 2, 0) }, 0.34)
		c.Completed:Wait()
		d.Completed:Wait()

		tween(leftPart, { Position = rightPos }, 0.2).Completed:Wait()
		tween(rightPart, { Position = leftPos }, 0.2).Completed:Wait()
		packageParts[index], packageParts[index + 1] = rightPart, leftPart
	end

	local function lockDecisionButtons(locked)
		keepPrompt.Enabled = not locked
		swapPrompt.Enabled = not locked
		if locked then
			keepControl.Color = C.dark
			keepControl.Material = Enum.Material.Metal
			swapControl.Color = C.dark
			swapControl.Material = Enum.Material.Metal
		else
			keepControl.Color = C.green
			keepControl.Material = Enum.Material.SmoothPlastic
			swapControl.Color = C.orange
			swapControl.Material = Enum.Material.SmoothPlastic
		end
	end

	local function roundFinished()
		lockDecisionButtons(true)
		scannerBeam.Transparency = 1
		for _, crate in ipairs(packageParts) do
			crate.Color = C.green
			crate.Material = Enum.Material.Neon
		end

		if state.sortArena.stage == 1 then
			state.objective = "RUNDA 1 GOTOWA • Uruchom SPEED BATCH i sprawdź wcześniejsze zakończenie."
			statusBoard.Color = C.green
			statusText.Text = string.format(
				"TRENING GOTOWY\n%d PORÓWNAŃ • %d ZAMIAN",
				state.sortArena.practiceComparisons or 0,
				state.sortArena.practiceSwaps or 0
			)
			speedPrompt.Enabled = true
			speedControl.Color = C.purple
			speedControl.Material = Enum.Material.Neon
			message(
				remote,
				player,
				"Pierwsza partia posortowana. Druga jest prawie gotowa — zobacz, kiedy algorytm może skończyć wcześniej.",
				true
			)
		else
			local efficiency = Rules.Efficiency(state.sortArena)
			state.objective = "RUNDA 2 GOTOWA • Uruchom automatyczną produkcję i otwórz wysyłkę."
			statusBoard.Color = C.green
			statusText.Text = "SPEED BATCH GOTOWY\nBRAK ZAMIAN = EARLY STOP"
			earlyStopBeacon.Color = C.green
			earlyStopBeacon.Material = Enum.Material.Neon
			earlyLight.Color = C.green
			earlyLight.Brightness = 2
			efficiencyText.Text = string.format(
				"SPEED: %d PORÓWNAŃ\nOSZCZĘDZONO %d / 10\nBŁĘDY: %d",
				efficiency.speedComparisons,
				efficiency.saved,
				efficiency.errors
			)
			productionPrompt.Enabled = true
			productionControl.Color = C.blue
			productionControl.Material = Enum.Material.Neon
			message(remote, player, "Pełny przebieg bez zamiany pozwolił zakończyć sortowanie wcześniej.", true)
		end
		updateStats()
		updateHistory()
		updateHud()
	end
	local function decide(decision)
		if not entryReady then
			message(remote, player, "Najpierw uruchom KALIBRUJ SORTER przy wejściu.", false)
			return
		end
		if state.done or state.sortBusy then
			return
		end
		local pair = Rules.CurrentPair(state.sortArena)
		if not pair then
			return
		end
		local index = pair.index
		local chosenControl = decision == "SWAP" and swapControl or keepControl
		local ok, result = Rules.Decide(state.sortArena, decision)
		if not ok then
			chosenControl.Color = C.red
			chosenControl.Material = Enum.Material.Neon
			state.score = math.max(0, state.score - 5)
			statusBoard.Color = C.red
			statusText.Text = "DEBUG SORTERA\n" .. tostring(result)
			scannerBeam.Color = C.red
			scannerLight.Color = C.red
			message(remote, player, tostring(result) .. " Spróbuj ponownie na tej samej parze.", false)
			updateStats()
			updateHud()
			task.delay(0.6, function()
				if not state.done then
					scannerBeam.Color = C.cyan
					scannerLight.Color = C.cyan
					chosenControl.Color = decision == "SWAP" and C.orange or C.green
					chosenControl.Material = Enum.Material.SmoothPlastic
					setScanner(index)
				end
			end)
			return
		end

		state.sortBusy = true
		statusBoard.Color = C.dark
		if decision == "SWAP" then
			animateSwap(index)
			state.score += 18
		else
			animateKeep()
			state.score += 12
		end
		state.sortBusy = false
		updateStats()
		updateHistory()

		if result.roundDone then
			roundFinished()
		else
			local nextPair = Rules.CurrentPair(state.sortArena)
			setScanner(nextPair and nextPair.index or nil)
			state.objective =
				string.format("%s • Porównuj sąsiednie paczki i wybieraj ZOSTAW albo ZAMIEŃ.", currentRoundName())
			updateHud()
		end
	end

	keepPrompt = prompt(keepControl, "ZOSTAW", "lewa ≤ prawa", function(who)
		if who == player then
			decide("KEEP")
		end
	end)

	swapPrompt = prompt(swapControl, "ZAMIEŃ", "lewa > prawa", function(who)
		if who == player then
			decide("SWAP")
		end
	end)

	speedPrompt = prompt(speedControl, "START SPEED", "druga partia", function(who)
		if who ~= player or state.done or state.sortBusy then
			return
		end
		local ok, reason = Rules.StartSpeedRound(state.sortArena)
		if not ok then
			message(remote, player, reason, false)
			return
		end
		state.score += 40
		state.objective = "RUNDA 2/2 • Posortuj prawie gotową partię i zauważ EARLY STOP."
		statusBoard.Color = C.purple
		resetPackages(state.sortArena.values)
		updateStats()
		updateHistory()
		speedPrompt.Enabled = false
		speedControl.Color = C.dark
		speedControl.Material = Enum.Material.Metal
		lockDecisionButtons(false)
		local pair = Rules.CurrentPair(state.sortArena)
		setScanner(pair and pair.index or nil)
		message(
			remote,
			player,
			"Speed batch jest prawie uporządkowany. Jeśli cały przebieg nie zrobi zamiany, algorytm zatrzyma się wcześniej.",
			true
		)
		updateHud()
	end)
	speedPrompt.Enabled = false

	productionPrompt = prompt(productionControl, "AUTO SORT", "produkcja", function(who)
		if who ~= player or state.done or state.sortBusy then
			return
		end
		local ok, efficiency = Rules.Complete(state.sortArena)
		if not ok then
			message(remote, player, efficiency, false)
			return
		end

		state.sortBusy = true
		productionControl.Color = C.green
		productionControl.Material = Enum.Material.Neon
		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += efficiency.score
		statusBoard.Color = C.green
		statusBoard.Material = Enum.Material.Neon
		statusText.Text = "PRODUKCJA ONLINE\nSORTOWANIE ZAUTOMATYZOWANE"
		conveyor.Color = C.green
		conveyor.Material = Enum.Material.Neon
		efficiencyText.Text = string.format(
			"EFEKTYWNOŚĆ %d%%\nTRENING %d • SPEED %d\nOSZCZĘDZONO %d",
			efficiency.score,
			efficiency.practiceComparisons,
			efficiency.speedComparisons,
			efficiency.saved
		)

		task.spawn(function()
			for i, crate in ipairs(packageParts) do
				local target = origin + Vector3.new(-28 + (i - 1) * 14, 5.2, 53)
				tween(crate, { Position = target }, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				task.wait(0.12)
			end
			for i, lamp in ipairs(lamps) do
				task.delay((i - 1) * 0.1, function()
					lamp.Color = C.cyan
					lamp.Material = Enum.Material.Neon
					light(lamp, C.cyan, 1.4, 15)
				end)
			end
			tween(gate, { Position = gateOpen }, 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)

		state.objective = string.format(
			"Sorter Arena ukończona: %d porównań treningowych, %d w speed batch, %d błędów.",
			efficiency.practiceComparisons,
			efficiency.speedComparisons,
			efficiency.errors
		)
		remote:FireClient(player, {
			kind = "objective",
			text = state.objective,
			score = state.score,
		})
		message(
			remote,
			player,
			"Sortowanie to seria porównań i ewentualnych zamian. Brak zamiany w całym przebiegu oznacza, że można zakończyć wcześniej.",
			true
		)
		updateHud()
	end)
	productionPrompt.Enabled = false

	local calibrationConsole = part(
		model,
		"SortingCalibrationConsole",
		Vector3.new(10, 5, 7),
		origin + Vector3.new(0, 3.5, -44),
		C.orange,
		Enum.Material.Metal
	)
	calibrationConsole.CanCollide = false
	calibrationConsole.CanTouch = false
	local calibrationText = label(calibrationConsole, "KALIBRUJ SORTER\nLINIA: OFFLINE", Enum.NormalId.Front, 23)
	local calibrationPrompt
	calibrationPrompt = prompt(calibrationConsole, "KALIBRUJ", "Sorter Arena", function(who)
		if who ~= player or entryReady or state.done then
			return
		end
		entryReady = true
		calibrationPrompt.Enabled = false
		calibrationConsole.Color = C.green
		calibrationConsole.Material = Enum.Material.Neon
		calibrationText.Text = "KALIBRACJA ✓\nRUNDA 1 AKTYWNA"
		lockDecisionButtons(false)
		local activePair = Rules.CurrentPair(state.sortArena)
		setScanner(activePair and activePair.index or nil)
		state.objective =
			"RUNDA 1/2 • Porównaj sąsiednią parę. Jeśli lewa > prawa wybierz ZAMIEŃ, inaczej ZOSTAW."
		updateHud()
		message(remote, player, "Kalibracja gotowa. Przykład: 42 > 17, więc pierwsza decyzja to ZAMIEŃ.", true)
	end)

	resetPackages(state.sortArena.values)
	setScanner(nil)
	lockDecisionButtons(true)
	state.objective = "ETAP START • Podejdź do KALIBRUJ SORTER przy wejściu. Potem porównuj sąsiednie paczki."
	updateStats()
	updateHistory()
	updateHud()
	message(
		remote,
		player,
		"Zacznij od pomarańczowego stanowiska KALIBRUJ SORTER. Dopiero potem aktywują się decyzje ZOSTAW/ZAMIEŃ.",
		true
	)
end

return SortingArena