# Cyber Escape Room

Szkolna gra Roblox powiązana z planem informatyki SP4–SP8 i LO1–LO3.

## Stan
- 185 tematów z centralnego planu lekcji.
- 0 tematów bez przypisanego typu gry.
- Mechaniki: Decision, Sort, Collect, Sequence, Vault, Build, Hunt oraz PythonLab.
- Osobne scenografie dla sprzętu komputerowego, sieci, WWW/CSS, baz danych, grafiki, robotyki i kodu.
- Punkty, czas, hazard/firewall, checkpoint i brama końcowa.
- Ranking leaderstats/Punkty.

## Uruchomienie lokalne
1. Otwórz build/CyberEscapeRoom.rbxlx w Roblox Studio.
2. Kliknij Play.
3. Wybierz klasę i konkretny temat.
4. Kliknij START MISJI.
5. Wykonaj zadanie, pokonaj przeszkody i aktywuj bramę wyjścia.

## Python Lab
Uczeń wpisuje kod w składni zbliżonej do Pythona, a serwer wykonuje bezpieczny, ograniczony podzbiór języka i steruje robotem na planszy.

Obsługiwane elementy:
- move(n)
- turn_left() / turn_right()
- pickup() / drop()
- print(...)
- proste zmienne liczbowe, np. kroki = 2
- for i in range(...): z jedną warstwą pętli

Nie jest używany loadstring ani dowolne wykonywanie kodu. Parser odrzuca nieznane polecenia i ma limity długości programu, ruchu, range() oraz liczby poleceń.

## Walidacja
- python tools/qa_priority.py
- python tools/qa_curriculum.py
- lune run tools/test_python_subset.luau
- stylua --check <zmienione pliki .lua>
- rojo build default.project.json -o build/CyberEscapeRoom.rbxlx
- git diff --check

Warunek mapowania: LESSONS=185, GENERIC=0, MISSING_ARCHETYPE=0.

## Publikacja
Nie publikować wersji z niezamkniętym Play Testem/regresją. Publikacja Roblox może wymagać aktywnej sesji konta i ewentualnego 2FA.