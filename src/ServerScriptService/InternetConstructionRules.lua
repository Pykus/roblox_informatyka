local InternetConstructionRules = {}

InternetConstructionRules.Jobs = {
	{
		id = "ISP_ONT",
		stage = 1,
		source = "ISP FIBER",
		target = "ONT",
		cable = "FIBER",
		port = "OPTICAL",
		wrongPort = "LAN",
	},
	{
		id = "ONT_ROUTER",
		stage = 1,
		source = "ONT LAN",
		target = "ROUTER",
		cable = "ETHERNET",
		port = "WAN",
		wrongPort = "LAN",
	},
	{
		id = "ROUTER_SWITCH",
		stage = 2,
		source = "ROUTER LAN",
		target = "SWITCH",
		cable = "ETHERNET",
		port = "UPLINK",
		wrongPort = "SERVICE",
	},
	{
		id = "SWITCH_PC",
		stage = 2,
		source = "SWITCH LAN 1",
		target = "PC",
		cable = "ETHERNET",
		port = "ETHERNET",
		wrongPort = "USB",
	},
	{
		id = "SWITCH_AP",
		stage = 2,
		source = "SWITCH LAN 2",
		target = "ACCESS POINT",
		cable = "ETHERNET",
		port = "LAN",
		wrongPort = "POWER",
	},
}

function InternetConstructionRules.NewState()
	return {
		job = 1,
		selectedCable = nil,
		built = {},
		tests = { WIRED = false, WIFI = false },
		errors = 0,
		done = false,
	}
end

function InternetConstructionRules.CurrentJob(state)
	return InternetConstructionRules.Jobs[state.job]
end

function InternetConstructionRules.Stage(state)
	if state.done then
		return 3
	end
	local job = InternetConstructionRules.CurrentJob(state)
	if job then
		return job.stage
	end
	return 3
end

function InternetConstructionRules.SelectCable(state, cable)
	if cable ~= "FIBER" and cable ~= "ETHERNET" then
		return false, "Nieznany typ kabla."
	end
	state.selectedCable = cable
	return true, "Wybrano kabel " .. cable .. "."
end

function InternetConstructionRules.Connect(state, port)
	local job = InternetConstructionRules.CurrentJob(state)
	if not job then
		return false, { message = "Okablowanie jest już gotowe.", code = "BUILT" }
	end
	if not state.selectedCable then
		return false, {
			message = "Najpierw wybierz kabel z bębna.",
			code = "NO_CABLE",
		}
	end
	if state.selectedCable ~= job.cable then
		state.errors += 1
		local used = state.selectedCable
		state.selectedCable = nil
		return false,
			{
				message = string.format(
					"DEBUG KABLA • %s → %s wymaga %s, nie %s.",
					job.source,
					job.target,
					job.cable,
					used
				),
				code = "WRONG_CABLE",
			}
	end
	if port ~= job.port then
		state.errors += 1
		local used = port
		state.selectedCable = nil
		return false,
			{
				message = string.format(
					"DEBUG PORTU • %s ma trafić do portu %s, nie %s.",
					job.source,
					job.port,
					used
				),
				code = "WRONG_PORT",
			}
	end

	state.built[job.id] = true
	local completedJob = state.job
	state.job += 1
	state.selectedCable = nil
	return true,
		{
			message = string.format("Połączenie %s → %s działa.", job.source, job.target),
			code = "CONNECTED",
			job = completedJob,
			stage = InternetConstructionRules.Stage(state),
		}
end

function InternetConstructionRules.CanTest(state)
	return state.job > #InternetConstructionRules.Jobs
end

function InternetConstructionRules.TestRoute(state, route)
	if not InternetConstructionRules.CanTest(state) then
		return false, {
			message = "Najpierw zbuduj wszystkie 5 połączeń.",
			code = "LINKS_MISSING",
		}
	end
	if route ~= "WIRED" and route ~= "WIFI" then
		return false, { message = "Nieznana trasa testowa.", code = "BAD_ROUTE" }
	end
	if state.tests[route] then
		return false, { message = "Ta trasa została już przetestowana.", code = "ALREADY_TESTED" }
	end

	state.tests[route] = true
	state.done = state.tests.WIRED and state.tests.WIFI
	local hops = route == "WIRED" and 5 or 6
	return true,
		{
			message = string.format(
				"%s: pakiet przeszedł %d punktów trasy.",
				route == "WIRED" and "PC" or "WI-FI",
				hops
			),
			code = "ROUTE_OK",
			route = route,
			hops = hops,
			done = state.done,
		}
end

function InternetConstructionRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return InternetConstructionRules