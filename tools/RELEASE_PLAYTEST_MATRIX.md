# CyberEscapeRoom — release PlayTest matrix

Automatyczny smoke: `powershell -ExecutionPolicy Bypass -File tools/build_release_smoke.ps1` → otwórz dokładnie świeżo zbudowany `build/playtest/CyberEscapeRoom_RELEASE_QA.rbxlx` → PlaySolo → po zakończeniu uruchom `powershell -ExecutionPolicy Bypass -File tools/check_release_smoke.ps1`. W pierwszej rodzinie klient QA celowo podmienia całe workspace.CurrentCamera na nową Scriptable kamerę z błędnym FOV/zoom; mission-only self-heal musi przechwycić nowy obiekt i przywrócić Custom, Humanoid, FOV 70 i zoom 5–16 przed raportem. Wymagane: zgodny BUILD_ID bieżącego QA builda, komplet PASS/client-verified PASS równy aktualnej macierzy, 0 FAIL i ALL_OK. Checker ignoruje PASS-y sprzed markera BUILD_ID bieżącego builda. Potem wykonaj poniższy manualny gate wizualny.

Po zalogowaniu do Roblox Studio wykonaj w jednej instancji reprezentatywne testy rodzin plansz. Automatyczny smoke dodatkowo wymaga dla każdej z 40 rodzin: żywego Humanoida, WalkSpeed >=8, niezakotwiczonego HumanoidRootPart i kolizyjnego podłoża maks. 16 studów pod spawnem. Każda rodzina musi też mieć co najmniej jeden faktycznie widoczny world-label; aktywne SurfaceGui/BillboardGui muszą mieć LightInfluence=0 i Brightness>=1.1, a każdy renderowany world-text minimum 18 px, kontrastowy stroke oraz TextBounds w całości mieszczące się w AbsoluteSize etykiety. `TextFits` nie jest używany dla world BillboardGui, bo Roblox zwraca dla części TextScaled billboardów fałszywe `false` mimo poprawnych bounds. Wyłączone/ukryte markery oraz world GUI bez dodatniego `AbsoluteSize` (np. BillboardGui poza aktualnym render/zasięgiem) nie są liczone do runtime czytelności; każda rodzina nadal musi mieć co najmniej jeden faktycznie renderowany label. Każdy skalowany napis HUD/świata ma mieć dokładnie jeden UITextSizeConstraint; QA celowo dokłada spóźniony drugi constraint i wymaga jego automatycznego scalenia. Żaden ukryty lub wyłączony TextBox nie może zachować focusu i blokować WASD/kamery; otwarcie LEKCJE ma zwolnić bieżący TextBox i podnieść menu ponad Python/Typing modal, a start nowej lekcji ponownie zwolnić focus; pierwszy przypadek QA celowo skupia TextBox, ukrywa go i wymaga automatycznego zwolnienia focusu. Dla każdego testu sprawdź: kamera obraca się myszą/touchem, zoom 5–16 działa, CEL jest czytelny i jego TextBounds w całości mieszczą się w polu HUD, napisy świata są widoczne, pierwsza akcja jest oczywista, co najmniej jedna interakcja działa i można wrócić/ukończyć etap bez utknięcia. Na telefonie przycisk LEKCJE nie może nachodzić na dolne strefy joysticka/skoku ani notification; w low-landscape jest przy górnej krawędzi y=12, na krótkim portrait y=210, poza aktywną misją ma być ukryty. Zminimalizowany Python Lab nie może kłaść przycisku PYTHON na prawym dolnym przycisku skoku — reopen ma pozostać po prawej, ale nad strefą CoreGui. Python Lab na bardzo niskim landscape (<360 px) musi mieścić cały panel z min. 8 px marginesem; QA obejmuje 568×320. Typing Terminal ma ten sam wymóg i nie może nakładać input/status/submit. Komunikaty sukcesu/błędu na touch mają kończyć się nad dolną strefą sterowania: portrait min. 120 px, zwykły low-landscape 110 px, a <360 px wysokości 120 px od dołu. Na low-landscape tekst skaluje się tylko 16–22 px; notification nie może nachodzić na HUD ani joystick/skok. Na niskim landscape HUD ma zajmować najwyżej 126 px / 40% wysokości ekranu; CEL skaluje się wyłącznie 16–20 px i HUD rezerwuje miejsce dla LEKCJE. QA obejmuje 568×320 oraz ekstremalne 390×320, gdzie pomocnicza linia sterowania znika na rzecz większego pola CEL. Na krótkim portrait (<560 px wysokości) HUD ma mieć najwyżej 192 px / 40%; QA obejmuje 390×480 i 320×480. Na planszach z ProximityPrompt automatyczny smoke wymaga najbliższej pierwszej akcji w odległości ≤80 studów od startu, MaxActivationDistance ≥8, `RequiresLineOfSight=false` dla każdego aktywnego promptu oraz niepustych ActionText/ObjectText. W PlayTeście powinien pojawić się niebieski znacznik ZACZNIJ TUTAJ oraz pionowy pulsujący beacon nad pierwszą aktywną interakcją, także gdy prompt zreplikuje się później niż HUD; mają pozostać widoczne do 20 s i zniknąć tylko po użyciu właśnie oznaczonego promptu; kliknięcie innego promptu nie może go skasować. Automatyczny smoke dodatkowo restartuje SP4/03 z tym samym tytułem i wymaga, żeby guide pojawił się ponownie dla nowej instancji misji. Następnie wykonuje prawdziwy respawn postaci (`LoadCharacter`): aktywny model i postęp muszą przetrwać, postać ma wrócić maks. 8 studów od StartPad, a kamera, CEL i guide mają się odtworzyć. Respawn ma przywrócić ostatni faktycznie wyświetlany CEL/wynik/czas, nie początkowy tekst etapu 1. Zablokowany RDZEŃ/WYJŚCIE nie może dostać tego znacznika.

