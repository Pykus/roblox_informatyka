# CyberEscapeRoom — execution matrix for lessons 12–13 (WIP)

This branch is preparation only. Do not merge or publish until the current PP-HP-Touch worktree is rebased/compared and every changed board passes fresh Roblox Studio FULL E2E.

## Mandatory 3D / Meshy gate

For every board touched or tested:
1. Audit important primitive placeholders.
2. Prefer an existing safe semantic asset from SemanticAssetLibrary when it fits the object.
3. If no good semantic asset exists, generate the missing prop on Meshy.ai on PP-HP-Touch, export GLB/FBX, import in Roblox Studio, fix scale/pivot/orientation/collisions/materials, then check performance and real camera.
4. At least one meaningful 3D improvement per tested board when a placeholder exists.
5. After any 3D change run fresh FULL E2E: launch, first action, all stages, error/retry path, finale, exit/return, camera rotation/zoom, HUD/CEL, world text, mobile/touch, performance.
6. Record asset source, primitive replaced, performance result and E2E evidence in WORKSTATE.md.

## Existing safe semantic assets to reuse first

desktop, laptop, monitor, printer, serverRack, switch, camera, chair, shelf, keyboard, mouse, toolbox, robot, drone, router, tablet, desk, table, projector, speaker, microphone, crate, cabinet, phone, scanner, controlConsole, computerTerminal, projectorScreen, toggleSwitch, pushButton.

## 16-board implementation queue

