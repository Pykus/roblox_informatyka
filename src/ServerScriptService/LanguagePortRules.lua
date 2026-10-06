local Rules = {}

Rules.Languages = { "PYTHON", "JAVASCRIPT", "C", "CSHARP" }

Rules.Projects = {
	{
		id = "DATA",
		title = "ANALIZA DANYCH",
		manifest = "CSV + wykresy + szybki prototyp",
		language = "PYTHON",
		reason = "Python ma rozbudowany ekosystem do analizy danych i szybkiego prototypowania.",
	},
	{
		id = "WEB",
		title = "PANEL W PRZEGLĄDARCE",
		manifest = "interaktywny interfejs uruchamiany w przeglądarce",
		language = "JAVASCRIPT",
		reason = "JavaScript działa bezpośrednio w przeglądarce i obsługuje interakcję strony.",
	},
	{
		id = "DEVICE",
		title = "STEROWNIK CZUJNIKA",
		manifest = "mikrokontroler + mało pamięci + bezpośredni sprzęt",
		language = "C",
		reason = "C daje niskopoziomową kontrolę i ma mały narzut w systemach wbudowanych.",
	},
	{
		id = "GAME",
		title = "PROTOTYP GRY 3D",
		manifest = "scena 3D + silnik Unity + logika rozgrywki",
		language = "CSHARP",
		reason = "C# jest podstawowym językiem skryptowym w typowym projekcie Unity.",
	},
}

local function copyProject(project)
	return {
		id = project.id,
		title = project.title,
		manifest = project.manifest,
		language = project.language,
		reason = project.reason,
	}
end

function Rules.NewState()
	return {
		stage = "SCAN",
		index = 1,
		scanned = false,
		routed = {},
		errors = 0,
		completed = false,
		history = {},
	}
end

function Rules.CurrentProject(state)
	local project = Rules.Projects[state.index]
	if not project then
		return nil
	end
	return copyProject(project)
end

function Rules.ScanCurrent(state)
	if state.completed then
		return false, "Port jest już odprawiony."
	end
	local project = Rules.CurrentProject(state)
	if not project then
		return false, "Brak kontenera do skanowania."
	end
	if state.scanned then
		return false, "Manifest tego kontenera jest już otwarty."
	end
	state.scanned = true
	state.stage = "ROUTE"
	return true, project
end

function Rules.RouteCurrent(state, language)
	if state.completed then
		return false, "Port jest już odprawiony."
	end
	if not table.find(Rules.Languages, language) then
		return false, "Nieznany dok technologiczny."
	end
	local project = Rules.CurrentProject(state)
	if not project then
		return false, "Brak aktywnego kontenera."
	end
	if not state.scanned or state.stage ~= "ROUTE" then
		return false, "Najpierw zeskanuj manifest bieżącego kontenera."
	end

	if language ~= project.language then
		state.errors += 1
		return false,
			string.format("%s nie pasuje do wymagań projektu „%s”. %s", language, project.title, project.reason)
	end

	state.routed[project.id] = language
	table.insert(state.history, {
		project = project.id,
		language = language,
	})
	state.index += 1
	state.scanned = false

	if state.index > #Rules.Projects then
		state.stage = "LAUNCH"
	else
		state.stage = "SCAN"
	end

	return true,
		{
			project = project,
			language = language,
			routedCount = #state.history,
			nextProject = Rules.CurrentProject(state),
			stage = state.stage,
		}
end

function Rules.RoutedCount(state)
	return #state.history
end

function Rules.CanLaunch(state)
	if state.stage ~= "LAUNCH" then
		return false
	end
	for _, project in ipairs(Rules.Projects) do
		if state.routed[project.id] ~= project.language then
			return false
		end
	end
	return true
end

function Rules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

function Rules.Launch(state)
	if not Rules.CanLaunch(state) then
		return false, "Najpierw poprawnie odpraw wszystkie cztery projekty."
	end
	state.completed = true
	return true,
		{
			efficiency = Rules.Efficiency(state),
			errors = state.errors,
			routed = Rules.RoutedCount(state),
		}
end

function Rules.ManifestText(project)
	if not project then
		return "SKANER MANIFESTU\nBRAK ŁADUNKU"
	end
	return string.format("ŁADUNEK: %s\nWYMAGANIA: %s", project.title, project.manifest)
end

return Rules