| Rodzina | Reprezentant | Co sprawdzić poza wspólnym gate |
|---|---|---|
| Klasyfikacja | SP4/03 Software Tower | moduł trafia do właściwego urządzenia |
| Pliki | SP4/04 File Warehouse | taśma + routing plików |
| Chmura | SP4/05 Cloud Sync | dwa urządzenia + synchronizacja |
| Cyberbezpieczeństwo | SP4/06 Cyber Defense | hasło → phishing → MFA |
| Dowody/źródła | SP4/07 Newsroom | tablica dowodów + hamulec + realna kamera/biurko/monitor/skaner (4/4 semantic assets) |
| Edytor grafiki | SP4/08 Paint Shapes | narzędzie → slot → live canvas + realne biurko/monitor/klawiatura/mysz (4/4 semantic assets) |
| Historia/timeline | SP5/03 Timeline Museum | eksponat + ruch platformy |
| Wyszukiwanie WWW | SP5/05 Search Escape | zapytanie otwiera właściwą drogę |
| Problem solving | SP5/07 Factory | pomiar → diagnoza → naprawa |
| Typing | SP5/08 Terminal Run | startowy terminal + widoczne UI + dokładność wpisu |
| Hardware | SP6/04 Inventor Workshop | moduły + przewody + test |
| Foto | SP6/05 PhotoLab | kontrolki zmieniają obraz na żywo |
| Scratch/block | SP6/07 Scratch Loop Grid | blok/zmienna steruje światem |
| Prezentacja | SP6/09 Animation Lab | animacja i preview |
| Finał mieszany | SP7/05 Cyber Escape Finale | algorytm + bity + bezpieczeństwo; 4 realne push-buttony algorytmu + 8 toggle-switchy bitów + 3 przyciski bezpieczeństwa + console/scanner/terminal (18/18 semantic assets) |
| Robot/algorytm | SP7/08 Robot Rescue | energia + ładunek + trasa |
| Python | SP7/10 Python Robot Dock | kod steruje realnym semantic robotem; server rack + control console; min. 3/3 semantic assets |
| Dane/arkusz | SP8/04 Spreadsheet Factory | formuła zmienia linię produkcyjną |
| Python / sensory | SP8/05 Python Robot Maze | realny semantic robot + sensor + lasery + server rack/control console; min. 3/3 semantic assets |
| Python / world control | SP8/06 Python Power Plant | realny semantic robot + control console + automation rack; program uruchamia pompę/wentylator/most/rdzeń |
| Liczby | SP8/07 Number Foundry | modulo + fizyczna klasyfikacja |
| Search algorithm | SP8/08 Search Race | linear vs binary |
| Sortowanie | SP8/09 Sorting Arena | porównanie + zamiana |
| Media | SP8/10 Sports Newsroom | skan → wykres → kamera → publikacja |
| Dobór technologii | LO1/03 Language Port | manifest → dok → kontener |
| Pierwsze polecenia Python | LO1/04 Python Command Yard | print("START") → move(2) → trzy polecenia sterują fizycznym wózkiem i robotem |
| Zmienne w Pythonie | LO1/05 Parameter Lab | kalibracja → jedna zmienna steruje 2 siłownikami → reuse w trasie robota + realna konsola/monitor/szafa automatyki (3/3 semantic assets) |
| Funkcje | LO1/06 Math Engine | sqrt/floor/ceil poruszają maszynami |
| Warunki | LO1/07 Decision Drone | operator/próg → IF/ELSE na 3 danych |
| Logika | LO1/08 Logic Gate Control | przełączniki → AND/OR/NOT → live przewody → bariery |
| Pętla Python | LO1/09 Loop Factory | prawdziwy for/range → live iteracje → fizyczna linia + debug off-by-one |
| Ciągi | LO1/10 Sequence Reactor | reguła → skan błędu → generator → fizyczny most wartości |
| Systemy pozycyjne | LO2/03 Vault 2/10/16 | 6 realnych toggle-switchy bitów → dziesiętne cyfry → koła HEX → wspólny sejf (6/6 semantic assets) |
| Konwersja systemów | LO2/04 Conversion Machine | dzielenie przez 2 → stos reszt → dzielenie przez 16 → weryfikacja HEX |
| Sortowanie liniowe | LO2/05 Rail Sort | sąsiednie wagony → koszt manewrów → bocznica → odjazd; 4 realne push-buttony swapów + toggle nastawni + dispatch console (6/6 semantic assets) |
| Napisy w Pythonie | LO2/06 Message Lab | strip/lower → replace → slice+len → kapsuła komunikatu; realne CLEAN/SLICE scanners + REPLACE console + live preview monitor (4/4 semantic assets) |
| Algorytmy tekstowe | LO2/07 Forensic Text Scanner | okno KOD42 → licznik BANANA → dwa wskaźniki KOTEK/early-exit |
| Szyfr Cezara | LO2/08 Cipher Ring Vault | pierścień +3 → KHOOR→HELLO → wraparound XYZ→ABC → rygle sejfu |
| Korespondencja seryjna | LO2/09 Mail Merge Factory | mapowanie pól → podgląd 3 rekordów → druk |
| Import danych | LO2/10 Data Import Dock | format → nagłówki → kolumny → gotowy import |
| Historia technologii | LO3/03 Chrono Museum | eksponaty → chronologia → przywrócenie osi czasu |
| Cyfryzacja | LO3/04 Decision City | kompromisy → konsekwencje → decyzje w mieście |
| Diagnostyka systemu | LO3/05 PC Emergency Room | triage → narzędzie → naprawa → test 3 komputerów |
| Internet/topologia | LO3/06 Internet Construction Yard | FIBER/ETHERNET + porty → 5 łączy → test pakietu PC i Wi‑Fi |
| Usługi sieciowe | LO3/07 Network Service District | skan żądania → DNS/WWW/MAIL/CLOUD → fizyczny pakiet + wynik usługi |
| HTML | LO3/08 HTML Construction Studio | tagi → DOM → href → walidator + realne biurko/laptop/mysz/krzesło developera (4/4 semantic assets) |
| CSS | LO3/09 CSS Style Reactor | brief → style → live preview → walidator |
| Publikacja WWW | LO3/10 Launch Day Website | checklista → routing → launch |

Gate publikacji jest zielony dopiero po przejściu tej macierzy bez krytycznego problemu kamery, HUD, czytelności lub pierwszej akcji. Manualny gate wykonaj co najmniej w 1366×768 oraz w wąskim emulatorze telefonu: CEL nie może się ucinać, sterowanie ma się zawijać, a notification pozostaje nad dolną krawędzią.