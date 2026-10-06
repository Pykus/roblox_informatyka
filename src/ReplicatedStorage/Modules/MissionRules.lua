local MissionRules = {}

local PriorityMissions = require(script.Parent:WaitForChild("PriorityMissions"))

local topicRules = {
	{ { "pracowni komputerowej", "zaczynamy lekcje" }, "LabSafety" },
	{
		{ "jak działa komputer", "elementy i urządzenia", "komputerze i nośnikach", "nośnikach danych" },
		"HardwareBuild",
	},
	{ { "program, system, aplikacja", "system operacyj", "systemach operacyj" }, "SoftwareSort" },
	{ { "plik", "katalog", "folder" }, "FileSort" },
	{ { "chmur", "onedrive", "google dysk" }, "CloudAccess" },
	{ { "hasł", "phishing", "cyberhigien", "bezpieczeństwo w sieci", "prywatno" }, "CyberTerminal" },
	{ { "fake news", "fałszyw", "wiarygod", "krytyczne myślenie", "manipulac" }, "SourceCheck" },
	{
		{ "paint", "grafik", "fotomontaż", "rastrow", "wektor", "korekty zdjęć", "album fotograficzny" },
		"GraphicsLab",
	},
	{ { "prezentac", "slajd", "animację", "animacja", "ścieżki ruchu" }, "PresentationLab" },
	{
		{ "tekst", "word", "dokument", "recenzj", "kolumn", "sekcj", "korespondencja seryjna", "gazetki szkolnej" },
		"DocumentRepair",
	},
	{ { "klawiatur" }, "TypingRush" },
	{
		{ "wyszukiwan informacji", "wyszukiwania informacji", "wyszukiwanie informacji", "przeglądanie stron" },
		"SearchMission",
	},
	{ { "poczt", "komunik", "netykiet" }, "CommunicationMission" },
	{ { "robot", "ozob", "mblock", "micropython" }, "RobotSequence" },
	{ { "scratch" }, "BlockProgram" },
	{ { "szyfr cezara", "szyfrow" }, "CipherVault" },
	{ { "system liczbow", "binarn", "pozycyjn" }, "BinaryVault" },
	{
		{
			"algorytm",
			"euklides",
			"wyszukiwanie wzorca",
			"porządkowanie ciągu",
			"etapy rozwiązywania zadań",
			"fibonacciego",
			"liczba jest pierwsza",
		},
		"AlgorithmPath",
	},
	{
		{
			"python",
			"języku programowania",
			"programowania tekstowego",
			"operatory przypisania",
			"instrukcje iteracyjne",
			"iteracja",
			"typy danych — listy",
			"typy danych — napisy",
		},
		"CodeRepair",
	},
	{ { "tworzenie stron", "stron internetowych", "własna strona", "opublikowanie strony", "html" }, "WebBuilder" },
	{ { "kaskadow", "css" }, "StyleLab" },
	{ { "arkusz", "excel", "formuł", "wykres", "analiza danych", "importowanie danych" }, "SpreadsheetLab" },
	{ { "sieć komputer", "internet", "usługi w sieci" }, "NetworkBuilder" },
	{ { "baza danych", "relac", "tabele", "kwerend", "filtrowanie danych", "sortowanie danych" }, "DatabaseMission" },
	{ { "sztuczna inteligenc", " ai ", "pomocą ai" }, "AICheck" },
	{ { "grafika trójwymiarowa", "3d" }, "ThreeDLab" },
	{ { "rozwój informatyki", "cyfryzacja" }, "TechHistory" },
	{ { "prawo", "własność intelektualna", "licencj" }, "DigitalLaw" },
	{ { "projekt informatyczny", "projekt edukacyjny", "projekt zespołowy" }, "ProjectQuest" },
	{ { "to już umiem", "moje prace" }, "MixedChallenge" },
}

local sectionRules = {
	{ { "grafika" }, "GraphicsLab" },
	{ { "dokument", "tekst" }, "DocumentRepair" },
	{ { "arkusz" }, "SpreadsheetLab" },
	{ { "sieci komputer" }, "NetworkBuilder" },
	{ { "relacyjna baza" }, "DatabaseMission" },
	{ { "strony www" }, "WebBuilder" },
	{ { "programowanie", "algorytm" }, "AlgorithmPath" },
	{ { "bezpieczna", "bezpieczeństwa" }, "LabSafety" },
	{ { "projekt" }, "ProjectQuest" },
}

