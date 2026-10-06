local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LoopFactory = {}
local Rules = require(script.Parent:WaitForChild("LoopFactoryRules"))
local PythonSubset = require(script.Parent:WaitForChild("PythonSubset"))

local C = {
	floor = Color3.fromRGB(118, 112, 98),
	wall = Color3.fromRGB(185, 174, 145),
	steel = Color3.fromRGB(67, 75, 82),
	dark = Color3.fromRGB(28, 34, 40),
	yellow = Color3.fromRGB(245, 181, 62),
	blue = Color3.fromRGB(70, 165, 235),
	green = Color3.fromRGB(65, 220, 125),
	red = Color3.fromRGB(235, 82, 72),
	white = Color3.fromRGB(242, 246, 248),
	purple = Color3.fromRGB(156, 104, 220),
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

local function setHud(factory, objective)
	factory.state.objective = objective
	factory.remote:FireClient(factory.player, {
		kind = "hud",
		title = factory.mission.name or factory.lesson.topic,
		objective = objective,
		score = factory.state.score,
	})
end

local function message(factory, text, good)
	factory.remote:FireClient(factory.player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function tween(instance, goal, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	tw:Play()
	return tw
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

local function syncSemanticVisibility(semantic, hidden)
	for _, item in ipairs(semantic:GetDescendants()) do
		if item:IsA("BasePart") then
			if item:GetAttribute("LoopFactoryBaseTransparency") == nil then
				item:SetAttribute("LoopFactoryBaseTransparency", item.Transparency)
			end
			local baseTransparency = item:GetAttribute("LoopFactoryBaseTransparency")
			item.Transparency = hidden and 1 or baseTransparency
		end
	end
end

local function followSemanticVisual(source, syncVisibility)
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
			if syncVisibility then
				syncSemanticVisibility(semantic, source.Transparency >= 0.95)
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

local function stageCopy(stageIndex)
	local stage = Rules.Stages[stageIndex]
	if not stage then
		return "FABRYKA ONLINE", "", ""
	end
	return string.format("ETAP %d/3 • %s", stageIndex, stage.id), stage.challenge, stage.starter
end

local function resetPackages(factory)
	for _, package in ipairs(factory.packages) do
		package.Transparency = 1
		package.Position = factory.packageOrigin
	end
	factory.stamper.Position = factory.stamperHome
	factory.status.Text = "ITERACJE: 0\nczekam na kod"
	factory.status.TextColor3 = C.white
end

local function illuminateStage(factory)
	for index, lamp in ipairs(factory.stageLamps) do
		lamp.Color = index < factory.rules.stage and C.green or C.yellow
		lamp.Material = index < factory.rules.stage and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end

local function animateProduction(factory, count, good)
	resetPackages(factory)
	local visible = math.min(count, #factory.packages)
	for index = 1, visible do
		local package = factory.packages[index]
		package.Transparency = 0
		package.Position = factory.packageOrigin
		factory.status.Text = string.format("ITERACJA %d/%d\nindeks = %d", index, count, index - 1)
		tween(factory.stamper, { Position = factory.stamperHome - Vector3.new(0, 2.5, 0) }, 0.08).Completed:Wait()
		tween(factory.stamper, { Position = factory.stamperHome }, 0.08)
		local target = factory.packageTargets[index]
		tween(package, { Position = target }, 0.13).Completed:Wait()
	end
	factory.status.TextColor3 = good and C.green or C.red
end

local function updateConsole(factory, consoleRemote, intro)
	local stageIndex = factory.rules.stage
	local title, challenge, starter = stageCopy(stageIndex)
	if not Rules.Stages[stageIndex] then
		consoleRemote:FireClient(factory.player, {
			kind = "output",
			text = "LOOP FACTORY ONLINE • wszystkie trzy serie działają.",
			good = true,
		})
		return
	end
	consoleRemote:FireClient(factory.player, {
		kind = "open",
		title = "LOOP FACTORY • " .. title,
		challenge = challenge,
		starter = starter,
		output = intro or "Uruchom kod. Każde print(i) zapala kolejną iterację linii.",
	})
end

function LoopFactory.Build(model, origin, player, lesson, mission, remote, state, accent, consoleRemote)
	local factory = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		packages = {},
		packageTargets = {},
		stageLamps = {},
	}

	part(
		model,
		"LoopFactoryFloor",
		Vector3.new(76, 1, 70),
		origin + Vector3.new(0, -0.5, -10),
		C.floor,
		Enum.Material.Concrete
	)
	part(
		model,
		"LoopFactoryBackWall",
		Vector3.new(76, 18, 2),
		origin + Vector3.new(0, 9, -43),
		C.wall,
		Enum.Material.Brick
	)
	local sign = part(
		model,
		"LoopFactorySign",
		Vector3.new(40, 8, 1),
		origin + Vector3.new(0, 13, -41.8),
		C.dark,
		Enum.Material.Metal
	)
	label(sign, "LOOP FACTORY\nfor i in range(...)", Enum.NormalId.Front, 22)

	local belt = part(
		model,
		"LoopFactoryConveyor",
		Vector3.new(54, 2, 12),
		origin + Vector3.new(0, 1, -8),
		C.steel,
		Enum.Material.Metal
	)
	for index = 1, 9 do
		local roller = part(
			model,
			"LoopFactoryRoller_" .. index,
			Vector3.new(2.4, 11, 2.4),
			origin + Vector3.new(-24 + (index - 1) * 6, 2.4, -8),
			C.blue,
			Enum.Material.Metal
		)
		roller.Shape = Enum.PartType.Cylinder
		roller.CFrame = CFrame.new(roller.Position) * CFrame.Angles(0, 0, math.rad(90))
		roller.CanCollide = false
	end

	local scannerLeft = part(
		model,
		"LoopFactoryScannerLeft",
		Vector3.new(2, 10, 2),
		origin + Vector3.new(11, 6, -8),
		C.purple,
		Enum.Material.Neon
	)
	local scannerRight = part(
		model,
		"LoopFactoryScannerRight",
		Vector3.new(2, 10, 2),
		origin + Vector3.new(19, 6, -8),
		C.purple,
		Enum.Material.Neon
	)
	local scannerTop = part(
		model,
		"LoopFactoryScannerTop",
		Vector3.new(10, 2, 2),
		origin + Vector3.new(15, 11, -8),
		C.purple,
		Enum.Material.Neon
	)
	scannerLeft.CanCollide = false
	scannerRight.CanCollide = false
	scannerTop.CanCollide = false
	followSemanticVisual(scannerTop, false)

	factory.stamperHome = origin + Vector3.new(-16, 10, -8)
	factory.stamper =
		part(model, "LoopFactoryStamper", Vector3.new(7, 5, 7), factory.stamperHome, C.yellow, Enum.Material.Metal)
	followSemanticVisual(factory.stamper, false)
	local stampHead = part(
		model,
		"LoopFactoryStampHead",
		Vector3.new(3, 4, 3),
		factory.stamperHome - Vector3.new(0, 4, 0),
		C.red,
		Enum.Material.Neon
	)
	stampHead.CanCollide = false

	local statusBoard = part(
		model,
		"LoopFactoryIterationBoard",
		Vector3.new(20, 9, 1),
		origin + Vector3.new(-24, 11, -25),
		C.dark,
		Enum.Material.Metal
	)
	factory.status = label(statusBoard, "ITERACJE: 0\nczekam na kod", Enum.NormalId.Front, 20)

	local controlConsole = part(
		model,
		"LoopFactoryControlConsole",
		Vector3.new(10, 7, 8),
		origin + Vector3.new(-9, 4, -29),
		C.steel,
		Enum.Material.Metal
	)
	controlConsole.CanCollide = false

	local automationRack = part(
		model,
		"LoopFactoryAutomationRack",
		Vector3.new(9, 12, 8),
		origin + Vector3.new(3, 6, -30),
		C.dark,
		Enum.Material.Metal
	)
	automationRack.CanCollide = false

	local shippingCrate = part(
		model,
		"LoopFactoryShippingCrate",
		Vector3.new(7, 7, 7),
		origin + Vector3.new(27, 3.5, -18),
		C.yellow,
		Enum.Material.WoodPlanks
	)
	shippingCrate.CanCollide = false

	for index = 1, 3 do
		local lamp = part(
			model,
			"LoopFactoryStageLamp_" .. index,
			Vector3.new(5, 5, 2),
			origin + Vector3.new(8 + index * 7, 11, -25),
			C.yellow,
			Enum.Material.SmoothPlastic
		)
		label(lamp, tostring(index), Enum.NormalId.Front, 20)
		lamp.CanCollide = false
		table.insert(factory.stageLamps, lamp)
	end

	factory.packageOrigin = origin + Vector3.new(-24, 4.2, -8)
	for index = 1, 6 do
		local package = part(
			model,
			"LoopFactoryPackage_" .. index,
			Vector3.new(4.5, 4.5, 4.5),
			factory.packageOrigin,
			index % 2 == 0 and C.blue or C.yellow,
			Enum.Material.SmoothPlastic
		)
		package.Transparency = 1
		package.CanCollide = false
		label(package, tostring(index - 1), Enum.NormalId.Top, 18)
		followSemanticVisual(package, true)
		table.insert(factory.packages, package)
		table.insert(factory.packageTargets, origin + Vector3.new(-14 + (index - 1) * 7, 4.2, -8))
	end

	local finalGate = part(
		model,
		"LoopFactoryFinalGate",
		Vector3.new(24, 11, 2),
		origin + Vector3.new(0, 5.5, 27),
		C.red,
		Enum.Material.Metal
	)
	factory.finalGate = finalGate
	factory.finalLabel = label(finalGate, "LINIA OFFLINE\n3 SERIE DO URUCHOMIENIA", Enum.NormalId.Front, 19)

	local coreLamp = part(
		model,
		"LoopFactoryCoreLamp",
		Vector3.new(7, 7, 7),
		origin + Vector3.new(0, 8, 19),
		accent,
		Enum.Material.Glass
	)
	coreLamp.Shape = Enum.PartType.Ball
	coreLamp.CanCollide = false
	factory.coreLamp = coreLamp

	resetPackages(factory)
	illuminateStage(factory)
	updateConsole(factory, consoleRemote)
	setHud(factory, "ETAP 1/3 • Napraw pętlę: linia ma wykonać dokładnie 4 iteracje.")
	return factory
end

function LoopFactory.Reset(factory, consoleRemote)
	resetPackages(factory)
	illuminateStage(factory)
	updateConsole(
		factory,
		consoleRemote,
		"Linia zresetowana. Etap pozostaje ten sam — popraw kod i uruchom ponownie."
	)
end

function LoopFactory.Execute(factory, source, consoleRemote)
	local plan, parseError = PythonSubset.Parse(source)
	if not plan then
		factory.rules.errors += 1
		resetPackages(factory)
		factory.status.Text = "BŁĄD SKŁADNI"
		factory.status.TextColor3 = C.red
		consoleRemote:FireClient(factory.player, {
			kind = "output",
			text = "Błąd składni: " .. parseError,
			good = false,
		})
		return false
	end

	local ok, result = Rules.Analyze(factory.rules, source, plan)
	animateProduction(factory, result.produced or 0, ok)
	if not ok then
		factory.state.score = math.max(0, factory.state.score - 5)
		factory.status.Text = string.format("DEBUG\n%d iteracji", result.produced or 0)
		message(factory, result.message, false)
		consoleRemote:FireClient(factory.player, {
			kind = "output",
			text = result.message,
			good = false,
		})
		setHud(factory, string.format("ETAP %d/3 • Popraw pętlę bez restartu misji.", factory.rules.stage))
		return false
	end

	factory.state.score += 45
	illuminateStage(factory)
	factory.status.Text = result.message
	factory.status.TextColor3 = C.green

	if result.completed then
		factory.state.done = true
		factory.state.score += 80
		factory.finalGate.Color = C.green
		factory.finalGate.Material = Enum.Material.Neon
		factory.finalLabel.Text = "LOOP FACTORY ONLINE\n3/3 SERIE GOTOWE"
		factory.coreLamp.Color = C.green
		factory.coreLamp.Material = Enum.Material.Neon
		message(
			factory,
			string.format(
				"Fabryka działa. Pętla wykonała trzy serie; efektywność %d%%.",
				Rules.Efficiency(factory.rules)
			),
			true
		)
		consoleRemote:FireClient(factory.player, {
			kind = "output",
			text = "SUKCES • 3/3 serie poprawne. Rdzeń misji jest gotowy.",
			good = true,
		})
		setHud(factory, "ETAP 2/3 • Loop Factory online. Przejdź do oznaczonego RDZENIA MISJI.")
		return true
	end

	local stage = Rules.Current(factory.rules)
	message(factory, result.message .. " Następna seria.", true)
	updateConsole(factory, consoleRemote, "Poprzednia seria gotowa. Teraz napisz pętlę dla kolejnego celu.")
	setHud(factory, string.format("ETAP %d/3 • %s", factory.rules.stage, stage.challenge))
	return true
end

return LoopFactory