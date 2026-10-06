from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "src/StarterPlayer/StarterPlayerScripts"
SERVER = ROOT / "src/ServerScriptService"

camera = (CLIENT / "MissionCamera.client.lua").read_text(encoding="utf-8")
menu = (CLIENT / "MainMenu.client.lua").read_text(encoding="utf-8")
readability = (CLIENT / "WorldReadability.client.lua").read_text(encoding="utf-8")
screen_readability = (CLIENT / "ScreenReadability.client.lua").read_text(encoding="utf-8")
first_action = (CLIENT / "FirstActionGuide.client.lua").read_text(encoding="utf-8")
python_console = (CLIENT / "PythonConsole.client.lua").read_text(encoding="utf-8")
typing_terminal = (CLIENT / "TypingTerminal.client.lua").read_text(encoding="utf-8")
focus_guard = (CLIENT / "InputFocusGuard.client.lua").read_text(encoding="utf-8")
mission_engine = (SERVER / "MissionEngine.lua").read_text(encoding="utf-8")
semantic_library = (SERVER / "SemanticAssetLibrary.lua").read_text(encoding="utf-8")
semantic_decorator = (SERVER / "SemanticAssetDecorator.server.lua").read_text(encoding="utf-8")
project_config = (ROOT / "default.project.json").read_text(encoding="utf-8")
all_client = "\n".join(p.read_text(encoding="utf-8") for p in CLIENT.glob("*.lua"))
long_waits = []
for path in SERVER.glob("*.lua"):
    text = path.read_text(encoding="utf-8")
    for match in re.finditer(r"task\.(?:wait|delay)\(([0-9.]+)", text):
        if float(match.group(1)) > 1.2:
            long_waits.append(f"{path.name}:{match.group(1)}")

