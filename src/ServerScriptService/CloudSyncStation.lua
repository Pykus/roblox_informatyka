local CloudSyncStation = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("CloudSyncRules"))
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
	gui.Brightness = 1.15
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -36, 1, -28)
	txt.Position = UDim2.fromOffset(18, 14)
	txt.BackgroundColor3 = Color3.fromRGB(10, 16, 25)
	txt.BackgroundTransparency = 0.12
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(245, 250, 255)
	txt.TextStrokeTransparency = 0.6
	txt.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = txt

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 16
	constraint.MaxTextSize = 44
	constraint.Parent = txt
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
	light.Brightness = brightness or 1.5
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

local function packet(model, fromPos, toPos, color, name)
	local p = part(model, name or "DataPacket", Vector3.new(2.5, 2.5, 2.5), fromPos, color, Enum.Material.Neon)
	p.Shape = Enum.PartType.Ball
	p.CanCollide = false
	glow(p, color, 2.2, 13)
	TweenService:Create(p, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = toPos,
		Size = Vector3.new(1.2, 1.2, 1.2),
	}):Play()
	task.delay(0.95, function()
		if p.Parent then
			p:Destroy()
		end
	end)
end

local function pulse(target, color)
	local original = target.Color
	target.Color = color
	TweenService:Create(target, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Color = original,
	}):Play()
