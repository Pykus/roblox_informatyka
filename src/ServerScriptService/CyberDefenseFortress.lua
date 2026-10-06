local CyberDefenseFortress = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("CyberDefenseRules"))
local VisualThemes = require(script.Parent:WaitForChild("VisualThemes"))

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

local function label(target, text, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(960, 480)
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -36, 1, -28)
	txt.Position = UDim2.fromOffset(18, 14)
	txt.BackgroundColor3 = Color3.fromRGB(8, 13, 22)
	txt.BackgroundTransparency = 0.12
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(248, 250, 255)
	txt.TextStrokeTransparency = 0.6
	txt.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = txt

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = 42
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 12
	pr.HoldDuration = 0.12
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function glow(target, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.6
	light.Range = range or 16
	light.Parent = target
	return light
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

local function pulse(target, color)
	local old = target.Color
	target.Color = color
	TweenService:Create(target, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Color = old,
	}):Play()
end

local function attackPacket(model, startPos, shield, index)
	local packet = part(
		model,
		"AttackPacket" .. index,
		Vector3.new(2.6, 2.6, 2.6),
		startPos,
		Color3.fromRGB(255, 55, 70),
		Enum.Material.Neon
	)
	packet.Shape = Enum.PartType.Ball
	packet.CanCollide = false
	glow(packet, packet.Color, 2.5, 12)
	TweenService:Create(packet, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = shield.Position,
		Size = Vector3.new(0.6, 0.6, 0.6),
	}):Play()
	task.delay(0.72, function()
		if shield.Parent then
			pulse(shield, Color3.fromRGB(120, 255, 200))
		end
	end)
	task.delay(0.82, function()
		if packet.Parent then
			packet:Destroy()
		end
	end)
end

