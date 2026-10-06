local LogicGateControl = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("LogicGateControlRules"))

local C = {
	floor = Color3.fromRGB(182, 191, 199),
	dark = Color3.fromRGB(24, 31, 43),
	panel = Color3.fromRGB(52, 66, 82),
	white = Color3.fromRGB(241, 245, 248),
	cyan = Color3.fromRGB(54, 198, 220),
	blue = Color3.fromRGB(62, 126, 211),
	green = Color3.fromRGB(66, 205, 118),
	red = Color3.fromRGB(225, 72, 76),
	yellow = Color3.fromRGB(242, 196, 62),
	orange = Color3.fromRGB(234, 137, 52),
	purple = Color3.fromRGB(150, 92, 205),
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

local function label(target, text, face, maxText, bg, fg)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 430)
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 0.04
	txt.BackgroundColor3 = bg or C.dark
	txt.TextColor3 = fg or C.white
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.TextStrokeTransparency = 0.55
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 18
	constraint.MaxTextSize = maxText or 30
	constraint.Parent = txt
	return txt
end

local function control(parent, name, size, pos, color, text)
	local p = part(parent, name, size, pos, color, Enum.Material.SmoothPlastic)
	p.CanCollide = false
	p.CanTouch = false
	label(p, text, Enum.NormalId.Front, 20)
	return p
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 14
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
	l.Shadows = false
	l.Parent = target
	return l
end

