local TweenService = game:GetService("TweenService")

local RailSort = {}
local Rules = require(script.Parent:WaitForChild("RailSortRules"))

local C = {
	sky = Color3.fromRGB(158, 193, 210),
	gravel = Color3.fromRGB(112, 104, 91),
	rail = Color3.fromRGB(64, 68, 72),
	wood = Color3.fromRGB(126, 88, 53),
	dark = Color3.fromRGB(28, 34, 39),
	cream = Color3.fromRGB(235, 221, 184),
	green = Color3.fromRGB(70, 208, 120),
	yellow = Color3.fromRGB(242, 188, 56),
	red = Color3.fromRGB(226, 77, 70),
	blue = Color3.fromRGB(74, 145, 219),
	orange = Color3.fromRGB(225, 132, 52),
	white = Color3.fromRGB(245, 247, 242),
}

local WAGON_COLORS = {
	Color3.fromRGB(196, 72, 62),
	Color3.fromRGB(65, 135, 203),
	Color3.fromRGB(222, 158, 58),
	Color3.fromRGB(87, 173, 111),
	Color3.fromRGB(149, 105, 190),
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

local function modelPart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(target, text, face, minSize, maxSize)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.CanvasSize = Vector2.new(900, 420)
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -18, 1, -18)
	txt.Position = UDim2.fromOffset(9, 9)
	txt.BackgroundColor3 = C.dark
	txt.BackgroundTransparency = 0.08
	txt.TextColor3 = C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.55
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Text = text
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize or 18
	constraint.MaxTextSize = maxSize or 30
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

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, {
		kind = "message",
		text = text,
		good = good,
	})
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

local function tweenModel(model, target, seconds)
	local driver = Instance.new("CFrameValue")
	driver.Value = model:GetPivot()
	local connection = driver:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(driver.Value)
		end
	end)
	local tw = TweenService:Create(
		driver,
		TweenInfo.new(seconds or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Value = target }
	)
	tw.Completed:Connect(function()
		connection:Disconnect()
		driver:Destroy()
	end)
	tw:Play()
	return tw
end