| Board | Curriculum topic | Game concept / required actions | 3D direction |
|---|---|---|---|
| SP4/12 | Kleki — nowe możliwości cyfrowego rysowania online | **Digital Art Dock.** Stage 1: choose brush/size/color on a physical drawing console and paint 3 marked zones. Stage 2: use layer/undo-style stations to repair a bad composition. Finale: gallery wall lights and exports the picture. Minimum actions: choose tool, paint, correct/reorder, publish. | Reuse tablet + monitor + desk + projectorScreen; replace any blocky drawing tablet/easel with semantic assets. Meshy only if a convincing stylus/easel is still missing. |
| SP4/13 | AI w grafice — jak pomaga w twórczości | **Prompt-to-Poster Studio.** Stage 1: assemble prompt cards describing subject/style/detail; preview machine changes a poster. Stage 2: detect two AI mistakes and correct prompt constraints. Finale: print/exhibit accepted poster. | controlConsole + monitor + printer + projectorScreen. Meshy candidate: friendly image-generator kiosk if primitives dominate. |
| SP5/12 | Prosta animacja poklatkowa z własnych rysunków | **Stop-Motion Stage.** Stage 1: position character through 3 poses and capture frames. Stage 2: fix wrong frame order/timing, preview animation. Finale: cinema projector runs finished sequence. | camera + projector + projectorScreen + table; Meshy candidate: low-poly stop-motion puppet if only cubes exist. |
| SP5/13 | Tinkercad — pierwszy projekt 3D | **Shape Forge 3D.** Stage 1: combine primitive solids to match silhouette. Stage 2: use hole/group/align-like stations to cut and assemble final object. Finale: fabrication platform raises finished model. | toolbox + controlConsole + table; semantic assets for workstation. Meshy candidate: finished target model/3D-printer shell if no safe semantic equivalent. |
| SP6/12 | Dokument wielostronicowy / gazetka szkolna | **Newsroom Layout Press.** Stage 1: route title/text/image blocks onto two pages. Stage 2: repair overflow, columns and page order. Finale: printing press outputs newspaper stack. | printer + desk + monitor + shelf. Meshy only for press machinery if primitives remain visually dominant. |
| SP6/13 | Film ze zdjęć w Clipchamp | **Editing Bay.** Stage 1: place 4 clips/photos on timeline in order. Stage 2: add transition/audio and remove one bad clip. Finale: render progress lights then projector premiere. | monitor + camera + speaker + projectorScreen + controlConsole. Meshy candidate: timeline console shell if needed. |
| SP7/12 | Rozwiązywanie problemów z arkuszem kalkulacyjnym | **Spreadsheet Logistics Center.** Stage 1: enter/repair data cells to meet constraints. Stage 2: choose formulas that reroute physical cargo totals. Finale: warehouse dispatch opens. | scanner + crate + computerTerminal + shelf. Reuse existing spreadsheet motifs but new physical logistics layout. |
| SP7/13 | Prezentowanie danych w postaci wykresu | **Chart Observatory.** Stage 1: select correct chart family for physical data towers. Stage 2: calibrate labels/axes and fix misleading scale. Finale: large holographic-style chart rises. | projector + projectorScreen + controlConsole; Meshy candidate: observatory instrument only if necessary. |
| SP8/12 | Historia i rozwój informatyki | **Computing Time Vault.** Stage 1: place 4 milestones in chronological bays. Stage 2: connect inventions to consequences/capabilities. Finale: timeline corridor powers on from past to future. | desktop + laptop + phone + serverRack. Use semantic assets as milestone exhibits instead of cubes. |
| SP8/13 | Informatyka w moim przyszłym życiu | **Future Systems Hub.** Stage 1: route 4 real-life scenarios to useful computing systems. Stage 2: balance privacy/automation/human-control choices. Finale: city model activates. | drone + robot + serverRack + phone + controlConsole. Meshy candidate: distinctive smart-city centerpiece if needed. |
| LO1/12 | Algorytm Euklidesa | **GCD Gearworks.** Stage 1: repeatedly feed two numbers into modulo/division machines. Stage 2: repair one wrong remainder chain and finish NWD. Finale: two gear trains synchronize only at gcd. | controlConsole + mechanical geometry; Meshy candidate: two interlocking industrial gear assemblies if primitives are visually weak. |
| LO1/13 | Prawo i zasady bezpieczeństwa | **Digital Rights Incident Room.** Stage 1: inspect 3 evidence stations (license/privacy/source). Stage 2: choose lawful/safe remediation actions and document attribution. Finale: compliance vault opens. | scanner + laptop + cabinet + camera; semantic assets should cover most props. |
| LO2/12 | Analiza danych | **Data Investigation Lab.** Stage 1: clean outliers/missing records. Stage 2: filter/group and derive a conclusion that physically changes dashboard displays. Finale: decision board resolves case. | monitor + scanner + serverRack + controlConsole. Meshy candidate: lab analyzer only if needed. |
| LO2/13 | Tabele i relacje między nimi | **Relational Data Depot.** Stage 1: place PK/FK connectors between physical table racks. Stage 2: repair one-to-many links and reject invalid duplicate key. Finale: data packets travel across correct relations. | serverRack + switch + cabinet + cable geometry. Meshy candidate: relational junction device if primitive-only. |
| LO3/12 | Projekt informatyczny podsumowujący | **Systems Integration Mission.** Stage 1: choose components from web/data/code/security stations to satisfy brief. Stage 2: integrate and debug two cross-system failures. Finale: project control room launches solution. | broad reuse: serverRack, router, monitor, controlConsole, projector. Must feel like integrated facility, not quiz hub. |
| LO3/13 | Projekt edukacyjny z poznanymi narzędziami | **Capstone Exhibition.** Stage 1: build a deliverable path from research → artifact → presentation. Stage 2: test accessibility/source attribution and repair one failure. Finale: exhibition hall opens and project goes live. | projectorScreen + camera + microphone + laptop + display stands. Meshy candidate: custom exhibition centerpiece if semantic library is insufficient. |

## Quality gate per board

- At least 2 stages and at least 3 meaningful player actions.
- Target understood within 5 seconds.
- First action obvious and physically close to spawn.
- Error path gives concrete debug and retry without full mission restart.
- Knowledge changes the world; no quiz-in-decoration.
- Distinct scenery, palette and dominant interaction from adjacent lessons.
- Satisfying finale changes the physical scene.
- Exit/return works.
- Important UI/world text >= current readability thresholds.
- Camera rotates normally and supports close zoom.
- Mobile/touch does not overlap core controls.
- Fresh full regression + targeted PlaySolo + full release E2E before merge/publish.

## Order after PP-HP-Touch returns

1. Compare/rebase this WIP branch against the live local worktree — local PP state wins on conflicts.
2. SP4/12 + SP4/13 first, because both can use existing semantic assets with minimal Meshy dependency.
3. FULL E2E + 3D proof in WORKSTATE after each pair.
4. Continue SP5 → SP6 → SP7 → SP8 → LO1 → LO2 → LO3.
