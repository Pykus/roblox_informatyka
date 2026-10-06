local PythonPowerPlant = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("PythonPowerPlantRules"))
local SemanticAssets = require(script.Parent:WaitForChild("SemanticAssetLibrary"))

local C = {
	dark = Color3.fromRGB(24, 31, 38),
	steel = Color3.fromRGB(76, 88, 98),
	cyan = Color3.fromRGB(51, 211, 220),
	blue = Color3.fromRGB(61, 132, 224),
	green = Color3.fromRGB(72, 211, 119),
	yellow = Color3.fromRGB(246, 202, 67),
	orange = Color3.fromRGB(238, 137, 52),
	red = Color3.fromRGB(232, 73, 72),
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
	txt.TextColor3 = Color3.fromRGB(241, 245, 248)
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.Code
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 16
	constraint.MaxTextSize = maxText or 28
	constraint.Parent = txt
	return txt
end

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.5
	l.Range = range or 16
	l.Parent = target
	return l
end

local function tween(target, props, seconds)
	local t = TweenService:Create(
		target,
		TweenInfo.new(seconds or 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		props
	)
	t:Play()
	return t
end

local function attachRobotVisual(plant, model, robot)
	if not robot then
		return
	end
	robot:SetAttribute("SemanticDecorated", true)
	local visual, reason = SemanticAssets.Place("robot", model, robot.CFrame, robot.Size, "Semantic_PythonPowerRobot")
	if not visual then
		robot:SetAttribute("SemanticAssetFallback", true)
		warn("[PYTHON-POWER] robot semantic fallback: " .. tostring(reason))
		return
	end
	robot:SetAttribute("SemanticAssetKey", "robot")
	robot:SetAttribute("SemanticAssetId", visual:GetAttribute("SemanticAssetId"))
	robot:SetAttribute("SemanticAssetFallback", false)
	plant.robotVisual = visual
	plant.robotVisualOffset = robot.CFrame:ToObjectSpace(visual:GetPivot())
	robot.Transparency = 1
	plant.robotFollow = RunService.Heartbeat:Connect(function()
		if not robot.Parent or not visual.Parent then
			if plant.robotFollow then
				plant.robotFollow:Disconnect()
				plant.robotFollow = nil
			end
			return
		end
		visual:PivotTo(robot.CFrame * plant.robotVisualOffset)
	end)
end

function PythonPowerPlant.Build(model, origin, gridOrigin, gridSize, step, robot)
	local plant = {
		rulesState = Rules.NewState(),
		traces = {},
		pads = {},
		gridOrigin = gridOrigin,
		step = step,
	}

	local floor = part(
		model,
		"PythonPowerPlantFloor",
		Vector3.new(82, 1, 106),
		origin + Vector3.new(0, 0.1, 8),
		Color3.fromRGB(49, 57, 63),
		Enum.Material.DiamondPlate
	)
	floor.CanCollide = true

	local gantry = part(
		model,
		"PythonPowerPlantGantry",
		Vector3.new(62, 8, 2),
		origin + Vector3.new(0, 22, -43),
		C.orange,
		Enum.Material.Metal
	)
	plant.headerText =
		label(gantry, "PYTHON POWER PLANT\nPOMPA → WENTYLATOR → MOST → RDZEŃ", Enum.NormalId.Front, 28)
	light(gantry, C.orange, 1.8, 20)

	local status = part(
		model,
		"PythonPowerPlantStatus",
		Vector3.new(38, 10, 2),
		origin + Vector3.new(20, 10, -34),
		C.dark,
		Enum.Material.Metal
	)
	plant.statusPart = status
	plant.statusText = label(status, "0/4 SYSTEMÓW ONLINE\nCZEKA NA PROGRAM", Enum.NormalId.Front, 25)
	local statusMonitor = part(
		model,
		"PythonPowerStatusMonitor",
		Vector3.new(9, 7, 3),
		origin + Vector3.new(33, 5, -33),
		C.steel,
		Enum.Material.Metal
	)
	statusMonitor.CanCollide = false
	label(statusMonitor, "LIVE\nSTATUS", Enum.NormalId.Front, 18)
	plant.statusMonitor = statusMonitor

	local controlConsole = part(
		model,
		"PythonPowerControlConsole",
		Vector3.new(12, 7, 8),
		origin + Vector3.new(-20, 4, -34),
		C.steel,
		Enum.Material.Metal
	)
	controlConsole.CanCollide = false
	label(controlConsole, "POWER CONTROL\nRUN / RESET", Enum.NormalId.Front, 20)
	plant.controlConsole = controlConsole

	local rack =
		part(model, "PythonRack", Vector3.new(9, 12, 8), origin + Vector3.new(-6, 6, -34), C.dark, Enum.Material.Metal)
	rack.CanCollide = false
	label(rack, "AUTOMATYKA\n4 SYSTEMY", Enum.NormalId.Front, 20)
	plant.automationRack = rack

	local padColor = {
		PUMP = C.blue,
		FAN = C.cyan,
		BRIDGE = C.yellow,
		CORE = C.green,
	}
	local padLabel = {
		PUMP = "POMPA",
		FAN = "WENTYLATOR",
		BRIDGE = "MOST",
		CORE = "RDZEŃ",
	}
	plant.systemConsoles = {}
	for id, pos in pairs(Rules.Pads) do
		local pad = part(
			model,
			"PythonPowerPad_" .. id,
			Vector3.new(7, 0.7, 7),
			gridOrigin + Vector3.new(pos.X * step, 0.9, pos.Y * step),
			padColor[id],
			Enum.Material.Neon
		)
		pad.CanCollide = false
		pad.Transparency = 0.18
		label(pad, padLabel[id], Enum.NormalId.Top, 19)
		plant.pads[id] = pad

		local console = part(
			model,
			"PythonPowerSystemConsole_" .. id,
			Vector3.new(5.5, 4.5, 3),
			pad.Position + Vector3.new(4.8, 3, -4.8),
			C.dark,
			Enum.Material.Metal
		)
		console.CanCollide = false
		console.CanTouch = false
		label(console, padLabel[id] .. "\nTARGET", Enum.NormalId.Front, 17)
		plant.systemConsoles[id] = console
	end

	for x = 0, gridSize - 1 do
		for y = 0, gridSize - 1 do
			local trace = part(
				model,
				string.format("PythonPowerTrace_%d_%d", x, y),
				Vector3.new(2.3, 0.15, 2.3),
				gridOrigin + Vector3.new(x * step, 1.02, y * step),
				Color3.fromRGB(72, 84, 91),
				Enum.Material.Neon
			)
			trace.Transparency = 0.72
			trace.CanCollide = false
			plant.traces[string.format("%d:%d", x, y)] = trace
		end
	end

	local pump = part(
		model,
		"PythonPowerPump",
		Vector3.new(13, 12, 13),
		origin + Vector3.new(-30, 6, 34),
		Color3.fromRGB(58, 70, 85),
		Enum.Material.Metal
	)
	label(pump, "POMPA\nOFF", Enum.NormalId.Front, 23)
	plant.pump = pump
	plant.pumpLight = light(pump, C.red, 0.7, 14)

	local water = part(
		model,
		"PythonPowerWater",
		Vector3.new(5, 1, 24),
		origin + Vector3.new(-30, 1.3, 49),
		Color3.fromRGB(48, 119, 188),
		Enum.Material.Glass
	)
	water.Transparency = 0.6
	water.CanCollide = false
	plant.water = water
	plant.waterBase = water.Size
	plant.waterBasePos = water.Position

	local fanHub = part(
		model,
		"PythonPowerFanHub",
		Vector3.new(8, 8, 4),
		origin + Vector3.new(-9, 8, 49),
		Color3.fromRGB(61, 72, 80),
		Enum.Material.Metal
	)
	label(fanHub, "FAN\nOFF", Enum.NormalId.Front, 22)
	plant.fanHub = fanHub
	plant.fanLight = light(fanHub, C.red, 0.7, 14)
	plant.fanBlades = {}
	for i = 1, 4 do
		local blade = part(
			model,
			"PythonPowerFanBlade_" .. i,
			Vector3.new(i % 2 == 0 and 2 or 11, i % 2 == 0 and 11 or 2, 1),
			fanHub.Position + Vector3.new(0, 0, -2.6),
			C.steel,
			Enum.Material.Metal
		)
		blade.CanCollide = false
		plant.fanBlades[i] = blade
	end
	local bridgeClosed = origin + Vector3.new(15, -5, 42)
	local bridgeOpen = origin + Vector3.new(15, 1, 42)
	local bridge =
		part(model, "PythonPowerBridge", Vector3.new(18, 1, 12), bridgeClosed, C.yellow, Enum.Material.DiamondPlate)
	bridge.CanCollide = false
	plant.bridge = bridge
	plant.bridgeClosed = bridgeClosed
	plant.bridgeOpen = bridgeOpen

	local core = part(
		model,
		"PythonPowerCore",
		Vector3.new(15, 16, 15),
		origin + Vector3.new(31, 8, 52),
		Color3.fromRGB(54, 61, 67),
		Enum.Material.Metal
	)
	plant.core = core
	plant.coreText = label(core, "RDZEŃ\nOFFLINE", Enum.NormalId.Front, 24)
	plant.coreLight = light(core, C.red, 0.8, 18)
	local coreRack = part(
		model,
		"PythonPowerCoreRack",
		Vector3.new(8, 12, 6),
		origin + Vector3.new(20, 6, 54),
		C.dark,
		Enum.Material.Metal
	)
	coreRack.CanCollide = false
	label(coreRack, "CORE\nCONTROL", Enum.NormalId.Front, 18)
	plant.coreRack = coreRack

	local turbine = part(
		model,
		"PythonPowerTurbine",
		Vector3.new(10, 18, 10),
		origin + Vector3.new(7, 9, 57),
		Color3.fromRGB(64, 72, 81),
		Enum.Material.Metal
	)
	label(turbine, "TURBINA", Enum.NormalId.Front, 22)
	plant.turbine = turbine
	local turbineConsole = part(
		model,
		"PythonPowerTurbineConsole",
		Vector3.new(7, 5, 4),
		origin + Vector3.new(7, 4, 46),
		C.steel,
		Enum.Material.Metal
	)
	turbineConsole.CanCollide = false
	label(turbineConsole, "TURBINE\nCTRL", Enum.NormalId.Front, 18)
	plant.turbineConsole = turbineConsole

	local gate = part(
		model,
		"PythonPowerExitGate",
		Vector3.new(34, 18, 2),
		origin + Vector3.new(0, 9, 65),
		C.steel,
		Enum.Material.Metal
	)
	label(gate, "ELEKTROWNIA OFFLINE\nPROGRAMUJ SEKWENCJĘ", Enum.NormalId.Back, 24)
	plant.gate = gate
	plant.gateClosed = gate.Position
	plant.gateOpen = gate.Position + Vector3.new(0, 20, 0)

	attachRobotVisual(plant, model, robot)

	plant.lamps = {}
	for i = 1, 6 do
		local lamp = part(
			model,
			"PythonPowerLamp_" .. i,
			Vector3.new(7, 0.6, 2.5),
			origin + Vector3.new(-30 + (i - 1) * 12, 18, 29),
			Color3.fromRGB(68, 74, 80),
			Enum.Material.Metal
		)
		plant.lamps[i] = lamp
	end

	PythonPowerPlant.Reset(plant)
	return plant
end

function PythonPowerPlant.Reset(plant)
	if not plant then
		return
	end
	plant.rulesState = Rules.NewState()
	for _, trace in pairs(plant.traces or {}) do
		trace.Color = Color3.fromRGB(72, 84, 91)
		trace.Transparency = 0.72
	end
	for id, pad in pairs(plant.pads or {}) do
		pad.Transparency = 0.18
		local console = plant.systemConsoles and plant.systemConsoles[id]
		if console then
			console.Color = C.dark
			console.Material = Enum.Material.Metal
		end
	end
	if plant.statusPart then
		plant.statusPart.Color = C.dark
		plant.statusPart.Material = Enum.Material.Metal
	end
	if plant.statusText then
		plant.statusText.Text = "0/4 SYSTEMÓW ONLINE\nCZEKA NA PROGRAM"
	end
	if plant.pump then
		plant.pump.Color = Color3.fromRGB(58, 70, 85)
		plant.pump.Material = Enum.Material.Metal
	end
	if plant.pumpLight then
		plant.pumpLight.Color = C.red
	end
	if plant.water then
		plant.water.Size = plant.waterBase
		plant.water.Position = plant.waterBasePos
		plant.water.Transparency = 0.6
	end
	if plant.fanHub then
		plant.fanHub.Color = Color3.fromRGB(61, 72, 80)
		plant.fanHub.Material = Enum.Material.Metal
	end
	if plant.fanLight then
		plant.fanLight.Color = C.red
	end
	if plant.bridge then
		plant.bridge.Position = plant.bridgeClosed
		plant.bridge.CanCollide = false
	end
	if plant.core then
		plant.core.Color = Color3.fromRGB(54, 61, 67)
		plant.core.Material = Enum.Material.Metal
	end
	if plant.coreText then
		plant.coreText.Text = "RDZEŃ\nOFFLINE"
	end
	if plant.coreLight then
		plant.coreLight.Color = C.red
		plant.coreLight.Brightness = 0.8
	end
	if plant.gate then
		plant.gate.Position = plant.gateClosed
		plant.gate.Color = C.steel
		plant.gate.Material = Enum.Material.Metal
	end
	for _, lamp in ipairs(plant.lamps or {}) do
		lamp.Color = Color3.fromRGB(68, 74, 80)
		lamp.Material = Enum.Material.Metal
	end
end

local function activateSystemConsole(plant, id, color)
	local console = plant.systemConsoles and plant.systemConsoles[id]
	if console then
		console.Color = color
		console.Material = Enum.Material.Neon
	end
end

local function activatePump(plant)
	activateSystemConsole(plant, "PUMP", C.blue)
	plant.pump.Color = C.blue
	plant.pump.Material = Enum.Material.Neon
	plant.pumpLight.Color = C.blue
	tween(plant.water, {
		Size = Vector3.new(5, 5, 24),
		Transparency = 0.25,
		Position = plant.water.Position + Vector3.new(0, 2, 0),
	}, 0.7)
end

local function activateFan(plant)
	activateSystemConsole(plant, "FAN", C.cyan)
	plant.fanHub.Color = C.cyan
	plant.fanHub.Material = Enum.Material.Neon
	plant.fanLight.Color = C.cyan
	for i, blade in ipairs(plant.fanBlades) do
		task.delay((i - 1) * 0.08, function()
			blade.Color = C.cyan
			blade.Material = Enum.Material.Neon
		end)
	end
end

local function activateBridge(plant)
	activateSystemConsole(plant, "BRIDGE", C.yellow)
	plant.bridge.CanCollide = true
	tween(plant.bridge, { Position = plant.bridgeOpen }, 0.7)
end
function PythonPowerPlant.Step(plant, x, y)
	if not plant then
		return true, "track", false
	end
	local ok, kind, completed = Rules.Step(plant.rulesState, x, y)
	if not ok then
		plant.statusPart.Color = C.red
		plant.statusText.Text = "DEBUG SEKWENCJI\n" .. tostring(kind)
		return false, kind, false
	end

	local trace = plant.traces[string.format("%d:%d", x, y)]
	if trace then
		trace.Color = C.cyan
		trace.Transparency = 0
	end

	if kind == "PUMP" then
		activatePump(plant)
	elseif kind == "FAN" then
		activateFan(plant)
	elseif kind == "BRIDGE" then
		activateBridge(plant)
	elseif kind == "CORE" then
		PythonPowerPlant.Complete(plant)
	end

	local count = Rules.ActivatedCount(plant.rulesState)
	plant.statusPart.Color = count > 0 and C.blue or C.dark
	if not completed then
		plant.statusText.Text = string.format("%d/4 SYSTEMÓW ONLINE\nOSTATNI: %s", count, tostring(kind))
	end
	return true, kind, completed
end

function PythonPowerPlant.Command(plant, text)
	if plant and plant.statusText then
		plant.statusText.Text = text
	end
end

function PythonPowerPlant.Fail(plant, text)
	if not plant then
		return
	end
	plant.statusPart.Color = C.red
	plant.statusPart.Material = Enum.Material.Neon
	plant.statusText.Text = "DEBUG PYTHON\n" .. tostring(text)
end

function PythonPowerPlant.Complete(plant)
	if not plant then
		return
	end
	if not Rules.Complete(plant.rulesState) then
		return
	end
	plant.statusPart.Color = C.green
	plant.statusPart.Material = Enum.Material.Neon
	plant.statusText.Text = "4/4 SYSTEMÓW ONLINE\nPROGRAM PORUSZYŁ ŚWIAT"
	activateSystemConsole(plant, "CORE", C.green)
	plant.core.Color = C.green
	plant.core.Material = Enum.Material.Neon
	plant.coreText.Text = "RDZEŃ\nONLINE"
	plant.coreLight.Color = C.green
	plant.coreLight.Brightness = 3
	plant.turbine.Color = C.green
	plant.turbine.Material = Enum.Material.Neon
	plant.gate.Color = C.green
	plant.gate.Material = Enum.Material.Neon
	tween(plant.gate, { Position = plant.gateOpen }, 1.1)
	for i, lamp in ipairs(plant.lamps) do
		task.delay((i - 1) * 0.1, function()
			lamp.Color = C.cyan
			lamp.Material = Enum.Material.Neon
			light(lamp, C.cyan, 1.4, 14)
		end)
	end
end

return PythonPowerPlant