local FileWarehouse = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rules = require(script.Parent:WaitForChild("FileWarehouseRules"))

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
	gui.LightInfluence = 0.08
	gui.Parent = target
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -28, 1, -20)
	txt.Position = UDim2.fromOffset(14, 10)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.TextStrokeTransparency = 0.42
	txt.Parent = gui
	return txt
end

local function prompt(target, action, objectText, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = objectText
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.HoldDuration = 0.12
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function glow(target, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.5
	light.Range = range or 14
	light.Parent = target
	return light
end

local function floorMarker(parent, name, pos, color, text)
	local pad = part(parent, name, Vector3.new(14, 0.35, 8), pos, color, Enum.Material.Neon)
	pad.Transparency = 0.18
	label(pad, text, Enum.NormalId.Top)
	return pad
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

local function setSourceHidden(source)
	if not source then
		return
	end
	source:SetAttribute("Sorted", true)
	source.Transparency = 1
	source.CanCollide = false
	local pr = source:FindFirstChildOfClass("ProximityPrompt")
	if pr then
		pr.Enabled = false
	end
	local root = source.Parent
	if root then
		local semantic = root:FindFirstChild("Semantic_" .. source.Name)
		if semantic then
			semantic:Destroy()
		end
	end
end

local function followSemanticVisual(source)
	task.spawn(function()
		local root = source.Parent
		if not root then
			return
		end

		local semantic = nil
		for _ = 1, 100 do
			if not source.Parent then
				return
			end
			semantic = root:FindFirstChild("Semantic_" .. source.Name)
			if semantic then
				break
			end
			task.wait(0.05)
		end
		if not semantic then
			return
		end

		local pivot = semantic:GetPivot()
		local yOffset = pivot.Position.Y - source.Position.Y
		local rotationOffset = source.CFrame.Rotation:ToObjectSpace(pivot.Rotation)
		local offset = CFrame.new(0, yOffset, 0) * rotationOffset
		while source.Parent and semantic.Parent and not source:GetAttribute("Sorted") do
			semantic:PivotTo(source.CFrame * offset)
			RunService.Heartbeat:Wait()
		end
	end)
end

function FileWarehouse.Run(model, origin, player, lesson, mission, remote, state, accent)
	state.carry = nil
	state.source = nil
	state.sorted = 0
	state.scanCount = 0
	state.counts = {
		DOKUMENTY = 0,
		OBRAZY = 0,
		DANE = 0,
		KWARANTANNA = 0,
	}
	state.beltLights = {}
	local entryReady = false
	local packagePrompts = {}
	local packageSources = {}
	local scannerPrompt = nil
	local binPrompts = {}

	floorMarker(model, "StartMarker", origin + Vector3.new(0, 0.25, -36), accent, "START\nPACZKI")
	floorMarker(model, "ScanMarker", origin + Vector3.new(0, 0.25, 7), Color3.fromRGB(70, 180, 255), "2. SKANER")
	floorMarker(model, "SortMarker", origin + Vector3.new(0, 0.25, 34), Color3.fromRGB(80, 220, 135), "3. FOLDERY")

	local brief = part(
		model,
		"WarehouseBrief",
		Vector3.new(68, 10, 2),
		origin + Vector3.new(0, 8, -42),
		Color3.fromRGB(38, 42, 48),
		Enum.Material.Metal
	)
	label(brief, "MAGAZYN DANYCH\nPODNIES PACZKE -> SKANUJ -> ODKLADAJ DO WLASCIWEGO FOLDERU")
	glow(brief, accent, 1.2, 15)

	local entryConsole = part(
		model,
		"WarehouseEntryConsole",
		Vector3.new(16, 5, 6),
		origin + Vector3.new(0, 3, -35),
		Color3.fromRGB(48, 85, 118),
		Enum.Material.Metal
	)
	local entryText = label(entryConsole, "START SORTOWANIA\nLINIA OFFLINE", Enum.NormalId.Top)
	entryConsole.CanCollide = false
	entryConsole.CanTouch = false
	glow(entryConsole, Color3.fromRGB(70, 180, 255), 1.2, 12)

	local instructionBoard = part(
		model,
		"WarehouseInstructionBoard",
		Vector3.new(28, 10, 2),
		origin + Vector3.new(28, 8, -36),
		Color3.fromRGB(31, 42, 54),
		Enum.Material.Metal
	)
	label(
		instructionBoard,
		"CO ZROBIC\n1. START SORTOWANIA\n2. PODNIES PACZKE -> SKANUJ\n3. ODKLADAJ WG ROZSZERZENIA\nPRZYKLAD: .png -> OBRAZY • .exe -> KWARANTANNA"
	)
	glow(instructionBoard, Color3.fromRGB(70, 180, 255), 0.9, 12)

	local beltBase = part(
		model,
		"ConveyorBase",
		Vector3.new(68, 2.2, 24),
		origin + Vector3.new(0, 1.7, -17),
		Color3.fromRGB(48, 50, 54),
		Enum.Material.DiamondPlate
	)
	beltBase.CanCollide = true

	for i = 1, 6 do
		local x = -30 + (i - 1) * 12
		local strip = part(
			model,
			"ConveyorLight" .. i,
			Vector3.new(7, 0.25, 20),
			origin + Vector3.new(x, 2.9, -17),
			accent,
			Enum.Material.Neon
		)
		strip.Transparency = 0.28
		table.insert(state.beltLights, strip)
	end

	local scanner = part(
		model,
		"ExtensionScanner",
		Vector3.new(22, 12, 5),
		origin + Vector3.new(0, 6, 1),
		Color3.fromRGB(40, 48, 58),
		Enum.Material.Metal
	)
	local scannerPanel = part(
		model,
		"ScannerPanel",
		Vector3.new(16, 6, 1),
		scanner.Position + Vector3.new(0, 1, -3),
		Color3.fromRGB(45, 80, 100),
		Enum.Material.Glass
	)
	local scannerText = label(scannerPanel, "SKANER ROZSZERZEN\nBRAK PACZKI")
	local scannerLight = glow(scannerPanel, accent, 1.8, 18)

	local treeBoard = part(
		model,
		"FolderTree",
		Vector3.new(26, 15, 2),
		origin + Vector3.new(-27, 9, 43),
		Color3.fromRGB(28, 34, 42),
		Enum.Material.Metal
	)
	local treeText = label(treeBoard, "PROJEKT\n|- DOKUMENTY 0\n|- OBRAZY 0\n|- DANE 0\n|- KWARANTANNA 0")

	local archiveDoor = part(
		model,
		"ArchiveDoor",
		Vector3.new(34, 18, 4),
		origin + Vector3.new(0, 9, 48),
		Color3.fromRGB(120, 40, 35),
		Enum.Material.Metal
	)
	local archiveText = label(archiveDoor, "ARCHIWUM ZABLOKOWANE\nPOSEGREGUJ 5/5 PACZEK")
	local archiveLight = glow(archiveDoor, archiveDoor.Color, 1.1, 14)

	local packages = {}
	for i, cfg in ipairs(Rules.Packages) do
		packages[i] = {
			name = cfg.name,
			category = cfg.category,
			scanned = false,
			danger = cfg.danger,
		}
		local x = -26 + (i - 1) * 13
		local box = part(
			model,
			"DataPackage" .. i,
			Vector3.new(11, 5, 8),
			origin + Vector3.new(x, 5, -24),
			cfg.danger and Color3.fromRGB(220, 70, 55) or accent,
			Enum.Material.Neon
		)
		label(box, cfg.name, Enum.NormalId.Top)
		glow(box, box.Color, cfg.danger and 1.8 or 1.1, 10)
		TweenService:Create(
			box,
			TweenInfo.new(2.5 + i * 0.18, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
			{ Position = origin + Vector3.new(x, 5, -10) }
		):Play()
		followSemanticVisual(box)

		packageSources[i] = box
		local packagePrompt = prompt(box, "PODNIES", cfg.name, function(p)
			if p ~= player or state.done or not entryReady or box:GetAttribute("Sorted") then
				return
			end
			if state.carry then
				message(remote, player, "Najpierw zakoncz obsluge trzymanej paczki.", false)
				return
			end
			state.carry = packages[i]
			state.source = box
			box.Transparency = box:GetAttribute("SemanticAssetId") and 1 or 0.55
			state.carry.scanned = false
			hud(
				remote,
				player,
				mission.name or lesson.topic,
				"Masz " .. cfg.name .. ". Przejdz przez SKANER ROZSZERZEN.",
				state.score
			)
		end)
	end
	prompt(scanner, "SKANUJ", "ROZSZERZENIE PLIKU", function(p)
		if p ~= player or state.done then
			return
		end
		if not state.carry then
			message(remote, player, "Najpierw podnies paczke z tasmy.", false)
			return
		end
		local scan = Rules.Scan(state.carry.name)
		if not scan then
			message(remote, player, "Skaner nie rozpoznal paczki.", false)
			return
		end
		state.carry.scanned = true
		state.scanCount += 1
		state.score += 10
		if scan.danger then
			scannerPanel.Color = Color3.fromRGB(255, 60, 50)
			scannerLight.Color = scannerPanel.Color
			scannerText.Text = "ALARM: " .. state.carry.name .. "\nKONCOWE " .. scan.extension .. " -> " .. scan.hint
			message(remote, player, "Uwaga! Koncowe rozszerzenie to .exe. To nie jest zwykle zdjecie.", false)
		else
			scannerPanel.Color = Color3.fromRGB(55, 225, 135)
			scannerLight.Color = scannerPanel.Color
			scannerText.Text = state.carry.name .. "\n" .. scan.extension .. " -> " .. scan.hint
			message(remote, player, "Skan zakonczony. Teraz wybierz folder docelowy.", true)
		end
		hud(
			remote,
			player,
			mission.name or lesson.topic,
			"Przeskanowano " .. state.carry.name .. ". Odloz do wlasciwego folderu.",
			state.score
		)
	end)

	local function updateFolderTree()
		treeText.Text = string.format(
			"PROJEKT\n|- DOKUMENTY %d\n|- OBRAZY %d\n|- DANE %d\n|- KWARANTANNA %d",
			state.counts.DOKUMENTY,
			state.counts.OBRAZY,
			state.counts.DANE,
			state.counts.KWARANTANNA
		)
	end

	local function finishWarehouse()
		state.done = true
		state.score += 100
		archiveDoor.Color = Color3.fromRGB(50, 230, 120)
		archiveDoor.Material = Enum.Material.Neon
		archiveLight.Color = archiveDoor.Color
		archiveText.Text = "ARCHIWUM ONLINE\nSTRUKTURA FOLDEROW GOTOWA"
		for _, strip in ipairs(state.beltLights) do
			strip.Color = Color3.fromRGB(50, 230, 120)
		end
		local target = archiveDoor.Position + Vector3.new(0, 18, 0)
		local tween = TweenService:Create(
			archiveDoor,
			TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = target, Transparency = 0.18 }
		)
		tween:Play()
		task.delay(1.15, function()
			if archiveDoor.Parent then
				archiveDoor.CanCollide = false
			end
		end)
		message(remote, player, "Magazyn uporzadkowany. Drzwi archiwum otwarte — przejdz do RDZENIA MISJI.", true)
	end

	for i, binName in ipairs(Rules.Bins) do
		local x = -27 + (i - 1) * 18
		local isQuarantine = binName == "KWARANTANNA"
		local bin = part(
			model,
			"WarehouseFolderCabinet_" .. i,
			Vector3.new(15, 8, 12),
			origin + Vector3.new(x, 4, 22),
			isQuarantine and Color3.fromRGB(130, 45, 40) or Color3.fromRGB(55, 65, 78),
			Enum.Material.Metal
		)
		label(bin, binName, Enum.NormalId.Top)
		local binStatus = part(
			model,
			"FolderBinStatus" .. i,
			Vector3.new(10, 0.7, 2),
			bin.Position + Vector3.new(0, 4.6, 0),
			isQuarantine and Color3.fromRGB(180, 55, 45) or Color3.fromRGB(85, 100, 118),
			Enum.Material.Metal
		)
		binStatus.CanCollide = false
		binStatus.CanTouch = false
		prompt(bin, "ODLOZ", binName, function(p)
			if p ~= player or state.done then
				return
			end
			if not state.carry then
				message(remote, player, "Najpierw podnies paczke.", false)
				return
			end
			if not state.carry.scanned then
				message(remote, player, "Najpierw zeskanuj rozszerzenie paczki.", false)
				return
			end

			local ok, expected, danger = Rules.Route(state.carry.name, binName)
			if not ok then
				state.score = math.max(0, state.score - 10)
				message(
					remote,
					player,
					"Zly folder. " .. state.carry.name .. " nie nalezy do " .. binName .. ". Sprobuj ponownie.",
					false
				)
				return
			end

			local sortedName = state.carry.name
			setSourceHidden(state.source)
			state.sorted += 1
			state.counts[expected] += 1
			state.score += danger and 60 or 35
			state.carry = nil
			state.source = nil
			bin.Color = isQuarantine and Color3.fromRGB(255, 95, 70) or accent
			bin.Material = Enum.Material.Neon
			binStatus.Color = isQuarantine and Color3.fromRGB(255, 95, 70) or accent
			binStatus.Material = Enum.Material.Neon
			glow(binStatus, binStatus.Color, 1.2, 10)
			updateFolderTree()
			message(
				remote,
				player,
				(
					sortedName == "wakacje.jpg.exe" and "Pulapka wykryta i odizolowana!"
					or "Dobrze: " .. sortedName .. " -> " .. binName
				),
				true
			)
			if state.sorted >= #Rules.Packages then
				finishWarehouse()
			else
				hud(
					remote,
					player,
					mission.name or lesson.topic,
					string.format("Posegregowano %d/%d. Wez kolejna paczke z tasmy.", state.sorted, #Rules.Packages),
					state.score
				)
			end
		end)
	end

	hud(
		remote,
		player,
		mission.name or lesson.topic,
		"Podnies paczke z tasmy, zeskanuj rozszerzenie i odloz do wlasciwego folderu.",
		state.score
	)
end

return FileWarehouse