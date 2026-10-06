local NumberFoundry = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("NumberFoundryRules"))

local C = {
	dark = Color3.fromRGB(30, 34, 39),
	steel = Color3.fromRGB(83, 91, 98),
	orange = Color3.fromRGB(238, 139, 55),
	yellow = Color3.fromRGB(244, 201, 70),
	cyan = Color3.fromRGB(55, 205, 218),
	blue = Color3.fromRGB(66, 135, 224),
	green = Color3.fromRGB(73, 207, 112),
	red = Color3.fromRGB(229, 72, 70),
	purple = Color3.fromRGB(148, 91, 198),
}

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Parent = parent
	return p
end

local function label(target, text, face, maxText)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 420)
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 0.05
	txt.BackgroundColor3 = C.dark
	txt.TextColor3 = Color3.fromRGB(244, 246, 248)
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = maxText or 30
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
	l.Brightness = brightness or 1.4
	l.Range = range or 16
	l.Parent = target
	return l
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

function NumberFoundry.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Algorytmy na liczbach"
	state.numberFoundry = Rules.NewState()
	state.numberBusy = false
	local entryReady = false
	local divisorPrompts = {}
	local classifyPrompts = {}

	local floor = part(
		model,
		"NumberFoundryFloor",
		Vector3.new(88, 1, 112),
		origin + Vector3.new(0, 0.2, 10),
		Color3.fromRGB(58, 62, 66),
		Enum.Material.DiamondPlate
	)
	floor.CanCollide = true

	local back = part(
		model,
		"NumberFoundryBackWall",
		Vector3.new(84, 20, 2),
		origin + Vector3.new(0, 10, 64),
		C.steel,
		Enum.Material.Metal
	)
	local headerText = label(back, "NUMBER FOUNDRY • TESTUJ RESZTĘ → WYCIĄGNIJ WNIOSEK", Enum.NormalId.Back, 29)
	headerText.TextColor3 = C.yellow

	local instructionBoard = part(
		model,
		"NumberFoundryInstructionBoard",
		Vector3.new(30, 11, 2),
		origin + Vector3.new(27, 8, -39),
		C.dark,
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. URUCHOM ODLEWNIĘ\n2. Testuj %2/%3/%5/%7\n3. Wybierz PIERWSZA lub ZŁOŻONA\nPRZYKŁAD: 35 % 5 = 0 → ZŁOŻONA",
		Enum.NormalId.Front,
		23
	)

	local conveyor = part(
		model,
		"NumberFoundryConveyor",
		Vector3.new(18, 1.2, 70),
		origin + Vector3.new(0, 1, 22),
		Color3.fromRGB(45, 50, 55),
		Enum.Material.DiamondPlate
	)
	conveyor.CanCollide = true

	for z = -8, 54, 7 do
		part(
			model,
			"NumberFoundryRoller_" .. tostring(z),
			Vector3.new(16, 0.35, 1),
			origin + Vector3.new(0, 1.7, z),
			C.steel,
			Enum.Material.Metal
		).CanCollide =
			false
	end
	local scanner = part(
		model,
		"NumberModuloScanner",
		Vector3.new(26, 18, 8),
		origin + Vector3.new(0, 9, 14),
		Color3.fromRGB(71, 77, 83),
		Enum.Material.Metal
	)
	local scannerText = label(scanner, "SKANER %\nWPROWADŹ DZIELNIK", Enum.NormalId.Front, 28)
	local scannerLight = light(scanner, C.orange, 1.2, 18)

	local remainderBoard = part(
		model,
		"NumberRemainderBoard",
		Vector3.new(34, 10, 2),
		origin + Vector3.new(26, 10, 2),
		C.dark,
		Enum.Material.Metal
	)
	local remainderText = label(remainderBoard, "RESZTA: —\nCZEKA NA TEST", Enum.NormalId.Front, 27)

	local coreStart = origin + Vector3.new(0, 5, -8)
	local coreScan = origin + Vector3.new(0, 5, 14)
	local coreExit = origin + Vector3.new(0, 5, 46)
	local numberCore = part(model, "NumberCore", Vector3.new(8, 8, 8), coreStart, C.yellow, Enum.Material.Neon)
	numberCore.Shape = Enum.PartType.Ball
	numberCore.CanCollide = false
	local coreText = label(numberCore, "29", Enum.NormalId.Front, 34)
	local coreLight = light(numberCore, C.yellow, 2, 17)

	local piston = part(
		model,
		"NumberScannerPiston",
		Vector3.new(5, 12, 5),
		origin + Vector3.new(-12, 12, 14),
		C.orange,
		Enum.Material.Metal
	)
	local pistonHome = piston.Position
	local pistonTest = piston.Position + Vector3.new(9, -3, 0)

	local divisorLamps = {}
	local divisorControls = {}
	for i, divisor in ipairs(Rules.Divisors) do
		local x = -30 + (i - 1) * 20
		local button = part(
			model,
			"NumberDivisor_" .. divisor,
			Vector3.new(14, 5, 7),
			origin + Vector3.new(x, 4, -18),
			i % 2 == 0 and C.cyan or C.orange,
			Enum.Material.SmoothPlastic
		)
		label(button, "% " .. divisor, Enum.NormalId.Front, 29)
		local control = part(
			model,
			"NumberDivisorControl_" .. divisor,
			Vector3.new(4, 3, 4),
			origin + Vector3.new(x, 3.7, -10.5),
			i % 2 == 0 and C.cyan or C.orange,
			Enum.Material.Metal
		)
		control.CanCollide = false
		control.CanTouch = false
		divisorControls[divisor] = control

		local lamp = part(
			model,
			"NumberDivisorLamp_" .. divisor,
			Vector3.new(4, 4, 2),
			origin + Vector3.new(x, 10, -18),
			Color3.fromRGB(73, 78, 83),
			Enum.Material.Metal
		)
		lamp.CanCollide = false
		divisorLamps[divisor] = lamp
	end

	local primeFurnace = part(
		model,
		"PrimeFurnace",
		Vector3.new(22, 17, 18),
		origin + Vector3.new(-27, 8.5, 48),
		Color3.fromRGB(60, 67, 73),
		Enum.Material.Metal
	)
	label(primeFurnace, "PIERWSZA\nBRAK DZIELNIKA", Enum.NormalId.Front, 25)
	local primeLight = light(primeFurnace, C.purple, 0.7, 18)

	local compositeFurnace = part(
		model,
		"CompositeFurnace",
		Vector3.new(22, 17, 18),
		origin + Vector3.new(27, 8.5, 48),
		Color3.fromRGB(60, 67, 73),
		Enum.Material.Metal
	)
	label(compositeFurnace, "ZŁOŻONA\nMA DZIELNIK", Enum.NormalId.Front, 25)
	local compositeLight = light(compositeFurnace, C.orange, 0.7, 18)
	local classifyPrime = part(
		model,
		"NumberClassifyPrime",
		Vector3.new(20, 5, 8),
		origin + Vector3.new(-25, 4, 31),
		C.purple,
		Enum.Material.SmoothPlastic
	)
	label(classifyPrime, "DO PIECA\nPIERWSZA", Enum.NormalId.Front, 24)

	local classifyComposite = part(
		model,
		"NumberClassifyComposite",
		Vector3.new(20, 5, 8),
		origin + Vector3.new(25, 4, 31),
		C.orange,
		Enum.Material.SmoothPlastic
	)
	label(classifyComposite, "DO PIECA\nZŁOŻONA", Enum.NormalId.Front, 24)

	local classifyPrimeControl = part(
		model,
		"NumberClassifyControl_Prime",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(-25, 3.7, 23),
		C.purple,
		Enum.Material.Metal
	)
	classifyPrimeControl.CanCollide = false
	classifyPrimeControl.CanTouch = false
	local classifyCompositeControl = part(
		model,
		"NumberClassifyControl_Composite",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(25, 3.7, 23),
		C.orange,
		Enum.Material.Metal
	)
	classifyCompositeControl.CanCollide = false
	classifyCompositeControl.CanTouch = false

	local progressBoard = part(
		model,
		"NumberFoundryProgress",
		Vector3.new(36, 10, 2),
		origin + Vector3.new(-27, 10, 2),
		C.dark,
		Enum.Material.Metal
	)
	local progressText = label(progressBoard, "RDZENIE 0/3\nAKTYWNY: 29", Enum.NormalId.Front, 26)

	local storedCores = {}
	for i = 1, 3 do
		local stored = part(
			model,
			"NumberStoredCore_" .. i,
			Vector3.new(5, 5, 5),
			origin + Vector3.new(-9 + (i - 1) * 9, 3.5, 58),
			Color3.fromRGB(67, 72, 78),
			Enum.Material.Metal
		)
		stored.Shape = Enum.PartType.Ball
		stored.Transparency = 0.7
		stored.CanCollide = false
		storedCores[i] = stored
	end

	local finalReactor = part(
		model,
		"NumberFoundryReactor",
		Vector3.new(14, 16, 14),
		origin + Vector3.new(0, 8, 55),
		Color3.fromRGB(50, 57, 63),
		Enum.Material.Metal
	)
	local reactorText = label(finalReactor, "REAKTOR\n0/3", Enum.NormalId.Front, 25)
	local reactorLight = light(finalReactor, C.red, 0.7, 17)

	local gate = part(
		model,
		"NumberFoundryGate",
		Vector3.new(34, 18, 2),
		origin + Vector3.new(0, 9, 65),
		C.steel,
		Enum.Material.Metal
	)
	label(gate, "ODLEWNIA ZABLOKOWANA\nPRZETESTUJ 3 RDZENIE", Enum.NormalId.Back, 24)
	local gateOpen = gate.Position + Vector3.new(0, 20, 0)

	local foundryLamps = {}
	for i = 1, 6 do
		local lamp = part(
			model,
			"NumberFoundryLamp_" .. i,
			Vector3.new(7, 0.7, 2.5),
			origin + Vector3.new(-30 + (i - 1) * 12, 18, 34),
			Color3.fromRGB(70, 75, 80),
			Enum.Material.Metal
		)
		foundryLamps[i] = lamp
	end

	local function current()
		return Rules.Current(state.numberFoundry)
	end

	local function resetScannerVisuals()
		for _, lamp in pairs(divisorLamps) do
			lamp.Color = Color3.fromRGB(73, 78, 83)
			lamp.Material = Enum.Material.Metal
		end
		remainderBoard.Color = C.dark
		remainderBoard.Material = Enum.Material.Metal
		remainderText.Text = "RESZTA: —\nCZEKA NA TEST"
		scannerText.Text = "SKANER %\nWPROWADŹ DZIELNIK"
		scannerLight.Color = C.orange
	end

	local function updateHud()
		local info = current()
		if info then
			state.objective = string.format(
				"ETAP 1/3 • Rdzeń %d: testuj resztę z dzielenia i sklasyfikuj na podstawie wyników.",
				info.number
			)
		else
			state.objective = "ETAP 3/3 • Wszystkie rdzenie sklasyfikowane. Reaktor odlewni jest online."
		end
		hud(remote, player, title, state.objective, state.score)
	end
	local function loadCurrentCore()
		local info = current()
		if not info then
			return
		end
		state.numberBusy = true
		numberCore.Transparency = 0
		numberCore.Color = C.yellow
		numberCore.Position = coreStart
		coreText.Text = tostring(info.number)
		coreLight.Color = C.yellow
		resetScannerVisuals()
		progressText.Text = string.format("RDZENIE %d/3\nAKTYWNY: %d", Rules.Progress(state.numberFoundry), info.number)
		tween(numberCore, { Position = coreScan }, 0.8).Completed:Wait()
		state.numberBusy = false
		updateHud()
	end

	local function runDivisorTest(divisor)
		if not entryReady then
			message(remote, player, "Najpierw uruchom ODLEWNIĘ przy wejściu.", false)
			return
		end
		if state.numberBusy or state.done then
			return
		end
		local info = current()
		if not info then
			return
		end
		state.numberBusy = true
		tween(piston, { Position = pistonTest }, 0.22).Completed:Wait()
		local ok, result = Rules.TestDivisor(state.numberFoundry, divisor)
		tween(piston, { Position = pistonHome }, 0.22)
		if not ok then
			state.numberBusy = false
			message(remote, player, result, false)
			return
		end

		local lamp = divisorLamps[divisor]
		if result.remainder == 0 then
			lamp.Color = C.green
			lamp.Material = Enum.Material.Neon
			remainderBoard.Color = C.green
			remainderBoard.Material = Enum.Material.Neon
			scannerLight.Color = C.green
			numberCore.Color = C.green
			remainderText.Text = string.format(
				"%d %% %d = 0\nDZIELNIK ZNALEZIONY • %d × %d",
				info.number,
				divisor,
				divisor,
				result.quotient
			)
			message(remote, player, "Reszta 0 — masz dowód, że rdzeń jest złożony.", true)
		else
			lamp.Color = C.cyan
			lamp.Material = Enum.Material.Neon
			remainderBoard.Color = C.blue
			remainderText.Text =
				string.format("%d %% %d = %d\nNIE DZIELI SIĘ BEZ RESZTY", info.number, divisor, result.remainder)
		end
		scannerText.Text =
			string.format("TEST %% %d\nILORAZ %d • RESZTA %d", divisor, result.quotient, result.remainder)
		state.score += 8
		state.numberBusy = false
		updateHud()
	end

	for divisor, control in pairs(divisorControls) do
		local divisorPrompt = prompt(control, "TESTUJ", "% " .. divisor, function(who)
			if who ~= player then
				return
			end
			runDivisorTest(divisor)
		end)
		divisorPrompt.Enabled = false
		table.insert(divisorPrompts, divisorPrompt)
	end

	local function finalizeFoundry()
		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += 180
		finalReactor.Color = C.green
		finalReactor.Material = Enum.Material.Neon
		reactorText.Text = "REAKTOR\n3/3 • ONLINE"
		reactorLight.Color = C.green
		reactorLight.Brightness = 3
		primeLight.Brightness = 2.2
		compositeLight.Brightness = 2.2
		for i, lamp in ipairs(foundryLamps) do
			task.delay((i - 1) * 0.1, function()
				lamp.Color = i % 2 == 0 and C.cyan or C.orange
				lamp.Material = Enum.Material.Neon
				light(lamp, lamp.Color, 1.3, 14)
			end)
		end
		tween(gate, { Position = gateOpen }, 1.1)
		remote:FireClient(player, {
			kind = "objective",
			text = "Odlewnia liczb online: trzy rdzenie sklasyfikowane na podstawie realnych testów reszty.",
			score = state.score,
		})
		message(remote, player, "Sukces: algorytm opierał decyzję na obliczonej reszcie, nie na zgadywaniu.", true)
		updateHud()
	end
	local function classify(kind, furnace, furnaceLight)
		if not entryReady then
			message(remote, player, "Najpierw uruchom ODLEWNIĘ przy wejściu.", false)
			return
		end
		if state.numberBusy or state.done then
			return
		end
		local ok, result, completed = Rules.Classify(state.numberFoundry, kind)
		if not ok then
			remainderBoard.Color = C.red
			remainderBoard.Material = Enum.Material.Neon
			remainderText.Text = "DEBUG WNIOSKU\n" .. tostring(result)
			message(remote, player, result, false)
			state.score = math.max(0, state.score - 5)
			updateHud()
			return
		end

		state.numberBusy = true
		state.score += 45
		furnace.Color = kind == "PRIME" and C.purple or C.orange
		furnace.Material = Enum.Material.Neon
		furnaceLight.Brightness = 2.4
		local target = furnace.Position + Vector3.new(0, 2, -11)
		tween(numberCore, { Position = target }, 0.7).Completed:Wait()
		numberCore.Transparency = 1

		local storedIndex = Rules.Progress(state.numberFoundry)
		if completed then
			storedIndex = 3
		end
		local stored = storedCores[storedIndex]
		if stored then
			stored.Transparency = 0
			stored.Material = Enum.Material.Neon
			stored.Color = kind == "PRIME" and C.purple or C.orange
			local storedText = label(stored, tostring(result), Enum.NormalId.Front, 22)
			storedText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		reactorText.Text = string.format("REAKTOR\n%d/3", completed and 3 or Rules.Progress(state.numberFoundry))

		if completed then
			state.numberBusy = false
			finalizeFoundry()
			return
		end

		task.wait(0.4)
		loadCurrentCore()
	end

	local primePrompt = prompt(classifyPrimeControl, "KLASYFIKUJ", "PIERWSZA", function(who)
		if who == player then
			classify("PRIME", primeFurnace, primeLight)
		end
	end)
	primePrompt.Enabled = false
	table.insert(classifyPrompts, primePrompt)

	local compositePrompt = prompt(classifyCompositeControl, "KLASYFIKUJ", "ZŁOŻONA", function(who)
		if who == player then
			classify("COMPOSITE", compositeFurnace, compositeLight)
		end
	end)
	compositePrompt.Enabled = false
	table.insert(classifyPrompts, compositePrompt)

	local entryConsole = part(
		model,
		"NumberFoundryEntryConsole",
		Vector3.new(10, 5, 7),
		origin + Vector3.new(0, 3.5, -44),
		C.orange,
		Enum.Material.Metal
	)
	entryConsole.CanCollide = false
	entryConsole.CanTouch = false
	local entryText = label(entryConsole, "URUCHOM ODLEWNIĘ\nLINIA: OFFLINE", Enum.NormalId.Front, 23)
	local entryPrompt
	entryPrompt = prompt(entryConsole, "URUCHOM", "Number Foundry", function(who)
		if who ~= player or entryReady or state.done then
			return
		end
		entryReady = true
		entryPrompt.Enabled = false
		entryConsole.Color = C.green
		entryConsole.Material = Enum.Material.Neon
		entryText.Text = "ODLEWNIA ONLINE\nRDZEŃ 29 GOTOWY"
		for _, divisorPrompt in ipairs(divisorPrompts) do
			divisorPrompt.Enabled = true
		end
		for _, classifyPrompt in ipairs(classifyPrompts) do
			classifyPrompt.Enabled = true
		end
		state.objective =
			"ETAP 1/3 • Rdzeń 29: testuj %2/%3/%5/%7. Dla liczby pierwszej wystarczą dzielniki do √n."
		hud(remote, player, title, state.objective, state.score)
		message(remote, player, "Odlewnia online. Przykład: jeśli reszta = 0, masz dowód liczby złożonej.", true)
		task.spawn(loadCurrentCore)
	end)

	state.objective = "ETAP START • Podejdź do URUCHOM ODLEWNIĘ przy wejściu. Potem testuj resztę z dzielenia."
	hud(remote, player, title, state.objective, state.score)
	message(
		remote,
		player,
		"Zacznij od pomarańczowej konsoli URUCHOM ODLEWNIĘ. Tablica obok pokazuje przykład.",
		true
	)
end

return NumberFoundry