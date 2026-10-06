local PythonRobotMaze = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("PythonRobotMazeRules"))
local SemanticAssets = require(script.Parent:WaitForChild("SemanticAssetLibrary"))

local C = {
	dark = Color3.fromRGB(25, 29, 38),
	steel = Color3.fromRGB(72, 81, 94),
	blue = Color3.fromRGB(65, 141, 230),
	cyan = Color3.fromRGB(56, 214, 224),
	green = Color3.fromRGB(76, 209, 115),
	red = Color3.fromRGB(235, 70, 77),
	yellow = Color3.fromRGB(245, 202, 70),
	purple = Color3.fromRGB(153, 92, 210),
	white = Color3.fromRGB(240, 245, 248),
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
	constraint.MaxTextSize = maxText or 29
	constraint.Parent = txt
	return txt
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.5
	l.Range = range or 15
	l.Parent = target
	return l
end

local function attachRobotVisual(maze, model, robot)
	if not robot then
		return
	end
	robot:SetAttribute("SemanticDecorated", true)
	local visual, reason = SemanticAssets.Place("robot", model, robot.CFrame, robot.Size, "Semantic_PythonMazeRobot")
	if not visual then
		robot:SetAttribute("SemanticAssetFallback", true)
		warn("[PYTHON-MAZE] robot semantic fallback: " .. tostring(reason))
		return
	end
	robot:SetAttribute("SemanticAssetKey", "robot")
	robot:SetAttribute("SemanticAssetId", visual:GetAttribute("SemanticAssetId"))
	robot:SetAttribute("SemanticAssetFallback", false)
	maze.robotVisual = visual
	maze.robotVisualOffset = robot.CFrame:ToObjectSpace(visual:GetPivot())
	robot.Transparency = 1
	maze.robotPart = robot
	maze.robotFollow = RunService.Heartbeat:Connect(function()
		if not robot.Parent or not visual.Parent then
			if maze.robotFollow then
				maze.robotFollow:Disconnect()
				maze.robotFollow = nil
			end
			return
		end
		visual:PivotTo(robot.CFrame * maze.robotVisualOffset)
	end)
end

local function attachChipCargo(maze, model, anchor)
	anchor:SetAttribute("SemanticDecorated", true)
	local visual, reason =
		SemanticAssets.Place("crate", model, anchor.CFrame, anchor.Size, "Semantic_PythonMazeChipCargo")
	if not visual then
		anchor:SetAttribute("SemanticAssetFallback", true)
		warn("[PYTHON-MAZE] chip cargo semantic fallback: " .. tostring(reason))
		return
	end

	anchor:SetAttribute("SemanticAssetKey", "crate")
	anchor:SetAttribute("SemanticAssetId", visual:GetAttribute("SemanticAssetId"))
	anchor:SetAttribute("SemanticAssetFallback", false)
	anchor.Transparency = 1
	maze.chipCargoAnchor = anchor
	maze.chipCargoVisual = visual
	maze.chipCargoHome = visual:GetPivot()
	maze.carryingChip = false
	maze.chipDelivered = false

	maze.chipCargoFollow = RunService.Heartbeat:Connect(function()
		if not anchor.Parent or not visual.Parent then
			if maze.chipCargoFollow then
				maze.chipCargoFollow:Disconnect()
				maze.chipCargoFollow = nil
			end
			return
		end
		if maze.chipDelivered and maze.serverTower and maze.serverTower.Parent then
			visual:PivotTo(maze.serverTower.CFrame * CFrame.new(0, 9, 0))
		elseif maze.carryingChip and maze.robotPart and maze.robotPart.Parent then
			visual:PivotTo(maze.robotPart.CFrame * CFrame.new(0, 3.8, 0))
		else
			visual:PivotTo(maze.chipCargoHome)
		end
	end)
end

function PythonRobotMaze.Build(model, origin, gridOrigin, gridSize, step, robot)
	local maze = {
		traces = {},
		barriers = {},
		rulesState = Rules.NewState(),
		gridOrigin = gridOrigin,
		step = step,
	}

	local floor = part(
		model,
		"PythonRobotMazeFloor",
		Vector3.new(80, 1, 104),
		origin + Vector3.new(0, 0.12, 8),
		Color3.fromRGB(37, 42, 51),
		Enum.Material.DiamondPlate
	)
	floor.CanCollide = true

	local gantry = part(
		model,
		"PythonMazeGantry",
		Vector3.new(60, 8, 2),
		origin + Vector3.new(0, 22, -43),
		C.purple,
		Enum.Material.Metal
	)
	maze.headerText =
		label(gantry, "PYTHON ROBOT MAZE\nSENSOR (0,2) → CHIP (2,2) → SERWER (4,4)", Enum.NormalId.Front, 28)
	light(gantry, C.purple, 1.8, 20)

	local status = part(
		model,
		"PythonMazeStatus",
		Vector3.new(38, 9, 2),
		origin + Vector3.new(20, 10, -34),
		C.dark,
		Enum.Material.Metal
	)
	maze.statusPart = status
	maze.statusText = label(status, "LASERY AKTYWNE\nSENSOR: OFF", Enum.NormalId.Front, 25)

	local controlConsole = part(
		model,
		"PythonMazeControlConsole",
		Vector3.new(12, 7, 8),
		origin + Vector3.new(-20, 4, -34),
		C.steel,
		Enum.Material.Metal
	)
	controlConsole.CanCollide = false
	label(controlConsole, "RUN / RESET\nOMIŃ LASERY", Enum.NormalId.Front, 20)
	maze.controlConsole = controlConsole

	local sensorPad = part(
		model,
		"PythonMazeSensor",
		Vector3.new(7, 0.6, 7),
		gridOrigin + Vector3.new(Rules.Sensor.X * step, 0.9, Rules.Sensor.Y * step),
		C.yellow,
		Enum.Material.Neon
	)
	sensorPad.CanCollide = false
	maze.sensorPad = sensorPad
	maze.sensorLight = light(sensorPad, C.yellow, 2, 16)
	label(sensorPad, "SENSOR\n(0,2)", Enum.NormalId.Top, 20)
	for x = 0, gridSize - 1 do
		for y = 0, gridSize - 1 do
			local trace = part(
				model,
				string.format("PythonMazeTrace_%d_%d", x, y),
				Vector3.new(2.4, 0.15, 2.4),
				gridOrigin + Vector3.new(x * step, 1, y * step),
				Color3.fromRGB(73, 82, 96),
				Enum.Material.Neon
			)
			trace.Transparency = 0.7
			trace.CanCollide = false
			maze.traces[Rules.Key(x, y)] = trace
		end
	end

	for key in pairs(Rules.Blocked) do
		local sx, sy = string.match(key, "^(%d+):(%d+)$")
		local x = tonumber(sx)
		local y = tonumber(sy)
		local base = gridOrigin + Vector3.new(x * step, 4.5, y * step)
		local post = part(
			model,
			"PythonLaserPost_" .. key:gsub(":", "_"),
			Vector3.new(1.2, 8, 1.2),
			base,
			C.red,
			Enum.Material.Metal
		)
		local beam = part(
			model,
			"PythonLaserBarrier_" .. key:gsub(":", "_"),
			Vector3.new(6.8, 0.35, 0.35),
			base,
			C.red,
			Enum.Material.Neon
		)
		beam.CanCollide = false
		light(post, C.red, 1.5, 13)
		maze.barriers[key] = beam
	end

	local keyTower = part(
		model,
		"PythonMazeKeyTower",
		Vector3.new(9, 12, 9),
		gridOrigin + Vector3.new(Rules.Chip.X * step, 6, Rules.Chip.Y * step),
		Color3.fromRGB(76, 65, 42),
		Enum.Material.Metal
	)
	label(keyTower, "CHIP LOCK\nSENSOR REQUIRED", Enum.NormalId.Front, 20)
	maze.keyTower = keyTower
	maze.keyLight = light(keyTower, C.red, 1.2, 14)
	local chipCargoAnchor = part(
		model,
		"PythonMazeChipCargoAnchor",
		Vector3.new(4.5, 3.5, 4.5),
		gridOrigin + Vector3.new(Rules.Chip.X * step, 2.7, Rules.Chip.Y * step),
		C.yellow,
		Enum.Material.SmoothPlastic
	)
	chipCargoAnchor.CanCollide = false
	chipCargoAnchor.CanTouch = false

	local serverTower = part(
		model,
		"PythonMazeServerTower",
		Vector3.new(11, 14, 11),
		gridOrigin + Vector3.new(Rules.Server.X * step, 7, Rules.Server.Y * step),
		Color3.fromRGB(42, 64, 78),
		Enum.Material.Metal
	)
	label(serverTower, "SERWER\n(4,4)", Enum.NormalId.Front, 22)
	maze.serverTower = serverTower
	maze.serverLight = light(serverTower, C.blue, 0.8, 16)

	local gate = part(
		model,
		"PythonMazeExitGate",
		Vector3.new(30, 17, 2),
		origin + Vector3.new(0, 8.5, 63),
		C.steel,
		Enum.Material.Metal
	)
	label(gate, "LABIRYNT ZABLOKOWANY\nDOSTARCZ CHIP", Enum.NormalId.Back, 24)
	maze.gate = gate
	maze.gateOpen = gate.Position + Vector3.new(0, 19, 0)

	attachRobotVisual(maze, model, robot)
	attachChipCargo(maze, model, chipCargoAnchor)

	maze.lamps = {}
	for i = 1, 6 do
		local lamp = part(
			model,
			"PythonMazeLamp_" .. i,
			Vector3.new(7, 0.6, 2.5),
			origin + Vector3.new(-30 + (i - 1) * 12, 18, 52),
			Color3.fromRGB(68, 74, 82),
			Enum.Material.Metal
		)
		maze.lamps[i] = lamp
	end

	PythonRobotMaze.Reset(maze)
	return maze
end
function PythonRobotMaze.Reset(maze)
	if not maze then
		return
	end
	maze.rulesState = Rules.NewState()
	for _, trace in pairs(maze.traces or {}) do
		if trace and trace.Parent then
			trace.Color = Color3.fromRGB(73, 82, 96)
			trace.Transparency = 0.7
		end
	end
	if maze.sensorPad then
		maze.sensorPad.Color = C.yellow
	end
	if maze.sensorLight then
		maze.sensorLight.Color = C.yellow
	end
	if maze.keyTower then
		maze.keyTower.Color = Color3.fromRGB(76, 65, 42)
	end
	if maze.keyLight then
		maze.keyLight.Color = C.red
	end
	maze.carryingChip = false
	maze.chipDelivered = false
	if maze.chipCargoVisual and maze.chipCargoHome then
		maze.chipCargoVisual:PivotTo(maze.chipCargoHome)
	end
	if maze.statusPart then
		maze.statusPart.Color = C.dark
		maze.statusPart.Material = Enum.Material.Metal
	end
	if maze.statusText then
		maze.statusText.Text = "LASERY AKTYWNE\nSENSOR: OFF"
	end
	if maze.serverTower then
		maze.serverTower.Color = Color3.fromRGB(42, 64, 78)
		maze.serverTower.Material = Enum.Material.Metal
	end
	if maze.serverLight then
		maze.serverLight.Color = C.blue
		maze.serverLight.Brightness = 0.8
	end
	if maze.gate then
		maze.gate.Position = maze.gateOpen - Vector3.new(0, 19, 0)
		maze.gate.Color = C.steel
		maze.gate.Material = Enum.Material.Metal
	end
	for _, lamp in ipairs(maze.lamps or {}) do
		lamp.Color = Color3.fromRGB(68, 74, 82)
		lamp.Material = Enum.Material.Metal
	end
end

function PythonRobotMaze.CanEnter(maze, x, y)
	local ok, reason = Rules.CanEnter(x, y)
	if not ok and maze and maze.statusText then
		maze.statusPart.Color = C.red
		maze.statusText.Text = string.format("DEBUG RUCHU\n(%d,%d): %s", x, y, reason)
	end
	return ok, reason
end

function PythonRobotMaze.Step(maze, x, y)
	if not maze then
		return
	end
	local _, kind = Rules.MarkStep(maze.rulesState, x, y)
	local trace = maze.traces[Rules.Key(x, y)]
	if trace then
		trace.Color = C.cyan
		trace.Transparency = 0
	end
	if kind == "sensor" then
		maze.sensorPad.Color = C.green
		maze.sensorLight.Color = C.green
		maze.keyTower.Color = C.yellow
		maze.keyLight.Color = C.green
		maze.statusPart.Color = C.green
		maze.statusText.Text = "SENSOR: ON\nCHIP ODBLOKOWANY"
	else
		maze.statusPart.Color = C.blue
		maze.statusText.Text = string.format("BOT (%d,%d)\nLASERY OMIJANE", x, y)
	end
end

function PythonRobotMaze.Command(maze, text)
	if maze and maze.statusText then
		maze.statusText.Text = text
	end
end

function PythonRobotMaze.CanPickup(maze, x, y)
	if not maze then
		return true
	end
	return Rules.CanPickup(maze.rulesState, x, y)
end

function PythonRobotMaze.CanDrop(maze, x, y)
	if not maze then
		return true
	end
	return Rules.CanDrop(maze.rulesState, x, y)
end
function PythonRobotMaze.Pickup(maze)
	if not maze then
		return
	end
	maze.keyTower.Color = C.green
	maze.keyTower.Material = Enum.Material.Neon
	maze.keyLight.Color = C.green
	maze.statusPart.Color = C.green
	maze.statusText.Text = "pickup()\nCHIP PRZEJĘTY • OMIŃ LASERY"
	maze.carryingChip = true
	maze.chipDelivered = false
end

function PythonRobotMaze.Fail(maze, text)
	if not maze then
		return
	end
	maze.statusPart.Color = C.red
	maze.statusPart.Material = Enum.Material.Neon
	maze.statusText.Text = "DEBUG PYTHON\n" .. tostring(text)
end

function PythonRobotMaze.Complete(maze)
	if not maze then
		return
	end
	Rules.Complete(maze.rulesState)
	maze.statusPart.Color = C.green
	maze.statusPart.Material = Enum.Material.Neon
	maze.statusText.Text = "drop() • SERWER\nLABIRYNT ROZBROJONY"
	maze.carryingChip = false
	maze.chipDelivered = true
	maze.serverTower.Color = C.green
	maze.serverTower.Material = Enum.Material.Neon
	maze.serverLight.Color = C.green
	maze.serverLight.Brightness = 3
	if maze.gate then
		maze.gate.Color = C.green
		maze.gate.Material = Enum.Material.Neon
		TweenService:Create(
			maze.gate,
			TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = maze.gateOpen }
		):Play()
	end
	for i, lamp in ipairs(maze.lamps or {}) do
		task.delay((i - 1) * 0.1, function()
			lamp.Color = C.cyan
			lamp.Material = Enum.Material.Neon
			light(lamp, C.cyan, 1.3, 14)
		end)
	end
end

return PythonRobotMaze