local function createWagon(parent, value, position, index)
	local wagon = Instance.new("Model")
	wagon.Name = "RailWagon_" .. index .. "_Value_" .. value
	wagon.Parent = parent

	local color = WAGON_COLORS[((value - 1) % #WAGON_COLORS) + 1]
	local body = modelPart(wagon, "Body", Vector3.new(9, 4.5, 8), CFrame.new(position), color, Enum.Material.Metal)
	wagon.PrimaryPart = body

	local rim = modelPart(
		wagon,
		"CargoRim",
		Vector3.new(8, 1, 7),
		CFrame.new(position + Vector3.new(0, 2.6, 0)),
		C.cream,
		Enum.Material.WoodPlanks
	)
	rim.CanCollide = false
	label(rim, tostring(value), Enum.NormalId.Top, 26, 42)

	for _, x in ipairs({ -2.8, 2.8 }) do
		for _, z in ipairs({ -3.2, 3.2 }) do
			local wheel = modelPart(
				wagon,
				"Wheel",
				Vector3.new(2.2, 1.1, 2.2),
				CFrame.new(position + Vector3.new(x, -2.2, z)) * CFrame.Angles(math.rad(90), 0, 0),
				C.dark,
				Enum.Material.Metal
			)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CanCollide = false
		end
	end

	for _, x in ipairs({ -5.1, 5.1 }) do
		local coupler = modelPart(
			wagon,
			"Coupler",
			Vector3.new(1.5, 1.5, 1.5),
			CFrame.new(position + Vector3.new(x, -0.6, 0)),
			C.rail,
			Enum.Material.Metal
		)
		coupler.Shape = Enum.PartType.Ball
		coupler.CanCollide = false
	end

	for _, obj in ipairs(wagon:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CanCollide = false
			obj.CanTouch = false
		end
	end
	return wagon
end

local function createLocomotive(parent, position)
	local loco = Instance.new("Model")
	loco.Name = "RailSortLocomotive"
	loco.Parent = parent

	local base = modelPart(loco, "Base", Vector3.new(12, 3, 9), CFrame.new(position), C.dark, Enum.Material.Metal)
	loco.PrimaryPart = base

	local boiler = modelPart(
		loco,
		"Boiler",
		Vector3.new(5.5, 11, 5.5),
		CFrame.new(position + Vector3.new(0.5, 4.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		C.blue,
		Enum.Material.Metal
	)
	boiler.Shape = Enum.PartType.Cylinder
	boiler.CanCollide = false

	local cabin = modelPart(
		loco,
		"Cabin",
		Vector3.new(5, 7, 8),
		CFrame.new(position + Vector3.new(-4.2, 4, 0)),
		C.orange,
		Enum.Material.Metal
	)
	cabin.CanCollide = false

	local chimney = modelPart(
		loco,
		"Chimney",
		Vector3.new(2.2, 6, 2.2),
		CFrame.new(position + Vector3.new(3, 7, 0)),
		C.dark,
		Enum.Material.Metal
	)
	chimney.Shape = Enum.PartType.Cylinder
	chimney.CanCollide = false

	for _, x in ipairs({ -4, 0, 4 }) do
		for _, z in ipairs({ -3.2, 3.2 }) do
			local wheel = modelPart(
				loco,
				"Wheel",
				Vector3.new(2.7, 1.2, 2.7),
				CFrame.new(position + Vector3.new(x, -2.1, z)) * CFrame.Angles(math.rad(90), 0, 0),
				C.rail,
				Enum.Material.Metal
			)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CanCollide = false
		end
	end
	return loco
end

local function valuesText(values)
	local pieces = {}
	for _, value in ipairs(values) do
		table.insert(pieces, tostring(value))
	end
	return table.concat(pieces, "  •  ")
end

local function clearWagons(ctx)
	for _, wagon in ipairs(ctx.wagons) do
		wagon:Destroy()
	end
	ctx.wagons = {}
end

local function loadWagons(ctx)
	clearWagons(ctx)
	for index, value in ipairs(ctx.rules.values) do
		ctx.wagons[index] = createWagon(ctx.model, value, ctx.slotPositions[index], index)
	end
end

local function updatePromptLabels(ctx)
	for index, pr in ipairs(ctx.swapPrompts) do
		local enabled = ctx.entryScanned
			and index < #ctx.rules.values
			and not ctx.rules.awaitingNext
			and not ctx.rules.completed
		pr.Enabled = enabled
		if enabled then
			pr.ObjectText = string.format("WAGONY %d ↔ %d", ctx.rules.values[index], ctx.rules.values[index + 1])
		else
			pr.ObjectText = "TOR NIEAKTYWNY"
		end
	end
end

local function updateBoards(ctx, note)
	local stage = Rules.Current(ctx.rules)
	local inversions = Rules.Inversions(ctx.rules.values)
	ctx.orderText.Text = "SKŁAD TERAZ\n"
		.. valuesText(ctx.rules.values)
		.. "\nCEL: "
		.. valuesText(Rules.Target(ctx.rules))
	ctx.costText.Text = string.format(
		"KOSZT MANEWRÓW: %d\nOPTIMUM TEJ SERII: %d\nNIEPORZĄDEK: %d",
		ctx.rules.moves,
		stage.optimal,
		inversions
	)
	ctx.statusText.Text = note
		or string.format("SERIA %d/2 • %s\nZamieniaj tylko sąsiednie wagony.", ctx.rules.stage, stage.id)
	updatePromptLabels(ctx)
end

local function animateSwap(ctx, index)
	local left = ctx.wagons[index]
	local right = ctx.wagons[index + 1]
	local leftSlot = CFrame.new(ctx.slotPositions[index])
	local rightSlot = CFrame.new(ctx.slotPositions[index + 1])
	local siding = CFrame.new(ctx.slotPositions[index] + Vector3.new(0, 0, 10))

	tweenModel(left, siding, 0.17).Completed:Wait()
	tweenModel(right, leftSlot, 0.17).Completed:Wait()
	tweenModel(left, rightSlot, 0.17).Completed:Wait()

	ctx.wagons[index], ctx.wagons[index + 1] = right, left
end

local function setStageLights(ctx)
	for index, lightPart in ipairs(ctx.stageLights) do
		local done = index < ctx.rules.stage
			or (ctx.rules.awaitingNext and index == ctx.rules.stage)
			or (ctx.rules.completed and index <= #Rules.Stages)
		lightPart.Color = done and C.green or C.yellow
		lightPart.Material = done and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end

local function finishRailYard(ctx)
	ctx.state.done = true
	ctx.state.score += 110
	ctx.stageLeverPrompt.Enabled = false
	updatePromptLabels(ctx)
	setStageLights(ctx)

	local efficiency = Rules.Efficiency(ctx.rules)
	ctx.signal.Color = C.green
	ctx.signal.Material = Enum.Material.Neon
	ctx.stageMonitorText.Text = "SERIE\n2/2 OK"
	ctx.departureMonitorText.Text = "SIGNAL\nGREEN"
	ctx.departureMonitor.Color = C.green
	ctx.departureMonitor.Material = Enum.Material.Neon
	ctx.finalText.Text = string.format(
		"SKŁAD GOTOWY • ODJAZD\nKOSZT %d / OPTIMUM %d\nEFEKTYWNOŚĆ %d%%",
		efficiency.moves,
		efficiency.optimal,
		efficiency.score
	)
	ctx.finalGate.Color = C.green
	ctx.finalGate.Material = Enum.Material.Neon
	ctx.finalGate.CanCollide = false

	local shift = CFrame.new(78, 0, 0)
	tweenModel(ctx.locomotive, ctx.locomotive:GetPivot() * shift, 0.75)
	for _, wagon in ipairs(ctx.wagons) do
		tweenModel(wagon, wagon:GetPivot() * shift, 0.75)
	end

	hud(ctx, "ETAP 2/3 • Rail Sort ukończony. Przejdź do oznaczonego RDZENIA MISJI.")
	message(
		ctx,
		string.format(
			"Skład odjechał • %d manewrów przy optimum %d. Nadmiar kosztował efektywność, ale misja nie wymagała restartu.",
			efficiency.moves,
			efficiency.optimal
		),
		true
	)
end

local function handleSwap(ctx, index)
	if ctx.busy or ctx.state.done or not ctx.swapPrompts[index].Enabled then
		return
	end
	ctx.busy = true

	local ok, result = Rules.Swap(ctx.rules, index)
	if not ok then
		message(ctx, result, false)
		ctx.busy = false
		return
	end

	animateSwap(ctx, index)
	ctx.state.score += result.improved and 10 or 2

	if result.improved then
		message(
			ctx,
			string.format("Dobry manewr: nieporządek %d → %d. Koszt +1.", result.before, result.after),
			true
		)
	else
		message(
			ctx,
			string.format(
				"DEBUG KOSZTU • Ten swap zwiększył nieporządek %d → %d. Możesz go odwrócić bez restartu.",
				result.before,
				result.after
			),
			false
		)
	end

	if result.sorted then
		if result.completed then
			updateBoards(ctx, "SERIA 2/2 GOTOWA\nSygnał odjazdu jest zielony.")
			finishRailYard(ctx)
		else
			updateBoards(
				ctx,
				string.format(
					"SERIA 1/2 GOTOWA • koszt %d / optimum %d\nPociągnij DŹWIGNIĘ NOWA SERIA.",
					result.moves,
					result.optimal
				)
			)
			ctx.stageLeverPrompt.Enabled = true
			ctx.stageMonitorText.Text = "SERIA 1\nGOTOWA"
			setStageLights(ctx)
			hud(ctx, "ETAP 1/3 • Pierwszy skład gotowy. Uruchom drugą serię dźwignią przy nastawni.")
		end
	else
		updateBoards(ctx)
	end

	ctx.busy = false
end

function RailSort.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		wagons = {},
		swapPrompts = {},
		stageLights = {},
		entryScanned = false,
		busy = false,
	}

	part(
		model,
		"RailSortGround",
		Vector3.new(118, 1, 74),
		origin + Vector3.new(0, -0.5, -2),
		C.gravel,
		Enum.Material.Ground
	)

	for x = -48, 48, 6 do
		local sleeper = part(
			model,
			"RailSleeper_" .. tostring(x + 49),
			Vector3.new(1.1, 0.45, 13),
			origin + Vector3.new(x, 0.2, -4),
			C.wood,
			Enum.Material.WoodPlanks
		)
		sleeper.CanCollide = false
	end

	for _, z in ipairs({ -8, 0 }) do
		local rail = part(
			model,
			"RailMain_" .. tostring(z),
			Vector3.new(106, 0.55, 0.6),
			origin + Vector3.new(0, 0.65, z),
			C.rail,
			Enum.Material.Metal
		)
		rail.CanCollide = false
	end

	for _, z in ipairs({ 6, 14 }) do
		local rail = part(
			model,
			"RailSiding_" .. tostring(z),
			Vector3.new(54, 0.5, 0.55),
			origin + Vector3.new(-2, 0.62, z),
			C.rail,
			Enum.Material.Metal
		)
		rail.CanCollide = false
	end

	local manifestScanner = part(
		model,
		"RailManifestScanner",
		Vector3.new(10, 6, 4),
		origin + Vector3.new(0, 3, -42),
		C.blue,
		Enum.Material.Metal
	)
	manifestScanner.CanCollide = false
	manifestScanner.CanTouch = false
	local manifestText = label(manifestScanner, "MANIFEST\nSPRAWDŹ SKŁAD", Enum.NormalId.Back, 19, 28)
	local manifestPrompt
	manifestPrompt = prompt(manifestScanner, "SPRAWDŹ MANIFEST", "SERIA 1 • KOLEJNOŚĆ", function(p)
		if p ~= player or ctx.entryScanned or state.done then
			return
		end
		ctx.entryScanned = true
		manifestPrompt.Enabled = false
		manifestScanner.Color = C.green
		manifestScanner.Material = Enum.Material.Neon
		manifestText.Text = "MANIFEST OK\nSWAPY ODBLOKOWANE"
		updateBoards(ctx, "MANIFEST ODCZYTANY\nZamieniaj tylko sąsiednie wagony.")
		hud(ctx, "ETAP 1/3 • Posortuj 4 wagony rosnąco. Używaj wyłącznie sąsiednich swapów.")
		message(ctx, "Manifest potwierdzony. Sterowanie zwrotnicami jest aktywne.", true)
	end)
	ctx.manifestScanner = manifestScanner
	ctx.manifestPrompt = manifestPrompt

	local header = part(
		model,
		"RailSortHeader",
		Vector3.new(52, 9, 1.5),
		origin + Vector3.new(0, 13, -28),
		C.cream,
		Enum.Material.WoodPlanks
	)
	label(
		header,
		"RAIL SORT • PLAC MANEWROWY\nTYLKO SĄSIEDNIE ZAMIANY • KAŻDY SWAP = KOSZT 1",
		Enum.NormalId.Back,
		21,
		31
	)

	local orderBoard = part(
		model,
		"RailSortOrderBoard",
		Vector3.new(36, 10, 1.5),
		origin + Vector3.new(-32, 10, -21),
		C.dark,
		Enum.Material.Metal
	)
	ctx.orderText = label(orderBoard, "", Enum.NormalId.Back, 19, 28)

	local costBoard = part(
		model,
		"RailSortCostBoard",
		Vector3.new(28, 10, 1.5),
		origin + Vector3.new(32, 10, -21),
		C.dark,
		Enum.Material.Metal
	)
	ctx.costText = label(costBoard, "", Enum.NormalId.Back, 18, 26)

	local statusBoard = part(
		model,
		"RailSortStatusBoard",
		Vector3.new(42, 8, 1.5),
		origin + Vector3.new(0, 10, 22),
		C.dark,
		Enum.Material.Metal
	)
	ctx.statusText = label(statusBoard, "", Enum.NormalId.Front, 19, 28)

	local dispatchConsole = part(
		model,
		"RailDispatchConsole",
		Vector3.new(9, 4, 6),
		origin + Vector3.new(0, 2, 29),
		C.dark,
		Enum.Material.Metal
	)
	dispatchConsole.CanCollide = false

	local operatorDesk = part(
		model,
		"RailSortOperatorDesk",
		Vector3.new(16, 4, 8),
		origin + Vector3.new(18, 2, 29),
		C.wood,
		Enum.Material.WoodPlanks
	)
	operatorDesk.CanCollide = false
	operatorDesk.CanTouch = false
	local operatorKeyboard = part(
		model,
		"RailSortOperatorKeyboard",
		Vector3.new(6, 0.8, 2.4),
		origin + Vector3.new(16, 4.4, 28),
		C.dark,
		Enum.Material.Metal
	)
	operatorKeyboard.CanCollide = false
	operatorKeyboard.CanTouch = false
	local operatorMouse = part(
		model,
		"RailSortOperatorMouse",
		Vector3.new(2, 0.9, 1.6),
		origin + Vector3.new(23, 4.45, 28),
		C.dark,
		Enum.Material.Metal
	)
	operatorMouse.CanCollide = false
	operatorMouse.CanTouch = false

	local stageMonitor = part(
		model,
		"RailSortStageMonitor",
		Vector3.new(8, 6, 3),
		origin + Vector3.new(-12, 7, 29),
		C.dark,
		Enum.Material.Metal
	)
	stageMonitor.CanCollide = false
	stageMonitor.CanTouch = false
	ctx.stageMonitorText = label(stageMonitor, "SERIA\n1/2", Enum.NormalId.Front, 18, 26)

	local departureMonitor = part(
		model,
		"RailSortDepartureMonitor",
		Vector3.new(8, 6, 3),
		origin + Vector3.new(45, 7, 20),
		C.dark,
		Enum.Material.Metal
	)
	departureMonitor.CanCollide = false
	departureMonitor.CanTouch = false
	ctx.departureMonitor = departureMonitor
	ctx.departureMonitorText = label(departureMonitor, "SIGNAL\nRED", Enum.NormalId.Front, 18, 26)

	ctx.slotPositions = {
		origin + Vector3.new(-28, 4.1, -4),
		origin + Vector3.new(-14, 4.1, -4),
		origin + Vector3.new(0, 4.1, -4),
		origin + Vector3.new(14, 4.1, -4),
		origin + Vector3.new(28, 4.1, -4),
	}

	local postXs = { -21, -7, 7, 21 }
	for index, x in ipairs(postXs) do
		local post = part(
			model,
			"RailSwapPost_" .. index,
			Vector3.new(3.2, 7, 3.2),
			origin + Vector3.new(x, 3.5, 12),
			index % 2 == 0 and C.blue or C.orange,
			Enum.Material.Metal
		)
		local lamp = part(
			model,
			"RailSwapLamp_" .. index,
			Vector3.new(2.1, 2.1, 2.1),
			origin + Vector3.new(x, 7.7, 12),
			C.yellow,
			Enum.Material.Neon
		)
		lamp.Shape = Enum.PartType.Ball
		lamp.CanCollide = false
		local control = part(
			model,
			"RailSwapControl_" .. index,
			Vector3.new(2.8, 1.3, 2.8),
			origin + Vector3.new(x, 6.4, 12),
			C.yellow,
			Enum.Material.Metal
		)
		control.CanCollide = false
		ctx.swapPrompts[index] = prompt(control, "ZAMIEŃ SĄSIADÓW", "", function(p)
			if p == player then
				handleSwap(ctx, index)
			end
		end)
	end

	local leverBase = part(
		model,
		"RailStageLever",
		Vector3.new(7, 4, 7),
		origin + Vector3.new(-43, 2, 22),
		C.wood,
		Enum.Material.WoodPlanks
	)
	local lever = part(
		model,
		"RailStageLeverHandle",
		Vector3.new(2, 8, 2),
		origin + Vector3.new(-43, 7, 22),
		C.red,
		Enum.Material.Metal
	)
	lever.CFrame = CFrame.new(lever.Position) * CFrame.Angles(0, 0, math.rad(-28))
	lever.CanCollide = false
	label(leverBase, "NASTAWNIA\nSERIA 2", Enum.NormalId.Top, 18, 24)
	local stageSwitch = part(
		model,
		"RailStageSwitch",
		Vector3.new(3, 1.5, 3),
		origin + Vector3.new(-43, 5.2, 18),
		C.red,
		Enum.Material.Metal
	)
	stageSwitch.CanCollide = false

	ctx.stageLeverPrompt = prompt(stageSwitch, "NOWA SERIA", "DŹWIGNIA NASTAWNI", function(p)
		if p ~= player or ctx.busy or state.done then
			return
		end
		local ok, result = Rules.StartNext(ctx.rules)
		if not ok then
			message(ctx, result, false)
			return
		end
		ctx.stageLeverPrompt.Enabled = false
		ctx.busy = true
		ctx.stageMonitorText.Text = "SERIA\n2/2"
		loadWagons(ctx)
		updateBoards(ctx, "SERIA 2/2 • TOWAROWA\nCel: rosnąco przy koszcie bliskim 6.")
		updatePromptLabels(ctx)
		setStageLights(ctx)
		hud(ctx, "ETAP 2/3 • Posortuj 5 wagonów rosnąco. Każdy sąsiedni swap kosztuje 1 manewr.")
		message(ctx, "Nowy skład wjechał na tor. Minimum dla tej serii to 6 manewrów.", true)
		ctx.busy = false
	end)
	ctx.stageLeverPrompt.Enabled = false

	for index = 1, 2 do
		local lightPart = part(
			model,
			"RailSortStageLight_" .. index,
			Vector3.new(4, 4, 4),
			origin + Vector3.new(34 + index * 6, 8, 20),
			C.yellow,
			Enum.Material.SmoothPlastic
		)
		lightPart.Shape = Enum.PartType.Ball
		lightPart.CanCollide = false
		table.insert(ctx.stageLights, lightPart)
	end

	ctx.locomotive = createLocomotive(model, origin + Vector3.new(-43, 4.1, -4))

	ctx.signal = part(
		model,
		"RailSortDepartureSignal",
		Vector3.new(4, 4, 4),
		origin + Vector3.new(43, 10, -18),
		C.red,
		Enum.Material.Neon
	)
	ctx.signal.Shape = Enum.PartType.Ball
	ctx.signal.CanCollide = false

	ctx.finalGate = part(
		model,
		"RailSortFinalGate",
		Vector3.new(18, 11, 2),
		origin + Vector3.new(48, 5.5, -4),
		C.red,
		Enum.Material.Metal
	)
	ctx.finalText = label(ctx.finalGate, "ODJAZD ZABLOKOWANY\nUPORZĄDKUJ 2 SKŁADY", Enum.NormalId.Left, 19, 27)

	loadWagons(ctx)
	updateBoards(ctx, "ETAP START • Podejdź do skanera MANIFEST przy wejściu.")
	setStageLights(ctx)
	hud(ctx, "ETAP 1/3 • Najpierw zeskanuj manifest przy wejściu, aby odblokować zwrotnice.")
	return ctx
end

return RailSort