checks = {
    "gameplay_no_long_fixed_waits": not long_waits,
    "camera_intro_only_scriptable": all_client.count("Enum.CameraType.Scriptable") == 1
    and "local INTRO_DURATION = 0.85" in camera
    and "task.delay(INTRO_DURATION" in camera,
    "camera_intro_skippable": "UserInputService.InputBegan:Connect" in camera
    and "UserInputService.InputChanged:Connect" in camera
    and camera.count("finishOverview()") >= 4,
    "camera_custom": "camera.CameraType = Enum.CameraType.Custom" in camera,
    "camera_classic": "CameraMode = Enum.CameraMode.Classic" in camera,
    "camera_close_zoom_min": "local MIN_ZOOM = 5" in camera,
    "camera_close_zoom_max": "local MAX_ZOOM = 16" in camera,
    "camera_fov": "local DEFAULT_FOV = 70" in camera,
    "camera_subject_humanoid": "camera.CameraSubject = humanoid" in camera,
    "camera_recovers_on_event": 'message.kind == "camera"' in camera and "task.defer(startOverview)" in camera,
    "camera_self_heal_loop": "RunService.Heartbeat:Connect" in camera
    and "HEALTH_CHECK_INTERVAL = 0.5" in camera
    and "cameraNeedsRepair()" in camera,
    "camera_self_heal_mission_only": "if not missionActive then" in camera
    and 'message.kind == "hud"' in camera
    and "missionActive = true" in camera
    and 'message.kind == "complete"' in camera
    and "missionActive = false" in camera,
    "camera_cframe_only_intro": camera.count("camera.CFrame =") == 1 and "CFrame.lookAt(eye, center)" in camera,
    "hud_title_22": "hudTitle.TextSize = 22" in menu,
    "hud_objective_20": "hudObjective.TextSize = 20" in menu,
    "hud_objective_prefix": 'hudObjective.Text = "CEL: "' in menu,
    "hud_controls_16": "hudControls.TextSize = 16" in menu,
    "hud_desktop_controls": "WASD/strzałki" in menu and "mysz = kamera" in menu and "E = interakcja" in menu,
    "hud_touch_controls": "joystick" in menu and "przeciągnij ekran = kamera" in menu,
    "hud_controls_wrapped": "hudControls.TextWrapped = true" in menu
    and "hudControls.TextYAlignment = Enum.TextYAlignment.Top" in menu,
    "hud_responsive_breakpoint": "applyPlayabilityLayout" in menu
    and "viewport.X < 720 or viewport.Y < 520" in menu,
    "hud_narrow_width_guard": "math.min(620, math.max(240, viewport.X - 24))" in menu,
    "hud_narrow_objective_space": "hudObjective.Size = UDim2.new(1, -24, 0, 94)" in menu,
    "hud_narrow_controls_space": "hudControls.Size = UDim2.new(1, -24, 0, 40)" in menu,
    "hud_low_landscape_compact": "if menuLow then" in menu
    and "width = math.min(500, math.max(240, viewport.X - 154))" in menu
    and "hud.Size = UDim2.fromOffset(width, 126)" in menu
    and "hudObjective.Size = UDim2.new(1, -24, 0, 50)" in menu
    and "hudControls.Size = UDim2.new(1, -24, 0, 18)" in menu
    and 'and "joystick • przeciągnij = kamera • interakcja"' in menu,
    "hud_low_objective_scales_16_20": "hudObjectiveConstraint.MinTextSize = 16" in menu
    and "hudObjectiveConstraint.MaxTextSize = 20" in menu
    and "hudObjective.TextScaled = true" in menu,
    "hud_tiny_low_prioritizes_objective": "local tinyLow = width < 320" in menu
    and "hudObjective.Size = UDim2.new(1, -24, 0, 68)" in menu
    and "hudControls.Visible = false" in menu,
    "hud_short_portrait_compact": "elseif menuPortrait and viewport.Y < 560 then" in menu
    and "hud.Size = UDim2.fromOffset(width, 192)" in menu
    and "hudObjective.Size = UDim2.new(1, -24, 0, 78)" in menu,
    "hud_tracks_viewport": 'GetPropertyChangedSignal("ViewportSize")' in menu
    and 'GetPropertyChangedSignal("CurrentCamera")' in menu,
    "notification_named": 'notification.Name = "MissionNotification"' in menu,
    "notification_routes_objective": 'message.kind == "objective"' in menu
    and 'hudObjective.Text = "CEL: " .. tostring(message.text)' in menu,
    "notification_ignores_technical_kinds": 'message.kind ~= "message"' in menu
    and '"Aktualizacja misji"' not in menu,
    "notification_safe_bottom": "notification.AnchorPoint = Vector2.new(0.5, 1)" in menu
    and "local safeBottom = math.min(180, math.max(120, math.floor(viewport.Y * 0.22)))" in menu
    and "local tinyLowNotice = viewport.Y < 360" in menu
    and "local safeBottom = tinyLowNotice and 120 or 110" in menu
    and "notification.Position = UDim2.new(0.5, 0, 1, -safeBottom)" in menu,
    "notification_low_scales_16_22": "notificationConstraint.MinTextSize = 16" in menu
    and "notificationConstraint.MaxTextSize = 22" in menu
    and "notification.TextScaled = true" in menu,
    "poster_modal_responsive": "math.min(470, math.max(280, viewport.X - 24))" in menu
    and "posterModal.AnchorPoint = Vector2.new(0.5, 0.5)" in menu,
    "poster_modal_buttons_responsive": "posterSubmit.Size = UDim2.new(0.5, -25, 0, 52)" in menu
    and "posterCancel.Size = UDim2.new(0.5, -25, 0, 52)" in menu,
    "menu_grade_bar_scrollable": 'local gradeBar = Instance.new("ScrollingFrame")' in menu
    and "gradeBar.AutomaticCanvasSize = Enum.AutomaticSize.X" in menu,
    "menu_portrait_stack": "viewport.X < 700 and viewport.Y >= viewport.X * 1.05" in menu
    and "list.Size = UDim2.new(1, -24, 0, listHeight)" in menu
    and "details.Size = UDim2.new(1, -24, 0, contentHeight - listHeight - 10)" in menu,
    "ui_display_order_explicit": "gui.DisplayOrder = 20" in menu
    and "gui.DisplayOrder = 40" in python_console
    and "gui.DisplayOrder = 50" in typing_terminal,
    "lesson_menu_raises_above_modals": "gui.DisplayOrder = visible and 100 or 20" in menu
    and "setMenuVisible(not main.Visible)" in menu,
    "lesson_menu_releases_text_focus": "local function releaseFocusedTextBox()" in menu
    and "UserInputService:GetFocusedTextBox()" in menu
    and "focused:ReleaseFocus()" in menu
    and "setMenuVisible(false)" in menu,
    "mobile_lesson_button_avoids_joystick": "local compactControls = viewport.X < 720 or viewport.Y < 520" in menu
    and "local shortPortrait = menuPortrait and viewport.Y < 560" in menu
    and "local buttonTop = menuLow and 12 or (shortPortrait and 210 or 230)" in menu
    and "openButton.AnchorPoint = Vector2.new(1, 0)" in menu
    and "openButton.Size = UDim2.fromOffset(118, 42)" in menu
    and 'openButton.Text = "LEKCJE"' in menu,
    "lesson_button_only_during_mission": "openButton.Visible = false" in menu
    and menu.count("openButton.Visible = true") >= 2
    and 'message.kind == "complete"' in menu,
    "hud_first_action_help": "Podejdź do oznaczonych obiektów" in menu,
    "hud_hides_on_complete": 'message.kind == "complete"' in menu and "hud.Visible = false" in menu,
    "world_min_18": "local MIN_WORLD_TEXT = 18" in readability,
    "world_existing_constraints_upgraded": "math.max(keeper.MinTextSize, MIN_WORLD_TEXT)" in readability,
    "world_max_safe": "math.max(keeper.MaxTextSize, MAX_WORLD_TEXT, keeper.MinTextSize)" in readability,
    "world_constraint_dedupe": "local function normalizeConstraint(object)" in readability
    and "child:Destroy()" in readability
    and 'child:IsA("UITextSizeConstraint")' in readability,
    "world_late_constraint_repair": 'object:IsA("UITextSizeConstraint")' in readability
    and "improveText(parent)" in readability,
    "world_surface_light": 'object:IsA("SurfaceGui") or object:IsA("BillboardGui")' in readability
    and "object.LightInfluence = 0" in readability,
    "world_gui_brightness": "local MIN_WORLD_BRIGHTNESS = 1.1" in readability
    and "object.Brightness = math.max(object.Brightness, MIN_WORLD_BRIGHTNESS)" in readability,
    "world_fixed_min_18": "object.TextSize = math.max(object.TextSize, MIN_WORLD_TEXT)" in readability,
    "world_contrast_stroke": "MAX_STROKE_TRANSPARENCY = 0.65" in readability
    and "object.TextStrokeColor3" in readability
    and "object.TextStrokeTransparency = math.min" in readability,
    "world_dynamic_descendants": "workspace.DescendantAdded:Connect" in readability,
    "screen_min_16": "local MIN_SCREEN_TEXT = 16" in screen_readability,
    "screen_scaled_only": "if not object.TextScaled then" in screen_readability,
    "screen_existing_constraints_upgraded": "math.max(keeper.MinTextSize, MIN_SCREEN_TEXT)" in screen_readability,
    "screen_constraint_dedupe": "local function normalizeConstraint(object)" in screen_readability
    and "child:Destroy()" in screen_readability
    and 'child:IsA("UITextSizeConstraint")' in screen_readability,
    "screen_late_constraint_repair": 'object:IsA("UITextSizeConstraint")' in screen_readability
    and "improve(parent)" in screen_readability,
    "screen_dynamic_descendants": "playerGui.DescendantAdded:Connect" in screen_readability,
    "hidden_focus_guard": "RunService.Heartbeat:Connect(function()" in focus_guard
    and "CHECK_INTERVAL" not in focus_guard
    and "UserInputService:GetFocusedTextBox()" in focus_guard
    and "not isActuallyVisible(focused)" in focus_guard
    and "focused:ReleaseFocus()" in focus_guard
    and 'parent:IsA("LayerCollector") and not parent.Enabled' in focus_guard,
    "poster_releases_hidden_focus": "local function closePosterEditor()" in menu
    and "posterBox:ReleaseFocus()" in menu
    and "posterCancel.Activated:Connect(closePosterEditor)" in menu,
    "python_releases_hidden_focus": python_console.count("code:ReleaseFocus()") >= 2,
    "typing_releases_hidden_focus": typing_terminal.count("input:ReleaseFocus()") >= 2,
    "generic_prompt_no_los": "pr.RequiresLineOfSight = false" in mission_engine,
    "generic_prompt_fast": "pr.HoldDuration = 0.15" in mission_engine,
    "semantic_assets_use_creator_store": "AssetService:LoadAssetAsync(entry.id)" in semantic_library,
    "semantic_assets_project_allows_free_assets": '"AllowInsertFreeAssets": true' in project_config,
    "semantic_assets_complexity_guard": "maxParts" in semantic_library
    and "asset too complex" in semantic_library
    and "[CER-ASSET] rejected" in semantic_library,
    "semantic_assets_sanitized": 'item:IsA("LuaSourceContainer")' in semantic_library
    and 'item:IsA("Sound")' in semantic_library
    and "item:Destroy()" in semantic_library,
    "semantic_assets_cover_real_objects": all(
        key in semantic_library
        for key in (
            "desktop",
            "laptop",
            "monitor",
            "printer",
            "serverRack",
            "switch",
            "camera",
            "chair",
            "shelf",
            "keyboard",
            "mouse",
            "toolbox",
            "robot",
            "drone",
            "router",
            "tablet",
            "desk",
            "table",
            "projector",
            "speaker",
            "microphone",
            "crate",
            "cabinet",
            "phone",
            "scanner",
            "controlConsole",
            "computerTerminal",
            "projectorScreen",
            "toggleSwitch",
            "pushButton",
        )
    ),
    "semantic_decorator_replaces_placeholders": "SemanticAssets.Place" in semantic_decorator
    and 'part.Transparency = 1' in semantic_decorator
    and 'part:SetAttribute("SemanticAssetFallback", false)' in semantic_decorator,
    "first_action_nearest_prompt": "nearestPrompt" in first_action and "MAX_GUIDE_DISTANCE = 120" in first_action,
    "first_action_fast_replication_retry": "RETRY_COUNT = 30" in first_action and "RETRY_DELAY = 0.15" in first_action,
    "first_action_scoped_to_player_mission": "missionRoot" in first_action
    and '"Mission_" .. player.UserId' in first_action
    and "mission:GetDescendants()" in first_action
    and "mission.DescendantAdded:Connect" in first_action
    and "prompt:IsDescendantOf(mission)" in first_action
    and "workspace:GetDescendants()" not in first_action,
    "first_action_no_undefined_debug_helper": "guideDebug(" not in first_action,
    "first_action_late_prompt_recovery": "local function recoverGuideForPrompt(prompt)" in first_action
    and 'prompt:GetPropertyChangedSignal("Enabled"):Connect' in first_action
    and "tryShowNearestGuide(guideToken)" in first_action,
    "first_action_prefers_active_root": "local function preferredMissionRoot()" in first_action
    and "activeMissionRoot and activeMissionRoot.Parent" in first_action
    and "watchMissionPrompts(preferredMissionRoot())" in first_action,
    "first_action_semantic_prompt_anchor": "local function semanticVisual(part)" in first_action
    and 'mission:FindFirstChild("Semantic_" .. part.Name)' in first_action
    and 'part:GetAttribute("SemanticAssetId")' in first_action
    and 'part:GetAttribute("SemanticAssetFallback") ~= false' in first_action
    and "hasVisiblePromptAnchor(promptPart(prompt))" in first_action,
    "first_action_semantic_late_recovery": 'part:GetAttributeChangedSignal("SemanticAssetId"):Connect' in first_action
    and "promptSemanticConnections" in first_action,
    "first_action_tracks_replaced_mission_root": 'local missionName = "Mission_" .. player.UserId' in first_action
    and "local function handleMissionRootAdded(root)" in first_action
    and 'container.ChildAdded:Connect(handleMissionRootAdded)' in first_action
    and "activeMissionRoot = root" in first_action
    and "beginGuide(activeMissionTitle)" in first_action,
    "first_action_once_per_mission": "activeMissionTitle ~= title" in first_action
    and "beginGuide(title)" in first_action
    and "guideFinishedForMission = true" in first_action
    and "guideFinishedForMission = false" in first_action,
    "first_action_tracks_mission_instance": "local activeMissionRoot = nil" in first_action
    and "activeMissionRoot ~= root" in first_action
    and 'message.kind == "camera"' in first_action
    and "activeMissionRoot = root" in first_action,
    "first_action_clears_root_on_complete": "activeMissionRoot = nil" in first_action,
    "first_action_clears_on_prompt": "PromptTriggered:Connect" in first_action and "clearGuide()" in first_action,
    "first_action_timeout": "GUIDE_LIFETIME = 20" in first_action and "task.delay(GUIDE_LIFETIME" in first_action,
    "first_action_only_guided_prompt_clears": "if prompt == guidedPrompt then" in first_action
    and "or guidedPrompt ~= nil" not in first_action,
    "first_action_visible_label": "ZACZNIJ TUTAJ" in first_action and "AlwaysOnTop = true" in first_action,
    "first_action_text_min_16": "sizeConstraint.MinTextSize = 16" in first_action,
    "first_action_beacon": 'beacon.Name = "CER_FirstActionBeacon"' in first_action
    and "beacon.Material = Enum.Material.Neon" in first_action
    and "beacon.CanCollide = false" in first_action
    and "beacon.CanQuery = false" in first_action
    and "TweenService:Create" in first_action,
    "first_action_beacon_cleanup": "beaconTween:Cancel()" in first_action
    and "beacon:Destroy()" in first_action,
    "first_action_skips_disabled": "not prompt.Enabled" in first_action,
    "core_prompt_locked_initially": "corePrompt.Enabled = false" in mission_engine,
    "core_prompt_unlocks_after_stage1": "corePrompt.Enabled = true" in mission_engine
    and "not state.exitReady" in mission_engine,
    "exit_prompt_locked_initially": "exitPrompt.Enabled = false" in mission_engine,
    "exit_prompt_tracks_exit_ready": "state.exitPrompt = exitPrompt" in mission_engine
    and "state.exitReady and not state.completed" in mission_engine
    and "exitPrompt.Enabled = true" in mission_engine,
    "respawn_tracks_active_mission": "local respawnState = {}" in mission_engine
    and "local respawnConnections = {}" in mission_engine
    and "model = model" in mission_engine
    and "position = startPosition" in mission_engine,
    "respawn_returns_to_start": "restoreActiveMissionOnRespawn" in mission_engine
    and "root.CFrame = CFrame.lookAt(info.position" in mission_engine
    and "active[player] ~= info.model" in mission_engine,
    "respawn_preserves_progress": "info.state.objective" in mission_engine
    and "info.state.score" in mission_engine
    and "info.state.completed" in mission_engine,
    "respawn_tracks_last_hud": "local lastHudState = {}" in mission_engine
    and "lastHudState[player] = {" in mission_engine
    and "objective = objective" in mission_engine
    and "timeLeft = timeLeft" in mission_engine,
    "respawn_restores_exact_hud": "local hud = lastHudState[player]" in mission_engine
    and "local objective = hud and hud.objective or info.state.objective" in mission_engine
    and "local score = hud and hud.score or info.state.score" in mission_engine
    and "local timeLeft = hud and hud.timeLeft or nil" in mission_engine,
    "respawn_restores_hud_camera": "setHud(player, info.remote, title, objective, score, timeLeft)" in mission_engine
    and 'info.remote:FireClient(player, { kind = "camera", mode = info.cameraMode })' in mission_engine,
    "respawn_character_added": "player.CharacterAdded:Connect" in mission_engine
    and "Players.PlayerAdded:Connect(bindRespawn)" in mission_engine,
    "respawn_stop_cleanup": "respawnState[player] = nil" in mission_engine
    and "lastHudState[player] = nil" in mission_engine
    and "respawnConnections[player]:Disconnect()" in mission_engine,
}