local function tween(target, goal, seconds)
	local t = TweenService:Create(
		target,
		TweenInfo.new(seconds or 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	t:Play()
	return t
end

local function hud(remote, player, title, objective, score)
	remote:FireClient(player, {
		kind = "hud",
		title = title,
		objective = objective,
		score = score or 0,
	})
end

local function message(remote, player, text, good)
	remote:FireClient(player, { kind = "message", text = text, good = good })
end

function LogicGateControl.Run(model, origin, player, lesson, mission, remote, state, accent)
	local title = mission.name or "Logika w kodzie"
	state.logicGate = Rules.NewState()
	state.logicBusy = false
	local entryReady = false

	local floor = part(
		model,
		"LogicGateFloor",
		Vector3.new(96, 1, 112),
		origin + Vector3.new(0, 0.2, 8),
		C.floor,
		Enum.Material.Concrete
	)
	floor.CanCollide = true

	local header = part(
		model,
		"LogicGateHeader",
		Vector3.new(70, 10, 2),
		origin + Vector3.new(0, 18, -38),
		C.blue,
		Enum.Material.Neon
	)
	label(header, "LOGIC GATE CONTROL\nAND • OR • NOT", Enum.NormalId.Front, 30)
	light(header, C.cyan, 1.7, 24)

	local instructionBoard = part(
		model,
		"LogicInstructionBoard",
		Vector3.new(28, 11, 1.4),
		origin + Vector3.new(23, 7.5, -39.5),
		C.panel,
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. Włącz POWER LEVER\n2. Ustaw wejścia tak, aby OUTPUT = TRUE\n3. Naciśnij TEST\n\nGOTOWE ODPOWIEDZI\nAND: A=TRUE, B=TRUE\nOR: A=TRUE, B=FALSE\nNOT: A=FALSE",
		Enum.NormalId.Front,
		20
	)

	local core = part(
		model,
		"LogicControlCore",
		Vector3.new(18, 10, 18),
		origin + Vector3.new(0, 6, 54),
		C.dark,
		Enum.Material.Metal
	)
	local coreLamp = part(
		model,
		"LogicControlCoreLamp",
		Vector3.new(8, 8, 8),
		origin + Vector3.new(0, 8, 54),
		C.red,
		Enum.Material.Neon
	)
	coreLamp.Shape = Enum.PartType.Ball
	coreLamp.CanCollide = false
	local coreLight = light(coreLamp, C.red, 0.8, 18)
	local coreText = label(core, "CONTROL CORE\n0/3", Enum.NormalId.Front, 24)
	local coreRack = part(
		model,
		"LogicCoreRack",
		Vector3.new(8, 10, 6),
		origin + Vector3.new(-14, 6, 54),
		C.panel,
		Enum.Material.Metal
	)
	coreRack.CanCollide = false
	label(coreRack, "CONTROL\nBACKPLANE", Enum.NormalId.Front, 20)

	local finalGate = part(
		model,
		"LogicFinalGate",
		Vector3.new(30, 16, 3),
		origin + Vector3.new(0, 8, 68),
		C.dark,
		Enum.Material.Metal
	)
	local finalGateOpen = finalGate.Position + Vector3.new(0, 17, 0)
	label(finalGate, "WYJŚCIE ZASILANE PRZEZ 3 BRAMKI", Enum.NormalId.Front, 22)

	local stations = {}
	local stationXs = { -30, 0, 30 }
	local gateColors = { C.cyan, C.orange, C.purple }

	for i, stage in ipairs(Rules.Stages) do
		local x = stationXs[i]
		local station = {}
		station.stage = stage

		station.base = part(
			model,
			"LogicStation_" .. stage.id,
			Vector3.new(25, 1, 34),
			origin + Vector3.new(x, 1, 8),
			Color3.fromRGB(77, 88, 99),
			Enum.Material.Metal
		)
		station.base.CanCollide = true

		station.board = part(
			model,
			"LogicBoard_" .. stage.id,
			Vector3.new(24, 13, 2),
			origin + Vector3.new(x, 10, -6),
			C.panel,
			Enum.Material.SmoothPlastic
		)
		station.boardText = label(station.board, "", Enum.NormalId.Front, 24)

		station.gate = part(
			model,
			"LogicGateHardware_" .. stage.id,
			Vector3.new(8, 8, 4),
			origin + Vector3.new(x, 7, 15),
			gateColors[i],
			Enum.Material.Metal
		)
		station.gate.CanCollide = false
		label(station.gate, stage.id, Enum.NormalId.Front, 25)

		station.output = part(
			model,
			"LogicOutput_" .. stage.id,
			Vector3.new(5, 5, 5),
			origin + Vector3.new(x, 7, 23),
			C.red,
			Enum.Material.Neon
		)
		station.output.Shape = Enum.PartType.Ball
		station.output.CanCollide = false
		station.outputLight = light(station.output, C.red, 1, 13)
		station.outputMonitor = part(
			model,
			"LogicOutputMonitor_" .. stage.id,
			Vector3.new(6, 5, 2),
			origin + Vector3.new(x + 8, 8, 22),
			C.panel,
			Enum.Material.Metal
		)
		station.outputMonitor.CanCollide = false
		label(station.outputMonitor, "OUTPUT\n" .. stage.id, Enum.NormalId.Front, 18)

		station.barrier = part(
			model,
			"LogicBarrier_" .. stage.id,
			Vector3.new(20, 12, 2),
			origin + Vector3.new(x, 6, 29),
			C.dark,
			Enum.Material.Metal
		)
		station.barrierClosed = station.barrier.Position
		station.barrierOpen = station.barrier.Position + Vector3.new(0, 13, 0)
		label(station.barrier, "LOCK " .. stage.id, Enum.NormalId.Front, 23)

		local function makeInput(inputId, offsetX)
			local body = part(
				model,
				"LogicSwitch_" .. stage.id .. "_" .. inputId,
				Vector3.new(7, 5, 7),
				origin + Vector3.new(x + offsetX, 3.5, 4),
				C.panel,
				Enum.Material.Metal
			)
			local lever = part(
				model,
				"LogicLever_" .. stage.id .. "_" .. inputId,
				Vector3.new(1.4, 7, 1.4),
				body.Position + Vector3.new(0, 4.5, 0),
				C.red,
				Enum.Material.Neon
			)
			lever.CanCollide = false
			local lamp = light(lever, C.red, 1, 10)
			label(body, "INPUT " .. inputId, Enum.NormalId.Front, 21)

			local cable = part(
				model,
				"LogicCable_" .. stage.id .. "_" .. inputId,
				Vector3.new(1, 1, 10),
				origin + Vector3.new(x + offsetX * 0.45, 4.5, 10),
				C.red,
				Enum.Material.Neon
			)
			cable.CanCollide = false
			return { body = body, lever = lever, lamp = lamp, cable = cable }
		end

		station.a = makeInput("A", -7)
		if stage.defaultB ~= nil then
			station.b = makeInput("B", 7)
		end

		station.testConsole = part(
			model,
			"LogicTest_" .. stage.id,
			Vector3.new(12, 5, 7),
			origin + Vector3.new(x, 3.5, -13),
			C.yellow,
			Enum.Material.Metal
		)
		label(station.testConsole, "TEST\n" .. stage.id, Enum.NormalId.Front, 22)
		station.testControl = control(
			model,
			"LogicTestControl_" .. stage.id,
			Vector3.new(5.5, 2.4, 5.5),
			origin + Vector3.new(x, 2.8, -7.5),
			C.dark,
			"TEST\n" .. stage.id
		)
		stations[i] = station
	end

	local passedCount = 0

	local function currentStation()
		return stations[state.logicGate.stage]
	end

	local function boolText(v)
		return v and "TRUE" or "FALSE"
	end

	local function updateStation(station)
		local isCurrent = currentStation() == station
		local stage = station.stage
		local logic = state.logicGate
		local a = stage.defaultA
		local b = stage.defaultB
		if isCurrent then
			a = logic.a
			b = logic.b
		end
		if state.logicGate.passed[stage.id] then
			if stage.id == "AND" then
				a, b = true, true
			elseif stage.id == "OR" then
				a, b = true, false
			else
				a, b = false, nil
			end
		end

		local output = Rules.Evaluate(stage.id, a, b)
		local outputColor = output and C.green or C.red
		station.output.Color = outputColor
		station.outputLight.Color = outputColor
		station.outputLight.Brightness = output and 2.2 or 0.8

		local function setInput(input, value)
			if not input then
				return
			end
			local color = value and C.green or C.red
			input.lever.Color = color
			input.lamp.Color = color
			input.cable.Color = color
			input.lamp.Brightness = value and 2 or 0.7
			local tilt = value and math.rad(-32) or math.rad(32)
			input.lever.CFrame = CFrame.new(input.lever.Position) * CFrame.Angles(tilt, 0, 0)
		end

		setInput(station.a, a)
		setInput(station.b, b)

		local bLine = stage.defaultB ~= nil and ("\nB = " .. boolText(b)) or ""
		station.boardText.Text =
			string.format("%s\nA = %s%s\n%s = %s", stage.title, boolText(a), bLine, stage.expression, boolText(output))
	end

	local function updateAll()
		for _, station in ipairs(stations) do
			updateStation(station)
		end
	end

	local function updateHud()
		local stage = Rules.CurrentStage(state.logicGate)
		local objective
		if not entryReady then
			objective = "ETAP START • Włącz POWER LEVER przy wejściu, aby zasilić bramki logiczne."
		elseif stage then
			objective = string.format(
				"ETAP %d/3 • ustaw wejścia bramki %s tak, aby wynik był TRUE, potem użyj TEST.",
				state.logicGate.stage,
				stage.id
			)
		else
			objective = "AND, OR i NOT działają • uruchom CONTROL CORE."
		end
		state.objective = objective
		hud(remote, player, title, objective, state.score)
	end

	local function enableOnlyCurrent()
		for index, station in ipairs(stations) do
			local enabled = entryReady and index == state.logicGate.stage and not state.done
			station.promptA.Enabled = enabled
			if station.promptB then
				station.promptB.Enabled = enabled
			end
			station.testPrompt.Enabled = enabled
			if state.logicGate.passed[station.stage.id] then
				station.testControl.Color = C.green
				station.testControl.Material = Enum.Material.Neon
			else
				station.testControl.Color = enabled and C.yellow or C.dark
				station.testControl.Material = enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
			end
		end
	end

	for _, station in ipairs(stations) do
		station.promptA = prompt(station.a.body, "PRZEŁĄCZ A", station.stage.id .. " input A", function(who)
			if who ~= player or state.done or currentStation() ~= station or state.logicBusy then
				return
			end
			Rules.Toggle(state.logicGate, "A")
			updateStation(station)
			updateHud()
		end)

		if station.b then
			station.promptB = prompt(station.b.body, "PRZEŁĄCZ B", station.stage.id .. " input B", function(who)
				if who ~= player or state.done or currentStation() ~= station or state.logicBusy then
					return
				end
				Rules.Toggle(state.logicGate, "B")
				updateStation(station)
				updateHud()
			end)
		end

		station.testPrompt = prompt(station.testControl, "TEST", station.stage.id .. " gate", function(who)
			if who ~= player or state.done or currentStation() ~= station or state.logicBusy then
				return
			end
			state.logicBusy = true
			local ok, result = Rules.Test(state.logicGate)
			if not ok then
				state.score = math.max(0, state.score - 10)
				station.board.Color = C.red
				station.testControl.Color = C.red
				station.testControl.Material = Enum.Material.Neon
				message(remote, player, result.message, false)
				task.delay(0.45, function()
					if station.board.Parent then
						station.board.Color = C.panel
						station.testControl.Color = C.yellow
						station.testControl.Material = Enum.Material.Neon
					end
				end)
				updateAll()
				updateHud()
				state.logicBusy = false
				return
			end

			passedCount += 1
			coreText.Text = string.format("CONTROL CORE\n%d/3", passedCount)
			state.score += 85
			station.board.Color = C.green
			station.testControl.Color = C.green
			station.testControl.Material = Enum.Material.Neon
			station.output.Color = C.green
			station.outputLight.Color = C.green
			station.outputLight.Brightness = 2.6
			tween(station.barrier, { Position = station.barrierOpen }, 0.75)
			message(remote, player, station.stage.id .. " działa. Prąd płynie do następnej komory.", true)
			enableOnlyCurrent()
			updateAll()
			updateHud()
			state.logicBusy = false
		end)
	end

	local powerPedestal = part(
		model,
		"LogicPowerPedestal",
		Vector3.new(10, 4, 8),
		origin + Vector3.new(0, 2.5, -42),
		C.panel,
		Enum.Material.Metal
	)
	powerPedestal.CanCollide = false
	label(powerPedestal, "ZASILANIE\nOFFLINE", Enum.NormalId.Front, 20)

	local powerLever =
		part(model, "LogicPowerLever", Vector3.new(2, 7, 2), origin + Vector3.new(0, 7, -42), C.red, Enum.Material.Neon)
	powerLever.CanCollide = false
	powerLever.CanTouch = false
	local powerLight = light(powerLever, C.red, 1.2, 12)
	local powerPrompt
	powerPrompt = prompt(powerLever, "WŁĄCZ ZASILANIE", "Logic Gate Control", function(who)
		if who ~= player or entryReady or state.done then
			return
		end
		entryReady = true
		powerPrompt.Enabled = false
		powerLever.Color = C.green
		powerLight.Color = C.green
		powerLight.Brightness = 2.4
		powerLever.CFrame = CFrame.new(powerLever.Position) * CFrame.Angles(math.rad(-32), 0, 0)
		powerPedestal.Color = C.green
		powerPedestal.Material = Enum.Material.Neon
		for _, gui in ipairs(powerPedestal:GetChildren()) do
			if gui:IsA("SurfaceGui") then
				local textLabel = gui:FindFirstChildOfClass("TextLabel")
				if textLabel then
					textLabel.Text = "ZASILANIE\nONLINE ✓"
				end
			end
		end
		enableOnlyCurrent()
		updateAll()
		updateHud()
		message(remote, player, "Zasilanie aktywne. Ustaw AND, obserwuj przewody i użyj TEST.", true)
	end)

	local corePrompt
	corePrompt = prompt(core, "URUCHOM", "CONTROL CORE", function(who)
		if who ~= player or state.done or state.logicBusy then
			return
		end
		local ok, result = Rules.Complete(state.logicGate)
		if not ok then
			message(remote, player, result, false)
			return
		end

		state.done = true
		state.completed = true
		state.exitReady = true
		state.score += result.efficiency
		corePrompt.Enabled = false
		coreLamp.Color = C.green
		coreLight.Color = C.green
		coreLight.Brightness = 3
		core.Color = C.green
		header.Color = C.green
		tween(finalGate, { Position = finalGateOpen }, 1)
		for _, station in ipairs(stations) do
			station.output.Color = C.green
			station.outputLight.Color = C.green
			station.outputLight.Brightness = 2.4
		end
		state.objective = string.format(
			"Logic Gate Control ukończony • AND, OR i NOT zasilają system; błędy %d.",
			result.errors
		)
		remote:FireClient(player, {
			kind = "objective",
			text = state.objective,
			score = state.score,
		})
		message(
			remote,
			player,
			"System online. AND wymaga obu wejść, OR co najmniej jednego, a NOT odwraca wartość.",
			true
		)
		updateHud()
	end)
	corePrompt.Enabled = false

	local originalEnableOnlyCurrent = enableOnlyCurrent
	enableOnlyCurrent = function()
		originalEnableOnlyCurrent()
		corePrompt.Enabled = Rules.CanComplete(state.logicGate) and not state.done
	end

	updateAll()
	enableOnlyCurrent()
	updateHud()
	message(
		remote,
		player,
		"Najpierw włącz POWER LEVER przy wejściu. Potem ustaw AND i obserwuj przewody oraz lampę wyniku.",
		true
	)
end

return LogicGateControl