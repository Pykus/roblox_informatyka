local PythonRobotDock = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SemanticAssets = require(script.Parent:WaitForChild("SemanticAssetLibrary"))

local C = {
	dark = Color3.fromRGB(23, 29, 40),
	steel = Color3.fromRGB(74, 86, 101),
	blue = Color3.fromRGB(55, 165, 255),
	cyan = Color3.fromRGB(63, 221, 223),
	green = Color3.fromRGB(72, 212, 123),
	red = Color3.fromRGB(232, 76, 76),
	yellow = Color3.fromRGB(245, 203, 72),
	white = Color3.fromRGB(242, 246, 250),
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
	txt.Font = Enum.Font.Code
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 16
	constraint.MaxTextSize = maxText or 30
	constraint.Parent = txt
	return txt
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.4
	l.Range = range or 16
	l.Parent = target
	return l
end

local function attachRobotVisual(dock, model, robot)
	if not robot then
		return
	end

	robot:SetAttribute("SemanticDecorated", true)
	local visual, reason = SemanticAssets.Place("robot", model, robot.CFrame, robot.Size, "Semantic_PythonDockRobot")
	if not visual then
		robot:SetAttribute("SemanticAssetFallback", true)
		warn("[PYTHON-DOCK] robot semantic fallback: " .. tostring(reason))
		return
	end

	robot:SetAttribute("SemanticAssetKey", "robot")
	robot:SetAttribute("SemanticAssetId", visual:GetAttribute("SemanticAssetId"))
	robot:SetAttribute("SemanticAssetFallback", false)
	dock.robotPart = robot
	dock.robotVisual = visual
	dock.robotVisualOffset = robot.CFrame:ToObjectSpace(visual:GetPivot())
	robot.Transparency = 1

	dock.robotFollow = RunService.Heartbeat:Connect(function()
		if not robot.Parent or not visual.Parent then
			if dock.robotFollow then
				dock.robotFollow:Disconnect()
				dock.robotFollow = nil
			end
			return
		end
		visual:PivotTo(robot.CFrame * dock.robotVisualOffset)
	end)
end

local function attachChipCargo(dock, model, anchor)
	anchor:SetAttribute("SemanticDecorated", true)
	local visual, reason =
		SemanticAssets.Place("crate", model, anchor.CFrame, anchor.Size, "Semantic_PythonDockChipCargo")
	if not visual then
		anchor:SetAttribute("SemanticAssetFallback", true)
		warn("[PYTHON-DOCK] chip cargo semantic fallback: " .. tostring(reason))
		return
	end

	anchor:SetAttribute("SemanticAssetKey", "crate")
	anchor:SetAttribute("SemanticAssetId", visual:GetAttribute("SemanticAssetId"))
	anchor:SetAttribute("SemanticAssetFallback", false)
	anchor.Transparency = 1
	dock.chipCargoAnchor = anchor
	dock.chipCargoVisual = visual
	dock.chipCargoHome = visual:GetPivot()
	dock.carryingChip = false
	dock.chipDelivered = false

	dock.chipCargoFollow = RunService.Heartbeat:Connect(function()
		if not anchor.Parent or not visual.Parent then
			if dock.chipCargoFollow then
				dock.chipCargoFollow:Disconnect()
				dock.chipCargoFollow = nil
			end
			return
		end

		if dock.chipDelivered and dock.serverTower and dock.serverTower.Parent then
			visual:PivotTo(dock.serverTower.CFrame * CFrame.new(0, 8.5, 0))
		elseif dock.carryingChip and dock.robotPart and dock.robotPart.Parent then
			visual:PivotTo(dock.robotPart.CFrame * CFrame.new(0, 3.8, 0))
		else
			visual:PivotTo(dock.chipCargoHome)
		end
	end)
end

function PythonRobotDock.Build(model, origin, gridOrigin, gridSize, step, robot)
	local dock = {
		traces = {},
		signals = {},
	}

	local floor = part(
		model,
		"PythonRobotDockFloor",
		Vector3.new(78, 1, 104),
		origin + Vector3.new(0, 0.15, 8),
		Color3.fromRGB(45, 52, 63),
		Enum.Material.DiamondPlate
	)
	floor.CanCollide = true

	local gantry = part(
		model,
		"PythonDockGantry",
		Vector3.new(58, 8, 2),
		origin + Vector3.new(0, 22, -43),
		C.blue,
		Enum.Material.Metal
	)
	dock.headerText = label(gantry, "PYTHON ROBOT DOCK\nKOD → RUCH → STAN ŚWIATA", Enum.NormalId.Front, 30)
	light(gantry, C.blue, 1.8, 20)

	local status = part(
		model,
		"PythonDockStatus",
		Vector3.new(38, 9, 2),
		origin + Vector3.new(20, 10, -34),
		C.dark,
		Enum.Material.Metal
	)
	dock.statusPart = status
	dock.statusText = label(status, "BOT (0,0) • KIERUNEK →\nCZEKA NA KOD", Enum.NormalId.Front, 25)

	local controlConsole = part(
		model,
		"PythonDockControlConsole",
		Vector3.new(12, 7, 8),
		origin + Vector3.new(-20, 4, -34),
		C.steel,
		Enum.Material.Metal
	)
	controlConsole.CanCollide = false
	label(controlConsole, "RUN / RESET\nKOD STERUJE BOTEM", Enum.NormalId.Front, 20)
	dock.controlConsole = controlConsole

	local commandData = {
		{ "move(1)", C.blue },
		{ "turn_left()", C.cyan },
		{ "turn_right()", C.cyan },
		{ "pickup()", C.yellow },
		{ "drop()", C.green },
	}
	for i, data in ipairs(commandData) do
		local tower = part(
			model,
			"PythonCommandTower_" .. i,
			Vector3.new(13, 7, 5),
			origin + Vector3.new(-31 + (i - 1) * 15.5, 5, -25),
			data[2],
			Enum.Material.SmoothPlastic
		)
		label(tower, data[1], Enum.NormalId.Front, 21)
		dock.signals[i] = light(tower, data[2], 0.7, 9)
	end

	local railColor = Color3.fromRGB(79, 93, 111)
	for x = 0, gridSize - 1 do
		for y = 0, gridSize - 1 do
			local pos = gridOrigin + Vector3.new(x * step, 0.95, y * step)
			local trace = part(
				model,
				string.format("PythonDockTrace_%d_%d", x, y),
				Vector3.new(2.2, 0.18, 2.2),
				pos,
				railColor,
				Enum.Material.Neon
			)
			trace.CanCollide = false
			trace.Transparency = 0.55
			dock.traces[string.format("%d:%d", x, y)] = trace
		end
	end

	local chipCrane = part(
		model,
		"PythonDockChipCrane",
		Vector3.new(3, 14, 3),
		gridOrigin + Vector3.new(2 * step, 7, 2 * step),
		C.yellow,
		Enum.Material.Metal
	)
	label(chipCrane, "CHIP\n(2,2)", Enum.NormalId.Front, 20)
	dock.chipLight = light(chipCrane, C.yellow, 1.7, 15)
	local chipCargoAnchor = part(
		model,
		"PythonDockChipCargoAnchor",
		Vector3.new(4.5, 3.5, 4.5),
		gridOrigin + Vector3.new(2 * step, 2.6, 2 * step),
		C.yellow,
		Enum.Material.SmoothPlastic
	)
	chipCargoAnchor.CanCollide = false
	chipCargoAnchor.CanTouch = false

	local serverTower = part(
		model,
		"PythonDockServerTower",
		Vector3.new(10, 13, 10),
		gridOrigin + Vector3.new(4 * step, 6.5, 4 * step),
		Color3.fromRGB(42, 103, 82),
		Enum.Material.Metal
	)
	label(serverTower, "SERWER\n(4,4)", Enum.NormalId.Front, 22)
	dock.serverTower = serverTower
	dock.serverLight = light(serverTower, C.green, 0.9, 18)

	local gate = part(
		model,
		"PythonDockGate",
		Vector3.new(30, 17, 2),
		origin + Vector3.new(0, 8.5, 63),
		Color3.fromRGB(68, 77, 88),
		Enum.Material.Metal
	)
	label(gate, "DOK ZABLOKOWANY\nURUCHOM POPRAWNY KOD", Enum.NormalId.Back, 25)
	dock.gate = gate
	dock.gateClosed = gate.Position
	dock.gateOpen = gate.Position + Vector3.new(0, 19, 0)

	for i = 1, 5 do
		local lamp = part(
			model,
			"PythonDockLamp_" .. i,
			Vector3.new(7, 0.6, 2.5),
			origin + Vector3.new(-28 + (i - 1) * 14, 18, 52),
			Color3.fromRGB(70, 78, 88),
			Enum.Material.Metal
		)
		dock["lamp" .. i] = lamp
	end

	dock.gridOrigin = gridOrigin
	dock.step = step
	attachRobotVisual(dock, model, robot)
	attachChipCargo(dock, model, chipCargoAnchor)
	PythonRobotDock.Reset(dock)
	return dock
end

function PythonRobotDock.Reset(dock)
	if not dock then
		return
	end
	for _, trace in pairs(dock.traces) do
		if trace and trace.Parent then
			trace.Color = Color3.fromRGB(79, 93, 111)
			trace.Transparency = 0.55
		end
	end
	if dock.gate and dock.gate.Parent then
		dock.gate.Position = dock.gateClosed
		dock.gate.Color = Color3.fromRGB(68, 77, 88)
		dock.gate.Material = Enum.Material.Metal
	end
	if dock.statusText then
		dock.statusText.Text = "BOT (0,0) • KIERUNEK →\nCZEKA NA KOD"
	end
	if dock.statusPart then
		dock.statusPart.Color = C.dark
		dock.statusPart.Material = Enum.Material.Metal
	end
	if dock.serverTower then
		dock.serverTower.Color = Color3.fromRGB(42, 103, 82)
		dock.serverTower.Material = Enum.Material.Metal
	end
	if dock.serverLight then
		dock.serverLight.Brightness = 0.9
	end
	if dock.chipLight then
		dock.chipLight.Color = C.yellow
	end
	dock.carryingChip = false
	dock.chipDelivered = false
	if dock.chipCargoVisual and dock.chipCargoHome then
		dock.chipCargoVisual:PivotTo(dock.chipCargoHome)
	end
	for i = 1, 5 do
		local lamp = dock["lamp" .. i]
		if lamp then
			lamp.Color = Color3.fromRGB(70, 78, 88)
			lamp.Material = Enum.Material.Metal
		end
	end
end

function PythonRobotDock.Step(dock, x, y)
	if not dock then
		return
	end
	local key = string.format("%d:%d", x, y)
	local trace = dock.traces[key]
	if trace then
		trace.Color = C.cyan
		trace.Transparency = 0
	end
	if dock.statusText then
		dock.statusText.Text = string.format("BOT (%d,%d)\nmove() wykonał krok", x, y)
	end
	if dock.statusPart then
		dock.statusPart.Color = C.blue
	end
end

function PythonRobotDock.Command(dock, text)
	if dock and dock.statusText then
		dock.statusText.Text = text
	end
end

function PythonRobotDock.Pickup(dock)
	if not dock then
		return
	end
	if dock.statusText then
		dock.statusText.Text = "pickup()\nCHIP JEST TERAZ STANEM ROBOTA"
	end
	if dock.chipLight then
		dock.chipLight.Color = C.green
	end
	dock.carryingChip = true
	dock.chipDelivered = false
end

function PythonRobotDock.Fail(dock, text)
	if not dock then
		return
	end
	if dock.statusPart then
		dock.statusPart.Color = C.red
	end
	if dock.statusText then
		dock.statusText.Text = "DEBUG PYTHON\n" .. tostring(text)
	end
end

function PythonRobotDock.Complete(dock)
	if not dock then
		return
	end
	if dock.statusPart then
		dock.statusPart.Color = C.green
		dock.statusPart.Material = Enum.Material.Neon
	end
	if dock.statusText then
		dock.statusText.Text = "drop() • SERWER (4,4)\nPROGRAM ZMIENIŁ ŚWIAT"
	end
	dock.carryingChip = false
	dock.chipDelivered = true
	if dock.serverTower then
		dock.serverTower.Color = C.green
		dock.serverTower.Material = Enum.Material.Neon
	end
	if dock.serverLight then
		dock.serverLight.Brightness = 3
	end
	if dock.gate then
		dock.gate.Color = C.green
		dock.gate.Material = Enum.Material.Neon
		TweenService:Create(
			dock.gate,
			TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = dock.gateOpen }
		):Play()
	end
	for i = 1, 5 do
		local lamp = dock["lamp" .. i]
		if lamp then
			task.delay((i - 1) * 0.12, function()
				lamp.Color = C.cyan
				lamp.Material = Enum.Material.Neon
				light(lamp, C.cyan, 1.4, 14)
			end)
		end
	end
end

return PythonRobotDock