representatives = {
    "software_classification": "SoftwareTower.lua",
    "file_logistics": "FileWarehouse.lua",
    "cloud_sync": "CloudSyncStation.lua",
    "cyber_defense": "CyberDefenseFortress.lua",
    "evidence_newsroom": "NewsroomEvidence.lua",
    "graphics_editor": "PaintStudioShapes.lua",
    "timeline_history": "TimelineMuseum.lua",
    "search_escape": "SearchEscape.lua",
    "problem_solving": "ProblemSolvingFactory.lua",
    "typing_run": "TypingTerminalRun.lua",
    "hardware_build": "InventorWorkshop.lua",
    "photo_lab": "PhotoLabOne.lua",
    "scratch_block": "ScratchLoopGrid.lua",
    "presentation": "NatureAnimationLab.lua",
    "robot_algorithm": "RobotRescue.lua",
    "data_spreadsheet": "SpreadsheetFactory.lua",
    "number_algorithm": "NumberFoundry.lua",
    "search_algorithm": "SearchRace.lua",
    "sorting_algorithm": "SortingArena.lua",
    "media_project": "SportsNewsroom.lua",
    "language_application": "LanguagePort.lua",
    "parameter_lab": "ParameterLab.lua",
    "math_function": "MathEngine.lua",
    "condition_logic": "DecisionDrone.lua",
    "logic_gate": "LogicGateControl.lua",
    "python_loop_factory": "LoopFactory.lua",
    "sequence_reactor": "SequenceReactor.lua",
    "positional_vault": "PositionalVault.lua",
    "conversion_machine": "ConversionMachine.lua",
    "rail_sort": "RailSort.lua",
    "message_lab": "MessageLab.lua",
    "text_forensics": "TextForensics.lua",
    "caesar_cipher": "CaesarCipherVault.lua",
    "mail_merge": "MailMergeFactory.lua",
    "data_import_dock": "DataImportDock.lua",
    "chrono_museum": "ChronoMuseum.lua",
    "decision_city": "DecisionCity.lua",
    "pc_emergency_room": "PCEmergencyRoom.lua",
    "internet_construction": "InternetConstruction.lua",
    "network_service_district": "NetworkServiceDistrict.lua",
    "html_construction": "HTMLConstructionStudio.lua",
    "css_style": "CSSStyleStudio.lua",
    "website_launch": "WebsiteLaunchStudio.lua",
}

