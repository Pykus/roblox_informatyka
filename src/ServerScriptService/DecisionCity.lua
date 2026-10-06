local TweenService = game:GetService("TweenService")

local DecisionCity = {}
local Rules = require(script.Parent:WaitForChild("DecisionCityRules"))

local C = {
	asphalt = Color3.fromRGB(35, 43, 53),
	sidewalk = Color3.fromRGB(105, 116, 124),
	dark = Color3.fromRGB(21, 28, 38),
	glass = Color3.fromRGB(52, 92, 118),
	cyan = Color3.fromRGB(60, 207, 228),
	orange = Color3.fromRGB(239, 146, 65),
	green = Color3.fromRGB(71, 220, 126),
	red = Color3.fromRGB(226, 77, 74),
	white = Color3.fromRGB(244, 247, 249),
	blue = Color3.fromRGB(74, 139, 226),
	purple = Color3.fromRGB(154, 102, 216),
	yellow = Color3.fromRGB(241, 198, 68),
}

local PROFILE_COLOR = {
	CLOUD = C.cyan,
	LOCAL = C.orange,
	HYBRID = C.purple,
}

local METRIC_LABEL = {
	access = "DOSTĘP",
	privacy = "PRYWATNOŚĆ",
	resilience = "ODPORNOŚĆ",
	speed = "SZYBKOŚĆ",
}

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
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
	gui.Brightness = 1.1
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34
	gui.Parent = target

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -12, 1, -12)
	txt.Position = UDim2.fromOffset(6, 6)
	txt.BackgroundTransparency = 0.12
	txt.BackgroundColor3 = C.dark
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = C.white
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0.45
	txt.Parent = gui

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = minSize or 18
	limit.MaxTextSize = maxSize or 32
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

local function light(target, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.7
	l.Range = range or 17
	l.Shadows = false
	l.Parent = target
	return l
end

local function message(ctx, text, good)
	ctx.remote:FireClient(ctx.player, { kind = "message", text = text, good = good })
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

local function tween(instance, goal, duration)
	local tw = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		goal
	)
	tw:Play()
	return tw
end

local function metricsText(profile)
	return string.format(
		"Dostęp %d  Prywatność %d\nOdporność %d  Szybkość %d\nKoszt %d • %s",
		profile.metrics.access,
		profile.metrics.privacy,
		profile.metrics.resilience,
		profile.metrics.speed,
		profile.cost,
		profile.note
	)
end

local function needsText(district)
	local lines = {}
	for _, metric in ipairs(Rules.MetricOrder) do
		local minimum = district.needs[metric]
		if minimum then
			table.insert(lines, string.format("%s ≥ %d", METRIC_LABEL[metric], minimum))
		end
	end
	return table.concat(lines, " • ")
end

local function segment(parent, name, a, b, color)
	local distance = (b - a).Magnitude
	local midpoint = (a + b) * 0.5
	local beam = part(parent, name, Vector3.new(0.8, 0.8, distance), midpoint, color, Enum.Material.Neon)
	beam.CanCollide = false
	beam.CFrame = CFrame.lookAt(midpoint, b)
	return beam
end

local function buildSchool(model, base)
	local body = part(
		model,
		"DecisionSchoolBody",
		Vector3.new(18, 10, 12),
		base + Vector3.new(0, 6, 0),
		C.blue,
		Enum.Material.Brick
	)
	local roof = part(
		model,
		"DecisionSchoolRoof",
		Vector3.new(20, 2, 14),
		base + Vector3.new(0, 12, 0),
		C.yellow,
		Enum.Material.SmoothPlastic
	)
	roof.CanCollide = false
	for index, x in ipairs({ -5, 0, 5 }) do
		local window = part(
			model,
			"DecisionSchoolWindow_" .. index,
			Vector3.new(3.2, 3.2, 0.5),
			base + Vector3.new(x, 7, -6.25),
			C.cyan,
			Enum.Material.Neon
		)
		window.CanCollide = false
	end
	return body
end

local function buildOffice(model, base)
	local tower = part(
		model,
		"DecisionOfficeTower",
		Vector3.new(14, 22, 14),
		base + Vector3.new(0, 12, 0),
		C.glass,
		Enum.Material.Glass
	)
	for floor = 1, 4 do
		local band = part(
			model,
			"DecisionOfficeBand_" .. floor,
			Vector3.new(15, 0.8, 15),
			base + Vector3.new(0, 4 + floor * 4, 0),
			C.cyan,
			Enum.Material.Neon
		)
		band.CanCollide = false
	end
	return tower
