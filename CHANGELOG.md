[Reading 42 lines from start (total: 42 lines, 0 remaining)]

[Reading 37 lines from start (total: 37 lines, 0 remaining)]

[Reading 26 lines from start (total: 26 lines, 0 remaining)]

# Changelog

## 2026-09-29
- SP5/11 otrzymał dedykowaną misję `LayeredGraphicsTextLab`: kolejność warstw → kontrast i pozycja tekstu → zapis pliku roboczego i eksport PNG; dodano QA i dedykowany dispatch.
- SP4/11 otrzymał dedykowaną misję `AIPaintPrintLab`: bezpieczny prompt AI → własne poprawki w Paint → poprawne ustawienia wydruku; dodano osobny QA i dedykowany dispatch.
- rozpoczęto temat 11 dla wszystkich 8 poziomów (SP4–LO3),
- dodano 8 grywalnych wariantów tematu 11 i zwiększono pulę aktywnych misji do 76,
- dodano dedykowane opisy celów dla wariantów tematu 11,
- poprawiono nieaktualny komunikat menu o zakresie dostępnych lekcji,
- dodano qa_lesson11.py; 8/8 mapowań zgodnych z Curriculum.lua,
- pełny pakiet qa_*.py i test_*.luau przechodzi bez błędów.

- rozszerzono grywalny zakres LO2 o tematy 01–02: liczby pierwsze i listy,
- rozszerzono grywalny zakres LO3 o tematy 01–02: wyszukiwanie wzorca i robotyka/MicroPython,
- liczba priorytetowych grywalnych misji wzrosła z 64 do 68,
- zaktualizowano walidację zakresu i ponownie potwierdzono: PRIORITY_LEVELS=68, ERRORS=0, LESSONS=185, GENERIC=0, MISSING_ARCHETYPE=0,
- testy podzbioru Python/Luau ponownie przechodzą bez błędów.

# Changelog

## 2026-09-27
- podpięto 185 tematów z planu UONET ↔ podręczniki,
- dodano wybór SP4–SP8 i LO1–LO3 oraz konkretnych tematów,
- dodano mapowanie temat → typ minigry,
- dodano mechaniki Decision / Sort / Collect / Sequence / Vault / Build / Hunt,
- dodano scenografie tematyczne: PC, serwerownia/sieć, przeglądarka WWW/CSS, baza danych, grafika/prezentacja, robot/algorytm, kod/sejf, cyberbezpieczeństwo,
- dodano punkty, timer, firewall, checkpoint, wyjście i leaderstats,
- dodano automatyczny audyt 185 tematów,
- dodano katalog 64 priorytetowych plansz: lekcje 3–10 dla każdej klasy,
- dodano Python Lab: edytor kodu, bezpieczny parser podzbioru Pythona i robota sterowanego kodem,
- Python Lab obsługuje move/turn/pickup/drop/print, proste zmienne i for ... in range(...),
- dodano testy parsera w Lune: poprawna trasa, zmienne, pętla, limity i odrzucanie niedozwolonych poleceń,
- wynik QA: 185/185, GENERIC=0, MISSING_ARCHETYPE=0; plansze priorytetowe 64/64.