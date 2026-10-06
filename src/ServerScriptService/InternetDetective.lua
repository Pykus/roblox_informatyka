local InternetDetective = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("DetectiveRules"))
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
	gui.Parent = target
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -24, 1, -20)
	txt.Position = UDim2.fromOffset(12, 10)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(246, 244, 236)
	txt.TextStrokeTransparency = 0.6
	txt.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16
	limit.MaxTextSize = 40
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 13
	pr.HoldDuration = 0.08
	pr.RequiresLineOfSight = false
	pr.Parent = target
	if callback then
		pr.Triggered:Connect(callback)
	end
	return pr
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
local function glow(target, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.4
	light.Range = range or 16
	light.Parent = target
	return light
end

local function cord(parent, name, a, b, color)
	local delta = b - a
	local center = (a + b) / 2
	local c = part(parent, name, Vector3.new(0.35, 0.35, delta.Magnitude), center, color, Enum.Material.Neon)
	c.CFrame = CFrame.lookAt(center, b)
	c.CanCollide = false
	return c
end

local function pulse(target, color)
	local old = target.Color
	target.Color = color
	TweenService:Create(target, TweenInfo.new(0.4), { Color = old }):Play()
end

local function evidenceColor(source)
	if source.reliable then
		return Color3.fromRGB(61, 139, 112)
	end
	return Color3.fromRGB(132, 69, 70)
end

function InternetDetective.Run(model, origin, player, lesson, mission, remote, state, accent)
	local profile = VisualThemes.Get(mission)
	accent = profile.accent
	state.detective = Rules.NewState()
	state.detectiveStage = 1
	local title = mission.name or lesson.topic

	local brief = part(
		model,
		"DetectiveBrief",
		Vector3.new(72, 11, 2),
		origin + Vector3.new(0, 9, -42),
		Color3.fromRGB(70, 55, 45),
		Enum.Material.Wood
	)
	brief.CanCollide = false
	label(
		brief,
		"INTERNETOWY DETEKTYW\nSPRAWDŹ 4 ŹRÓDŁA • ZABIERZ KARTY DOWODÓW • POŁĄCZ EVENT + DATĘ + MIASTO"
	)
	glow(brief, accent, 1.3, 18)

	local caseBoard = part(
		model,
		"CaseBoard",
		Vector3.new(56, 25, 2),
		origin + Vector3.new(0, 14, 45),
		Color3.fromRGB(104, 73, 46),
		Enum.Material.WoodPlanks
	)
	local boardTitle = label(caseBoard, "SPRAWA: GDZIE I KIEDY ODBYŁO SIĘ WYDARZENIE ZE ZDJĘCIA?")
	local slotCfg = {
		EVENT = { x = -18, text = "CO?\nEVENT" },
		DATE = { x = 0, text = "KIEDY?\nDATA" },
		CITY = { x = 18, text = "GDZIE?\nMIASTO" },
	}
	local slots = {}
	local slotTexts = {}
	local slotPrompts = {}
	for field, cfg in pairs(slotCfg) do
		local slot = part(
			model,
			"EvidenceSlot_" .. field,
			Vector3.new(15, 9, 1),
			origin + Vector3.new(cfg.x, 15, 43.7),
			Color3.fromRGB(77, 62, 49),
			Enum.Material.Wood
		)
		slot.CanCollide = false
		slots[field] = slot
		slotTexts[field] = label(slot, cfg.text)
	end

	local sourceLayout = {
		{ id = "SCHOOL", x = -27, z = -15, color = Color3.fromRGB(68, 105, 139) },
		{ id = "PHOTO", x = -9, z = 1, color = Color3.fromRGB(106, 94, 124) },
		{ id = "ARCHIVE", x = 9, z = 1, color = Color3.fromRGB(73, 117, 94) },
		{ id = "REPOST", x = 27, z = -15, color = Color3.fromRGB(123, 75, 76) },
	}
	local sourceStations = {}
	local sourcePrompts = {}
	local pickPrompts = {}
	local sourceCards = {}
	local sourceTexts = {}

	local scanner = part(
		model,
		"SourceScanner",
		Vector3.new(22, 8, 12),
		origin + Vector3.new(0, 5, -19),
		Color3.fromRGB(45, 54, 63),
		Enum.Material.Metal
	)
	local scannerText = label(scanner, "SKANER ŹRÓDEŁ\n0/4 SPRAWDZONE", Enum.NormalId.Top)
	glow(scanner, accent, 0.6, 12)
	local function refreshObjective()
		if state.detective.placedCount < 3 then
			state.objective = string.format(
				"ETAP ŚLEDZTWA 1/2 • Sprawdź wszystkie 4 źródła i połącz potwierdzone fakty z tablicą. Fakty: %d/3, źródła: %d/4.",
				state.detective.placedCount,
				state.detective.scannedCount
			)
		else
			state.detectiveStage = 2
			state.objective =
				"ETAP ŚLEDZTWA 2/2 • Wszystkie fakty są na tablicy. Sprawdź brakujące źródła i uruchom REKONSTRUKCJĘ."
		end
		hud(remote, player, title, state.objective, state.score)
	end

	for _, cfg in ipairs(sourceLayout) do
		local source = Rules.Sources[cfg.id]
		local station = part(
			model,
			"SourceStation_" .. cfg.id,
			Vector3.new(18, 10, 12),
			origin + Vector3.new(cfg.x, 6, cfg.z),
			cfg.color,
			Enum.Material.Metal
		)
		sourceStations[cfg.id] = station
		local stationText = label(station, source.label .. "\nNIEZBADANE", Enum.NormalId.Top)
		sourceTexts[cfg.id] = stationText
		local card = part(
			model,
			"EvidenceCard_" .. cfg.id,
			Vector3.new(11, 1, 7),
			station.Position + Vector3.new(0, 6.2, 0),
			Color3.fromRGB(95, 89, 78),
			Enum.Material.SmoothPlastic
		)
		card.CanCollide = false
		card.Transparency = 0.65
		label(card, "KARTA DOWODU", Enum.NormalId.Top)
		sourceCards[cfg.id] = card

		local pickPr = prompt(card, "ZABIERZ KARTĘ", source.label, function(p)
			if p ~= player then
				return
			end
			local ok, why = Rules.Pick(state.detective, cfg.id)
			if not ok then
				message(remote, player, why, false)
				return
			end
			card.Material = Enum.Material.Neon
			card.Color = accent
			message(
				remote,
				player,
				source.label .. ": karta dowodu w ręce. Podejdź do właściwego pola na tablicy.",
				true
			)
		end)
		pickPr.Enabled = false
		pickPrompts[cfg.id] = pickPr
		local scanPr
		scanPr = prompt(station, "SKANUJ", source.label, function(p)
			if p ~= player then
				return
			end
			local ok, result = Rules.Scan(state.detective, cfg.id)
			if not ok then
				message(remote, player, result, false)
				return
			end
			scanPr.Enabled = false
			pickPr.Enabled = true
			card.Transparency = 0
			card.Color = evidenceColor(result)
			station.Material = Enum.Material.Neon
			station.Color = evidenceColor(result)
			if result.reliable then
				stationText.Text = result.label .. "\n" .. result.value .. "\n" .. result.reason
				message(
					remote,
					player,
					result.label .. ": " .. result.reason .. ". To źródło daje użyteczną poszlakę.",
					true
				)
				state.score += 10
			else
				stationText.Text = result.label .. "\n" .. result.value .. "\nUWAGA: " .. result.reason
				message(
					remote,
					player,
					result.label .. ": " .. result.reason .. ". Traktuj tę informację ostrożnie.",
					false
				)
				state.score += 4
			end
			scannerText.Text = string.format("SKANER ŹRÓDEŁ\n%d/4 SPRAWDZONE", state.detective.scannedCount)
			refreshObjective()
		end)
		sourcePrompts[cfg.id] = scanPr
	end
	for field, slot in pairs(slots) do
		local pr
		pr = prompt(slot, "PRZYPINAM", field, function(p)
			if p ~= player then
				return
			end
			local ok, why, sourceId = Rules.Place(state.detective, field)
			if not ok then
				pulse(slot, Color3.fromRGB(210, 67, 67))
				message(remote, player, why, false)
				return
			end
			local source = Rules.Sources[sourceId]
			local card = sourceCards[sourceId]
			card.Material = Enum.Material.Neon
			card.Color = Color3.fromRGB(235, 191, 82)
			card.Position = slot.Position + Vector3.new(0, 0, -1)
			slot.Material = Enum.Material.Neon
			slot.Color = Color3.fromRGB(73, 142, 105)
			slotTexts[field].Text = field .. "\n" .. source.value .. "\n" .. source.label
			pickPrompts[sourceId].Enabled = false
			pr.Enabled = false
			state.score += 16
			cord(
				model,
				"Cord_" .. sourceId .. "_" .. field,
				sourceStations[sourceId].Position + Vector3.new(0, 5, 0),
				slot.Position,
				Color3.fromRGB(232, 75, 75)
			)
			message(remote, player, why .. " " .. source.value, true)
			refreshObjective()
		end)
		slotPrompts[field] = pr
	end
	local dropPad = part(
		model,
		"EvidenceDrop",
		Vector3.new(17, 2, 10),
		origin + Vector3.new(-28, 2, 28),
		Color3.fromRGB(76, 66, 60),
		Enum.Material.Metal
	)
	label(dropPad, "ODŁÓŻ KARTĘ", Enum.NormalId.Top)
	prompt(dropPad, "ODŁÓŻ", "Karta dowodu", function(p)
		if p ~= player or not state.detective.carrying then
			return
		end
		local sourceId = state.detective.carrying
		Rules.Drop(state.detective)
		sourceCards[sourceId].Material = Enum.Material.SmoothPlastic
		sourceCards[sourceId].Color = evidenceColor(Rules.Sources[sourceId])
		message(remote, player, "Karta odłożona. Możesz sprawdzić inną poszlakę.", true)
	end)

	local reconstruction = part(
		model,
		"ReconstructionConsole",
		Vector3.new(26, 11, 5),
		origin + Vector3.new(27, 8, 28),
		Color3.fromRGB(63, 55, 50),
		Enum.Material.Metal
	)
	local reconstructionText = label(reconstruction, "REKONSTRUKCJA\nOCZEKUJE NA DOWODY")
	local reconstructionPrompt
	reconstructionPrompt = prompt(reconstruction, "URUCHOM", "Rekonstrukcja sprawy", function(p)
		if p ~= player or state.done then
			return
		end
		local ok, result = Rules.Reconstruct(state.detective)
		if not ok then
			pulse(reconstruction, Color3.fromRGB(198, 65, 65))
			message(remote, player, result, false)
			return
		end

		reconstructionPrompt.Enabled = false
		state.score += 55
		state.done = true
		reconstruction.Material = Enum.Material.Neon
		reconstruction.Color = Color3.fromRGB(61, 183, 119)
		reconstructionText.Text =
			string.format("SPRAWA ROZWIĄZANA ✓\n%s • %s • %s", result.event, result.date, result.city)
		boardTitle.Text = string.format("REKONSTRUKCJA: %s\n%s • %s", result.event, result.date, result.city)
		caseBoard.Material = Enum.Material.Neon
		caseBoard.Color = Color3.fromRGB(91, 129, 104)
		glow(caseBoard, Color3.fromRGB(96, 232, 156), 3, 30)
		local finaleData = {
			{ label = "CO", value = result.event, x = -18 },
			{ label = "KIEDY", value = result.date, x = 0 },
			{ label = "GDZIE", value = result.city, x = 18 },
		}
		for _, item in ipairs(finaleData) do
			local holo = part(
				model,
				"CaseHologram_" .. item.label,
				Vector3.new(15, 10, 2),
				origin + Vector3.new(item.x, 10, 31),
				Color3.fromRGB(62, 176, 126),
				Enum.Material.Neon
			)
			holo.CanCollide = false
			label(holo, item.label .. "\n" .. item.value)
			glow(holo, Color3.fromRGB(99, 232, 166), 1.8, 18)
		end
		state.objective = "SPRAWA ROZWIĄZANA • Połączone źródła utworzyły jedną potwierdzoną rekonstrukcję."
		hud(remote, player, title, state.objective, state.score)
		message(
			remote,
			player,
			"Sprawa zamknięta. Najpewniejszy wniosek powstał z kilku niezależnych i sprawdzonych źródeł.",
			true
		)
	end)

	refreshObjective()
end

return InternetDetective