end

local function buildShop(model, base)
	local body = part(
		model,
		"DecisionShopBody",
		Vector3.new(18, 9, 13),
		base + Vector3.new(0, 5.5, 0),
		C.orange,
		Enum.Material.Brick
	)
	for index = -3, 3 do
		local awning = part(
			model,
			"DecisionShopAwning_" .. tostring(index),
			Vector3.new(2.2, 0.8, 3.6),
			base + Vector3.new(index * 2.4, 9.8, -7),
			index % 2 == 0 and C.white or C.red,
			Enum.Material.Fabric
		)
		awning.CanCollide = false
	end
	return body
end

local function buildHealth(model, base)
	local body = part(
		model,
		"DecisionHealthBody",
		Vector3.new(18, 11, 13),
		base + Vector3.new(0, 6.5, 0),
		C.white,
		Enum.Material.Concrete
	)
	local crossV = part(
		model,
		"DecisionHealthCrossV",
		Vector3.new(2.2, 7, 0.8),
		base + Vector3.new(0, 8, -6.8),
		C.red,
		Enum.Material.Neon
	)
	local crossH = part(
		model,
		"DecisionHealthCrossH",
		Vector3.new(7, 2.2, 0.8),
		base + Vector3.new(0, 8, -6.8),
		C.red,
		Enum.Material.Neon
	)
	crossV.CanCollide = false
	crossH.CanCollide = false
	return body
end

local BUILDERS = {
	SCHOOL = buildSchool,
	OFFICE = buildOffice,
	SHOP = buildShop,
	HEALTH = buildHealth,
}

local function profileSummary(profileId)
	local profile = Rules.Profiles[profileId]
	return profile.label .. "\n" .. metricsText(profile)
end

local function setSelected(ctx, districtId, profileId)
	for id, pad in pairs(ctx.profilePads[districtId]) do
		if id == profileId then
			pad.Color = PROFILE_COLOR[id]
			pad.Material = Enum.Material.Neon
			tween(pad, { Position = ctx.profilePadHomes[districtId][id] + Vector3.new(0, 0.8, 0) }, 0.12)
		else
			pad.Color = C.sidewalk
			pad.Material = Enum.Material.Metal
			tween(pad, { Position = ctx.profilePadHomes[districtId][id] }, 0.12)
		end
	end
	ctx.previewLabels[districtId].Text = "WYBRANO\n" .. profileSummary(profileId)
end

local function setPlanningPrompts(ctx, enabled)
	for _, districtId in ipairs(Rules.DistrictOrder) do
		if not ctx.rules.approved[districtId] then
			for _, pr in pairs(ctx.profilePrompts[districtId] or {}) do
				pr.Enabled = enabled
			end
			local validatePrompt = ctx.validatePrompts[districtId]
			if validatePrompt then
				validatePrompt.Enabled = enabled
			end
		end
	end
end

local function approveDistrict(ctx, districtId, profileId)
	local district = Rules.Districts[districtId]
	local profile = Rules.Profiles[profileId]
	ctx.buildingLights[districtId].Color = PROFILE_COLOR[profileId]
	ctx.buildingLights[districtId].Brightness = 2.5
	ctx.statusLabels[districtId].Text =
		string.format("%s ONLINE\n%s\n%s", district.label, profile.label, needsText(district))
	ctx.statusLabels[districtId].TextColor3 = C.green
	for _, pr in pairs(ctx.profilePrompts[districtId]) do
		pr.Enabled = false
	end
	ctx.validatePrompts[districtId].Enabled = false
	ctx.districtBeams[districtId].Color = PROFILE_COLOR[profileId]
	ctx.districtBeams[districtId].Transparency = 0.1
end

