# GAMEFORGE 12–13 — offline workstate (2026-10-14)

PP-HP-Touch jest offline w Remote Desktop Commander, więc ten plik jest buforem dowodowym do późniejszego przeniesienia do lokalnego WORKSTATE.md. Nie zastępuje FULL E2E.

## Obowiązkowa reguła 3D / Meshy
- Każda nowa plansza ma audyt ważnych prymitywnych placeholderów.
- Jeśli istnieje bezpieczny asset z SemanticAssetLibrary, placeholder jest nazwany i mapowany do tego assetu.
- Jeśli po powrocie PP-HP-Touch nie ma dobrego assetu semantycznego, obowiązkowo użyć Meshy.ai → GLB/FBX → Roblox Studio → scale/pivot/orientation/collisions/materials → kamera/wydajność.
- Po każdej lokalnej zmianie 3D wymagany świeży FULL E2E.

## SP4/12 — Kleki Studio
- Mechanika: PĘDZEL → turkus → 3 kreski → WARSTWA 2 → róż → 2 kreski → widoczność → eksport.
- 3D: semantic desk, tablet, monitor, printer, push buttons/toggle; live canvas i warstwy pozostają geometrią funkcjonalną.
- Branch static QA: ALL_OK.
- FULL E2E / kamera / runtime semantic load: PENDING — PP offline.

## SP4/13 — AI Graphics Lab
- Mechanika: brief → subject/style/privacy → generate A/B/C → ocena → iteracja promptu → human approve.
- 3D: semantic desk, scanner, control console, variant monitors, printer, push buttons.
- Branch static QA: ALL_OK.
- FULL E2E / kamera / runtime semantic load: PENDING — PP offline.

## SP5/12 — Stop-Motion Studio
- Mechanika: klatki 1→4 → tempo 4 kl./s → fizyczny preview → eksport.
- 3D: semantic camera, robot subject, desk, projector screen, control console, push buttons/toggle.
- Branch static QA: ALL_OK.
- FULL E2E / kamera / runtime semantic load: PENDING — PP offline.

## SP5/13 — Tinkercad Workshop
- Mechanika: sześcian+cylinder+klin → align → group → scale → export.
- 3D: laptop/desk/shelf/printer/controls są semantic assets.
- Sześcian, cylinder i klin są celowymi prymitywami edukacyjnymi (treść lekcji), a nie placeholderami do zastąpienia.
- Branch static QA: ALL_OK.
- FULL E2E / kamera / runtime semantic load: PENDING — PP offline.
