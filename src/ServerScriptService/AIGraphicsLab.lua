local TweenService = game:GetService("TweenService")

local Rules = require(script.Parent:WaitForChild("AIGraphicsLabRules"))

local AIGraphicsLab = {}

local C = {
	floor = Color3.fromRGB(32, 39, 48),
	wall = Color3.fromRGB(54, 63, 76),
	dark = Color3.fromRGB(20, 25, 32),
	green = Color3.fromRGB(71, 223, 133),
	blue = Color3.fromRGB(69, 157, 240),
	violet = Color3.fromRGB(154, 102, 236),
	yellow = Color3.fromRGB(247, 195, 67),
	red = Color3.fromRGB(235, 78, 83),
	white = Color3.fromRGB(247, 249, 252),
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

local function label(target, text, face, minSize)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.38
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.Parent = gui

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = minSize or 18
	limit.MaxTextSize = 32
	limit.Parent = txt
	return txt
end

local function prompt(target, action, objectText, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = objectText
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.HoldDuration = 0.08
	p.Parent = target
	p.Triggered:Connect(callback)
	return p
end

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, { kind = "message", text = text, good = good })
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

local function glow(target, color)
	local original = target.Color
	target.Color = color
	TweenService:Create(target, TweenInfo.new(0.35), { Color = original }):Play()
end

function AIGraphicsLab.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		variantMonitors = {},
		variantLabels = {},
	}

	part(model, "AIGraphicsFloor", Vector3.new(82, 1, 76), origin + Vector3.new(0, -0.5, -7), C.floor, Enum.Material.Metal)
	part(model, "AIGraphicsBackWall", Vector3.new(82, 19, 2), origin + Vector3.new(0, 9.5, -44), C.wall, Enum.Material.Metal)

	local sign = part(model, "AIGraphicsSign", Vector3.new(40, 7, 1), origin + Vector3.new(0, 14, -42.8), C.violet, Enum.Material.Neon)
	label(sign, "AI GRAPHICS LAB\nczłowiek prowadzi • AI proponuje", Enum.NormalId.Front, 20)

	local desk = part(model, "AIGraphicsOperatorDesk", Vector3.new(19, 4, 8), origin + Vector3.new(-22, 2, -30), C.dark, Enum.Material.Wood)
	desk:SetAttribute("Important3DPlaceholder", true)
	local scanner = part(model, "AIGraphicsBriefScanner", Vector3.new(8, 4, 7), origin + Vector3.new(-22, 4, -38), C.blue, Enum.Material.Metal)
	scanner:SetAttribute("Important3DPlaceholder", true)
	label(scanner, "START\nSKANUJ BRIEF", Enum.NormalId.Front, 18)

	local tokenNames = {
		{ "Subject", "TEMAT\nzielony park", C.green, "subject" },
		{ "Style", "STYL\nprosty plakat", C.violet, "style" },
		{ "Privacy", "PRYWATNOŚĆ\nbez danych osób", C.yellow, "privacy" },
	}
	local tokenParts = {}
	for index, info in ipairs(tokenNames) do
		local p = part(
			model,
			"AIGraphicsTokenControl_" .. info[1],
			Vector3.new(8, 3, 7),
			origin + Vector3.new(-18 + (index - 1) * 12, 2, -25),
			info[3],
			Enum.Material.Neon
		)
		p:SetAttribute("Important3DPlaceholder", true)
		label(p, info[2], Enum.NormalId.Top, 16)
		tokenParts[index] = { part = p, key = info[4] }
	end

	local console = part(model, "AIGraphicsPromptConsole", Vector3.new(11, 7, 7), origin + Vector3.new(20, 3.5, -24), C.dark, Enum.Material.Metal)
	console:SetAttribute("Important3DPlaceholder", true)
	local consoleText = label(console, "PROMPT\n0/3 SKŁADNIKI", Enum.NormalId.Front, 18)

	local galleryBack = part(model, "AIGraphicsGalleryWall", Vector3.new(58, 15, 1), origin + Vector3.new(0, 8, 0), C.dark, Enum.Material.Metal)
	label(galleryBack, "GALERIA WARIANTÓW • A / B / C", Enum.NormalId.Top, 18)

	local variantInfo = {
		{ key = "A", x = -19, color = C.red, text = "A\nZA DUŻO DETALI" },
		{ key = "B", x = 0, color = C.green, text = "B\nPROSTA KOMPOZYCJA" },
		{ key = "C", x = 19, color = C.yellow, text = "C\nNIECZYTELNY TEKST AI" },
	}
	for _, info in ipairs(variantInfo) do
		local monitor = part(
			model,
			"AIGraphicsVariantMonitor_" .. info.key,
			Vector3.new(15, 10, 2),
			origin + Vector3.new(info.x, 8, 2),
			C.dark,
			Enum.Material.Metal
		)
		monitor:SetAttribute("Important3DPlaceholder", true)
		ctx.variantMonitors[info.key] = monitor
		ctx.variantLabels[info.key] = label(monitor, info.text, Enum.NormalId.Front, 18)
	end

	local improve = part(model, "AIGraphicsImproveControl", Vector3.new(12, 4, 8), origin + Vector3.new(-10, 2, 18), C.blue, Enum.Material.Neon)
	improve:SetAttribute("Important3DPlaceholder", true)
	label(improve, "ITERUJ PROMPT\nprościej • bez tekstu", Enum.NormalId.Top, 16)

	local printer = part(model, "AIGraphicsPrinter", Vector3.new(11, 7, 9), origin + Vector3.new(12, 3.5, 22), C.dark, Enum.Material.Metal)
	printer:SetAttribute("Important3DPlaceholder", true)
	local printerText = label(printer, "CZŁOWIEK ZATWIERDZA\nDRUK", Enum.NormalId.Front, 17)

	local promptPreview = part(model, "AIGraphicsPromptPreview", Vector3.new(30, 9, 1), origin + Vector3.new(0, 12, -15), C.dark, Enum.Material.Metal)
	local previewText = label(promptPreview, "PROMPT: —", Enum.NormalId.Front, 18)

	local function updatePreview()
		local items = {}
		if ctx.rules.tokens.subject then table.insert(items, "zielony park") end
		if ctx.rules.tokens.style then table.insert(items, "prosty plakat") end
		if ctx.rules.tokens.privacy then table.insert(items, "bez danych osobowych") end
		if #items == 0 then
			previewText.Text = "PROMPT: —"
		else
			previewText.Text = "PROMPT:\n" .. table.concat(items, " • ")
		end
		if ctx.rules.improved then
			previewText.Text ..= "\n+ bez tekstu AI • czytelny układ"
		end
		consoleText.Text = string.format("PROMPT\n%d/3 SKŁADNIKI", #items)
	end

	local function updateHud()
		if ctx.rules.completed then
			setHud(ctx, "ETAP 2/3 • Projekt zatwierdzony. Przejdź do RDZENIA MISJI.")
		elseif ctx.rules.stage == 1 then
			if not ctx.rules.briefScanned then
				setHud(ctx, "ETAP 1/3 • ZACZNIJ: zeskanuj BRIEF Dnia Ziemi.")
			else
				setHud(ctx, "ETAP 1/3 • Zbierz TEMAT, STYL i PRYWATNOŚĆ do promptu.")
			end
		elseif ctx.rules.stage == 2 then
			if not ctx.rules.generated then
				setHud(ctx, "ETAP 1/3 • Uruchom GENERATOR WARIANTÓW.")
			else
				setHud(ctx, "ETAP 1/3 • Porównaj A/B/C i wybierz najlepszy wariant.")
			end
		else
			if not ctx.rules.improved then
				setHud(ctx, "ETAP 1/3 • ITERUJ PROMPT: prościej, bez tekstu i danych osobowych.")
			else
				setHud(ctx, "ETAP 1/3 • Człowiek podejmuje decyzję: ZATWIERDŹ i wydrukuj.")
			end
		end
	end

	local function act(action, value)
		local ok, result = Rules.Apply(ctx.rules, action, value)
		if ok then
			ctx.state.score += 18
			message(ctx, result.message, true)
		else
			ctx.state.score = math.max(0, ctx.state.score - 4)
			message(ctx, result.message, false)
		end

		updatePreview()
		if action == "generate" and ok then
			for _, monitor in pairs(ctx.variantMonitors) do
				monitor.Material = Enum.Material.Neon
			end
		elseif action == "choose" then
			local monitor = ctx.variantMonitors[value]
			if monitor then glow(monitor, ok and C.green or C.red) end
			if ok then
				ctx.variantLabels.B.Text = "B • WYBRANY\nCZYTELNY + ZGODNY Z BRIEFEM"
			end
		elseif action == "improve" and ok then
			improve.Color = C.green
			improve.Material = Enum.Material.Neon
		elseif action == "approve" and ok and result.completed then
			ctx.state.done = true
			ctx.state.score += 75
			printer.Color = C.green
			printer.Material = Enum.Material.Neon
			printerText.Text = "ZATWIERDZONE\nCZŁOWIEK + AI"
			sign.Color = C.green
			previewText.Text ..= string.format("\nEFEKTYWNOŚĆ %d%%", Rules.Efficiency(ctx.rules))
		end
		updateHud()
	end

	prompt(scanner, "SKANUJ BRIEF", "BRIEF • DZIEŃ ZIEMI", function(triggerPlayer)
		if triggerPlayer == player then act("brief") end
	end)
	for _, token in ipairs(tokenParts) do
		prompt(token.part, "DODAJ DO PROMPTU", "SKŁADNIK PROMPTU", function(triggerPlayer)
			if triggerPlayer == player then act("token", token.key) end
		end)
	end
	prompt(console, "GENERUJ 3 WARIANTY", "SYMULOWANY GENERATOR AI", function(triggerPlayer)
		if triggerPlayer == player then act("generate") end
	end)
	for key, monitor in pairs(ctx.variantMonitors) do
		prompt(monitor, "WYBIERZ WARIANT " .. key, "GALERIA AI", function(triggerPlayer)
			if triggerPlayer == player then act("choose", key) end
		end)
	end
	prompt(improve, "POPRAW PROMPT", "ITERACJA CZŁOWIEKA", function(triggerPlayer)
		if triggerPlayer == player then act("improve") end
	end)
	prompt(printer, "ZATWIERDŹ I DRUKUJ", "FINALNA DECYZJA", function(triggerPlayer)
		if triggerPlayer == player then act("approve") end
	end)

	updatePreview()
	updateHud()
	return ctx
end

return AIGraphicsLab
