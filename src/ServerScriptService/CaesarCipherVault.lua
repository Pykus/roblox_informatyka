local TweenService = game:GetService("TweenService")

local CaesarCipherVault = {}
local Rules = require(script.Parent:WaitForChild("CaesarCipherRules"))

local C = {
	floor = Color3.fromRGB(45, 38, 48),
	stone = Color3.fromRGB(82, 68, 76),
	stone2 = Color3.fromRGB(118, 99, 87),
	brass = Color3.fromRGB(207, 157, 66),
	brass2 = Color3.fromRGB(151, 107, 45),
	ink = Color3.fromRGB(20, 22, 27),
	blue = Color3.fromRGB(63, 148, 215),
	cyan = Color3.fromRGB(62, 214, 210),
	green = Color3.fromRGB(64, 210, 118),
	red = Color3.fromRGB(225, 73, 68),
	white = Color3.fromRGB(245, 239, 218),
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

local function label(target, text, face, minSize, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = color or C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.5
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

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.GamepadKeyCode = Enum.KeyCode.ButtonX
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.HoldDuration = 0.15
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function tween(instance, props, duration)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		props
	)
	t:Play()
	return t
end

local function setHud(ctx, objective)
	ctx.state.objective = objective
	ctx.remote:FireClient(ctx.player, {
		kind = "hud",
		title = ctx.mission.name or ctx.lesson.topic,
		objective = objective,
		score = ctx.state.score,
	})
end

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function setPrompts(prompts, enabled)
	for _, pr in ipairs(prompts) do
		pr.Enabled = enabled
	end
end

local function alphabetChar(index)
	return string.char(65 + (index % 26))
end

local function ringPosition(center, radius, index, shift)
	local step = math.pi * 2 / 26
	local angle = (index - shift) * step
	return Vector3.new(center.X + math.cos(angle) * radius, center.Y + math.sin(angle) * radius, center.Z), angle
end

local function updateRing(ctx)
	for index, entry in ipairs(ctx.innerRing) do
		local zero = index - 1
		local pos, angle = ringPosition(ctx.ringCenter, 8.4, zero, ctx.rules.shift)
		tween(entry.part, {
			Position = pos,
			Orientation = Vector3.new(0, 0, math.deg(angle) + 90),
		}, 0.13)
	end
	ctx.shiftReadout.Text = string.format(
		"PRZESUNIĘCIE +%d\nA → %s   X → %s\nCEL: A → D",
		ctx.rules.shift,
		Rules.ShiftChar("A", ctx.rules.shift),
		Rules.ShiftChar("X", ctx.rules.shift)
	)
	ctx.ringHub.Color = ctx.rules.shift == Rules.ExpectedShift and C.green or C.brass
	if ctx.shiftMonitorText then
		ctx.shiftMonitorText.Text = string.format("SHIFT\n+%d", ctx.rules.shift)
	end
	if ctx.ringConsole then
		ctx.ringConsole.Color = ctx.rules.shift == Rules.ExpectedShift and C.green or C.brass2
		ctx.ringConsole.Material = ctx.rules.shift == Rules.ExpectedShift and Enum.Material.Neon or Enum.Material.Metal
	end
end

local function stageLights(ctx)
	for i, lamp in ipairs(ctx.stageLamps) do
		local done = i < ctx.rules.stage or ctx.rules.completed
		lamp.Color = done and C.green or C.brass
		lamp.Material = done and Enum.Material.Neon or Enum.Material.Metal
	end
end

local function updateRotorText(ctx)
	local input
	if ctx.rules.stage == 2 then
		input = Rules.CipherText
	elseif ctx.rules.stage == 3 then
		input = Rules.WrapPlain
	else
		input = ""
	end
	local preview = Rules.Preview(ctx.rules)
	for i = 1, 5 do
		local visible = i <= #input
		local inputEntry = ctx.inputRotors[i]
		local outputEntry = ctx.outputRotors[i]
		inputEntry.part.Transparency = visible and 0 or 1
		outputEntry.part.Transparency = visible and 0 or 1
		inputEntry.text.Text = visible and input:sub(i, i) or ""
		outputEntry.text.Text = visible and preview:sub(i, i) or ""
		outputEntry.part.Color = C.blue
	end
	ctx.modeBoard.Text = string.format(
		"TRYB: %s\nSHIFT: %s3\n%s → %s",
		ctx.rules.mode == "ENCODE" and "SZYFRUJ" or "ODSZYFRUJ",
		ctx.rules.mode == "ENCODE" and "+" or "-",
		input,
		preview
	)
	ctx.modeLever.Color = ctx.rules.mode == "ENCODE" and C.brass or C.cyan
	ctx.modeLever.Orientation = ctx.rules.mode == "ENCODE" and Vector3.new(0, 0, -28) or Vector3.new(0, 0, 28)
	if ctx.modeMonitorText then
		ctx.modeMonitorText.Text = ctx.rules.mode == "ENCODE" and "TRYB\nSZYFRUJ" or "TRYB\nODSZYFRUJ"
	end
	if ctx.rotorRack then
		ctx.rotorRack.Color = ctx.rules.stage >= 2 and C.cyan or C.stone
		ctx.rotorRack.Material = ctx.rules.stage >= 2 and Enum.Material.Neon or Enum.Material.Metal
	end
end

local function pulseRotors(ctx, good)
	local targetColor = good and C.green or C.red
	for _, entry in ipairs(ctx.outputRotors) do
		if entry.part.Transparency < 1 then
			entry.part.Color = targetColor
			tween(entry.part, { Position = entry.home + Vector3.new(0, 1.4, 0) }, 0.1)
			task.delay(0.14, function()
				if entry.part and entry.part.Parent then
					tween(entry.part, { Position = entry.home }, 0.1)
				end
			end)
		end
	end
end

local function finish(ctx, resultText)
	ctx.state.done = true
	ctx.state.score += 100
	stageLights(ctx)
	ctx.vaultLight.Color = C.green
	ctx.vaultLight.Material = Enum.Material.Neon
	if ctx.vaultMonitorText then
		ctx.vaultMonitorText.Text = "VAULT\nOPEN"
	end
	if ctx.vaultConsole then
		ctx.vaultConsole.Color = C.green
		ctx.vaultConsole.Material = Enum.Material.Neon
	end
	ctx.vaultStatus.Text =
		string.format("SEJF OTWARTY\n%s\nEFEKTYWNOŚĆ %d%%", resultText, Rules.Efficiency(ctx.rules))
	for i, bolt in ipairs(ctx.bolts) do
		local direction = i % 2 == 0 and 1 or -1
		tween(bolt, { Position = bolt.Position + Vector3.new(direction * 7, 0, 0) }, 0.35)
	end
	tween(ctx.leftDoor, { Position = ctx.leftDoor.Position - Vector3.new(10, 0, 0) }, 0.5)
	tween(ctx.rightDoor, { Position = ctx.rightDoor.Position + Vector3.new(10, 0, 0) }, 0.5)
	setPrompts(ctx.cipherPrompts, false)
	message(ctx, "Cipher Ring Vault otwarty. Zawijanie alfabetu działa — rdzeń misji jest gotowy.", true)
	setHud(ctx, "ETAP 2/3 • Sejf Cezara otwarty. Przejdź do świecącego RDZENIA MISJI.")
end

function CaesarCipherVault.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		entryReady = false,
		outerRing = {},
		innerRing = {},
		stageLamps = {},
		inputRotors = {},
		outputRotors = {},
		bolts = {},
		ringPrompts = {},
		cipherPrompts = {},
	}
	state.caesarCipher = ctx

	part(
		model,
		"CipherVaultFloor",
		Vector3.new(88, 1, 86),
		origin + Vector3.new(0, -0.5, -4),
		C.floor,
		Enum.Material.Slate
	)
	part(
		model,
		"CipherVaultBackWall",
		Vector3.new(88, 25, 2),
		origin + Vector3.new(0, 12.5, -46),
		C.stone,
		Enum.Material.Slate
	)
	part(
		model,
		"CipherVaultLeftPillar",
		Vector3.new(6, 23, 6),
		origin + Vector3.new(-38, 11.5, -28),
		C.stone2,
		Enum.Material.Marble
	)
	part(
		model,
		"CipherVaultRightPillar",
		Vector3.new(6, 23, 6),
		origin + Vector3.new(38, 11.5, -28),
		C.stone2,
		Enum.Material.Marble
	)

	local title = part(
		model,
		"CipherVaultTitle",
		Vector3.new(44, 8, 1),
		origin + Vector3.new(0, 18, -44.8),
		C.ink,
		Enum.Material.Metal
	)
	label(title, "CIPHER RING VAULT\nSZYFR CEZARA", Enum.NormalId.Front, 24)

	local entryConsole = part(
		model,
		"CaesarEntryConsole",
		Vector3.new(16, 7, 7),
		origin + Vector3.new(-13, 4, -44),
		C.brass,
		Enum.Material.Metal
	)
	entryConsole.CanCollide = false
	entryConsole.CanTouch = false
	local entryText = label(entryConsole, "URUCHOM ROTOR\nVAULT OFFLINE", Enum.NormalId.Front, 22)

	local instructionBoard = part(
		model,
		"CaesarInstructionBoard",
		Vector3.new(30, 10, 1.2),
		origin + Vector3.new(16, 7, -44),
		C.ink,
		Enum.Material.Metal
	)
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. Ustaw shift +3\n2. ODSZYFRUJ KHOOR → HELLO\n3. Sprawdź zawijanie XYZ → ABC\nPRZYKŁAD: A → D = +3",
		Enum.NormalId.Front,
		20
	)
	instructionBoard.CanCollide = false
	instructionBoard.CanTouch = false

	local entryPrompt
	entryPrompt = prompt(entryConsole, "URUCHOM ROTOR", "panel wejściowy", function(who)
		if who ~= player or ctx.entryReady or state.done then
			return
		end
		ctx.entryReady = true
		entryPrompt.Enabled = false
		entryConsole.Color = C.green
		entryConsole.Material = Enum.Material.Neon
		entryText.Text = "ROTOR ONLINE\nUSTAW SHIFT +3"
		setPrompts(ctx.ringPrompts, true)
		setHud(ctx, "ETAP 1/3 • Obróć wewnętrzny alfabet do +3. A ma wskazać D, potem SPRAWDŹ +3.")
		message(ctx, "Rotor uruchomiony. Przykład A → D oznacza przesunięcie +3.", true)
	end)

	for i = 1, 3 do
		local lamp = part(
			model,
			"CipherStageLamp_" .. i,
			Vector3.new(5, 5, 2),
			origin + Vector3.new(25 + i * 7, 14, -43.5),
			C.brass,
			Enum.Material.Metal
		)
		label(lamp, tostring(i), Enum.NormalId.Front, 20)
		lamp.CanCollide = false
		table.insert(ctx.stageLamps, lamp)
	end

	-- Stage 1: physical double alphabet ring
	ctx.ringCenter = origin + Vector3.new(0, 14, -27)
	local ringBack = part(
		model,
		"CipherRingBackplate",
		Vector3.new(1, 31, 31),
		ctx.ringCenter + Vector3.new(0, 0, 0.8),
		C.ink,
		Enum.Material.Metal
	)
	ringBack.Shape = Enum.PartType.Cylinder
	ringBack.CFrame = CFrame.new(ringBack.Position) * CFrame.Angles(0, math.rad(90), 0)
	ctx.ringHub = part(model, "CipherRingHub", Vector3.new(2, 6, 6), ctx.ringCenter, C.brass, Enum.Material.Metal)
	ctx.ringHub.Shape = Enum.PartType.Cylinder
	ctx.ringHub.CFrame = CFrame.new(ctx.ringHub.Position) * CFrame.Angles(0, math.rad(90), 0)

	for index = 0, 25 do
		local outerPos, outerAngle = ringPosition(ctx.ringCenter, 12.1, index, 0)
		local outer = part(
			model,
			"CipherOuter_" .. alphabetChar(index),
			Vector3.new(2.3, 1.55, 0.8),
			outerPos,
			C.stone2,
			Enum.Material.Marble
		)
		outer.Orientation = Vector3.new(0, 0, math.deg(outerAngle) + 90)
		label(outer, alphabetChar(index), Enum.NormalId.Front, 18)
		outer.CanCollide = false
		table.insert(ctx.outerRing, { part = outer })

		local innerPos, innerAngle = ringPosition(ctx.ringCenter, 8.4, index, 0)
		local inner = part(
			model,
			"CipherInner_" .. alphabetChar(index),
			Vector3.new(2.0, 1.4, 0.8),
			innerPos,
			C.brass2,
			Enum.Material.Metal
		)
		inner.Orientation = Vector3.new(0, 0, math.deg(innerAngle) + 90)
		label(inner, alphabetChar(index), Enum.NormalId.Front, 18)
		inner.CanCollide = false
		table.insert(ctx.innerRing, { part = inner })
	end

	local shiftBoard = part(
		model,
		"CipherShiftReadout",
		Vector3.new(28, 9, 1),
		origin + Vector3.new(-26, 10, -10),
		C.ink,
		Enum.Material.Metal
	)
	ctx.shiftReadout = label(shiftBoard, "", Enum.NormalId.Front, 18)

	local shiftMonitor = part(
		model,
		"CaesarShiftReadoutMonitor",
		Vector3.new(8, 6, 3),
		origin + Vector3.new(-40, 6, -10),
		C.ink,
		Enum.Material.Metal
	)
	shiftMonitor.CanCollide = false
	shiftMonitor.CanTouch = false
	ctx.shiftMonitorText = label(shiftMonitor, "SHIFT\n+0", Enum.NormalId.Front, 18)

	ctx.ringConsole = part(
		model,
		"CaesarRingMechanismConsole",
		Vector3.new(9, 6, 6),
		origin + Vector3.new(29, 3, -13),
		C.brass2,
		Enum.Material.Metal
	)
	ctx.ringConsole.CanCollide = false
	ctx.ringConsole.CanTouch = false
	label(ctx.ringConsole, "RING\nDRIVE", Enum.NormalId.Front, 18)

	local minus = part(
		model,
		"CipherShiftMinus",
		Vector3.new(9, 3, 8),
		origin + Vector3.new(-12, 1.5, -13),
		C.blue,
		Enum.Material.Metal
	)
	label(minus, "−1", Enum.NormalId.Top, 22)
	local plus = part(
		model,
		"CipherShiftPlus",
		Vector3.new(9, 3, 8),
		origin + Vector3.new(0, 1.5, -13),
		C.blue,
		Enum.Material.Metal
	)
	label(plus, "+1", Enum.NormalId.Top, 22)
	local lock = part(
		model,
		"CipherShiftLock",
		Vector3.new(11, 3, 8),
		origin + Vector3.new(13, 1.5, -13),
		C.brass,
		Enum.Material.Metal
	)
	label(lock, "ZABLOKUJ", Enum.NormalId.Top, 18)

	local shiftMinusControl = part(
		model,
		"CaesarShiftControl_Minus",
		Vector3.new(2.8, 1.2, 2.8),
		minus.Position + Vector3.new(0, 2.3, 0),
		C.blue,
		Enum.Material.Metal
	)
	shiftMinusControl.CanCollide = false
	local shiftPlusControl = part(
		model,
		"CaesarShiftControl_Plus",
		Vector3.new(2.8, 1.2, 2.8),
		plus.Position + Vector3.new(0, 2.3, 0),
		C.blue,
		Enum.Material.Metal
	)
	shiftPlusControl.CanCollide = false
	local shiftLockControl = part(
		model,
		"CaesarShiftControl_Lock",
		Vector3.new(2.8, 1.2, 2.8),
		lock.Position + Vector3.new(0, 2.3, 0),
		C.brass,
		Enum.Material.Metal
	)
	shiftLockControl.CanCollide = false

	table.insert(
		ctx.ringPrompts,
		prompt(shiftMinusControl, "OBRÓĆ −1", "Wewnętrzny alfabet", function(who)
			if who ~= player or state.done then
				return
			end
			local ok, msg = Rules.ChangeShift(ctx.rules, -1)
			if ok then
				updateRing(ctx)
				message(ctx, msg, true)
			else
				message(ctx, msg, false)
			end
		end)
	)
	table.insert(
		ctx.ringPrompts,
		prompt(shiftPlusControl, "OBRÓĆ +1", "Wewnętrzny alfabet", function(who)
			if who ~= player or state.done then
				return
			end
			local ok, msg = Rules.ChangeShift(ctx.rules, 1)
			if ok then
				updateRing(ctx)
				message(ctx, msg, true)
			else
				message(ctx, msg, false)
			end
		end)
	)
	table.insert(
		ctx.ringPrompts,
		prompt(shiftLockControl, "SPRAWDŹ +3", "Blokada pierścienia", function(who)
			if who ~= player or state.done then
				return
			end
			local ok, msg = Rules.LockShift(ctx.rules)
			if not ok then
				state.score = math.max(0, state.score - 5)
				ctx.ringHub.Color = C.red
				message(ctx, msg, false)
				task.delay(0.35, function()
					if ctx.ringHub and ctx.ringHub.Parent then
						updateRing(ctx)
					end
				end)
				return
			end
			state.score += 45
			ctx.ringHub.Color = C.green
			ctx.ringHub.Material = Enum.Material.Neon
			setPrompts(ctx.ringPrompts, false)
			setPrompts(ctx.cipherPrompts, true)
			stageLights(ctx)
			updateRotorText(ctx)
			message(ctx, msg, true)
			setHud(ctx, "ETAP 2/3 • Ustaw tryb ODSZYFRUJ i uruchom rotory: KHOOR ma dać HELLO.")
		end)
	)

	-- Stages 2/3: physical rotor decoder/encoder
	local rotorDesk = part(
		model,
		"CipherRotorDesk",
		Vector3.new(58, 3, 20),
		origin + Vector3.new(5, 1.5, 12),
		C.stone2,
		Enum.Material.Marble
	)
	local rotorBoard = part(
		model,
		"CipherRotorBoard",
		Vector3.new(28, 10, 1),
		origin + Vector3.new(-27, 12, 7),
		C.ink,
		Enum.Material.Metal
	)
	ctx.modeBoard = label(rotorBoard, "", Enum.NormalId.Front, 18)

	local modeMonitor = part(
		model,
		"CaesarModeStatusMonitor",
		Vector3.new(8, 6, 3),
		origin + Vector3.new(-41, 6, 8),
		C.ink,
		Enum.Material.Metal
	)
	modeMonitor.CanCollide = false
	modeMonitor.CanTouch = false
	ctx.modeMonitorText = label(modeMonitor, "TRYB\nSZYFRUJ", Enum.NormalId.Front, 18)

	ctx.rotorRack = part(
		model,
		"CaesarRotorDriveRack",
		Vector3.new(8, 11, 7),
		origin + Vector3.new(38, 5.5, 1),
		C.stone,
		Enum.Material.Metal
	)
	ctx.rotorRack.CanCollide = false
	ctx.rotorRack.CanTouch = false
	label(ctx.rotorRack, "ROTOR\nDRIVE", Enum.NormalId.Front, 18)

	for i = 1, 5 do
		local x = origin.X - 6 + (i - 1) * 7
		local inputPart = part(
			model,
			"CipherInputRotor_" .. i,
			Vector3.new(5.5, 5.5, 5.5),
			Vector3.new(x, origin.Y + 6, origin.Z + 9),
			C.stone,
			Enum.Material.Metal
		)
		inputPart.Shape = Enum.PartType.Cylinder
		inputPart.CFrame = CFrame.new(inputPart.Position) * CFrame.Angles(0, 0, math.rad(90))
		local inputText = label(inputPart, "", Enum.NormalId.Top, 20)
		local outputPart = part(
			model,
			"CipherOutputRotor_" .. i,
			Vector3.new(5.5, 5.5, 5.5),
			Vector3.new(x, origin.Y + 6, origin.Z + 17),
			C.blue,
			Enum.Material.Metal
		)
		outputPart.Shape = Enum.PartType.Cylinder
		outputPart.CFrame = CFrame.new(outputPart.Position) * CFrame.Angles(0, 0, math.rad(90))
		local outputText = label(outputPart, "", Enum.NormalId.Top, 20)
		table.insert(ctx.inputRotors, { part = inputPart, text = inputText, home = inputPart.Position })
		table.insert(ctx.outputRotors, { part = outputPart, text = outputText, home = outputPart.Position })
	end

	ctx.modeLever = part(
		model,
		"CipherModeLever",
		Vector3.new(4, 10, 4),
		origin + Vector3.new(27, 6, 4),
		C.brass,
		Enum.Material.Metal
	)
	local modeBase = part(
		model,
		"CipherModeBase",
		Vector3.new(10, 3, 10),
		origin + Vector3.new(27, 1.5, 4),
		C.ink,
		Enum.Material.Metal
	)
	label(modeBase, "TRYB", Enum.NormalId.Top, 18)
	local runButton = part(
		model,
		"CipherRunButton",
		Vector3.new(11, 3, 10),
		origin + Vector3.new(39, 1.5, 13),
		C.green,
		Enum.Material.Metal
	)
	label(runButton, "URUCHOM\nROTORY", Enum.NormalId.Top, 18)

	local rotorTerminal = part(
		model,
		"CaesarRotorTerminal",
		Vector3.new(8, 5, 5),
		origin + Vector3.new(39, 4, 26),
		C.ink,
		Enum.Material.Metal
	)
	rotorTerminal.CanCollide = false
	local modeControl = part(
		model,
		"CaesarModeControl_Toggle",
		Vector3.new(2.8, 1.2, 2.8),
		modeBase.Position + Vector3.new(0, 2.3, 0),
		C.cyan,
		Enum.Material.Metal
	)
	modeControl.CanCollide = false
	local runControl = part(
		model,
		"CaesarRunControl_Execute",
		Vector3.new(2.8, 1.2, 2.8),
		runButton.Position + Vector3.new(0, 2.3, 0),
		C.green,
		Enum.Material.Metal
	)
	runControl.CanCollide = false

	table.insert(
		ctx.cipherPrompts,
		prompt(modeControl, "PRZEŁĄCZ", "SZYFRUJ / ODSZYFRUJ", function(who)
			if who ~= player or state.done then
				return
			end
			local ok, mode = Rules.ToggleMode(ctx.rules)
			if not ok then
				message(ctx, mode, false)
				return
			end
			updateRotorText(ctx)
			message(ctx, "Tryb: " .. mode, true)
		end)
	)
	table.insert(
		ctx.cipherPrompts,
		prompt(runControl, "URUCHOM", "Rotory szyfru Cezara", function(who)
			if who ~= player or state.done then
				return
			end
			local ok, msg, output = Rules.Run(ctx.rules)
			pulseRotors(ctx, ok)
			if not ok then
				state.score = math.max(0, state.score - 5)
				message(ctx, msg, false)
				return
			end
			state.score += 55
			stageLights(ctx)
			message(ctx, msg, true)
			if ctx.rules.completed then
				finish(ctx, "XYZ +3 → " .. output)
				return
			end
			updateRotorText(ctx)
			setHud(ctx, "ETAP 3/3 • Przełącz na SZYFRUJ i sprawdź zawijanie: XYZ +3 ma dać ABC.")
		end)
	)

	-- Physical vault finale
	ctx.leftDoor = part(
		model,
		"CaesarVaultDoorLeft",
		Vector3.new(18, 22, 3),
		origin + Vector3.new(-9, 11, 39),
		C.stone,
		Enum.Material.DiamondPlate
	)
	ctx.rightDoor = part(
		model,
		"CaesarVaultDoorRight",
		Vector3.new(18, 22, 3),
		origin + Vector3.new(9, 11, 39),
		C.stone,
		Enum.Material.DiamondPlate
	)
	local vaultFrame = part(
		model,
		"CaesarVaultFrame",
		Vector3.new(48, 5, 5),
		origin + Vector3.new(0, 23, 39),
		C.brass2,
		Enum.Material.Metal
	)
	label(vaultFrame, "VAULT 26\nMODULO ALFABETU", Enum.NormalId.Front, 19)
	ctx.vaultStatus = label(ctx.leftDoor, "ZAMKNIĘTE\n3 ETAPY", Enum.NormalId.Front, 19)
	ctx.vaultLight = part(
		model,
		"CaesarVaultLight",
		Vector3.new(6, 6, 2),
		origin + Vector3.new(0, 5, 37.2),
		C.red,
		Enum.Material.Neon
	)
	ctx.vaultLight.CanCollide = false

	local vaultMonitor = part(
		model,
		"CaesarVaultStatusMonitor",
		Vector3.new(8, 6, 3),
		origin + Vector3.new(-27, 5, 34),
		C.ink,
		Enum.Material.Metal
	)
	vaultMonitor.CanCollide = false
	vaultMonitor.CanTouch = false
	ctx.vaultMonitorText = label(vaultMonitor, "VAULT\nLOCKED", Enum.NormalId.Front, 18)

	ctx.vaultConsole = part(
		model,
		"CaesarVaultLockConsole",
		Vector3.new(9, 6, 6),
		origin + Vector3.new(27, 3, 34),
		C.red,
		Enum.Material.Metal
	)
	ctx.vaultConsole.CanCollide = false
	ctx.vaultConsole.CanTouch = false
	label(ctx.vaultConsole, "LOCK\nCONTROL", Enum.NormalId.Front, 18)

	for i = 1, 3 do
		local bolt = part(
			model,
			"CaesarVaultBolt_" .. i,
			Vector3.new(30, 2.2, 2.2),
			origin + Vector3.new(0, 6 + i * 4, 36.8),
			C.brass,
			Enum.Material.Metal
		)
		bolt.CanCollide = false
		table.insert(ctx.bolts, bolt)
	end

	setPrompts(ctx.ringPrompts, false)
	setPrompts(ctx.cipherPrompts, false)
	updateRing(ctx)
	updateRotorText(ctx)
	stageLights(ctx)
	setHud(ctx, "ETAP START • Uruchom ROTOR przy wejściu i przeczytaj przykład A → D = +3.")
end

return CaesarCipherVault