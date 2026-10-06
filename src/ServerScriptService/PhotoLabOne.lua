local PhotoLabOne = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("PhotoLabRules"))
local VisualThemes = require(script.Parent:WaitForChild("VisualThemes"))

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

local function label(target, text, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 480)
	gui.LightInfluence = 0
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -24, 1, -20)
	txt.Position = UDim2.fromOffset(12, 10)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(238, 248, 255)
	txt.TextStrokeTransparency = 0.6
	txt.Parent = gui

	local c = Instance.new("UITextSizeConstraint")
	c.MinTextSize = 16
	c.MaxTextSize = 38
	c.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 13
	pr.HoldDuration = 0.05
	pr.RequiresLineOfSight = false
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function glow(target, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.5
	light.Range = range or 15
	light.Parent = target
	return light
end

local function tween(target, props, duration)
	local t = TweenService:Create(target, TweenInfo.new(duration or 0.45, Enum.EasingStyle.Quad), props)
	t:Play()
	return t
end

local function hud(remote, player, title, objective, score)
	remote:FireClient(player, {
		kind = "hud",
		title = title,
		objective = objective,
		score = score,
	})
end

local function message(remote, player, text, good)
	remote:FireClient(player, {
		kind = "message",
		text = text,
		good = good,
	})
end

local function localizedContrast(value)
	if value == "LOW" then
		return "NISKI"
	elseif value == "HIGH" then
		return "WYSOKI"
	end
	return "NORMALNY"
end

local function localizedOrientation(value)
	return value == "LANDSCAPE" and "POZIOM" or "PION"
end

local function localizedFrame(value)
	if value < 0 then
		return "LEWO"
	elseif value > 0 then
		return "PRAWO"
	end
	return "ŚRODEK"
end

function PhotoLabOne.Run(model, origin, player, lesson, mission, remote, state, accent)
	local profile = VisualThemes.Get(mission)
	local rules = Rules.NewState()
	local title = mission.name or "FotoLab I"

	local deck = part(
		model,
		"PhotoLabDeck",
		Vector3.new(98, 1, 120),
		origin + Vector3.new(0, 0.25, 8),
		Color3.fromRGB(15, 18, 23),
		Enum.Material.DiamondPlate
	)
	deck.CanCollide = true

	local darkroomWall = part(
		model,
		"PhotoBackdrop",
		Vector3.new(70, 28, 2),
		origin + Vector3.new(0, 14, 27),
		Color3.fromRGB(34, 46, 55),
		Enum.Material.SmoothPlastic
	)
	label(darkroomWall, "PLAN ZDJĘCIOWY", Enum.NormalId.Back)

	local missionBoard = part(
		model,
		"PhotoMissionBoard",
		Vector3.new(63, 13, 2),
		origin + Vector3.new(0, 10, -47),
		Color3.fromRGB(37, 48, 58),
		Enum.Material.Metal
	)
	local missionText = label(
		missionBoard,
		"FOTOLAB I • MISJA\nZrób czytelne zdjęcie DRONA + BEACONU.\nUstaw kadr, światło i kontrast."
	)
	glow(missionBoard, profile.accent, 1.2, 18)

	local entryReady = false
	local entryConsole = part(
		model,
		"PhotoEntryConsole",
		Vector3.new(16, 5, 8),
		origin + Vector3.new(0, 3, -43),
		Color3.fromRGB(54, 92, 122),
		Enum.Material.Metal
	)
	local entryText = label(entryConsole, "START SESJI\nAPARAT OFFLINE", Enum.NormalId.Top)
	entryConsole.CanCollide = false
	entryConsole.CanTouch = false
	glow(entryConsole, Color3.fromRGB(75, 170, 235), 1.1, 12)

	local instructionBoard = part(
		model,
		"PhotoInstructionBoard",
		Vector3.new(26, 10, 2),
		origin + Vector3.new(35, 8, -42),
		Color3.fromRGB(30, 42, 52),
		Enum.Material.Metal
	)
	label(
		instructionBoard,
		"CO ZROBIĆ\n1. START SESJI\n2. POZIOM + KADR ŚRODEK\n3. JASNOŚĆ +1 • KONTRAST NORMALNY\nPRZYKŁAD: POZIOM • ŚRODEK",
		Enum.NormalId.Front
	)
	glow(instructionBoard, Color3.fromRGB(75, 170, 235), 0.8, 12)

	local cameraBody = part(
		model,
		"PhotoCameraBody",
		Vector3.new(18, 12, 12),
		origin + Vector3.new(0, 8, -24),
		Color3.fromRGB(45, 50, 58),
		Enum.Material.Metal
	)
	label(cameraBody, "KAMERA\nLIVE", Enum.NormalId.Top)
	local lens = part(
		model,
		"PhotoCameraLens",
		Vector3.new(7, 7, 5),
		origin + Vector3.new(0, 8, -16),
		Color3.fromRGB(26, 37, 49),
		Enum.Material.Glass
	)
	lens.Shape = Enum.PartType.Cylinder
	lens.Orientation = Vector3.new(90, 0, 0)
	glow(lens, Color3.fromRGB(70, 160, 255), 1.2, 12)

	local cameraFlash = Instance.new("PointLight")
	cameraFlash.Name = "PhotoFlash"
	cameraFlash.Color = Color3.fromRGB(255, 250, 232)
	cameraFlash.Brightness = 0
	cameraFlash.Range = 50
	cameraFlash.Parent = cameraBody

	local droneBody = part(
		model,
		"PhotoDroneBody",
		Vector3.new(9, 3, 6),
		origin + Vector3.new(-5, 10, 15),
		Color3.fromRGB(236, 165, 65),
		Enum.Material.Metal
	)
	local droneEye = part(
		model,
		"PhotoDroneEye",
		Vector3.new(2, 2, 1),
		droneBody.Position + Vector3.new(0, 0, -3.3),
		Color3.fromRGB(75, 220, 255),
		Enum.Material.Neon
	)
	droneEye.CanCollide = false
	glow(droneEye, droneEye.Color, 1.3, 10)
	for _, side in ipairs({ -1, 1 }) do
		local arm = part(
			model,
			"PhotoDroneArm_" .. tostring(side),
			Vector3.new(9, 0.8, 1),
			droneBody.Position + Vector3.new(side * 7, 0, 0),
			Color3.fromRGB(95, 102, 110),
			Enum.Material.Metal
		)
		local rotor = part(
			model,
			"PhotoDroneRotor_" .. tostring(side),
			Vector3.new(7, 0.4, 7),
			arm.Position + Vector3.new(side * 4.4, 0.8, 0),
			Color3.fromRGB(55, 61, 68),
			Enum.Material.Metal
		)
		rotor.Shape = Enum.PartType.Cylinder
	end

	local beacon = part(
		model,
		"PhotoBeacon",
		Vector3.new(5, 9, 5),
		origin + Vector3.new(9, 5, 15),
		Color3.fromRGB(240, 82, 72),
		Enum.Material.Metal
	)
	local beaconTop = part(
		model,
		"PhotoBeaconLight",
		Vector3.new(4, 3, 4),
		beacon.Position + Vector3.new(0, 5.7, 0),
		Color3.fromRGB(255, 84, 74),
		Enum.Material.Neon
	)
	glow(beaconTop, beaconTop.Color, 1.8, 15)

	local ceilingLamp = part(
		model,
		"PhotoSceneLamp",
		Vector3.new(18, 1, 8),
		origin + Vector3.new(0, 24, 11),
		Color3.fromRGB(225, 230, 235),
		Enum.Material.Metal
	)
	local sceneLight = Instance.new("PointLight")
	sceneLight.Name = "PhotoSceneLight"
	sceneLight.Color = Color3.fromRGB(255, 232, 195)
	sceneLight.Brightness = 1.05
	sceneLight.Range = 44
	sceneLight.Shadows = true
	sceneLight.Parent = ceilingLamp

	local frameParts = {}
	local function makeFramePart(name)
		local p = part(
			model,
			"PhotoViewfinder_" .. name,
			Vector3.new(1, 1, 1),
			origin + Vector3.new(0, 9, -3),
			Color3.fromRGB(255, 214, 62),
			Enum.Material.Neon
		)
		p.CanCollide = false
		glow(p, p.Color, 0.55, 6)
		frameParts[name] = p
		return p
	end
	makeFramePart("Top")
	makeFramePart("Bottom")
	makeFramePart("Left")
	makeFramePart("Right")

	local framingStatus = part(
		model,
		"PhotoFramingStatus",
		Vector3.new(28, 9, 2),
		origin + Vector3.new(-31, 9, -5),
		Color3.fromRGB(37, 48, 58),
		Enum.Material.Metal
	)
	local framingText = label(framingStatus, "")

	local exposureStatus = part(
		model,
		"PhotoExposureStatus",
		Vector3.new(28, 9, 2),
		origin + Vector3.new(31, 9, -5),
		Color3.fromRGB(37, 48, 58),
		Enum.Material.Metal
	)
	local exposureText = label(exposureStatus, "")

	local function applyViewfinder()
		local landscape = rules.orientation == "LANDSCAPE"
		local width = landscape and 32 or 16
		local height = landscape and 15 or 25
		local cx = rules.frame * 7
		local cy = 10
		local z = -3

		frameParts.Top.Size = Vector3.new(width, 0.75, 0.7)
		frameParts.Bottom.Size = Vector3.new(width, 0.75, 0.7)
		frameParts.Left.Size = Vector3.new(0.75, height, 0.7)
		frameParts.Right.Size = Vector3.new(0.75, height, 0.7)
		frameParts.Top.Position = origin + Vector3.new(cx, cy + height / 2, z)
		frameParts.Bottom.Position = origin + Vector3.new(cx, cy - height / 2, z)
		frameParts.Left.Position = origin + Vector3.new(cx - width / 2, cy, z)
		frameParts.Right.Position = origin + Vector3.new(cx + width / 2, cy, z)
		framingText.Text = string.format(
			"VIZJER LIVE\n%s • KADR %s",
			localizedOrientation(rules.orientation),
			localizedFrame(rules.frame)
		)
	end

	local function applyExposure()
		sceneLight.Brightness = 0.55 + (rules.brightness + 2) * 0.55
		local tone = math.clamp(44 + (rules.brightness + 2) * 18, 44, 116)
		ceilingLamp.Color = Color3.fromRGB(tone + 80, tone + 75, tone + 60)
		exposureText.Text = string.format(
			"EKSPOZYCJA LIVE\nJASNOŚĆ %+d • KONTRAST %s",
			rules.brightness,
			localizedContrast(rules.contrast)
		)
	end

	local normalDrone = Color3.fromRGB(236, 165, 65)
	local function applyContrast()
		if rules.contrast == "LOW" then
			darkroomWall.Color = Color3.fromRGB(102, 108, 112)
			droneBody.Color = Color3.fromRGB(154, 158, 160)
			beacon.Color = Color3.fromRGB(158, 135, 132)
		elseif rules.contrast == "HIGH" then
			darkroomWall.Color = Color3.fromRGB(8, 10, 13)
			droneBody.Color = Color3.fromRGB(255, 148, 34)
			beacon.Color = Color3.fromRGB(255, 48, 40)
		else
			darkroomWall.Color = Color3.fromRGB(34, 46, 55)
			droneBody.Color = normalDrone
			beacon.Color = Color3.fromRGB(240, 82, 72)
		end
		applyExposure()
	end

	local orientationPanel = part(
		model,
		"PhotoOrientationPanel",
		Vector3.new(13, 4, 8),
		origin + Vector3.new(-30, 3, -25),
		Color3.fromRGB(73, 99, 122),
		Enum.Material.Metal
	)
	local orientationText = label(orientationPanel, "OBRÓĆ\nPION ↔ POZIOM", Enum.NormalId.Top)
	local orientationControl = part(
		model,
		"PhotoOrientationControl",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(-30, 2.5, -18),
		Color3.fromRGB(84, 180, 235),
		Enum.Material.Metal
	)
	orientationControl.CanCollide = false
	orientationControl.CanTouch = false

	local panLeftPanel = part(
		model,
		"PhotoPanLeftPanel",
		Vector3.new(10, 4, 8),
		origin + Vector3.new(-14, 3, -25),
		Color3.fromRGB(64, 75, 86),
		Enum.Material.Metal
	)
	label(panLeftPanel, "KADR\n←", Enum.NormalId.Top)
	local panLeft = part(
		model,
		"PhotoPanLeft",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(-14, 2.5, -18),
		Color3.fromRGB(72, 155, 225),
		Enum.Material.Metal
	)
	panLeft.CanCollide = false
	panLeft.CanTouch = false

	local panRightPanel = part(
		model,
		"PhotoPanRightPanel",
		Vector3.new(10, 4, 8),
		origin + Vector3.new(-2, 3, -25),
		Color3.fromRGB(64, 75, 86),
		Enum.Material.Metal
	)
	label(panRightPanel, "KADR\n→", Enum.NormalId.Top)
	local panRight = part(
		model,
		"PhotoPanRight",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(-2, 2.5, -18),
		Color3.fromRGB(72, 155, 225),
		Enum.Material.Metal
	)
	panRight.CanCollide = false
	panRight.CanTouch = false

	local darkerPanel = part(
		model,
		"PhotoDarkerPanel",
		Vector3.new(10, 4, 8),
		origin + Vector3.new(15, 3, -25),
		Color3.fromRGB(68, 69, 76),
		Enum.Material.Metal
	)
	label(darkerPanel, "ŚWIATŁO\n−", Enum.NormalId.Top)
	local darker = part(
		model,
		"PhotoDarker",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(15, 2.5, -18),
		Color3.fromRGB(92, 117, 140),
		Enum.Material.Metal
	)
	darker.CanCollide = false
	darker.CanTouch = false

	local brighterPanel = part(
		model,
		"PhotoBrighterPanel",
		Vector3.new(10, 4, 8),
		origin + Vector3.new(27, 3, -25),
		Color3.fromRGB(88, 84, 65),
		Enum.Material.Metal
	)
	label(brighterPanel, "ŚWIATŁO\n+", Enum.NormalId.Top)
	local brighter = part(
		model,
		"PhotoBrighter",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(27, 2.5, -18),
		Color3.fromRGB(232, 190, 76),
		Enum.Material.Metal
	)
	brighter.CanCollide = false
	brighter.CanTouch = false
	local contrastPanel = part(
		model,
		"PhotoContrastPanel",
		Vector3.new(12, 4, 8),
		origin + Vector3.new(40, 3, -25),
		Color3.fromRGB(77, 66, 90),
		Enum.Material.Metal
	)
	local contrastText = label(contrastPanel, "KONTRAST\nWYSOKI", Enum.NormalId.Top)
	local contrastDial = part(
		model,
		"PhotoContrastDial",
		Vector3.new(4, 3, 4),
		origin + Vector3.new(40, 2.5, -18),
		Color3.fromRGB(154, 104, 205),
		Enum.Material.Metal
	)
	contrastDial.CanCollide = false
	contrastDial.CanTouch = false

	local shutterPanel = part(
		model,
		"PhotoShutterPanel",
		Vector3.new(18, 5, 10),
		origin + Vector3.new(31, 3.5, 35),
		Color3.fromRGB(109, 48, 52),
		Enum.Material.Metal
	)
	local shutterText = label(shutterPanel, "MIGAWKA\nZRÓB ZDJĘCIE", Enum.NormalId.Top)
	local shutter = part(
		model,
		"PhotoShutter",
		Vector3.new(5, 3, 5),
		origin + Vector3.new(31, 2.8, 27),
		Color3.fromRGB(225, 72, 78),
		Enum.Material.Metal
	)
	shutter.CanCollide = false
	shutter.CanTouch = false

	local printer = part(
		model,
		"PhotoPrinter",
		Vector3.new(20, 9, 14),
		origin + Vector3.new(-30, 5, 35),
		Color3.fromRGB(48, 54, 61),
		Enum.Material.Metal
	)
	label(printer, "DRUKARKA\nFOTO", Enum.NormalId.Top)
	local photoPrint = part(
		model,
		"PhotoPrint",
		Vector3.new(15, 0.8, 11),
		printer.Position + Vector3.new(0, -1, -7),
		Color3.fromRGB(244, 244, 238),
		Enum.Material.SmoothPlastic
	)
	photoPrint.Transparency = 1
	photoPrint.CanCollide = false
	local printText = label(photoPrint, "UDANE UJĘCIE\nDRON + BEACON", Enum.NormalId.Top)

	local galleryGateL = part(
		model,
		"PhotoGalleryGateL",
		Vector3.new(10, 18, 3),
		origin + Vector3.new(-5, 9, 53),
		Color3.fromRGB(74, 75, 84),
		Enum.Material.Metal
	)
	local galleryGateR = part(
		model,
		"PhotoGalleryGateR",
		Vector3.new(10, 18, 3),
		origin + Vector3.new(5, 9, 53),
		Color3.fromRGB(74, 75, 84),
		Enum.Material.Metal
	)
	label(galleryGateL, "FOTO")
	label(galleryGateR, "LAB")

	local function refreshControls()
		local ready = Rules.Readiness(rules)
		if not entryReady then
			orientationControl.Material = Enum.Material.Metal
			panLeft.Material = Enum.Material.Metal
			panRight.Material = Enum.Material.Metal
			darker.Material = Enum.Material.Metal
			brighter.Material = Enum.Material.Metal
			contrastDial.Material = Enum.Material.Metal
			shutter.Material = Enum.Material.Metal
			shutter.Color = Color3.fromRGB(109, 48, 52)
			return
		end
		orientationControl.Material = rules.orientation == "LANDSCAPE" and Enum.Material.Neon or Enum.Material.Metal
		panLeft.Material = rules.frame < 0 and Enum.Material.Neon or Enum.Material.Metal
		panRight.Material = rules.frame > 0 and Enum.Material.Neon or Enum.Material.Metal
		darker.Material = rules.brightness > 1 and Enum.Material.Neon or Enum.Material.Metal
		brighter.Material = rules.brightness < 1 and Enum.Material.Neon or Enum.Material.Metal
		contrastDial.Material = rules.contrast == "NORMAL" and Enum.Material.Neon or Enum.Material.Metal
		shutter.Material = ready and Enum.Material.Neon or Enum.Material.Metal
		shutter.Color = ready and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(225, 72, 78)
	end

	local function objective()
		local ready, checks = Rules.Readiness(rules)
		refreshControls()
		if state.done then
			state.objective = "UDANE UJĘCIE • Odbitka gotowa. Przejdź przez otwarte studio."
		elseif not entryReady then
			state.objective = "ZACZNIJ TUTAJ • Podejdź do START SESJI i uruchom aparat."
		elseif not checks.orientation or not checks.frame then
			state.objective = string.format(
				"ETAP FOTO 1/3 • Zmieść DRONA i BEACON w wizjerze. %s • KADR %s",
				localizedOrientation(rules.orientation),
				localizedFrame(rules.frame)
			)
		elseif not checks.brightness or not checks.contrast then
			state.objective = string.format(
				"ETAP FOTO 2/3 • Ustaw czytelne światło. Jasność %+d • kontrast %s",
				rules.brightness,
				localizedContrast(rules.contrast)
			)
		elseif ready then
			state.objective = "ETAP FOTO 3/3 • Kadr wygląda dobrze. Naciśnij MIGAWKĘ."
		end
		hud(remote, player, title, state.objective, state.score)
	end

	local orientationPrompt = prompt(orientationControl, "Obróć aparat", "ORIENTACJA", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or not entryReady then
			return
		end
		local nextValue = rules.orientation == "PORTRAIT" and "LANDSCAPE" or "PORTRAIT"
		Rules.SetOrientation(rules, nextValue)
		orientationText.Text = "OBRÓĆ\n" .. localizedOrientation(nextValue)
		state.score += 2
		applyViewfinder()
		objective()
	end)

	local panLeftPrompt = prompt(panLeft, "Przesuń", "KADR W LEWO", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or not entryReady then
			return
		end
		Rules.SetFrame(rules, math.max(-1, rules.frame - 1))
		applyViewfinder()
		objective()
	end)

	local panRightPrompt = prompt(panRight, "Przesuń", "KADR W PRAWO", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or not entryReady then
			return
		end
		Rules.SetFrame(rules, math.min(1, rules.frame + 1))
		applyViewfinder()
		objective()
	end)

	local darkerPrompt = prompt(darker, "Przyciemnij", "EKSPOZYCJA", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or not entryReady then
			return
		end
		Rules.SetBrightness(rules, math.max(-2, rules.brightness - 1))
		applyExposure()
		objective()
	end)

	local brighterPrompt = prompt(brighter, "Rozjaśnij", "EKSPOZYCJA", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or not entryReady then
			return
		end
		Rules.SetBrightness(rules, math.min(2, rules.brightness + 1))
		applyExposure()
		objective()
	end)

	local contrastPrompt = prompt(contrastDial, "Obróć pokrętło", "KONTRAST", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or not entryReady then
			return
		end
		local nextValue
		if rules.contrast == "HIGH" then
			nextValue = "LOW"
		elseif rules.contrast == "LOW" then
			nextValue = "NORMAL"
		else
			nextValue = "HIGH"
		end
		Rules.SetContrast(rules, nextValue)
		contrastText.Text = "KONTRAST\n" .. localizedContrast(nextValue)
		applyContrast()
		objective()
	end)

	local shutterPrompt
	shutterPrompt = prompt(shutter, "Zrób zdjęcie", "MIGAWKA", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or not entryReady then
			return
		end
		local ok, result = Rules.Capture(rules)
		if not ok then
			state.score = math.max(0, state.score - 3)
			local checks = result.checks
			if not checks.orientation then
				message(
					remote,
					player,
					"Oba obiekty nie mieszczą się wygodnie w pionie. Spróbuj szerszej orientacji.",
					false
				)
			elseif not checks.frame then
				message(
					remote,
					player,
					"Jeden obiekt ucieka z wizjera. Przesuń kadr tak, aby oba znalazły się w środku.",
					false
				)
			elseif not checks.brightness then
				if rules.brightness < 1 then
					message(remote, player, "Zdjęcie jest za ciemne — szczegóły drona giną.", false)
				else
					message(
						remote,
						player,
						"Zdjęcie jest prześwietlone — jasne elementy tracą szczegóły.",
						false
					)
				end
			elseif not checks.contrast then
				message(
					remote,
					player,
					"Kontrast jest skrajny. Ustaw naturalniejszą różnicę między tłem a obiektami.",
					false
				)
			end
			shutter.Color = Color3.fromRGB(151, 50, 56)
			task.delay(0.3, function()
				if shutter.Parent and not state.done then
					shutter.Color = Color3.fromRGB(109, 48, 52)
				end
			end)
			objective()
			return
		end

		shutterPrompt.Enabled = false
		state.score += math.max(35, 60 - rules.mistakes * 4)
		cameraFlash.Brightness = 12
		missionText.Text = "BŁYSK!\nPRZETWARZANIE ZDJĘCIA..."
		task.delay(0.18, function()
			if cameraFlash.Parent then
				cameraFlash.Brightness = 0
			end
		end)

		task.spawn(function()
			task.wait(0.4)
			photoPrint.Transparency = 0
			printText.Text = "UDANE UJĘCIE\nDRON + BEACON"
			local printTween = tween(photoPrint, { Position = printer.Position + Vector3.new(0, 7, -8) }, 0.9)
			printTween.Completed:Wait()
			glow(photoPrint, Color3.fromRGB(255, 226, 132), 1, 13)
			tween(galleryGateL, {
				Position = galleryGateL.Position + Vector3.new(-10, 0, 0),
				Color = Color3.fromRGB(48, 183, 111),
			}, 0.8)
			local gateTween = tween(galleryGateR, {
				Position = galleryGateR.Position + Vector3.new(10, 0, 0),
				Color = Color3.fromRGB(48, 183, 111),
			}, 0.8)
			gateTween.Completed:Wait()
			state.done = true
			missionBoard.Color = Color3.fromRGB(38, 133, 84)
			missionText.Text = "FOTOLAB I ✓\nUDANE UJĘCIE • ODBITKA GOTOWA"
			shutter.Color = Color3.fromRGB(42, 172, 104)
			shutterText.Text = "MIGAWKA ✓\nZDJĘCIE GOTOWE"
			message(
				remote,
				player,
				"Udane zdjęcie! Dobra fotografia to nie maksymalne suwaki, tylko czytelny kadr i światło.",
				true
			)
			objective()
		end)
	end)

	local stagePrompts = {
		orientationPrompt,
		panLeftPrompt,
		panRightPrompt,
		darkerPrompt,
		brighterPrompt,
		contrastPrompt,
		shutterPrompt,
	}
	for _, stagePrompt in ipairs(stagePrompts) do
		stagePrompt.Enabled = false
	end

	local entryPrompt
	entryPrompt = prompt(entryConsole, "START SESJI", "FOTOLAB • START", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or entryReady then
			return
		end
		entryReady = true
		entryPrompt.Enabled = false
		entryConsole.Color = Color3.fromRGB(48, 190, 112)
		entryConsole.Material = Enum.Material.Neon
		entryText.Text = "SESJA AKTYWNA\nAPARAT ONLINE"
		for _, stagePrompt in ipairs(stagePrompts) do
			stagePrompt.Enabled = true
		end
		state.score += 5
		message(
			remote,
			player,
			"Aparat uruchomiony. Ustaw POZIOM, kadr ŚRODEK, jasność +1 i kontrast NORMALNY.",
			true
		)
		objective()
	end)

	applyViewfinder()
	applyContrast()
	objective()
end

return PhotoLabOne