local function finalize(ctx)
	local ok, result = Rules.Complete(ctx.rules)
	if not ok then
		ctx.state.score = math.max(0, ctx.state.score - 4)
		message(ctx, result, false)
		return
	end

	ctx.syncPrompt.Enabled = false
	ctx.state.score += 100
	ctx.state.done = true

	ctx.cityCore.Color = C.green
	ctx.cityCore.Material = Enum.Material.Neon
	ctx.cityCoreLight.Color = C.green
	ctx.cityCoreLight.Brightness = 3.2
	ctx.dashboard.TextColor3 = C.green
	ctx.dashboard.Text = string.format(
		"DECISION CITY ONLINE\nDostęp %d • Prywatność %d • Odporność %d • Szybkość %d\nŁączny koszt %d • Profil miasta, nie ranking",
		result.access,
		result.privacy,
		result.resilience,
		result.speed,
		result.cost
	)

	for _, tower in ipairs(ctx.skylineTowers) do
		tower.Material = Enum.Material.Neon
		tower.Color = C.green
	end

	hud(ctx, "ETAP 2/3 • Miasto działa. Przejdź do oznaczonego RDZENIA MISJI.")
	message(
		ctx,
		string.format("Miasto uruchomione. Cztery lokalne kompromisy, efektywność %d%%.", Rules.Efficiency(ctx.rules)),
		true
	)
end

