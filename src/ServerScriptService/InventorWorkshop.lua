local InventorWorkshop = {}

local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent:WaitForChild("InventorWorkshopRules"))
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
	txt.TextColor3 = Color3.fromRGB(236, 248, 255)
	txt.TextStrokeTransparency = 0.6
	txt.Parent = gui

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 16
	constraint.MaxTextSize = 38
	constraint.Parent = txt
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

local function flash(target, color, restore)
	target.Color = color
	task.delay(0.45, function()
		if target.Parent then
			target.Color = restore
		end
	end)
end

function InventorWorkshop.Run(model, origin, player, lesson, mission, remote, state, accent)
	local profile = VisualThemes.Get(mission)
	local rules = Rules.NewState()
	local title = mission.name or "Cyfrowe urządzenia"
	state.inventorEntryReady = false

	local deck = part(
		model,
		"InventorWorkshopDeck",
		Vector3.new(96, 1, 118),
		origin + Vector3.new(0, 0.25, 9),
		profile.floor,
		profile.floorMaterial
	)
	deck.CanCollide = true

	local board = part(
		model,
		"InventorStatusBoard",
		Vector3.new(64, 14, 2),
		origin + Vector3.new(0, 10, -47),
		profile.surface2,
		profile.structureMaterial
	)
	local boardText = label(board, "WARSZTAT WYNALAZCY\nNAJPIERW URUCHOM START MONTAŻU")
	glow(board, profile.accent, 1.3, 20)

	local entryConsole = part(
		model,
		"InventorEntryConsole",
		Vector3.new(12, 5, 7),
		origin + Vector3.new(0, 3.5, -43),
		Color3.fromRGB(67, 132, 185),
		Enum.Material.Metal
	)
	entryConsole.CanCollide = false
	local entryText = label(entryConsole, "START\nMONTAŻU", Enum.NormalId.Front)
	glow(entryConsole, Color3.fromRGB(86, 200, 255), 1.2, 14)

	local instructionBoard = part(
		model,
		"InventorInstructionBoard",
		Vector3.new(34, 9, 2),
		origin + Vector3.new(18, 9, -39),
		Color3.fromRGB(35, 48, 62),
		Enum.Material.Metal
	)
	instructionBoard.CanCollide = false
	label(
		instructionBoard,
		"PLAN\n1. START MONTAŻU\n2. WYBIERZ: SENSOR + STEROWNIK + SILNIK\n3. ZAMONTUJ: WEJŚCIE → PRZETWARZANIE → WYJŚCIE\n4. POŁĄCZ I TESTUJ"
	)
	glow(instructionBoard, Color3.fromRGB(90, 185, 235), 1.0, 13)

	local gateLeft = part(
		model,
		"InventorGateLeft",
		Vector3.new(10, 18, 3),
		origin + Vector3.new(-5, 9, 49),
		profile.surface,
		profile.structureMaterial
	)
	local gateRight = part(
		model,
		"InventorGateRight",
		Vector3.new(10, 18, 3),
		origin + Vector3.new(5, 9, 49),
		profile.surface,
		profile.structureMaterial
	)
	label(gateLeft, "BRAMA")
	label(gateRight, "LOCK")

	local rack = part(
		model,
		"InventorComponentRack",
		Vector3.new(20, 11, 64),
		origin + Vector3.new(-35, 6, -3),
		profile.surface2,
		profile.structureMaterial
	)
	label(rack, "MAGAZYN\nMODUŁÓW", Enum.NormalId.Right)

	local componentSpecs = {
		{ id = "MOTION_SENSOR", label = "SENSOR\nRUCHU", color = Color3.fromRGB(255, 181, 61) },
		{ id = "CONTROLLER", label = "STEROWNIK", color = Color3.fromRGB(65, 151, 255) },
		{ id = "MOTOR", label = "SILNIK", color = Color3.fromRGB(72, 220, 137) },
		{ id = "BATTERY", label = "AKUMULATOR", color = Color3.fromRGB(205, 95, 75) },
		{ id = "STORAGE", label = "PAMIĘĆ", color = Color3.fromRGB(174, 91, 220) },
		{ id = "ANTENNA", label = "ANTENA", color = Color3.fromRGB(76, 205, 214) },
	}

	local components = {}
	local selectedModule = nil
	local selectedPart = nil

	for i, spec in ipairs(componentSpecs) do
		local z = -29 + (i - 1) * 10.5
		local item = part(
			model,
			"InventorComponent_" .. spec.id,
			Vector3.new(13, 4, 8),
			origin + Vector3.new(-31, 3.2, z),
			spec.color,
			Enum.Material.Metal
		)
		local itemText = label(item, spec.label, Enum.NormalId.Top)
		local selectControl = part(
			model,
			"InventorModuleControl_" .. spec.id,
			Vector3.new(4, 2.4, 4),
			item.Position + Vector3.new(0, 2.2, -5.2),
			spec.color,
			Enum.Material.Metal
		)
		selectControl.CanCollide = false
		selectControl.CanTouch = false
		local itemPrompt
		itemPrompt = prompt(selectControl, "Wybierz", spec.label:gsub("\n", " "), function(triggeringPlayer)
			if triggeringPlayer ~= player or rules.stage ~= 1 or item:GetAttribute("Installed") then
				return
			end
			if selectedPart and selectedPart.Parent then
				local old = components[selectedModule]
				selectedPart.Material = Enum.Material.Metal
				selectedPart.Color = old.spec.color
				old.text.Text = old.spec.label
			end
			selectedModule = spec.id
			selectedPart = item
			item.Material = Enum.Material.Neon
			item.Color = Color3.fromRGB(245, 245, 255)
			itemText.Text = spec.label .. "\nWYBRANO"
			message(
				remote,
				player,
				"Wybrano moduł: " .. spec.label:gsub("\n", " ") .. ". Podejdź do właściwego gniazda.",
				true
			)
		end)
		itemPrompt.Enabled = false
		components[spec.id] = {
			part = item,
			control = selectControl,
			text = itemText,
			prompt = itemPrompt,
			spec = spec,
		}
	end

	local slotSpecs = {
		INPUT = {
			label = "WEJŚCIE",
			hint = "WEJŚCIE ma odebrać informację z otoczenia.",
			z = -12,
		},
		PROCESSOR = {
			label = "PRZETWARZANIE",
			hint = "PRZETWARZANIE ma podjąć decyzję na podstawie sygnału.",
			z = 8,
		},
		OUTPUT = {
			label = "WYJŚCIE",
			hint = "WYJŚCIE ma wykonać fizyczne działanie.",
			z = 28,
		},
	}
	local slots = {}
	local installedVisuals = {}

	for slotId, spec in pairs(slotSpecs) do
		local socket = part(
			model,
			"InventorSlot_" .. slotId,
			Vector3.new(18, 3, 14),
			origin + Vector3.new(0, 2, spec.z),
			Color3.fromRGB(58, 66, 77),
			Enum.Material.Metal
		)
		local socketText = label(socket, spec.label .. "\nPUSTE", Enum.NormalId.Top)
		local installControl = part(
			model,
			"InventorSlotControl_" .. slotId,
			Vector3.new(4, 2.4, 4),
			socket.Position + Vector3.new(7, 2.1, 0),
			Color3.fromRGB(85, 150, 210),
			Enum.Material.Metal
		)
		installControl.CanCollide = false
		installControl.CanTouch = false
		local socketPrompt
		socketPrompt = prompt(installControl, "Zamontuj", spec.label, function(triggeringPlayer)
			if triggeringPlayer ~= player or rules.stage ~= 1 then
				return
			end
			if not selectedModule then
				message(remote, player, "Najpierw wybierz moduł z regału.", false)
				return
			end
			local ok = Rules.Install(rules, slotId, selectedModule)
			if not ok then
				state.score = math.max(0, state.score - 3)
				flash(socket, Color3.fromRGB(215, 57, 67), Color3.fromRGB(58, 66, 77))
				message(remote, player, spec.hint .. " Ten moduł tu nie pasuje.", false)
				return
			end

			local chosen = components[selectedModule]
			chosen.part:SetAttribute("Installed", true)
			chosen.part.Transparency = 0.6
			chosen.part.Material = Enum.Material.Metal
			chosen.prompt.Enabled = false
			chosen.control.Color = Color3.fromRGB(48, 137, 92)
			chosen.control.Material = Enum.Material.Neon
			chosen.text.Text = chosen.spec.label .. "\nW UŻYCIU"

			local installed = part(
				model,
				"InventorInstalled_" .. slotId,
				Vector3.new(10, 5, 9),
				socket.Position + Vector3.new(0, 4, 0),
				chosen.spec.color,
				Enum.Material.Neon
			)
			label(installed, chosen.spec.label, Enum.NormalId.Top)
			glow(installed, chosen.spec.color, 1.1, 10)
			installedVisuals[slotId] = installed

			socket.Color = Color3.fromRGB(48, 137, 92)
			installControl.Color = Color3.fromRGB(48, 137, 92)
			installControl.Material = Enum.Material.Neon
			socketPrompt.Enabled = false
			socketText.Text = spec.label .. "\n✓ " .. chosen.spec.label:gsub("\n", " ")
			state.score += 18
			message(remote, player, spec.label .. " gotowe: " .. chosen.spec.label:gsub("\n", " "), true)

			selectedModule = nil
			selectedPart = nil
			if rules.stage == 2 then
				for _, component in pairs(components) do
					component.prompt.Enabled = false
				end
				for _, slot in pairs(slots) do
					slot.prompt.Enabled = false
				end
				board.Color = Color3.fromRGB(38, 88, 104)
				boardText.Text = "ETAP 2/3 • OKABLOWANIE\nSENSOR → STEROWNIK → SILNIK"
			end
		end)
		socketPrompt.Enabled = false
		slots[slotId] = {
			part = socket,
			control = installControl,
			text = socketText,
			prompt = socketPrompt,
		}
	end

	local function cableLine(name, z1, z2)
		local segments = {}
		for i = 1, 5 do
			local alpha = i / 6
			local z = z1 + (z2 - z1) * alpha
			local segment = part(
				model,
				name .. "_" .. i,
				Vector3.new(0.8, 0.8, 2.8),
				origin + Vector3.new(7, 3, z),
				Color3.fromRGB(45, 52, 60),
				Enum.Material.Metal
			)
			segment.CanCollide = false
			segments[i] = segment
		end
		return segments
	end

	local wireA = cableLine("InventorWire_InputProcessor", -12, 8)
	local wireB = cableLine("InventorWire_ProcessorOutput", 8, 28)
	local signalPulse = part(
		model,
		"InventorSignalPulse",
		Vector3.new(2.2, 2.2, 2.2),
		origin + Vector3.new(7, 4, -12),
		Color3.fromRGB(255, 226, 72),
		Enum.Material.Neon
	)
	signalPulse.Shape = Enum.PartType.Ball
	signalPulse.CanCollide = false
	signalPulse.Transparency = 1
	glow(signalPulse, Color3.fromRGB(255, 224, 72), 2, 12)

	local cableAButton = part(
		model,
		"InventorCable_INPUT_PROCESSOR",
		Vector3.new(13, 3, 8),
		origin + Vector3.new(29, 2.5, -5),
		Color3.fromRGB(52, 65, 75),
		Enum.Material.Metal
	)
	label(cableAButton, "SENSOR\n→ STEROWNIK", Enum.NormalId.Top)
	local bypassButton = part(
		model,
		"InventorCable_INPUT_OUTPUT",
		Vector3.new(13, 3, 8),
		origin + Vector3.new(29, 2.5, 9),
		Color3.fromRGB(78, 55, 58),
		Enum.Material.Metal
	)
	label(bypassButton, "SENSOR\n→ SILNIK", Enum.NormalId.Top)
	local cableBButton = part(
		model,
		"InventorCable_PROCESSOR_OUTPUT",
		Vector3.new(13, 3, 8),
		origin + Vector3.new(29, 2.5, 23),
		Color3.fromRGB(52, 65, 75),
		Enum.Material.Metal
	)
	label(cableBButton, "STEROWNIK\n→ SILNIK", Enum.NormalId.Top)

	local cableAControl = part(
		model,
		"InventorCableControl_INPUT_PROCESSOR",
		Vector3.new(4, 2.4, 4),
		cableAButton.Position + Vector3.new(-8, 1.8, 0),
		Color3.fromRGB(67, 205, 255),
		Enum.Material.Metal
	)
	local bypassControl = part(
		model,
		"InventorCableControl_INPUT_OUTPUT",
		Vector3.new(4, 2.4, 4),
		bypassButton.Position + Vector3.new(-8, 1.8, 0),
		Color3.fromRGB(220, 84, 54),
		Enum.Material.Metal
	)
	local cableBControl = part(
		model,
		"InventorCableControl_PROCESSOR_OUTPUT",
		Vector3.new(4, 2.4, 4),
		cableBButton.Position + Vector3.new(-8, 1.8, 0),
		Color3.fromRGB(67, 205, 255),
		Enum.Material.Metal
	)
	for _, control in ipairs({ cableAControl, bypassControl, cableBControl }) do
		control.CanCollide = false
		control.CanTouch = false
	end

	local cablePrompts = {}

	local function energize(segments)
		for index, segment in ipairs(segments) do
			task.delay(index * 0.07, function()
				if segment.Parent then
					segment.Material = Enum.Material.Neon
					segment.Color = Color3.fromRGB(67, 205, 255)
					glow(segment, Color3.fromRGB(67, 205, 255), 0.6, 7)
				end
			end)
		end
	end

	local testConsole = part(
		model,
		"InventorTestConsole",
		Vector3.new(18, 7, 10),
		origin + Vector3.new(29, 4.5, 38),
		Color3.fromRGB(61, 67, 76),
		Enum.Material.Metal
	)
	local testText = label(testConsole, "TEST\nZABLOKOWANY")
	local testPrompt

	local function objective()
		local stage, installed, links = Rules.Progress(rules)
		if not state.inventorEntryReady then
			state.objective = "START • Uruchom START MONTAŻU przy wejściu i przeczytaj plan budowy."
		elseif state.done then
			state.objective =
				"BRAMA DZIAŁA • Wejście → przetwarzanie → wyjście działa w prawdziwym urządzeniu."
		elseif stage == 1 then
			state.objective = string.format("ETAP WARSZTATU 1/3 • Zamontuj moduły %d/3.", installed)
		elseif stage == 2 then
			state.objective = string.format("ETAP WARSZTATU 2/3 • Połącz sygnał przez sterownik %d/2.", links)
		else
			state.objective = "ETAP WARSZTATU 3/3 • Uruchom test i obserwuj drogę sygnału."
		end
		hud(remote, player, title, state.objective, state.score)
	end

	local entryPrompt
	entryPrompt = prompt(entryConsole, "START MONTAŻU", "Inteligentna brama", function(triggeringPlayer)
		if triggeringPlayer ~= player or state.done or state.inventorEntryReady then
			return
		end
		state.inventorEntryReady = true
		entryPrompt.Enabled = false
		entryConsole.Color = Color3.fromRGB(51, 181, 114)
		entryConsole.Material = Enum.Material.Neon
		entryText.Text = "MONTAŻ\nAKTYWNY"
		board.Color = Color3.fromRGB(38, 88, 104)
		boardText.Text = "ETAP 1/3 • MODUŁY\nSENSOR → STEROWNIK → SILNIK"
		for _, component in pairs(components) do
			if not component.part:GetAttribute("Installed") then
				component.prompt.Enabled = true
			end
		end
		for _, slot in pairs(slots) do
			slot.prompt.Enabled = true
		end
		message(
			remote,
			player,
			"Warsztat aktywny. Wybierz moduł z regału i zamontuj go w odpowiednim gnieździe.",
			true
		)
		objective()
	end)

	local function connectCable(linkId, button, segments)
		if rules.stage < 2 then
			message(remote, player, "Najpierw zamontuj trzy właściwe moduły.", false)
			return
		end
		local ok, result = Rules.Connect(rules, linkId)
		if not ok then
			if result.reason == "bypass_processor" then
				state.score = math.max(0, state.score - 4)
				flash(button, Color3.fromRGB(220, 54, 64), Color3.fromRGB(78, 55, 58))
				message(
					remote,
					player,
					"Skrót nie działa: czujnik wysyła dane do sterownika, a dopiero sterownik uruchamia silnik.",
					false
				)
			elseif result.reason == "already_connected" then
				message(remote, player, "To połączenie już działa. Wybierz następny odcinek przewodu.", true)
			elseif result.reason == "wrong_order" then
				state.score = math.max(0, state.score - 2)
				flash(button, Color3.fromRGB(220, 84, 54), Color3.fromRGB(52, 65, 75))
				message(remote, player, "Najpierw doprowadź sygnał WEJŚCIE → PRZETWARZANIE.", false)
			end
			objective()
			return
		end

		button.Color = Color3.fromRGB(43, 164, 104)
		button.Material = Enum.Material.Neon
		state.score += 16
		energize(segments)
		message(remote, player, "Połączenie aktywne: sygnał ma dokąd płynąć.", true)

		if rules.stage == 3 then
			for _, pr in pairs(cablePrompts) do
				pr.Enabled = false
			end
			testPrompt.Enabled = true
			testConsole.Color = Color3.fromRGB(45, 130, 93)
			testText.Text = "TEST LIVE\nURUCHOM"
			board.Color = Color3.fromRGB(39, 105, 93)
			boardText.Text = "ETAP 3/3 • TEST LIVE\nPRZEJDŹ SYGNAŁEM PRZEZ CAŁE URZĄDZENIE"
		end
		objective()
	end

	cablePrompts.a = prompt(cableAControl, "Połącz", "SENSOR → STEROWNIK", function(triggeringPlayer)
		if triggeringPlayer == player then
			connectCable("INPUT_PROCESSOR", cableAButton, wireA)
		end
	end)
	cablePrompts.bypass = prompt(bypassControl, "Połącz", "SENSOR → SILNIK", function(triggeringPlayer)
		if triggeringPlayer == player then
			connectCable("INPUT_OUTPUT", bypassButton, {})
		end
	end)
	cablePrompts.b = prompt(cableBControl, "Połącz", "STEROWNIK → SILNIK", function(triggeringPlayer)
		if triggeringPlayer == player then
			connectCable("PROCESSOR_OUTPUT", cableBButton, wireB)
		end
	end)
	for _, pr in pairs(cablePrompts) do
		pr.Enabled = false
	end

	local testBot = part(
		model,
		"InventorTestBot",
		Vector3.new(7, 5, 7),
		origin + Vector3.new(0, 3.5, -34),
		Color3.fromRGB(240, 177, 63),
		Enum.Material.Metal
	)
	label(testBot, "BOT\nTEST", Enum.NormalId.Top)

	local function runSignalTest()
		local ok = Rules.RunTest(rules)
		if not ok then
			message(remote, player, "Układ nie jest jeszcze gotowy do testu.", false)
			return
		end

		testPrompt.Enabled = false
		testText.Text = "TEST\nW TOKU..."
		boardText.Text = "TEST LIVE • BOT WCHODZI W ZASIĘG CZUJNIKA"
		message(remote, player, "Obserwuj: czujnik → sterownik → silnik.", true)

		task.spawn(function()
			local botMove = tween(testBot, { Position = origin + Vector3.new(0, 3.5, -16) }, 0.8)
			botMove.Completed:Wait()

			if installedVisuals.INPUT then
				installedVisuals.INPUT.Color = Color3.fromRGB(255, 224, 75)
				installedVisuals.INPUT.Material = Enum.Material.Neon
			end
			boardText.Text = "WEJŚCIE ✓ • SENSOR WYKRYŁ RUCH"
			task.wait(0.25)

			signalPulse.Transparency = 0
			signalPulse.Position = origin + Vector3.new(7, 4, -12)
			local first = tween(signalPulse, { Position = origin + Vector3.new(7, 4, 8) }, 0.65)
			first.Completed:Wait()

			if installedVisuals.PROCESSOR then
				installedVisuals.PROCESSOR.Color = Color3.fromRGB(87, 190, 255)
				installedVisuals.PROCESSOR.Material = Enum.Material.Neon
			end
			boardText.Text = "PRZETWARZANIE ✓ • STEROWNIK PODJĄŁ DECYZJĘ"
			task.wait(0.25)

			local second = tween(signalPulse, { Position = origin + Vector3.new(7, 4, 28) }, 0.65)
			second.Completed:Wait()
			signalPulse.Transparency = 1

			if installedVisuals.OUTPUT then
				installedVisuals.OUTPUT.Color = Color3.fromRGB(70, 242, 145)
				installedVisuals.OUTPUT.Material = Enum.Material.Neon
			end
			boardText.Text = "WYJŚCIE ✓ • SILNIK OTWIERA BRAMĘ"

			tween(gateLeft, {
				Position = gateLeft.Position + Vector3.new(-11, 0, 0),
				Color = Color3.fromRGB(53, 185, 116),
			}, 0.85)
			local openRight = tween(gateRight, {
				Position = gateRight.Position + Vector3.new(11, 0, 0),
				Color = Color3.fromRGB(53, 185, 116),
			}, 0.85)
			openRight.Completed:Wait()

			local pass = tween(testBot, {
				Position = origin + Vector3.new(0, 3.5, 61),
				Color = Color3.fromRGB(66, 222, 137),
			}, 1.25)
			pass.Completed:Wait()

			state.score += math.max(20, 38 - rules.mistakes * 3)
			state.done = true
			board.Color = Color3.fromRGB(34, 142, 91)
			boardText.Text = "BRAMA DZIAŁA ✓\nWEJŚCIE → PRZETWARZANIE → WYJŚCIE"
			testConsole.Color = Color3.fromRGB(42, 178, 108)
			testText.Text = "TEST ✓\nSUKCES"
			glow(gateLeft, Color3.fromRGB(75, 255, 160), 1.4, 18)
			glow(gateRight, Color3.fromRGB(75, 255, 160), 1.4, 18)
			message(
				remote,
				player,
				"Sukces! Sensor podał dane, sterownik je przetworzył, a silnik zmienił świat.",
				true
			)
			objective()
		end)
	end

	testPrompt = prompt(testConsole, "Uruchom test", "INTELIGENTNA BRAMA", function(triggeringPlayer)
		if triggeringPlayer == player and not state.done then
			runSignalTest()
		end
	end)
	testPrompt.Enabled = false

	task.spawn(function()
		while model.Parent and not state.done do
			if rules.stage >= 2 then
				for _, pr in pairs(cablePrompts) do
					if rules.stage == 2 then
						pr.Enabled = true
					end
				end
			end
			task.wait(0.2)
		end
	end)

	objective()
end

return InventorWorkshop