local descriptions = {
	LabSafety = "Przejdź bezpiecznie przez pracownię i wybierz właściwe zachowanie.",
	HardwareBuild = "Uruchom komputer, odnajdując i aktywując jego kluczowe podzespoły.",
	SoftwareSort = "Rozpoznaj systemy i aplikacje, a potem przypisz je do kategorii.",
	CyberTerminal = "Rozpoznaj zagrożenie i podejmij bezpieczną decyzję.",
	CyberDefense = "Przepuszczaj bezpieczne pakiety i blokuj cyfrowe zagrożenia.",
	FileSort = "Odnajdź pliki i posegreguj je do właściwych folderów.",
	CloudAccess = "Dobierz poprawny sposób zapisu, udostępniania i dostępu.",
	SourceCheck = "Oceń źródła i wykryj manipulację lub fałszywą informację.",
	EscapeMission = "Zbieraj właściwe wskazówki i unikaj patrolujących cyfrowych zagrożeń.",
	GraphicsLab = "Zdobądź elementy projektu graficznego i ukończ cyfrową kompozycję.",
	PresentationLab = "Zbierz elementy dobrej prezentacji i przejdź przez scenę multimedialną.",
	DocumentRepair = "Napraw dokument, odnajdując potrzebne elementy i ustawienia.",
	TypingRush = "Wpisuj komendy dokładnie; bezbłędny tekst porusza maszynę.",
	SearchMission = "Wybierz skuteczniejszą strategię wyszukiwania informacji.",
	CommunicationMission = "Wybierz właściwy sposób komunikacji i zachowania online.",
	RobotSequence = "Zaprogramuj robota, aktywując polecenia we właściwej kolejności.",
	BlockProgram = "Ułóż bloki programu we właściwej kolejności.",
	CodeRepair = "Znajdź poprawny wynik lub poprawkę kodu i otwórz cyfrowy sejf.",
	PythonLab = "Napisz kod w składni Pythona i steruj robotem bezpośrednio na planszy.",
	AlgorithmPath = "Ułóż kolejne etapy algorytmu prowadzącego do celu.",
	SpreadsheetLab = "Rozwiąż zadanie arkuszowe i otwórz sejf danych.",
	DataFactory = "Przeprowadź dane przez stacje i uruchom poprawny wynik.",
	NetworkBuilder = "Uruchom sieć, aktywując jej kluczowe elementy.",
	WebBuilder = "Zbuduj strukturę strony, łącząc jej najważniejsze elementy.",
	StyleLab = "Uruchom warstwy stylu i doprowadź stronę do właściwego wyglądu.",
	DatabaseMission = "Zbuduj działający model danych z tabel, kluczy, relacji i kwerend.",
	CipherVault = "Odszyfruj wiadomość i otwórz cyfrowy sejf.",
	BinaryVault = "Przelicz zapis liczby i otwórz cyfrowy sejf.",
	AICheck = "Oceń wynik narzędzia AI i wskaż, co wymaga weryfikacji.",
	ThreeDLab = "Zbuduj scenę 3D z podstawowych elementów.",
	TechHistory = "Odnajdź rozsiane fragmenty osi rozwoju technologii.",
	DigitalLaw = "Podejmij zgodną z prawem i etyką decyzję cyfrową.",
	ProjectQuest = "Zbierz elementy potrzebne do ukończenia projektu informatycznego.",
	MixedChallenge = "Przejdź podsumowującą próbę wiedzy i zręczności.",
	GenericChallenge = "Zdobądź wszystkie fragmenty wiedzy i dotrzyj do wyjścia.",
}

local variantDescriptions = {
	ai_paint_print = "Stwórz pomysł z AI, popraw go w Paint i przygotuj wydruk.",
	layered_graphics_text = "Zbuduj grafikę warstwową, dodaj czytelny tekst i uporządkuj kompozycję.",
	document_table_graphics = "Utwórz dokument z tabelą i grafiką oraz uporządkuj układ.",
	python_practice = "Rozwiąż krótkie zadania w Pythonie i popraw błędy w kodzie.",
	screen_object_control = "Napisz logikę sterowania obiektem i przeprowadź go przez tor na ekranie.",
	fibonacci = "Zbuduj algorytm ciągu Fibonacciego i sprawdź wynik.",
	spreadsheet_chart = "Policz dane w arkuszu i pokaż właściwy zakres na wykresie.",
	web_publish = "Sprawdź stronę i wybierz poprawny sposób publikacji w internecie.",
}

local function normalize(s)
	return string.lower(tostring(s or ""))
end

local function matchRules(text, rules)
	for _, rule in ipairs(rules) do
		for _, needle in ipairs(rule[1]) do
			if string.find(text, needle, 1, true) then
				return rule[2]
			end
		end
	end
	return nil
end

function MissionRules.GetMissionType(topic, section)
	local byTopic = matchRules(normalize(topic), topicRules)
	if byTopic then
		return byTopic
	end

	local bySection = matchRules(normalize(section), sectionRules)
	if bySection then
		return bySection
	end

	return "GenericChallenge"
end

function MissionRules.GetDescription(missionType, variant)
	return variantDescriptions[variant] or descriptions[missionType] or descriptions.GenericChallenge
end
function MissionRules.GetForLesson(lesson, grade)
	local priority = grade and PriorityMissions.Get(grade, lesson.nr) or nil
	local missionType = priority and priority.type or MissionRules.GetMissionType(lesson.topic, lesson.section)
	return {
		type = missionType,
		name = priority and priority.name or lesson.topic,
		variant = priority and priority.variant or "legacy",
		difficulty = priority and priority.difficulty or 1,
		available = priority ~= nil,
		description = MissionRules.GetDescription(missionType, priority and priority.variant or nil),
		topic = lesson.topic,
		section = lesson.section,
		number = lesson.nr,
		hours = lesson.hours,
		material = lesson.material,
		folder = lesson.folder,
	}
end

return MissionRules