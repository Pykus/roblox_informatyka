local TweenService = game:GetService("TweenService")

local InternetConstruction = {}
local Rules = require(script.Parent:WaitForChild("InternetConstructionRules"))

local C = {
	asphalt = Color3.fromRGB(72, 76, 78),
	concrete = Color3.fromRGB(184, 184, 174),
	grass = Color3.fromRGB(97, 137, 82),
	dark = Color3.fromRGB(35, 43, 48),
	steel = Color3.fromRGB(91, 101, 108),
	orange = Color3.fromRGB(238, 137, 42),
	yellow = Color3.fromRGB(244, 196, 55),
	cyan = Color3.fromRGB(58, 195, 230),
	blue = Color3.fromRGB(55, 120, 210),
	green = Color3.fromRGB(58, 214, 116),
	red = Color3.fromRGB(225, 74, 67),
	white = Color3.fromRGB(242, 245, 247),
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

local function label(target, text, face, minSize, maxSize)
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
	txt.TextStrokeTransparency = 0.4
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize or 18
	constraint.MaxTextSize = maxSize or 32
	constraint.Parent = txt
	return txt
end

local function prompt(target, actionText, objectText, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p.HoldDuration = 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = target
	p.Triggered:Connect(callback)
	return p
end

local function tween(instance, goal, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	tw:Play()
	return tw
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

local function flash(ctx, text, good)
	ctx.remote:FireClient(ctx.player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function cableBetween(parent, name, a, b, color)
	local midpoint = (a + b) * 0.5
	local distance = (b - a).Magnitude
	local cable = part(parent, name, Vector3.new(0.75, 0.75, distance), midpoint, color, Enum.Material.Neon)
	cable.CFrame = CFrame.lookAt(midpoint, b)
	cable.CanCollide = false
	cable.CastShadow = false
	return cable
end

local function deviceSign(model, name, text, position)
	local sign = part(model, name, Vector3.new(13, 5, 1), position, C.dark, Enum.Material.Metal)
	label(sign, text, Enum.NormalId.Front, 18)
	return sign
end

local function led(model, name, position)
	local light = part(model, name, Vector3.new(1.2, 1.2, 0.7), position, C.red, Enum.Material.Neon)
	light.CanCollide = false
	return light
end

local function makeRouterShape(model, anchorName, position, accent)
	local body = part(model, anchorName, Vector3.new(8, 3.2, 6), position, C.dark, Enum.Material.Metal)
	body.CanCollide = false
	for index, x in ipairs({ -2.5, 0, 2.5 }) do
		local antenna = part(
			model,
			anchorName .. "_Antenna_" .. index,
			Vector3.new(0.45, 6, 0.45),
			position + Vector3.new(x, 4.2, 2),
			accent,
			Enum.Material.Metal
		)
		antenna.CanCollide = false
	end
	for index = 1, 4 do
		led(model, anchorName .. "_LED_" .. index, position + Vector3.new(-2.4 + index * 1.2, 0.2, -3.2))
	end
	return body
end

local function makeSwitchShape(model, position)
	local body = part(model, "Switch", Vector3.new(12, 2.6, 6), position, C.steel, Enum.Material.Metal)
	body.CanCollide = false
	for index = 1, 8 do
		local port = part(
			model,
			"InternetSwitchPort_" .. index,
			Vector3.new(0.9, 0.65, 0.5),
			position + Vector3.new(-4.8 + index * 1.1, -0.2, -3.15),
			index <= 3 and C.yellow or C.dark,
			Enum.Material.Neon
		)
		port.CanCollide = false
	end
	return body
end

local function makeOnt(model, position)
	local body = part(model, "InternetONT", Vector3.new(7, 5, 4), position, C.white, Enum.Material.SmoothPlastic)
	local face =
		part(model, "InternetONTFace", Vector3.new(5.5, 2.2, 0.35), position + Vector3.new(0, 0, -2.15), C.dark)
	label(face, "ONT", Enum.NormalId.Front, 18)
	for index, color in ipairs({ C.red, C.red, C.red }) do
		led(model, "InternetONT_LED_" .. index, position + Vector3.new(-1.8 + index * 1.8, -1.5, -2.25)).Color = color
	end
	return body
end

local function makeIspMast(model, position)
	local mast = part(
		model,
		"InternetISPMast",
		Vector3.new(18, 1.8, 1.8),
		position + Vector3.new(0, 9, 0),
		C.steel,
		Enum.Material.Metal
	)
	mast.Shape = Enum.PartType.Cylinder
	mast.CFrame = CFrame.new(mast.Position) * CFrame.Angles(0, 0, math.rad(90))
	local beacon = part(
		model,
		"InternetISPBeacon",
		Vector3.new(2.5, 2.5, 2.5),
		position + Vector3.new(0, 18, 0),
		C.red,
		Enum.Material.Neon
	)
	beacon.Shape = Enum.PartType.Ball
	beacon.CanCollide = false
	local box = part(
		model,
		"InternetISPBox",
		Vector3.new(7, 5, 5),
		position + Vector3.new(0, 3, 0),
		C.dark,
		Enum.Material.Metal
	)
	label(box, "ISP\nŚWIATŁOWÓD", Enum.NormalId.Front, 18)
	return beacon
end

local function currentObjective(ctx)
	local job = Rules.CurrentJob(ctx.rules)
	if job then
		if job.stage == 1 then
			return string.format("ETAP 1/3 • %s → %s. Wybierz kabel i właściwy port.", job.source, job.target)
		end
		return string.format("ETAP 2/3 • %s → %s. Zbuduj LAN właściwym kablem i portem.", job.source, job.target)
	end
	local wired = ctx.rules.tests.WIRED and "PC ✓" or "PC …"
	local wifi = ctx.rules.tests.WIFI and "WI-FI ✓" or "WI-FI …"
	return "ETAP 3/3 • Test pakietów: " .. wired .. "  |  " .. wifi
end

local function refresh(ctx)
	local job = Rules.CurrentJob(ctx.rules)
	local selected = ctx.rules.selectedCable or "BRAK"
	ctx.cableStatus.Text = "KABEL: " .. selected

	for _, p in ipairs(ctx.cablePrompts) do
		p.Enabled = ctx.entryReady and job ~= nil and not ctx.state.done
	end
	for index, pair in ipairs(ctx.portPrompts) do
		local active = ctx.entryReady and job ~= nil and index == ctx.rules.job and not ctx.state.done
		pair.correct.Enabled = active
		pair.wrong.Enabled = active
	end

	if job then
		ctx.jobBoard.Text = string.format(
			"ZLECENIE %d/5\n%s → %s\nKABEL: %s • PORT: ?",
			ctx.rules.job,
			job.source,
			job.target,
			selected
		)
	else
		ctx.jobBoard.Text = string.format(
			"OKABLOWANIE 5/5\nTEST TRASY\nPC: %s • WI-FI: %s",
			ctx.rules.tests.WIRED and "OK" or "...",
			ctx.rules.tests.WIFI and "OK" or "..."
		)
	end

	local stage = Rules.Stage(ctx.rules)
	for index, lamp in ipairs(ctx.stageLamps) do
		if ctx.state.done or index < stage then
			lamp.Color = C.green
			lamp.Material = Enum.Material.Neon
		elseif index == stage then
			lamp.Color = C.yellow
			lamp.Material = Enum.Material.Neon
		else
			lamp.Color = C.steel
			lamp.Material = Enum.Material.Metal
		end
	end

	ctx.wiredPrompt.Enabled = ctx.entryReady
		and Rules.CanTest(ctx.rules)
		and not ctx.rules.tests.WIRED
		and not ctx.state.done
	ctx.wifiPrompt.Enabled = ctx.entryReady
		and Rules.CanTest(ctx.rules)
		and not ctx.rules.tests.WIFI
		and not ctx.state.done
	if ctx.entryReady then
		hud(ctx, currentObjective(ctx))
	else
		hud(ctx, "ETAP START • Uruchom SITE CHECK przy wejściu, aby aktywować zlecenie kablowe.")
	end
end

local function animatePacket(ctx, route)
	local path = route == "WIRED"
			and { ctx.positions.PC, ctx.positions.SWITCH, ctx.positions.ROUTER, ctx.positions.ONT, ctx.positions.ISP }
		or {
			ctx.positions.TABLET,
			ctx.positions.AP,
			ctx.positions.SWITCH,
			ctx.positions.ROUTER,
			ctx.positions.ONT,
			ctx.positions.ISP,
		}
	local packet = part(
		ctx.model,
		"InternetPacket_" .. route,
		Vector3.new(2, 2, 2),
		path[1] + Vector3.new(0, 5, 0),
		route == "WIRED" and C.yellow or C.cyan,
		Enum.Material.Neon
	)
	packet.Shape = Enum.PartType.Ball
	packet.CanCollide = false
	packet.CastShadow = false

	for index = 2, #path do
		tween(packet, { Position = path[index] + Vector3.new(0, 5, 0) }, 0.14).Completed:Wait()
	end
	packet:Destroy()
end

local function finish(ctx)
	ctx.state.done = true
	ctx.state.score += 100
	ctx.ispBeacon.Color = C.green
	ctx.finalGate.Color = C.green
	ctx.finalGate.Material = Enum.Material.Neon
	ctx.finalText.Text = "INTERNET ONLINE\nPC + WI-FI MAJĄ TRASĘ"
	tween(ctx.finalGate, { Position = ctx.finalGate.Position + Vector3.new(0, 12, 0) }, 0.8)
	for _, p in ipairs(ctx.cablePrompts) do
		p.Enabled = false
	end
	ctx.wiredPrompt.Enabled = false
	ctx.wifiPrompt.Enabled = false
	flash(
		ctx,
		string.format("Sieć działa. Obie trasy przeszły test; efektywność %d%%.", Rules.Efficiency(ctx.rules)),
		true
	)
	hud(ctx, "ETAP 3/3 • Internet online. Przejdź do oznaczonego RDZENIA MISJI.")
end

function InternetConstruction.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		cablePrompts = {},
		portPrompts = {},
		stageLamps = {},
		positions = {},
		entryReady = false,
	}
	state.score = state.score or 0

	part(
		model,
		"InternetYardFloor",
		Vector3.new(90, 1, 92),
		origin + Vector3.new(0, -0.5, 4),
		C.concrete,
		Enum.Material.Concrete
	)
	part(
		model,
		"InternetStreet",
		Vector3.new(86, 0.3, 24),
		origin + Vector3.new(0, 0.1, -28),
		C.asphalt,
		Enum.Material.Asphalt
	)
	part(
		model,
		"InternetGrassLeft",
		Vector3.new(14, 0.5, 60),
		origin + Vector3.new(-37, 0.1, 12),
		C.grass,
		Enum.Material.Grass
	)
	part(
		model,
		"InternetGrassRight",
		Vector3.new(14, 0.5, 60),
		origin + Vector3.new(37, 0.1, 12),
		C.grass,
		Enum.Material.Grass
	)

	for index = -3, 3 do
		part(
			model,
			"InternetRoadStripe_" .. index,
			Vector3.new(8, 0.15, 0.8),
			origin + Vector3.new(index * 12, 0.3, -28),
			C.white,
			Enum.Material.SmoothPlastic
		).CanCollide =
			false
	end

	local header = part(
		model,
		"InternetConstructionHeader",
		Vector3.new(52, 8, 1),
		origin + Vector3.new(0, 13, -40),
		C.dark,
		Enum.Material.Metal
	)
	label(header, "INTERNET CONSTRUCTION YARD\nOD ISP DO DOMOWEJ SIECI", Enum.NormalId.Front, 21)

	local instructionBoard = part(
		model,
		"InternetInstructionBoard",
		Vector3.new(24, 9, 1),
		origin + Vector3.new(25, 7, -35),
		C.dark,
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. SITE CHECK\n2. ISP → ONT: FIBER / OPTICAL\n3. ONT → ROUTER: ETHERNET / WAN\n4. ROUTER → SWITCH → PC/AP: ETHERNET\n5. TEST PC + WI-FI",
		Enum.NormalId.Front,
		20,
		28
	)

	local siteCheck = part(
		model,
		"InternetSiteCheck",
		Vector3.new(10, 5, 7),
		origin + Vector3.new(0, 3.5, -42),
		C.orange,
		Enum.Material.Metal
	)
	siteCheck.CanCollide = false
	siteCheck.CanTouch = false
	local siteCheckText = label(siteCheck, "SITE CHECK\nPLAC BUDOWY: OFFLINE", Enum.NormalId.Front, 20, 28)
	local sitePrompt
	sitePrompt = prompt(siteCheck, "URUCHOM SITE CHECK", "Internet Construction Yard", function(p)
		if p ~= player or ctx.entryReady or state.done then
			return
		end
		ctx.entryReady = true
		sitePrompt.Enabled = false
		siteCheck.Color = C.green
		siteCheck.Material = Enum.Material.Neon
		siteCheckText.Text = "SITE CHECK ✓\nZLECENIA AKTYWNE"
		flash(ctx, "Plac sprawdzony. Zacznij od ISP → ONT: światłowód + port OPTICAL.", true)
		refresh(ctx)
	end)
	ctx.entryPrompt = sitePrompt
	ctx.entryCheck = siteCheck

	ctx.positions.ISP = origin + Vector3.new(-30, 0, -25)
	ctx.positions.ONT = origin + Vector3.new(-18, 3, -12)
	ctx.positions.ROUTER = origin + Vector3.new(0, 3, -3)
	ctx.positions.SWITCH = origin + Vector3.new(0, 3, 11)
	ctx.positions.PC = origin + Vector3.new(-18, 3, 27)
	ctx.positions.AP = origin + Vector3.new(18, 3, 27)
	ctx.positions.TABLET = origin + Vector3.new(28, 3, 37)

	ctx.ispBeacon = makeIspMast(model, ctx.positions.ISP)
	makeOnt(model, ctx.positions.ONT)
	makeRouterShape(model, "Router", ctx.positions.ROUTER, C.blue)
	makeSwitchShape(model, ctx.positions.SWITCH)
	local pc = part(model, "PC_Tower", Vector3.new(7, 8, 6), ctx.positions.PC, C.dark, Enum.Material.Metal)
	pc.CanCollide = false
	makeRouterShape(model, "School_Router", ctx.positions.AP, C.cyan)
	local tablet = part(model, "Tablet_Shell", Vector3.new(7, 1, 10), ctx.positions.TABLET, C.dark, Enum.Material.Metal)
	tablet.CFrame = CFrame.new(tablet.Position) * CFrame.Angles(math.rad(-20), 0, 0)
	tablet.CanCollide = false

	deviceSign(model, "InternetSignONT", "ONT\nOPTICAL / LAN", ctx.positions.ONT + Vector3.new(0, 8, -1))
	deviceSign(model, "InternetSignRouter", "ROUTER\nWAN / LAN", ctx.positions.ROUTER + Vector3.new(0, 8, -1))
	deviceSign(model, "InternetSignSwitch", "SWITCH\nUPLINK / LAN", ctx.positions.SWITCH + Vector3.new(0, 8, -1))
	deviceSign(model, "InternetSignPC", "PC\nETHERNET / USB", ctx.positions.PC + Vector3.new(0, 9, -1))
	deviceSign(model, "InternetSignAP", "ACCESS POINT\nLAN / POWER", ctx.positions.AP + Vector3.new(0, 9, -1))

	for radiusIndex = 1, 3 do
		local ring = part(
			model,
			"InternetWiFiWave_" .. radiusIndex,
			Vector3.new(4 + radiusIndex * 4, 0.35, 4 + radiusIndex * 4),
			ctx.positions.AP + Vector3.new(0, 7 + radiusIndex * 1.7, 0),
			C.cyan,
			Enum.Material.Neon
		)
		ring.Transparency = 0.35 + radiusIndex * 0.12
		ring.CanCollide = false
	end

	local jobBoardPart = part(
		model,
		"InternetJobBoard",
		Vector3.new(32, 9, 1),
		origin + Vector3.new(0, 10, 19),
		C.dark,
		Enum.Material.Metal
	)
	ctx.jobBoard = label(jobBoardPart, "ZLECENIE", Enum.NormalId.Front, 18, 28)
	local cableStatusPart = part(
		model,
		"InternetCableStatus",
		Vector3.new(22, 4.5, 1),
		origin + Vector3.new(0, 4, 19),
		C.steel,
		Enum.Material.Metal
	)
	ctx.cableStatus = label(cableStatusPart, "KABEL: BRAK", Enum.NormalId.Front, 18, 24)

	for index = 1, 3 do
		local lamp = part(
			model,
			"InternetStageLamp_" .. index,
			Vector3.new(4.2, 4.2, 1.5),
			origin + Vector3.new(-7 + index * 7, 16, 19),
			C.steel,
			Enum.Material.Metal
		)
		label(lamp, tostring(index), Enum.NormalId.Front, 18, 22)
		lamp.CanCollide = false
		table.insert(ctx.stageLamps, lamp)
	end

	local fiberSpool = part(
		model,
		"InternetFiberSpool",
		Vector3.new(4, 7, 7),
		origin + Vector3.new(-14, 3.5, 13),
		C.cyan,
		Enum.Material.Metal
	)
	fiberSpool.Shape = Enum.PartType.Cylinder
	local ethernetSpool = part(
		model,
		"InternetEthernetSpool",
		Vector3.new(4, 7, 7),
		origin + Vector3.new(14, 3.5, 13),
		C.yellow,
		Enum.Material.Metal
	)
	ethernetSpool.Shape = Enum.PartType.Cylinder
	label(fiberSpool, "FIBER", Enum.NormalId.Right, 18, 24)
	label(ethernetSpool, "ETHERNET", Enum.NormalId.Right, 18, 24)

	table.insert(
		ctx.cablePrompts,
		prompt(fiberSpool, "Wybierz", "Światłowód", function(p)
			if p ~= player or state.done then
				return
			end
			Rules.SelectCable(ctx.rules, "FIBER")
			flash(ctx, "Wybrano światłowód. Znajdź właściwy port.", true)
			refresh(ctx)
		end)
	)
	table.insert(
		ctx.cablePrompts,
		prompt(ethernetSpool, "Wybierz", "Ethernet", function(p)
			if p ~= player or state.done then
				return
			end
			Rules.SelectCable(ctx.rules, "ETHERNET")
			flash(ctx, "Wybrano Ethernet. Znajdź właściwy port.", true)
			refresh(ctx)
		end)
	)

	local sourcePoints = {
		ctx.positions.ISP,
		ctx.positions.ONT,
		ctx.positions.ROUTER,
		ctx.positions.SWITCH,
		ctx.positions.SWITCH,
	}
	local targetPoints = {
		ctx.positions.ONT,
		ctx.positions.ROUTER,
		ctx.positions.SWITCH,
		ctx.positions.PC,
		ctx.positions.AP,
	}

	for index, job in ipairs(Rules.Jobs) do
		local target = targetPoints[index]
		local correctPad = part(
			model,
			"InternetPort_" .. job.id .. "_Correct",
			Vector3.new(5.5, 1.1, 4.5),
			target + Vector3.new(-3.4, -1.6, 6),
			C.green,
			Enum.Material.Metal
		)
		local wrongPad = part(
			model,
			"InternetPort_" .. job.id .. "_Wrong",
			Vector3.new(5.5, 1.1, 4.5),
			target + Vector3.new(3.4, -1.6, 6),
			C.red,
			Enum.Material.Metal
		)
		label(correctPad, job.port, Enum.NormalId.Top, 18, 23)
		label(wrongPad, job.wrongPort, Enum.NormalId.Top, 18, 23)

		local jobIndex = index
		local function attempt(portName)
			return function(p)
				if p ~= player or state.done then
					return
				end
				local ok, result = Rules.Connect(ctx.rules, portName)
				if not ok then
					state.score = math.max(0, state.score - 5)
					flash(ctx, result.message, false)
					refresh(ctx)
					return
				end

				state.score += 35
				local jobData = Rules.Jobs[jobIndex]
				cableBetween(
					model,
					"InternetCable_" .. jobData.id,
					sourcePoints[jobIndex] + Vector3.new(0, 2.5, 0),
					targetPoints[jobIndex] + Vector3.new(0, 2.5, 0),
					jobData.cable == "FIBER" and C.cyan or C.yellow
				)
				flash(ctx, result.message, true)
				refresh(ctx)
			end
		end

		local correctPrompt = prompt(correctPad, "Podłącz", job.port, attempt(job.port))
		local wrongPrompt = prompt(wrongPad, "Podłącz", job.wrongPort, attempt(job.wrongPort))
		table.insert(ctx.portPrompts, { correct = correctPrompt, wrong = wrongPrompt })
	end

	local wiredTest = part(
		model,
		"InternetWiredTest",
		Vector3.new(10, 2, 8),
		origin + Vector3.new(-18, 1.2, 38),
		C.yellow,
		Enum.Material.Metal
	)
	label(wiredTest, "TEST PC\nPAKIET", Enum.NormalId.Top, 18, 24)
	local wifiTest = part(
		model,
		"InternetWiFiTest",
		Vector3.new(10, 2, 8),
		origin + Vector3.new(18, 1.2, 38),
		C.cyan,
		Enum.Material.Metal
	)
	label(wifiTest, "TEST WI-FI\nPAKIET", Enum.NormalId.Top, 18, 24)

	local function runTest(route)
		return function(p)
			if p ~= player or state.done then
				return
			end
			local ok, result = Rules.TestRoute(ctx.rules, route)
			if not ok then
				flash(ctx, result.message, false)
				refresh(ctx)
				return
			end
			state.score += 50
			animatePacket(ctx, route)
			flash(ctx, result.message, true)
			if result.done then
				finish(ctx)
			else
				refresh(ctx)
			end
		end
	end

	ctx.wiredPrompt = prompt(wiredTest, "Wyślij", "Pakiet z PC", runTest("WIRED"))
	ctx.wifiPrompt = prompt(wifiTest, "Wyślij", "Pakiet z Wi-Fi", runTest("WIFI"))

	ctx.finalGate = part(
		model,
		"InternetFinalGate",
		Vector3.new(28, 12, 2),
		origin + Vector3.new(0, 6, 45),
		C.red,
		Enum.Material.Metal
	)
	ctx.finalText = label(ctx.finalGate, "INTERNET OFFLINE\nZBUDUJ 5 ŁĄCZY + 2 TESTY", Enum.NormalId.Front, 19, 28)

	for index, x in ipairs({ -31, -25, 25, 31 }) do
		local barrier = part(
			model,
			"InternetSafetyBarrier_" .. index,
			Vector3.new(10, 2.5, 1.2),
			origin + Vector3.new(x, 1.4, 5),
			C.orange,
			Enum.Material.Metal
		)
		barrier.CanCollide = false
	end

	refresh(ctx)
end

return InternetConstruction