local DecisionCityRules = {}

DecisionCityRules.ProfileOrder = { "CLOUD", "LOCAL", "HYBRID" }
DecisionCityRules.MetricOrder = { "access", "privacy", "resilience", "speed" }

DecisionCityRules.Profiles = {
	CLOUD = {
		label = "CLOUD FAST",
		metrics = { access = 3, privacy = 1, resilience = 1, speed = 3 },
		cost = 2,
		note = "łatwy dostęp i szybka obsługa • zależność od sieci",
	},
	LOCAL = {
		label = "LOCAL SAFE",
		metrics = { access = 1, privacy = 3, resilience = 3, speed = 1 },
		cost = 2,
		note = "lokalna kontrola i praca offline • trudniejszy dostęp z wielu miejsc",
	},
	HYBRID = {
		label = "HYBRID",
		metrics = { access = 2, privacy = 2, resilience = 2, speed = 2 },
		cost = 3,
		note = "równowaga online/offline • większa złożoność utrzymania",
	},
}

DecisionCityRules.DistrictOrder = { "SCHOOL", "OFFICE", "SHOP", "HEALTH" }

DecisionCityRules.Districts = {
	SCHOOL = {
		label = "SZKOŁA",
		needs = { access = 2, resilience = 1 },
		brief = "Uczniowie pracują w szkole i domu; po awarii sieci lekcja nie może całkiem stanąć.",
	},
	OFFICE = {
		label = "URZĄD",
		needs = { privacy = 2, resilience = 1 },
		brief = "Urząd przetwarza dane mieszkańców; potrzebuje kontroli dostępu i ciągłości pracy.",
	},
	SHOP = {
		label = "SKLEP",
		needs = { speed = 2, resilience = 1 },
		brief = "Sklep potrzebuje szybkiej sprzedaży; chwilowa awaria internetu nie może zatrzymać wszystkiego.",
	},
	HEALTH = {
		label = "ZDROWIE",
		needs = { privacy = 2, resilience = 2 },
		brief = "Placówka zdrowia przechowuje wrażliwe dane i musi działać podczas awarii.",
	},
}

function DecisionCityRules.NewState()
	return {
		selected = {},
		approved = {},
		approvedCount = 0,
		errors = 0,
		done = false,
	}
end

function DecisionCityRules.Select(state, districtId, profileId)
	if state.approved[districtId] then
		return false, "Ta dzielnica jest już uruchomiona."
	end
	if not DecisionCityRules.Districts[districtId] or not DecisionCityRules.Profiles[profileId] then
		return false, "Nieznana konfiguracja."
	end
	state.selected[districtId] = profileId
	return true, DecisionCityRules.Profiles[profileId]
end

function DecisionCityRules.Validate(state, districtId)
	local district = DecisionCityRules.Districts[districtId]
	if not district then
		return false, "Nieznana dzielnica."
	end
	if state.approved[districtId] then
		return true, { profile = state.approved[districtId], already = true }
	end

	local profileId = state.selected[districtId]
	if not profileId then
		state.errors += 1
		return false, { reason = "Najpierw wybierz wariant infrastruktury.", missing = {} }
	end

	local profile = DecisionCityRules.Profiles[profileId]
	local missing = {}
	for metric, minimum in pairs(district.needs) do
		if (profile.metrics[metric] or 0) < minimum then
			table.insert(missing, {
				metric = metric,
				have = profile.metrics[metric] or 0,
				need = minimum,
			})
		end
	end

	if #missing > 0 then
		state.errors += 1
		return false,
			{
				profile = profileId,
				missing = missing,
				reason = "Wybrany wariant nie spełnia wszystkich potrzeb dzielnicy.",
			}
	end

	state.approved[districtId] = profileId
	state.approvedCount += 1
	return true, { profile = profileId, missing = {} }
end

function DecisionCityRules.AllApproved(state)
	return state.approvedCount == #DecisionCityRules.DistrictOrder
end

function DecisionCityRules.CityTotals(state)
	local totals = { access = 0, privacy = 0, resilience = 0, speed = 0, cost = 0 }
	for _, districtId in ipairs(DecisionCityRules.DistrictOrder) do
		local profileId = state.approved[districtId]
		if profileId then
			local profile = DecisionCityRules.Profiles[profileId]
			for _, metric in ipairs(DecisionCityRules.MetricOrder) do
				totals[metric] += profile.metrics[metric]
			end
			totals.cost += profile.cost
		end
	end
	return totals
end

function DecisionCityRules.Complete(state)
	if not DecisionCityRules.AllApproved(state) then
		state.errors += 1
		return false, "Najpierw uruchom wszystkie cztery dzielnice."
	end
	state.done = true
	return true, DecisionCityRules.CityTotals(state)
end

function DecisionCityRules.ValidProfiles(districtId)
	local valid = {}
	local district = DecisionCityRules.Districts[districtId]
	for _, profileId in ipairs(DecisionCityRules.ProfileOrder) do
		local profile = DecisionCityRules.Profiles[profileId]
		local ok = true
		for metric, minimum in pairs(district.needs) do
			if profile.metrics[metric] < minimum then
				ok = false
				break
			end
		end
		if ok then
			table.insert(valid, profileId)
		end
	end
	return valid
end

function DecisionCityRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 8)
end

return DecisionCityRules