for family, filename in representatives.items():
    path = SERVER / filename
    exists = path.exists()
    text = path.read_text(encoding="utf-8") if exists else ""
    checks[f"{family}_module"] = exists
    checks[f"{family}_interaction"] = "ProximityPrompt" in text or "prompt(" in text
    checks[f"{family}_objective"] = "state.objective" in text or text.count("hud(") >= 2

checks["command_yard_interaction"] = (
    "function CommandYard.Execute" in (SERVER / "CommandYard.lua").read_text(encoding="utf-8")
    and "PythonSubset.Parse(source)" in (SERVER / "CommandYard.lua").read_text(encoding="utf-8")
    and "CommandYardCart" in (SERVER / "CommandYard.lua").read_text(encoding="utf-8")
    and "CommandYardRobot" in (SERVER / "CommandYard.lua").read_text(encoding="utf-8")
)
checks["python_loop_factory_interaction"] = (
    "function LoopFactory.Execute" in (SERVER / "LoopFactory.lua").read_text(encoding="utf-8")
    and "PythonSubset.Parse(source)" in (SERVER / "LoopFactory.lua").read_text(encoding="utf-8")
)
checks["parameter_lab_interaction"] = (
    "function ParameterLab.Execute" in (SERVER / "ParameterLab.lua").read_text(encoding="utf-8")
    and "PythonSubset.Parse(source)" in (SERVER / "ParameterLab.lua").read_text(encoding="utf-8")
)
checks["message_lab_interaction"] = (
    "function MessageLab.Execute" in (SERVER / "MessageLab.lua").read_text(encoding="utf-8")
    and "PythonSubset.Parse(source)" in (SERVER / "MessageLab.lua").read_text(encoding="utf-8")
)
checks["python_console_ui_first_action"] = "ZACZNIJ TUTAJ: sprawdź kod" in python_console
checks["python_console_ui_responsive"] = "applyConsoleLayout" in python_console and "viewport.X < 720 or viewport.Y < 520" in python_console
checks["python_console_tiny_landscape"] = (
    "local tiny = narrow and viewport.Y < 360" in python_console
    and "height = math.max(260, viewport.Y - 16)" in python_console
    and "codeFrame.Position = UDim2.fromOffset(10, 84)" in python_console
    and "outputFrame.Position = UDim2.fromOffset(10, height - 102)" in python_console
)
checks["python_console_reopen_avoids_jump"] = (
    "local reopenTop = viewport.Y < viewport.X and 62 or 282" in python_console
    and "reopen.AnchorPoint = Vector2.new(1, 0)" in python_console
    and "reopen.Size = UDim2.fromOffset(118, 42)" in python_console
    and 'local reopenLabelNarrow = "PYTHON"' in python_console
    and "reopen.Text = reopenLabelNarrow" in python_console
)
checks["python_console_ui_output_16"] = "output.TextSize = 16" in python_console
checks["typing_terminal_ui_responsive"] = "applyTerminalLayout" in typing_terminal and "viewport.X < 620 or viewport.Y < 400" in typing_terminal
checks["typing_terminal_tiny_landscape"] = (
    "local tiny = narrow and viewport.Y < 360" in typing_terminal
    and "input.Position = UDim2.fromOffset(10, 92)" in typing_terminal
    and "status.Position = UDim2.fromOffset(10, 150)" in typing_terminal
    and "submit.Position = UDim2.fromOffset(10, 200)" in typing_terminal
)
checks["typing_terminal_ui_first_action"] = "ZACZNIJ TUTAJ • " in typing_terminal
checks["typing_terminal_ui_autofocus"] = "input:CaptureFocus()" in typing_terminal
checks["python_console_module"] = (SERVER / "PythonRobotDock.lua").exists()
checks["python_console_interaction"] = (
    'pythonRemote("PythonConsole")' in mission_engine
    and 'kind = "open"' in mission_engine
    and "MissionEngine.ExecutePython" in mission_engine
)
checks["python_console_objective"] = (
    "challenge = variantInfo.challenge" in mission_engine
    and "Napisz program i kliknij URUCHOM KOD." in mission_engine
)

bad = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[PLAYABILITY-QA] {'PASS' if ok else 'FAIL'} {name}")

print(f"[PLAYABILITY-QA] REPRESENTATIVE_FAMILIES={len(representatives) + 2}")
if bad:
    raise SystemExit("PLAYABILITY_QA_FAILED: " + ",".join(bad))
print("PLAYABILITY_QA_OK")