function CyberDefenseFortress.Run(model, origin, player, lesson, mission, remote, state, accent)
	local profile = VisualThemes.Get(mission)
	accent = profile.accent

	state.defenseStep = 1
	state.secureCells = {}
	state.secureCount = 0
	state.messageIndex = 1
	state.mfaKey = false
	local entryArmed = false
	local passwordPrompts = {}
	local blockPrompt
	local allowPrompt
	local takePrompt
	local lockPrompt

	local brief = part(
		model,
		"FortressBrief",
		Vector3.new(72, 11, 2),
		origin + Vector3.new(0, 9, -42),
		profile.surface2,
		profile.structureMaterial
	)
	label(
		brief,
		"TWIERDZA KONTA • START: UZBRÓJ TARCZĘ\n1. HASŁO: długie + unikalne + menedżer   2. BLOKUJ phishing   3. MFA"
	)
	glow(brief, accent, 1.3, 18)

	local armStation = part(
		model,
		"CyberShieldArmLever",
		Vector3.new(10, 5, 7),
		origin + Vector3.new(0, 3.5, -44),
		Color3.fromRGB(145, 48, 58),
		Enum.Material.Metal
	)
	armStation.CanCollide = false
	armStation.CanTouch = false
	local armText = label(armStation, "TARCZA\nOFF", Enum.NormalId.Front)

	local armHandle = part(
		model,
		"CyberShieldArmHandle",
		Vector3.new(1.5, 7, 1.5),
		origin + Vector3.new(0, 7.3, -44),
		Color3.fromRGB(235, 75, 72),
		Enum.Material.Metal
	)
	armHandle.CanCollide = false
	armHandle.CanTouch = false
	armHandle.CFrame = CFrame.new(armHandle.Position) * CFrame.Angles(0, 0, math.rad(-32))
	local armHandleOn = CFrame.new(armHandle.Position) * CFrame.Angles(0, 0, math.rad(32))

	local alarmBeacon = part(
		model,
		"CyberShieldAlarmBeacon",
		Vector3.new(3.5, 3.5, 3.5),
		origin + Vector3.new(0, 11.5, -44),
		Color3.fromRGB(245, 65, 70),
		Enum.Material.Neon
	)
	alarmBeacon.Shape = Enum.PartType.Ball
	alarmBeacon.CanCollide = false
	alarmBeacon.CanTouch = false
	local alarmLight = glow(alarmBeacon, alarmBeacon.Color, 2.5, 18)

	local shieldBase = part(
		model,
		"ShieldBase",
		Vector3.new(26, 3, 22),
		origin + Vector3.new(0, 2, 14),
		profile.surface,
		Enum.Material.DiamondPlate
	)
	local shield = part(
		model,
		"AccountShield",
		Vector3.new(11, 11, 11),
		origin + Vector3.new(0, 14, 14),
		Color3.fromRGB(105, 45, 55),
		Enum.Material.Glass
	)
	shield.Shape = Enum.PartType.Ball
	shield.Transparency = 0.1
	local shieldLight = glow(shield, Color3.fromRGB(255, 70, 90), 2.2, 24)

	local statusPanel = part(
		model,
		"ShieldStatus",
		Vector3.new(26, 8, 1),
		origin + Vector3.new(0, 8, 2),
		Color3.fromRGB(55, 38, 45),
		Enum.Material.Glass
	)
	local statusText = label(statusPanel, "TARCZA 0/3\nKONTO NARAŻONE")

	local shieldStatusMonitor = part(
		model,
		"CyberShieldStatusMonitor",
		Vector3.new(8, 6, 3),
		origin + Vector3.new(-37, 6, 4),
		Color3.fromRGB(36, 46, 60),
		Enum.Material.Metal
	)
	shieldStatusMonitor.CanCollide = false
	shieldStatusMonitor.CanTouch = false
	local shieldStatusText = label(shieldStatusMonitor, "SHIELD\n0/3")

	local shieldGenerator = part(
		model,
		"CyberShieldGeneratorConsole",
		Vector3.new(9, 6, 6),
		origin + Vector3.new(-37, 3, 14),
		Color3.fromRGB(78, 52, 60),
		Enum.Material.Metal
	)
	shieldGenerator.CanCollide = false
	shieldGenerator.CanTouch = false
	label(shieldGenerator, "SHIELD\nGENERATOR")

	local attackStatusMonitor = part(
		model,
		"CyberAttackStatusMonitor",
		Vector3.new(8, 6, 3),
		origin + Vector3.new(37, 7, 12),
		Color3.fromRGB(74, 38, 48),
		Enum.Material.Metal
	)
	attackStatusMonitor.CanCollide = false
	attackStatusMonitor.CanTouch = false
	local attackStatusText = label(attackStatusMonitor, "THREATS\nWAITING")

	local socDesk = part(
		model,
		"CyberSOCDesk",
		Vector3.new(12, 4, 7),
		origin + Vector3.new(34, 2, -25),
		profile.surface,
		Enum.Material.Metal
	)
	socDesk.CanCollide = false
	socDesk.CanTouch = false

	local socKeyboard = part(
		model,
		"CyberSOCKeyboard",
		Vector3.new(5, 0.8, 2),
		origin + Vector3.new(32, 4.4, -24),
		Color3.fromRGB(45, 55, 68),
		Enum.Material.Metal
	)
	socKeyboard.CanCollide = false
	socKeyboard.CanTouch = false

	local socMouse = part(
		model,
		"CyberSOCMouse",
		Vector3.new(2, 0.9, 1.5),
		origin + Vector3.new(38, 4.45, -24),
		Color3.fromRGB(55, 65, 78),
		Enum.Material.Metal
	)
	socMouse.CanCollide = false
	socMouse.CanTouch = false

	local ringParts = {}
	for i = 1, 3 do
		local ring = part(
			model,
			"ShieldSegment" .. i,
			Vector3.new(2.5, 7, 16),
			origin + Vector3.new(-8 + (i - 1) * 8, 5, 14),
			Color3.fromRGB(85, 55, 62),
			Enum.Material.Metal
		)
		ring.Transparency = 0.18
		ringParts[i] = ring
	end

	local refreshMessage = function() end
	local cells = {}
	for i, item in ipairs(Rules.PasswordCells) do
		local row = i <= 3 and 0 or 1
		local col = ((i - 1) % 3) - 1
		local x = col * 22
		local z = -17 + row * 16
		local pad = part(
			model,
			"PasswordCell_" .. item.id,
			Vector3.new(18, 2, 11),
			origin + Vector3.new(x, 2, z),
			Color3.fromRGB(62, 68, 84),
			Enum.Material.Metal
		)
		label(pad, item.label, Enum.NormalId.Top)
		local control = part(
			model,
			"CyberPasswordControl_" .. item.id,
			Vector3.new(4, 3, 4),
			origin + Vector3.new(x, 3.6, z + 7.2),
			Color3.fromRGB(72, 86, 104),
			Enum.Material.Metal
		)
		control.CanCollide = false
		control.CanTouch = false
		local pr
		pr = prompt(control, "WŁĄCZ", item.label, function(p)
			if p ~= player or state.done then
				return
			end
			if not entryArmed then
				message(remote, player, "Najpierw uzbrój tarczę czerwonym wyłącznikiem przy wejściu.", false)
				return
			end
			if state.defenseStep ~= 1 then
				message(
					remote,
					player,
					"Tarcza hasła jest już skonfigurowana. Przejdź do skanera wiadomości.",
					false
				)
				return
			end
			if state.secureCells[item.id] then
				return
			end

			local safe, why = Rules.IsPasswordCellSafe(item.id)
			if not safe then
				state.score = math.max(0, state.score - 5)
				pulse(pad, Color3.fromRGB(255, 65, 70))
				message(remote, player, why, false)
				return
			end

			state.secureCells[item.id] = true
			state.secureCount += 1
			state.score += 18
			pr.Enabled = false
			pad.Color = Color3.fromRGB(45, 205, 135)
			pad.Material = Enum.Material.Neon
			local segment = ringParts[state.secureCount]
			segment.Color = Color3.fromRGB(55, 220, 145)
			segment.Material = Enum.Material.Neon
			statusText.Text = string.format(
				"TARCZA %d/3\n%s",
				state.secureCount,
				state.secureCount == 3 and "HASŁO WZMOCNIONE" or "ZASILANIE..."
			)
			shieldStatusText.Text = string.format("SHIELD\n%d/3", state.secureCount)
			shieldGenerator.Color = state.secureCount == 3 and Color3.fromRGB(235, 175, 55)
				or Color3.fromRGB(90, 95 + state.secureCount * 30, 80)
			shieldGenerator.Material = state.secureCount == 3 and Enum.Material.Neon or Enum.Material.Metal
			message(remote, player, why, true)

			if state.secureCount == 3 then
				state.defenseStep = 2
				state.score += 20
				shield.Color = Color3.fromRGB(235, 175, 55)
				shieldLight.Color = shield.Color
				statusPanel.Color = Color3.fromRGB(120, 85, 35)
				refreshMessage()
				if blockPrompt then
					blockPrompt.Enabled = true
				end
				if allowPrompt then
					allowPrompt.Enabled = true
				end
				state.objective =
					"ETAP OBRONY 2/3 • Oceń kolejne wiadomości na skanerze. BLOKUJ phishing, PRZEPUŚĆ bezpieczne."
				hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
			end
		end)
		pr.Enabled = false
		table.insert(passwordPrompts, pr)
		cells[item.id] = { pad = pad, prompt = pr }
	end

	local scanner = part(
		model,
		"MessageScanner",
		Vector3.new(64, 14, 2),
		origin + Vector3.new(0, 12, 38),
		profile.surface2,
		profile.structureMaterial
	)
	local scannerText = label(scanner, "SKANER WIADOMOŚCI\nNAJPIERW ZASIL TARCZĘ")

	local phishingTerminal = part(
		model,
		"CyberPhishingTerminal",
		Vector3.new(9, 6, 6),
		origin + Vector3.new(-39, 5, 38),
		Color3.fromRGB(45, 52, 66),
		Enum.Material.Metal
	)
	phishingTerminal.CanCollide = false
	phishingTerminal.CanTouch = false
	label(phishingTerminal, "MAIL\nANALYZER")

	local blockPad = part(
		model,
		"BlockPad",
		Vector3.new(22, 2, 13),
		origin + Vector3.new(-15, 2, 52),
		Color3.fromRGB(145, 45, 55),
		Enum.Material.Neon
	)
	label(blockPad, "BLOKUJ", Enum.NormalId.Top)
	local allowPad = part(
		model,
		"AllowPad",
		Vector3.new(22, 2, 13),
		origin + Vector3.new(15, 2, 52),
		Color3.fromRGB(45, 130, 95),
		Enum.Material.Neon
	)
	label(allowPad, "PRZEPUŚĆ", Enum.NormalId.Top)

	local blockControl = part(
		model,
		"CyberMessageControl_Block",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(-15, 3.8, 45),
		Color3.fromRGB(125, 48, 58),
		Enum.Material.Metal
	)
	blockControl.CanCollide = false
	blockControl.CanTouch = false
	local allowControl = part(
		model,
		"CyberMessageControl_Allow",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(15, 3.8, 45),
		Color3.fromRGB(45, 105, 82),
		Enum.Material.Metal
	)
	allowControl.CanCollide = false
	allowControl.CanTouch = false

	refreshMessage = function()
		local item = Rules.Messages[state.messageIndex]
		if item then
			scannerText.Text = string.format("WIADOMOŚĆ %d/%d\n%s", state.messageIndex, #Rules.Messages, item.label)
			attackStatusText.Text = string.format("MAIL SCAN\n%d/%d", state.messageIndex, #Rules.Messages)
			phishingTerminal.Color = Color3.fromRGB(70, 145, 205)
			phishingTerminal.Material = Enum.Material.Neon
		else
			scannerText.Text = "SKANER CZYSTY\nPHISHING ZATRZYMANY"
			attackStatusText.Text = "PHISHING\nCLEAR"
			phishingTerminal.Color = Color3.fromRGB(45, 205, 135)
			phishingTerminal.Material = Enum.Material.Neon
		end
	end

	local function decide(decision, pad)
		if state.done then
			return
		end
		if state.defenseStep < 2 then
			message(remote, player, "Najpierw uruchom tarczę dobrego hasła.", false)
			return
		end
		if state.defenseStep > 2 then
			message(remote, player, "Skaner zakończył pracę. Został drugi czynnik logowania.", false)
			return
		end

		local item = Rules.Messages[state.messageIndex]
		if not item then
			return
		end
		local expected, why = Rules.MessageVerdict(item.id)
		if decision ~= expected then
			state.score = math.max(0, state.score - 6)
			pulse(pad, Color3.fromRGB(255, 65, 70))
			message(remote, player, "Nie tym razem. " .. why, false)
			return
		end

		state.score += 20
		message(remote, player, why, true)
		state.messageIndex += 1
		refreshMessage()
		if state.messageIndex > #Rules.Messages then
			state.defenseStep = 3
			state.score += 20
			shield.Color = Color3.fromRGB(75, 175, 235)
			shieldLight.Color = shield.Color
			statusText.Text = "TARCZA 2/3\nPHISHING ZATRZYMANY"
			shieldStatusText.Text = "SHIELD\n2/3"
			mfaRack.Color = Color3.fromRGB(75, 175, 235)
			mfaRack.Material = Enum.Material.Neon
			attackStatusText.Text = "MFA\nREQUIRED"
			if blockPrompt then
				blockPrompt.Enabled = false
			end
			if allowPrompt then
				allowPrompt.Enabled = false
			end
			if takePrompt then
				takePrompt.Enabled = true
			end
			state.objective = "ETAP OBRONY 3/3 • Zabierz KLUCZ MFA i włóż go do zamka po prawej stronie twierdzy."
			hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
		end
	end

	blockPrompt = prompt(blockControl, "BLOKUJ", "Podejrzana wiadomość", function(p)
		if p == player then
			decide("BLOCK", blockPad)
		end
	end)
	blockPrompt.Enabled = false
	allowPrompt = prompt(allowControl, "PRZEPUŚĆ", "Bezpieczna wiadomość", function(p)
		if p == player then
			decide("ALLOW", allowPad)
		end
	end)
	allowPrompt.Enabled = false

	local mfaRack = part(
		model,
		"CyberMFAServiceRack",
		Vector3.new(8, 12, 7),
		origin + Vector3.new(40, 6, 24),
		Color3.fromRGB(42, 50, 62),
		Enum.Material.Metal
	)
	mfaRack.CanCollide = false
	mfaRack.CanTouch = false
	label(mfaRack, "MFA\nSERVICE")

	local keyPedestal = part(
		model,
		"MFAKeyPedestal",
		Vector3.new(16, 4, 14),
		origin + Vector3.new(-28, 3, 31),
		profile.surface,
		Enum.Material.DiamondPlate
	)
	local key = part(
		model,
		"MFAKey",
		Vector3.new(8, 3, 5),
		origin + Vector3.new(-28, 7, 31),
		Color3.fromRGB(90, 180, 255),
		Enum.Material.Neon
	)
	label(key, "KLUCZ MFA", Enum.NormalId.Top)
	glow(key, key.Color, 2.2, 14)
	local keyControl = part(
		model,
		"CyberMFAKeyControl",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(-28, 5, 23),
		Color3.fromRGB(65, 120, 175),
		Enum.Material.Metal
	)
	keyControl.CanCollide = false
	keyControl.CanTouch = false
	takePrompt = prompt(keyControl, "ZABIERZ", "Drugi czynnik", function(p)
		if p ~= player or state.done then
			return
		end
		if state.defenseStep < 3 then
			message(remote, player, "Klucz MFA odblokuje się po zatrzymaniu wiadomości phishingowych.", false)
			return
		end
		if state.mfaKey then
			return
		end
		state.mfaKey = true
		state.score += 10
		takePrompt.Enabled = false
		key.Transparency = 0.65
		key.CanCollide = false
		if lockPrompt then
			lockPrompt.Enabled = true
		end
		state.objective = "ETAP OBRONY 3/3 • Masz KLUCZ MFA. Włóż go do zamka po prawej stronie."
		hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
		message(remote, player, "Masz drugi czynnik. Samo hasło nie wystarczy już do wejścia na konto.", true)
	end)
	takePrompt.Enabled = false

	local mfaLock = part(
		model,
		"MFALock",
		Vector3.new(18, 13, 4),
		origin + Vector3.new(28, 8, 31),
		Color3.fromRGB(55, 65, 82),
		Enum.Material.Metal
	)
	local lockText = label(mfaLock, "ZAMEK MFA\nBRAK KLUCZA")
	local mfaConsole = part(
		model,
		"CyberMFALockConsole",
		Vector3.new(7, 5, 5),
		origin + Vector3.new(28, 4, 23),
		Color3.fromRGB(55, 75, 95),
		Enum.Material.Metal
	)
	mfaConsole.CanCollide = false
	mfaConsole.CanTouch = false
	lockPrompt = prompt(mfaConsole, "WŁÓŻ", "Klucz MFA", function(p)
		if p ~= player or state.done then
			return
		end
		if state.defenseStep < 3 then
			message(remote, player, "Najpierw ukończ skanowanie wiadomości.", false)
			return
		end
		if not state.mfaKey then
			message(remote, player, "Najpierw zabierz niebieski KLUCZ MFA z lewej strony.", false)
			return
		end

		state.score += 50
		state.done = true
		lockPrompt.Enabled = false
		mfaLock.Color = Color3.fromRGB(45, 220, 145)
		mfaLock.Material = Enum.Material.Neon
		lockText.Text = "MFA AKTYWNE\nDRUGI CZYNNIK DZIAŁA"
		shield.Color = Color3.fromRGB(55, 245, 155)
		shield.Material = Enum.Material.Neon
		shieldLight.Color = shield.Color
		shieldLight.Brightness = 4
		statusPanel.Color = Color3.fromRGB(35, 175, 105)
		statusText.Text = "TARCZA 3/3\nKONTO CHRONIONE"
		shieldStatusText.Text = "SHIELD\n3/3"
		shieldGenerator.Color = Color3.fromRGB(55, 245, 155)
		shieldGenerator.Material = Enum.Material.Neon
		mfaRack.Color = Color3.fromRGB(55, 245, 155)
		mfaRack.Material = Enum.Material.Neon
		attackStatusText.Text = "ATTACKS\nBLOCKED"
		attackStatusMonitor.Color = Color3.fromRGB(55, 245, 155)
		attackStatusMonitor.Material = Enum.Material.Neon
		TweenService:Create(shield, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(16, 16, 16),
		}):Play()

		for i = 1, 7 do
			task.delay((i - 1) * 0.12, function()
				if model.Parent and shield.Parent then
					local x = -28 + ((i - 1) % 4) * 18
					attackPacket(model, origin + Vector3.new(x, 8 + (i % 2) * 5, 66), shield, i)
				end
			end)
		end

		message(
			remote,
			player,
			"Twierdza działa: silne i unikalne hasło, czujność na phishing oraz drugi czynnik zatrzymały falę logowań.",
			true
		)
	end)
	lockPrompt.Enabled = false

	local armPrompt
	armPrompt = prompt(armStation, "UZBRÓJ", "Główny wyłącznik tarczy", function(p)
		if p ~= player or entryArmed or state.done then
			return
		end
		entryArmed = true
		armPrompt.Enabled = false
		armStation.Color = Color3.fromRGB(45, 205, 135)
		armStation.Material = Enum.Material.Neon
		armText.Text = "TARCZA\nARMED"
		alarmBeacon.Color = Color3.fromRGB(45, 220, 145)
		alarmLight.Color = alarmBeacon.Color
		alarmLight.Brightness = 1.7
		TweenService:Create(
			armHandle,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ CFrame = armHandleOn }
		):Play()
		for _, passwordPrompt in ipairs(passwordPrompts) do
			passwordPrompt.Enabled = true
		end
		state.objective =
			"ETAP OBRONY 1/3 • Tarcza uzbrojona. Włącz dokładnie 3 dobre moduły: długie, unikalne, menedżer."
		hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
		message(
			remote,
			player,
			"System uzbrojony. Wybierz 3 dobre nawyki hasła; słabe moduły dadzą czerwony błąd.",
			true
		)
	end)

	state.objective =
		"ETAP START • Użyj czerwonego WYŁĄCZNIKA TARCZY przy wejściu. Potem wybierz 3 dobre nawyki hasła."
	hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
	message(
		remote,
		player,
		"Zacznij od wyłącznika TARCZA OFF pod tablicą. Przykład: długie + unikalne + menedżer.",
		true
	)
end

return CyberDefenseFortress