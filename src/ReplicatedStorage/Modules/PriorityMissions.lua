local PriorityMissions = {}

PriorityMissions.AvailableFrom = 1
PriorityMissions.AvailableTo = 11
PriorityMissions.AvailableFromByGrade = { SP4 = 3, SP5 = 3, SP6 = 3, SP7 = 3, SP8 = 3, LO1 = 3, LO2 = 1, LO3 = 1 }

PriorityMissions.Data = {
	SP4 = {
		[3] = { type = "SoftwareSort", name = "System czy aplikacja?", variant = "software", difficulty = 1 },
		[4] = { type = "FileSort", name = "Porządek w plikach", variant = "files", difficulty = 1 },
		[5] = { type = "CloudAccess", name = "Chmura bez chaosu", variant = "cloud", difficulty = 1 },
		[6] = { type = "CyberDefense", name = "Cyber Defense: chroń konto", variant = "passwords", difficulty = 2 },
		[7] = { type = "EscapeMission", name = "Ucieczka z fabryki fake newsów", variant = "sources", difficulty = 2 },
		[8] = { type = "GraphicsLab", name = "Studio Paint: kształty", variant = "paint_shapes", difficulty = 1 },
		[9] = { type = "GraphicsLab", name = "Studio Paint: tekst i zapis", variant = "paint_text", difficulty = 2 },
		[10] = {
			type = "GraphicsLab",
			name = "Studio Paint: kompozycja",
			variant = "paint_composition",
			difficulty = 2,
		},
		[11] = {
			type = "GraphicsLab",
			name = "AI Paint: od pomysłu do wydruku",
			variant = "ai_paint_print",
			difficulty = 2,
		},
	},
	SP5 = {
		[3] = { type = "TechHistory", name = "Oś czasu komputerów", variant = "timeline", difficulty = 1 },
		[4] = { type = "CyberDefense", name = "Cyber Defense: bezpieczna sieć", variant = "cyber", difficulty = 2 },
		[5] = {
			type = "EscapeMission",
			name = "Search Escape: znajdź dobre wyniki",
			variant = "search",
			difficulty = 1,
		},
		[6] = { type = "EscapeMission", name = "Internetowy detektyw", variant = "research", difficulty = 2 },
		[7] = {
			type = "AlgorithmPath",
			name = "Misja: rozwiązanie problemu",
			variant = "problem_solving",
			difficulty = 2,
		},
		[8] = { type = "TypingRush", name = "Klawiaturowy sprint", variant = "typing", difficulty = 1 },
		[9] = { type = "GraphicsLab", name = "Graficzne sztuczki", variant = "graphics_tricks", difficulty = 2 },
		[10] = { type = "GraphicsLab", name = "Transformator obrazu", variant = "image_transform", difficulty = 2 },
		[11] = {
			type = "GraphicsLab",
			name = "Studio warstw: grafika i tekst",
			variant = "layered_graphics_text",
			difficulty = 2,
		},
	},
	SP6 = {
		[3] = { type = "CyberDefense", name = "Cyber Defense: fala zagrożeń", variant = "threats", difficulty = 2 },
		[4] = { type = "HardwareBuild", name = "Cyfrowe urządzenia", variant = "devices", difficulty = 1 },
		[5] = { type = "GraphicsLab", name = "FotoLab I", variant = "photo_edit_1", difficulty = 2 },
		[6] = { type = "GraphicsLab", name = "FotoLab II", variant = "photo_edit_2", difficulty = 2 },
		[7] = { type = "BlockProgram", name = "Scratch: pętla i zmienne", variant = "scratch_loop", difficulty = 2 },
		[8] = {
			type = "BlockProgram",
			name = "Scratch: tło, duszki i dźwięk",
			variant = "scratch_media",
			difficulty = 2,
		},
		[9] = { type = "PresentationLab", name = "Animowana prezentacja", variant = "slides_animation", difficulty = 2 },
		[10] = { type = "PresentationLab", name = "Przejścia i dźwięk", variant = "slides_sound", difficulty = 2 },
		[11] = {
			type = "DocumentRepair",
			name = "Dokument z tabelą i grafiką",
			variant = "document_table_graphics",
			difficulty = 2,
		},
	},
	SP7 = {
		[3] = { type = "AlgorithmPath", name = "JavaBlock: algorytm w ruchu", variant = "javablock", difficulty = 2 },
		[4] = {
			type = "BinaryVault",
			name = "Jak komputer widzi dane",
			variant = "data_representation",
			difficulty = 2,
		},
		[5] = { type = "MixedChallenge", name = "Finał rozdziału", variant = "chapter_finale", difficulty = 2 },
		[6] = { type = "BlockProgram", name = "Scratch: zdarzenia", variant = "scratch_events", difficulty = 2 },
		[7] = {
			type = "BlockProgram",
			name = "Scratch: projekt specjalny",
			variant = "scratch_project",
			difficulty = 2,
		},
		[8] = { type = "RobotSequence", name = "Programujemy robota", variant = "robot", difficulty = 2 },
		[9] = { type = "AlgorithmPath", name = "Od bloków do pseudokodu", variant = "pseudocode", difficulty = 2 },
		[10] = {
			type = "PythonLab",
			name = "Pierwszy Python: zaprogramuj robota",
			variant = "python_robot_intro_sp7",
			difficulty = 2,
		},
		[11] = {
			type = "PythonLab",
			name = "Python: laboratorium ćwiczeń",
			variant = "python_practice",
			difficulty = 2,
		},
	},
	SP8 = {
		[3] = { type = "DataFactory", name = "Fabryka wykresów", variant = "charts", difficulty = 2 },
		[4] = { type = "DataFactory", name = "Fabryka arkusza", variant = "spreadsheet_use", difficulty = 2 },
		[5] = { type = "PythonLab", name = "Python: steruj robotem", variant = "python_robot_maze_sp8", difficulty = 2 },
		[6] = {
			type = "PythonLab",
			name = "Python: program porusza świat",
			variant = "python_world_control_sp8",
			difficulty = 2,
		},
		[7] = { type = "AlgorithmPath", name = "Algorytmy na liczbach", variant = "natural_numbers", difficulty = 3 },
		[8] = { type = "AlgorithmPath", name = "Wyścig wyszukiwania", variant = "search_algorithm", difficulty = 3 },
		[9] = { type = "AlgorithmPath", name = "Sortowanie na czas", variant = "sorting", difficulty = 3 },
		[10] = { type = "ProjectQuest", name = "Reporter szkolnego sportu", variant = "sports_media", difficulty = 2 },
		[11] = {
			type = "PythonLab",
			name = "Sterowanie obiektem na ekranie",
			variant = "screen_object_control",
			difficulty = 3,
		},
	},
	LO1 = {
		[3] = { type = "CodeRepair", name = "Języki programowania", variant = "languages", difficulty = 2 },
		[4] = {
			type = "PythonLab",
			name = "Python Command Yard: pierwsze polecenia",
			variant = "python_robot_intro",
			difficulty = 2,
		},
		[5] = {
			type = "PythonLab",
			name = "Parameter Lab: zmienna steruje maszyną",
			variant = "python_variables",
			difficulty = 2,
		},
		[6] = { type = "CodeRepair", name = "Funkcje matematyczne", variant = "math_functions", difficulty = 2 },
		[7] = { type = "AlgorithmPath", name = "Warunki w Pythonie", variant = "conditions", difficulty = 3 },
		[8] = { type = "CodeRepair", name = "Logika w kodzie", variant = "logic", difficulty = 3 },
		[9] = {
			type = "PythonLab",
			name = "Loop Factory: pętla for",
			variant = "python_loop",
			difficulty = 3,
		},
		[10] = {
			type = "AlgorithmPath",
			name = "Sequence Reactor: generator ciągów",
			variant = "sequences",
			difficulty = 3,
		},
		[11] = { type = "AlgorithmPath", name = "Generator Fibonacciego", variant = "fibonacci", difficulty = 3 },
	},
	LO2 = {
		[1] = { type = "AlgorithmPath", name = "Łowca liczb pierwszych", variant = "prime_numbers", difficulty = 2 },
		[2] = { type = "CodeRepair", name = "Laboratorium list", variant = "python_lists", difficulty = 2 },
		[3] = {
			type = "BinaryVault",
			name = "Vault 2/10/16: jedna wartość",
			variant = "number_systems",
			difficulty = 2,
		},
		[4] = {
			type = "BinaryVault",
			name = "Conversion Machine: zmiana reprezentacji",
			variant = "conversion",
			difficulty = 3,
		},
		[5] = { type = "AlgorithmPath", name = "Rail Sort: koszt manewrów", variant = "linear_sort", difficulty = 3 },
		[6] = { type = "PythonLab", name = "Message Lab: napisy w Pythonie", variant = "strings", difficulty = 2 },
		[7] = { type = "AlgorithmPath", name = "Forensic Text Scanner", variant = "text_algorithms", difficulty = 3 },
		[8] = { type = "CipherVault", name = "Cipher Ring Vault: szyfr Cezara", variant = "caesar", difficulty = 3 },
		[9] = {
			type = "DocumentRepair",
			name = "Fabryka korespondencji seryjnej",
			variant = "mail_merge",
			difficulty = 2,
		},
		[10] = { type = "DataFactory", name = "Dock danych: import CSV/TXT", variant = "data_import", difficulty = 2 },
		[11] = {
			type = "SpreadsheetLab",
			name = "Arkusz i wykres danych",
			variant = "spreadsheet_chart",
			difficulty = 2,
		},
	},
	LO3 = {
		[1] = {
			type = "SearchMission",
			name = "Polowanie na wzorzec",
			variant = "naive_pattern_search",
			difficulty = 2,
		},
		[2] = { type = "PythonLab", name = "Robotyka MicroPython", variant = "python_robot_program", difficulty = 2 },
		[3] = { type = "TechHistory", name = "Chrono Museum: awaria czasu", variant = "tech_history", difficulty = 2 },
		[4] = {
			type = "DigitalLaw",
			name = "Decision City: cyfrowe kompromisy",
			variant = "digitization",
			difficulty = 2,
		},
		[5] = {
			type = "SoftwareSort",
			name = "PC Emergency Room: systemowy serwis",
			variant = "os_troubleshooting",
			difficulty = 2,
		},
		[6] = {
			type = "NetworkBuilder",
			name = "Internet Construction Yard: od ISP do Wi-Fi",
			variant = "internet",
			difficulty = 2,
		},
		[7] = {
			type = "NetworkBuilder",
			name = "Service District: DNS, WWW, poczta i chmura",
			variant = "network_services",
			difficulty = 3,
		},
		[8] = { type = "WebBuilder", name = "HTML Construction Studio: żywy DOM", variant = "html", difficulty = 2 },
		[9] = { type = "StyleLab", name = "CSS Style Reactor: live preview", variant = "css", difficulty = 2 },
		[10] = { type = "WebBuilder", name = "Launch Day: moja strona WWW", variant = "website", difficulty = 3 },
		[11] = { type = "WebBuilder", name = "Publikujemy stronę WWW", variant = "web_publish", difficulty = 2 },
	},
}

function PriorityMissions.Get(grade, lessonNo)
	local gradeData = PriorityMissions.Data[grade]
	return gradeData and gradeData[lessonNo] or nil
end

function PriorityMissions.IsAvailable(grade, lessonNo)
	return PriorityMissions.Get(grade, lessonNo) ~= nil
end

return PriorityMissions