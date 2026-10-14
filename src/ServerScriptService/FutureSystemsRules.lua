local FutureSystemsRules = {}

local REQUIRED = { work = true, home = true, city = true }

function FutureSystemsRules.NewState()
	return {
		stage = 1,
		systems = {},
		privacy = false,
		humanControl = false,
		simulated = false,
		errors = 0,
		completed = false,
	}
end

local function fail(state, message)
	state.errors += 1
	return false, { message = message, stage = state.stage, completed = false }
end

local function countSystems(state)
	local n=0
	for key in pairs(REQUIRED) do if state.systems[key] then n+=1 end end
	return n
end

function FutureSystemsRules.Apply(state, action, value)
	if state.completed then
		return false, { message = "Future Systems City już działa.", stage = state.stage, completed = true }
	end
	if action == "system" then
		if not REQUIRED[value] then return fail(state, "DEBUG SYSTEMU • Wybierz strefę WORK, HOME albo CITY.") end
		state.systems[value]=true
		if countSystems(state)==3 then
			state.stage=2
			return true,{message="3/3 systemy podłączone. Dodaj prywatność i kontrolę człowieka.",stage=2,stageChanged=true}
		end
		return true,{message=string.format("Systemy: %d/3.",countSystems(state)),stage=state.stage}
	elseif action == "privacy" then
		if countSystems(state)<3 then return fail(state,"DEBUG PRYWATNOŚCI • Najpierw uruchom wszystkie 3 strefy.") end
		state.privacy=true
		return true,{message="Minimalizacja danych i prywatność są aktywne.",stage=state.stage}
	elseif action == "human" then
		if not state.privacy then return fail(state,"DEBUG NADZORU • Najpierw zabezpiecz dane.") end
		state.humanControl=true
		return true,{message="Człowiek zachowuje decyzję i możliwość zatrzymania automatyzacji.",stage=state.stage}
	elseif action == "simulate" then
		if not state.humanControl then return fail(state,"DEBUG SYMULACJI • Brakuje kontroli człowieka.") end
		state.simulated=true
		state.completed=true
		return true,{message="Symulacja dnia 2035 zakończona: technologia pomaga, ale nie odbiera kontroli.",stage=3,completed=true}
	end
	return fail(state,"Nieznana akcja.")
end

function FutureSystemsRules.Efficiency(state)
	return math.max(40,100-state.errors*8)
end

return FutureSystemsRules