function DecisionCity.Run(model, origin, player, lesson, mission, remote, state, accent)
	local ctx = {
		model = model,
		player = player,
		lesson = lesson,
		mission = mission,
		remote = remote,
		state = state,
		rules = Rules.NewState(),
		profilePads = {},
		profilePadHomes = {},
		profilePrompts = {},
		validatePrompts = {},
		validateControls = {},
		previewLabels = {},
		statusLabels = {},
		buildingLights = {},
		districtBeams = {},
		skylineTowers = {},
		entryReady = false,
	}

	local floor = part(
		model,
		"DecisionCityFloor",
		Vector3.new(92, 1, 92),
		origin + Vector3.new(0, -0.5, 4),
		C.asphalt,
		Enum.Material.Asphalt
	)
	floor.CanCollide = true
	part(
		model,
		"DecisionCityRoadNS",
		Vector3.new(14, 0.5, 86),
		origin + Vector3.new(0, 0.1, 4),
		Color3.fromRGB(54, 59, 65),
		Enum.Material.Asphalt
	)
	part(
		model,
		"DecisionCityRoadEW",
		Vector3.new(86, 0.5, 14),
		origin + Vector3.new(0, 0.1, 4),
		Color3.fromRGB(54, 59, 65),
		Enum.Material.Asphalt
	)

	local planningConsole = part(
		model,
		"DecisionCityPlanningConsole",
		Vector3.new(16, 6, 9),
		origin + Vector3.new(0, 4, -44),
		C.cyan,
		Enum.Material.Metal
	)
	planningConsole.CanCollide = false
	planningConsole.CanTouch = false
	label(planningConsole, "MIEJSKI PANEL PLANOWANIA\nOTWÓRZ MAPĘ POTRZEB", Enum.NormalId.Front, 20, 28)
	local planningLight = light(planningConsole, C.yellow, 0.8, 13)

	local header = part(
		model,
		"DecisionCityHeader",
		Vector3.new(54, 9, 1),
		origin + Vector3.new(0, 16, -39),
		C.dark,
		Enum.Material.Metal
	)
	label(header, "DECISION CITY\nCYFRYZACJA = KORZYŚCI + KOSZTY", Enum.NormalId.Front, 22)

	ctx.cityCore = part(
		model,
		"DecisionCityCore",
		Vector3.new(10, 10, 10),
		origin + Vector3.new(0, 8, 4),
		C.red,
		Enum.Material.Glass
	)
	ctx.cityCore.Shape = Enum.PartType.Ball
	ctx.cityCore.CanCollide = false
	ctx.cityCoreLight = light(ctx.cityCore, C.red, 1.8, 20)

	local dashboardPart = part(
		model,
		"DecisionCityDashboard",
		Vector3.new(30, 9, 1),
		origin + Vector3.new(0, 15, 17),
		C.dark,
		Enum.Material.Metal
	)
	ctx.dashboard = label(dashboardPart, "MIASTO OFFLINE\n0/4 DZIELNICE", Enum.NormalId.Front, 18)

	local defs = {
		{ id = "SCHOOL", pos = Vector3.new(-27, 0, -20) },
		{ id = "OFFICE", pos = Vector3.new(27, 0, -20) },
		{ id = "SHOP", pos = Vector3.new(-27, 0, 30) },
		{ id = "HEALTH", pos = Vector3.new(27, 0, 30) },
	}

	for index, def in ipairs(defs) do
		local district = Rules.Districts[def.id]
		local base = origin + def.pos
		local plaza =
			part(model, "DecisionPlaza_" .. def.id, Vector3.new(31, 1, 31), base, C.sidewalk, Enum.Material.Concrete)
		plaza.CanCollide = true
		local building = BUILDERS[def.id](model, base + Vector3.new(0, 0, -5))
		ctx.buildingLights[def.id] = light(building, C.red, 0.8, 14)

		local statusPart = part(
			model,
			"DecisionStatus_" .. def.id,
			Vector3.new(24, 8, 1),
			base + Vector3.new(0, 14, -15.5),
			C.dark,
			Enum.Material.Metal
		)
		ctx.statusLabels[def.id] = label(
			statusPart,
			district.label .. "\nPOTRZEBY: " .. needsText(district) .. "\n" .. district.brief,
			Enum.NormalId.Front,
			16,
			27
		)

		local previewPart = part(
			model,
			"DecisionPreview_" .. def.id,
			Vector3.new(24, 7, 1),
			base + Vector3.new(0, 5, 15.5),
			C.dark,
			Enum.Material.Metal
		)
		ctx.previewLabels[def.id] =
			label(previewPart, "WYBIERZ WARIANT\nporównaj parametry", Enum.NormalId.Front, 16, 26)

		ctx.profilePads[def.id] = {}
		ctx.profilePadHomes[def.id] = {}
		ctx.profilePrompts[def.id] = {}
		for profileIndex, profileId in ipairs(Rules.ProfileOrder) do
			local x = -9 + (profileIndex - 1) * 9
			local home = base + Vector3.new(x, 1.7, 8)
			local pad = part(
				model,
				"DecisionPlan_" .. def.id .. "_" .. profileId,
				Vector3.new(7.5, 2.5, 5),
				home,
				C.sidewalk,
				Enum.Material.Metal
			)
			ctx.profilePads[def.id][profileId] = pad
			ctx.profilePadHomes[def.id][profileId] = home
			label(pad, Rules.Profiles[profileId].label, Enum.NormalId.Top, 15, 24)

			local profileControl = part(
				model,
				"DecisionProfileControl_" .. def.id .. "_" .. profileId,
				Vector3.new(3, 2, 3),
				home + Vector3.new(0, 0.4, -3.8),
				PROFILE_COLOR[profileId],
				Enum.Material.Metal
			)
			profileControl.CanCollide = false
			profileControl.CanTouch = false
			local profilePrompt = prompt(
				profileControl,
				"WYBIERZ",
				district.label .. " • " .. Rules.Profiles[profileId].label,
				function(p)
					if p ~= player or not ctx.entryReady or ctx.rules.approved[def.id] then
						return
					end
					local ok, profile = Rules.Select(ctx.rules, def.id, profileId)
					if ok then
						setSelected(ctx, def.id, profileId)
						message(ctx, profile.note, true)
					end
				end
			)
			ctx.profilePrompts[def.id][profileId] = profilePrompt
		end

		local validator = part(
			model,
			"DecisionValidate_" .. def.id,
			Vector3.new(10, 4, 4),
			base + Vector3.new(0, 2.5, 12),
			C.blue,
			Enum.Material.Metal
		)
		label(validator, "TEST POTRZEB", Enum.NormalId.Top, 16, 24)
		local validateControl = part(
			model,
			"DecisionValidateControl_" .. def.id,
			Vector3.new(3.2, 2.2, 3.2),
			validator.Position + Vector3.new(0, 0.8, -4.2),
			C.blue,
			Enum.Material.Metal
		)
		validateControl.CanCollide = false
		validateControl.CanTouch = false
		ctx.validateControls[def.id] = validateControl
		ctx.validatePrompts[def.id] = prompt(validateControl, "TESTUJ", district.label, function(p)
			if p ~= player or not ctx.entryReady or ctx.rules.approved[def.id] then
				return
			end
			local ok, result = Rules.Validate(ctx.rules, def.id)
			if not ok then
				ctx.state.score = math.max(0, ctx.state.score - 4)
				local reasons = {}
				for _, missing in ipairs(result.missing or {}) do
					table.insert(
						reasons,
						string.format("%s %d/%d", METRIC_LABEL[missing.metric], missing.have, missing.need)
					)
				end
				local suffix = #reasons > 0 and (" Brakuje: " .. table.concat(reasons, ", ")) or ""
				ctx.previewLabels[def.id].TextColor3 = C.red
				ctx.previewLabels[def.id].Text = "DEBUG POTRZEB\n" .. result.reason .. suffix
				pulse(validateControl, C.red)
				message(ctx, result.reason .. suffix .. " Wybierz inny kompromis.", false)
				return
			end

			ctx.state.score += 25
			validateControl.Color = C.green
			validateControl.Material = Enum.Material.Neon
			approveDistrict(ctx, def.id, result.profile)
			ctx.dashboard.Text = string.format("MIASTO OFFLINE\n%d/4 DZIELNICE", ctx.rules.approvedCount)
			message(
				ctx,
				string.format(
					"%s działa z profilem %s. To jedna z akceptowalnych konfiguracji.",
					district.label,
					Rules.Profiles[result.profile].label
				),
				true
			)
			if Rules.AllApproved(ctx.rules) then
				ctx.syncPrompt.Enabled = true
				ctx.dashboard.Text = "4/4 DZIELNICE ONLINE\nPORÓWNAJ PROFIL I URUCHOM MIASTO"
				hud(ctx, "ETAP 2/3 • Cztery dzielnice działają. Uruchom centralny węzeł miasta.")
			else
				hud(ctx, string.format("ETAP 1/3 • Uruchom dzielnice: %d/4.", ctx.rules.approvedCount))
			end
		end)

		local centerPoint = origin + Vector3.new(0, 4, 4)
		local districtPoint = base + Vector3.new(0, 4, 0)
		local beam = segment(model, "DecisionCityLink_" .. def.id, centerPoint, districtPoint, C.red)
		beam.Transparency = 0.72
		ctx.districtBeams[def.id] = beam

		local tower = part(
			model,
			"DecisionSkyline_" .. index,
			Vector3.new(3, 10 + index * 3, 3),
			origin + Vector3.new(-38 + index * 20, 5 + index * 1.5, -36),
			C.glass,
			Enum.Material.Glass
		)
		tower.CanCollide = false
		table.insert(ctx.skylineTowers, tower)
	end

	local sync = part(
		model,
		"DecisionCitySync",
		Vector3.new(12, 4, 7),
		origin + Vector3.new(0, 2.5, 25),
		C.red,
		Enum.Material.Metal
	)
	label(sync, "URUCHOM\nMIASTO", Enum.NormalId.Top, 18, 26)
	ctx.syncPrompt = prompt(sync, "URUCHOM", "CENTRALNY WĘZEŁ", function(p)
		if p ~= player then
			return
		end
		finalize(ctx)
	end)
	ctx.syncPrompt.Enabled = false
	setPlanningPrompts(ctx, false)

	local entryPrompt
	entryPrompt = prompt(planningConsole, "OTWÓRZ PLAN", "Decision City", function(p)
		if p ~= player or ctx.entryReady or ctx.state.done then
			return
		end
		ctx.entryReady = true
		entryPrompt.Enabled = false
		planningConsole.Color = C.green
		planningConsole.Material = Enum.Material.Neon
		planningLight.Color = C.green
		planningLight.Brightness = 2.4
		ctx.dashboard.Text = "PLANOWANIE AKTYWNE\n0/4 DZIELNICE"
		setPlanningPrompts(ctx, true)
		hud(
			ctx,
			"ETAP 1/3 • Dobierz wariant infrastruktury do potrzeb 4 dzielnic. Więcej niż jeden wybór może działać."
		)
		message(
			ctx,
			"Mapa potrzeb otwarta. Porównuj dostęp, prywatność, odporność, szybkość i koszt — nie ma jednego najlepszego profilu.",
			true
		)
	end)

	hud(ctx, "ETAP START • Otwórz miejski panel planowania przy wejściu.")
	message(
		ctx,
		"ZACZNIJ TUTAJ: otwórz mapę potrzeb. Dopiero wtedy aktywują się wybory CLOUD / LOCAL / HYBRID.",
		true
	)
end

return DecisionCity