end
function CloudSyncStation.Run(model, origin, player, lesson, mission, remote, state, accent)
	local profile = VisualThemes.Get(mission)
	accent = profile.accent

	state.cloudStep = 1
	state.cloudVersion = nil
	state.deviceVersions = {
		LAPTOP = 3,
		TABLET = 1,
	}

	local brief = part(
		model,
		"CloudBrief",
		Vector3.new(70, 10, 2),
		origin + Vector3.new(0, 8, -42),
		profile.surface2,
		profile.structureMaterial
	)
	label(
		brief,
		"STACJA SYNCHRONIZACJI\n1. WYŚLIJ NAJNOWSZĄ WERSJĘ   2. ZSYNCHRONIZUJ DRUGIE URZĄDZENIE   3. UDOSTĘPNIJ BEZPIECZNIE"
	)
	glow(brief, accent, 1.2, 16)

	local cloudBase = part(
		model,
		"CloudPedestal",
		Vector3.new(24, 3, 20),
		origin + Vector3.new(0, 2, 18),
		profile.surface,
		Enum.Material.DiamondPlate
	)
	cloudBase.CanCollide = true

	local cloudOrb = part(
		model,
		"CloudCore",
		Vector3.new(10, 10, 10),
		origin + Vector3.new(0, 13, 18),
		Color3.fromRGB(85, 125, 155),
		Enum.Material.Glass
	)
	cloudOrb.Shape = Enum.PartType.Ball
	cloudOrb.Transparency = 0.16
	local cloudLight = glow(cloudOrb, accent, 2.2, 24)

	local cloudPanel = part(
		model,
		"CloudPanel",
		Vector3.new(19, 8, 1),
		origin + Vector3.new(0, 8, 7),
		Color3.fromRGB(45, 58, 72),
		Enum.Material.Glass
	)
	local cloudText = label(cloudPanel, "CHMURA\nBRAK PLIKU")

	local pathLeft = part(
		model,
		"SyncPathLaptop",
		Vector3.new(24, 0.35, 2),
		origin + Vector3.new(-16, 1.4, 4),
		accent,
		Enum.Material.Neon
	)
	pathLeft.Transparency = 0.45
	local pathRight = part(
		model,
		"SyncPathTablet",
		Vector3.new(24, 0.35, 2),
		origin + Vector3.new(16, 1.4, 4),
		profile.accent2,
		Enum.Material.Neon
	)
	pathRight.Transparency = 0.45

	local devices = {}
	local deviceCfg = {
		{
			id = "LAPTOP",
			x = -27,
			title = "LAPTOP",
			color = accent,
		},
		{
			id = "TABLET",
			x = 27,
			title = "TABLET",
			color = profile.accent2,
		},
	}

	for _, cfg in ipairs(deviceCfg) do
		local shell = part(
			model,
			cfg.id .. "Shell",
			Vector3.new(23, 4, 18),
			origin + Vector3.new(cfg.x, 3, -10),
			profile.surface,
			Enum.Material.Metal
		)
		local screen = part(
			model,
			cfg.id .. "Screen",
			Vector3.new(19, 10, 1),
			origin + Vector3.new(cfg.x, 10, -1),
			Color3.fromRGB(35, 48, 62),
			Enum.Material.Glass
		)
		local txt =
			label(screen, string.format("%s\nPREZENTACJA v%d\nLOKALNIE", cfg.title, state.deviceVersions[cfg.id]))
		glow(screen, cfg.color, 1.3, 14)

		local uploadPosition = cfg.id == "LAPTOP" and origin + Vector3.new(-10, 1.3, -43)
			or origin + Vector3.new(cfg.x - 6, 1.3, -22)
		local upload =
			part(model, cfg.id .. "UploadPad", Vector3.new(10, 1, 8), uploadPosition, cfg.color, Enum.Material.Neon)
		label(upload, cfg.id == "LAPTOP" and "UPLOAD v3" or "UPLOAD", Enum.NormalId.Top)

		local download = part(
			model,
			cfg.id .. "DownloadPad",
			Vector3.new(10, 1, 8),
			origin + Vector3.new(cfg.x + 6, 1.3, -22),
			Color3.fromRGB(85, 100, 120),
			Enum.Material.Neon
		)
		label(download, "SYNC", Enum.NormalId.Top)

		local uploadControl = part(
			model,
			"CloudUploadControl_" .. cfg.id,
			Vector3.new(4, 3, 4),
			upload.Position + Vector3.new(0, 3, 0),
			cfg.color,
			Enum.Material.Metal
		)
		uploadControl.CanCollide = false
		uploadControl.CanTouch = false
		local downloadControl = part(
			model,
			"CloudDownloadControl_" .. cfg.id,
			Vector3.new(4, 3, 4),
			download.Position + Vector3.new(0, 3, 0),
			Color3.fromRGB(100, 130, 165),
			Enum.Material.Metal
		)
		downloadControl.CanCollide = false
		downloadControl.CanTouch = false

		devices[cfg.id] = {
			shell = shell,
			screen = screen,
			text = txt,
			upload = upload,
			download = download,
			uploadControl = uploadControl,
			downloadControl = downloadControl,
			color = cfg.color,
		}
	end
	local uploadPrompts = {}
	local downloadPrompts = {}
	local sharePrompts = {}

	local function setAllPrompts(promptMap, enabled)
		for _, pr in pairs(promptMap) do
			pr.Enabled = enabled
		end
	end

	local function refreshDevice(deviceId, suffix)
		local device = devices[deviceId]
		local version = state.deviceVersions[deviceId]
		device.text.Text = string.format("%s\nPREZENTACJA v%d\n%s", deviceId, version, suffix or "LOKALNIE")
	end

	local function attemptUpload(deviceId)
		if state.done then
			return
		end
		if state.cloudStep ~= 1 then
			message(remote, player, "Plik jest już w chmurze. Teraz zsynchronizuj starsze urządzenie.", false)
			return
		end

		local device = devices[deviceId]
		if not Rules.CanUpload(deviceId) then
			state.score = math.max(0, state.score - 8)
			pulse(device.uploadControl, Color3.fromRGB(255, 70, 60))
			message(
				remote,
				player,
				"To starsza wersja v1. Wysłanie jej mogłoby zastąpić nowszą pracę. Znajdź urządzenie z v3.",
				false
			)
			return
		end

		state.cloudVersion = state.deviceVersions[deviceId]
		state.cloudStep = 2
		setAllPrompts(uploadPrompts, false)
		setAllPrompts(downloadPrompts, false)
		if downloadPrompts.TABLET then
			downloadPrompts.TABLET.Enabled = true
		end
		state.score += 45
		packet(model, device.screen.Position, cloudOrb.Position, device.color, "UploadPacket")
		cloudPanel.Color = Color3.fromRGB(65, 145, 225)
		cloudText.Text = string.format("CHMURA\nPREZENTACJA v%d\nNAJNOWSZA WERSJA", state.cloudVersion)
		refreshDevice(deviceId, "WYSŁANO DO CHMURY")
		device.uploadControl.Color = Color3.fromRGB(55, 220, 130)
		device.uploadControl.Material = Enum.Material.Neon
		message(remote, player, "Dobrze. Najnowsza wersja v3 jest w chmurze. Teraz zaktualizuj tablet.", true)
		state.objective = "ETAP CHMURY 2/3 • Na tablecie jest v1. Pobierz z chmury wersję v3."
		hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
	end

	local function attemptDownload(deviceId)
		if state.done then
			return
		end
		if state.cloudStep == 1 then
			message(remote, player, "Najpierw wyślij do chmury najnowszą wersję pliku.", false)
			return
		end
		if state.cloudStep > 2 then
			message(
				remote,
				player,
				"Urządzenia są już zsynchronizowane. Ustaw teraz bezpieczne udostępnianie.",
				false
			)
			return
		end

		local current = state.deviceVersions[deviceId]
		if not Rules.CanDownload(state.cloudVersion, current) then
			state.score = math.max(0, state.score - 5)
			pulse(devices[deviceId].downloadControl, Color3.fromRGB(255, 95, 65))
			message(
				remote,
				player,
				string.format("%s ma już wersję v%d. Nie potrzebuje pobierania.", deviceId, current),
				false
			)
			return
		end

		state.deviceVersions[deviceId] = state.cloudVersion
		state.cloudStep = 3
		setAllPrompts(uploadPrompts, false)
		setAllPrompts(downloadPrompts, false)
		setAllPrompts(sharePrompts, true)
		state.score += 50
		packet(model, cloudOrb.Position, devices[deviceId].screen.Position, devices[deviceId].color, "DownloadPacket")
		devices[deviceId].screen.Color = Color3.fromRGB(55, 180, 125)
		devices[deviceId].downloadControl.Color = Color3.fromRGB(55, 220, 130)
		devices[deviceId].downloadControl.Material = Enum.Material.Neon
		refreshDevice(deviceId, "ZSYNCHRONIZOWANO")
		message(remote, player, "Tablet ma teraz tę samą wersję v3. Zostało bezpieczne udostępnienie.", true)
		state.objective = "ETAP CHMURY 3/3 • Wybierz sposób udostępnienia pliku."
		hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
	end

	for deviceId, device in pairs(devices) do
		uploadPrompts[deviceId] = prompt(device.uploadControl, "WYŚLIJ", deviceId .. " -> CHMURA", function(p)
			if p == player then
				attemptUpload(deviceId)
			end
		end)
		downloadPrompts[deviceId] = prompt(device.downloadControl, "POBIERZ", "CHMURA -> " .. deviceId, function(p)
			if p == player then
				attemptDownload(deviceId)
			end
		end)
	end
	setAllPrompts(uploadPrompts, false)
	setAllPrompts(downloadPrompts, false)
	uploadPrompts.LAPTOP.Enabled = true

	local shareBoard = part(
		model,
		"ShareBoard",
		Vector3.new(66, 8, 2),
		origin + Vector3.new(0, 7, 34),
		profile.surface2,
		profile.structureMaterial
	)
	label(shareBoard, "UDOSTĘPNIANIE\nKOMU NAPRAWDĘ POTRZEBNY JEST DOSTĘP?")
	for i, mode in ipairs(Rules.ShareModes) do
		local x = ({ -23, 0, 23 })[i]
		local pad = part(
			model,
			"ShareMode" .. mode.id,
			Vector3.new(19, 2, 14),
			origin + Vector3.new(x, 2, 46),
			mode.safe and Color3.fromRGB(55, 175, 120) or Color3.fromRGB(90, 75, 75),
			Enum.Material.Neon
		)
		label(pad, mode.label, Enum.NormalId.Top)
		local shareControl = part(
			model,
			"CloudShareControl_" .. mode.id,
			Vector3.new(5, 3, 5),
			pad.Position + Vector3.new(0, 3.6, 0),
			mode.safe and Color3.fromRGB(65, 205, 135) or Color3.fromRGB(145, 95, 95),
			Enum.Material.Metal
		)
		shareControl.CanCollide = false
		shareControl.CanTouch = false
		sharePrompts[mode.id] = prompt(shareControl, "WYBIERZ", mode.label, function(p)
			if p ~= player or state.done then
				return
			end
			if state.cloudStep < 3 then
				message(remote, player, "Najpierw zsynchronizuj plik na obu urządzeniach.", false)
				return
			end

			if not Rules.IsSafeShare(mode.id) then
				state.score = math.max(0, state.score - 8)
				pulse(shareControl, Color3.fromRGB(255, 70, 60))
				if mode.id == "PUBLIC" then
					message(
						remote,
						player,
						"Publiczny link daje dostęp każdemu, kto go zdobędzie. To za szerokie uprawnienie.",
						false
					)
				else
					message(
						remote,
						player,
						"Hasło w nazwie pliku nie chroni danych. Wybierz kontrolę dostępu dla konkretnych osób.",
						false
					)
				end
				return
			end

			state.score += 65
			state.done = true
			shareControl.Color = Color3.fromRGB(55, 245, 150)
			shareControl.Material = Enum.Material.Neon
			cloudOrb.Color = Color3.fromRGB(55, 245, 150)
			cloudOrb.Material = Enum.Material.Neon
			cloudLight.Color = cloudOrb.Color
			cloudLight.Brightness = 4
			cloudPanel.Color = Color3.fromRGB(45, 215, 135)
			cloudText.Text = "CHMURA GOTOWA\nv3 NA OBU URZĄDZENIACH\nDOSTĘP: WSKAZANE OSOBY"
			TweenService:Create(
				cloudOrb,
				TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = Vector3.new(15, 15, 15) }
			):Play()
			packet(model, devices.LAPTOP.screen.Position, cloudOrb.Position, accent, "FinalPacketA")
			packet(model, devices.TABLET.screen.Position, cloudOrb.Position, profile.accent2, "FinalPacketB")
			message(
				remote,
				player,
				"Synchronizacja zakończona: najnowsza wersja jest wszędzie, a dostęp mają tylko wskazane osoby.",
				true
			)
		end)
		sharePrompts[mode.id].Enabled = false
	end

	state.objective = "ETAP CHMURY 1/3 • Przy wejściu użyj UPLOAD v3 z laptopa. Potem zsynchronizujesz tablet."
	hud(remote, player, mission.name or lesson.topic, state.objective, state.score)
end

return CloudSyncStation