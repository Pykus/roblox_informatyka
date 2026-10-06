local SemanticAssets = require(script.Parent:WaitForChild("SemanticAssetLibrary"))

local EXACT = {
	pc_tower = "desktop",
	desktop = "desktop",
	computer = "desktop",
	laptop = "laptop",
	monitor = "monitor",
	printer = "printer",
	router = "router",
	switch = "switch",
	cabinet = "serverRack",
	phone = "phone",
	rack = "serverRack",
	school_router = "router",
	quarantine_switch = "toggleSwitch",
	laptop_shell = "laptop",
	tablet_shell = "tablet",
	network_node_laptop = "laptop",
	network_node_printer = "printer",
	photo_camera_body = "camera",
	photo_printer = "printer",
	photo_entry_console = "controlConsole",
	photo_instruction_board = "monitor",
	photo_orientation_control = "toggleSwitch",
	photo_pan_left = "pushButton",
	photo_pan_right = "pushButton",
	photo_darker = "pushButton",
	photo_brighter = "pushButton",
	photo_contrast_dial = "toggleSwitch",
	photo_shutter = "pushButton",
	sports_camera_drone = "drone",
	sports_broadcast_desk = "desk",
	sports_chart_validate_control = "controlConsole",
	sports_photo_capture_control = "pushButton",
	newsroom_field_camera = "camera",
	newsroom_editor_desk = "desk",
	newsroom_editor_monitor = "monitor",
	newsroom_source_scanner = "scanner",
	paint_studio_operator_desk = "desk",
	paint_studio_preview_monitor = "monitor",
	paint_studio_keyboard = "keyboard",
	paint_studio_mouse = "mouse",
	parameter_control_console = "controlConsole",
	parameter_monitor = "monitor",
	parameter_automation_rack = "serverRack",
	html_developer_desk = "desk",
	html_developer_laptop = "laptop",
	html_developer_mouse = "mouse",
	html_developer_chair = "chair",
	chapter_algorithm_console = "controlConsole",
	chapter_data_scanner = "scanner",
	chapter_security_terminal = "computerTerminal",
	chapter_entry_scanner = "scanner",
	chapter_instruction_board = "monitor",
	internet_site_check = "controlConsole",
	internet_instruction_board = "monitor",
	rail_dispatch_console = "controlConsole",
	rail_manifest_scanner = "scanner",
	rail_sort_order_board = "monitor",
	rail_sort_cost_board = "monitor",
	rail_sort_status_board = "monitor",
	rail_sort_operator_desk = "desk",
	rail_sort_operator_keyboard = "keyboard",
	rail_sort_operator_mouse = "mouse",
	rail_sort_stage_monitor = "monitor",
	rail_sort_departure_monitor = "monitor",
	rail_stage_switch = "toggleSwitch",
	message_clean_scanner = "scanner",
	message_replace_console = "controlConsole",
	message_slice_scanner = "scanner",
	message_preview_monitor = "monitor",
	message_operator_desk = "desk",
	message_operator_keyboard = "keyboard",
	message_operator_mouse = "mouse",
	message_stage_monitor = "monitor",
	message_pipeline_rack = "serverRack",
	message_archive_monitor = "monitor",
	math_calibration_console = "controlConsole",
	math_engine_status = "monitor",
	math_engine_result = "monitor",
	math_engine_explanation = "monitor",
	math_operator_desk = "desk",
	math_operator_keyboard = "keyboard",
	math_operator_mouse = "mouse",
	math_engine_core_rack = "serverRack",
	service_request_scanner = "scanner",
	service_dispatch_console = "controlConsole",
	service_request_board = "monitor",
	service_backbone_hub = "switch",
	service_dns_tower = "serverRack",
	service_dns_result = "monitor",
	service_web_server_rack = "serverRack",
	service_web_result = "monitor",
	service_mail_printer = "printer",
	service_mail_result = "monitor",
	mail_merge_intake_crate = "crate",
	service_cloud_server_rack = "serverRack",
	service_cloud_result = "monitor",
	forensic_pattern_scanner = "scanner",
	forensic_count_monitor = "monitor",
	forensic_palindrome_terminal = "computerTerminal",
	caesar_entry_console = "controlConsole",
	caesar_instruction_board = "monitor",
	caesar_rotor_terminal = "computerTerminal",
	caesar_shift_readout_monitor = "monitor",
	caesar_ring_mechanism_console = "controlConsole",
	caesar_mode_status_monitor = "monitor",
	caesar_rotor_drive_rack = "serverRack",
	caesar_vault_status_monitor = "monitor",
	caesar_vault_lock_console = "controlConsole",
	data_dock_entry_console = "controlConsole",
	data_dock_instruction_board = "monitor",
	data_dock_separator_control = "pushButton",
	data_dock_header_control = "toggleSwitch",
	data_dock_import_scanner = "scanner",
	data_dock_type_validate_console = "controlConsole",
	language_port_scanner_base = "scanner",
	photo_restore_table = "table",
	scratch_sound_speaker = "speaker",
	decision_drone_body = "drone",
	decision_drone_power_console = "controlConsole",
	decision_drone_instruction_board = "monitor",
	rescue_robot = "robot",
	java_block_robot = "robot",
	scratch_loop_robot = "robot",
	scratch_variable_board = "monitor",
	scratch_loop_status_board = "monitor",
	scratch_loop_start_control = "pushButton",
	scratch_loop_run_control = "pushButton",
	scratch_loop_debug_monitor = "monitor",
	scratch_loop_operator_desk = "desk",
	scratch_loop_operator_keyboard = "keyboard",
	scratch_loop_operator_mouse = "mouse",
	gallery_robot = "robot",
	jam_glitch_bot = "robot",
	linear_search_bot = "robot",
	binary_search_bot = "robot",
	search_race_entry_console = "controlConsole",
	search_race_instruction_board = "monitor",
	python_server = "serverRack",
	python_dock_server_tower = "serverRack",
	python_dock_status = "monitor",
	python_maze_server_tower = "serverRack",
	python_maze_status = "monitor",
	python_maze_sensor = "scanner",
	python_rack = "serverRack",
	python_power_status_monitor = "monitor",
	python_power_core_rack = "serverRack",
	python_power_turbine_console = "controlConsole",
	loop_factory_automation_rack = "serverRack",
	loop_factory_stamper = "printer",
	loop_factory_scanner_top = "scanner",
	logic_core_rack = "serverRack",
	logic_instruction_board = "monitor",
	logic_power_lever = "toggleSwitch",
	pc_emergency_check_in = "scanner",
	problem_entry_console = "controlConsole",
	problem_instruction_board = "monitor",
	chrono_time_sync_console = "controlConsole",
	pc_emergency_instruction_board = "monitor",
	chrono_instruction_board = "monitor",
	problem_repair_control_connect = "pushButton",
	problem_load_test_control = "pushButton",
	sequence_repair_scanner = "scanner",
	sequence_reactor_overview_screen = "monitor",
	sequence_rule_minus = "pushButton",
	sequence_rule_plus = "pushButton",
	sequence_next_lever = "pushButton",
	sequence_repair_minus = "pushButton",
	sequence_repair_plus = "pushButton",
	sequence_repair_test = "pushButton",
	sequence_generator_start = "monitor",
	sequence_generator_step = "monitor",
	sequence_generator_count = "monitor",
	sequence_generate_button = "pushButton",
	binary_remainder0 = "pushButton",
	binary_remainder1 = "pushButton",
	binary_division_crank = "toggleSwitch",
	hex_conversion_validate = "pushButton",
	reverse_hex_minus = "pushButton",
	reverse_hex_plus = "pushButton",
	reverse_conversion_validate = "pushButton",
	inventor_component_rack = "shelf",
	inventor_entry_console = "controlConsole",
	inventor_instruction_board = "monitor",
	scratch_program_rack = "shelf",
	formula_repair_desk = "desk",
	vault_entry_console = "controlConsole",
	vault_instruction_board = "monitor",
	spreadsheet_entry_console = "controlConsole",
	spreadsheet_instruction_board = "monitor",
	spreadsheet_run_control = "pushButton",
	spreadsheet_qty_minus_control = "pushButton",
	spreadsheet_qty_plus_control = "pushButton",
	spreadsheet_sync_control = "controlConsole",
	mission_terminal = "computerTerminal",
	typing_terminal = "computerTerminal",
	typing_courier_body = "robot",
	typing_operator_desk = "desk",
	typing_terminal_keyboard = "keyboard",
	typing_terminal_mouse = "mouse",
	typing_accuracy_monitor = "monitor",
	command_yard_robot = "robot",
	command_yard_cart = "crate",
	command_yard_operator_desk = "desk",
	command_yard_keyboard = "keyboard",
	command_yard_mouse = "mouse",
	command_yard_signal_monitor = "monitor",
	command_yard_toolbox = "toolbox",
	message_scanner = "scanner",
	extension_scanner = "scanner",
	source_scanner = "scanner",
	number_modulo_scanner = "scanner",
	number_foundry_entry_console = "controlConsole",
	number_foundry_instruction_board = "monitor",
	scanner_panel = "scanner",
	projection_main_screen = "projectorScreen",
	scratch_backdrop_screen = "projectorScreen",
	pseudocode_program_screen = "projectorScreen",
	composition_live_screen = "projectorScreen",
	boot_tower_screen = "monitor",
	device_screen = "monitor",
	software_graphics_desktop = "desktop",
	software_team_tablet = "tablet",
	cyber_shield_arm_lever = "toggleSwitch",
	cyber_mfa_key_control = "pushButton",
	cyber_mfa_lock_console = "controlConsole",
	cyber_shield_status_monitor = "monitor",
	cyber_shield_generator_console = "controlConsole",
	cyber_attack_status_monitor = "monitor",
	cyber_soc_desk = "desk",
	cyber_soc_keyboard = "keyboard",
	cyber_soc_mouse = "mouse",
	cyber_phishing_terminal = "computerTerminal",
	cyber_mfa_service_rack = "serverRack",
	python_rack_display = "monitor",
	timeline_artifact_eniac = "serverRack",
	timeline_artifact_pc = "desktop",
	timeline_artifact_phone = "phone",
	timeline_depot_shelf = "shelf",
	timeline_entry_scanner = "scanner",
	sorting_scanner_top = "scanner",
	sorting_decision_keep_control = "pushButton",
	sorting_decision_swap_control = "pushButton",
	sorting_speed_control = "pushButton",
	sorting_production_control = "pushButton",
	sorting_calibration_console = "controlConsole",
	sorting_instruction_board = "monitor",
}

local PREFIX = {
	{ "problem_measure_control_", "scanner" },
	{ "problem_diagnosis_control_", "pushButton" },
	{ "problem_repair_control_", "toggleSwitch" },
	{ "loop_factory_package_", "crate" },
	{ "sorter_package_", "crate" },
	{ "timeline_era_display_", "table" },
	{ "timeline_archive_cabinet_", "cabinet" },
	{ "pc_emergency_pc_", "desktop" },
	{ "pc_emergency_desk_", "desk" },
	{ "pc_emergency_scanner_", "scanner" },
	{ "pc_emergency_repair_console_", "controlConsole" },
	{ "pc_emergency_verify_", "pushButton" },
	{ "pc_emergency_tool_", "toolbox" },
	{ "cloud_upload_control_", "pushButton" },
	{ "cloud_download_control_", "pushButton" },
	{ "cloud_share_control_", "pushButton" },
	{ "warehouse_rack_", "shelf" },
	{ "data_package", "crate" },
	{ "warehouse_folder_cabinet_", "cabinet" },
	{ "scratch_sprite_rack_", "shelf" },
	{ "scratch_loop_x_control_", "pushButton" },
	{ "scratch_loop_y_control_", "pushButton" },
	{ "search_linear_shelf_", "shelf" },
	{ "search_binary_shelf_", "shelf" },
	{ "spreadsheet_product_crate_", "crate" },
	{ "spreadsheet_formula_control_", "pushButton" },
	{ "python_power_system_console_", "controlConsole" },
	{ "python_command_tower_", "computerTerminal" },
	{ "python_laser_post_", "scanner" },
	{ "bit_switch_", "toggleSwitch" },
	{ "vault_binary_switch_", "toggleSwitch" },
	{ "vault_decimal_adjust_control_", "pushButton" },
	{ "vault_hex_adjust_control_", "pushButton" },
	{ "vault_validate_control_", "pushButton" },
	{ "hex_adjust_", "pushButton" },
	{ "logic_switch_", "toggleSwitch" },
	{ "logic_gate_hardware_", "controlConsole" },
	{ "logic_output_monitor_", "monitor" },
	{ "logic_test_control_", "pushButton" },
	{ "sequence_repair_scan_control_", "scanner" },
	{ "sequence_generator_minus_", "pushButton" },
	{ "sequence_generator_plus_", "pushButton" },
	{ "chapter_algorithm_button_", "pushButton" },
	{ "chapter_bit_switch_", "toggleSwitch" },
	{ "chapter_security_button_", "pushButton" },
	{ "software_module", "crate" },
	{ "software_system_install_control_", "toggleSwitch" },
	{ "software_app_install_control_", "pushButton" },
	{ "inventor_module_control_", "pushButton" },
	{ "inventor_slot_control_", "pushButton" },
	{ "inventor_cable_control_", "toggleSwitch" },
	{ "animation_path_control_", "pushButton" },
	{ "animation_trigger_control_", "toggleSwitch" },
	{ "cyber_password_control_", "toggleSwitch" },
	{ "cyber_message_control_", "pushButton" },
	{ "number_divisor_control_", "pushButton" },
	{ "number_classify_control_", "pushButton" },
	{ "chrono_dial_control_", "toggleSwitch" },
	{ "chrono_stabilize_control_", "pushButton" },
	{ "chrono_scan_control_", "scanner" },
	{ "math_function_control_", "pushButton" },
	{ "sports_fact_scan_control_", "scanner" },
	{ "sports_chart_control_", "pushButton" },
	{ "sports_camera_control_", "pushButton" },
	{ "rail_swap_control_", "pushButton" },
	{ "forensic_pattern_control_", "pushButton" },
	{ "forensic_count_control_", "pushButton" },
	{ "forensic_palindrome_control_", "pushButton" },
	{ "caesar_shift_control_", "pushButton" },
	{ "caesar_mode_control_", "toggleSwitch" },
	{ "caesar_run_control_", "pushButton" },
	{ "mail_merge_mapping_control_", "pushButton" },
	{ "mail_merge_preview_control_", "pushButton" },
	{ "mail_merge_print_control", "pushButton" },
	{ "data_dock_type_control_", "pushButton" },
	{ "language_cargo_", "crate" },
	{ "language_dock_control_", "controlConsole" },
	{ "decision_operator_control_", "pushButton" },
	{ "decision_threshold_control_", "pushButton" },
	{ "decision_city_planning_console", "controlConsole" },
	{ "decision_profile_control_", "pushButton" },
	{ "decision_validate_control_", "pushButton" },
	{ "css_style_control_", "pushButton" },
	{ "html_tag_control_", "pushButton" },
	{ "html_attribute_control_", "pushButton" },
	{ "html_validator_control", "pushButton" },
	{ "launch_template_control_", "computerTerminal" },
	{ "launch_section_control_", "pushButton" },
	{ "launch_style_control_", "toggleSwitch" },
	{ "launch_cta_control_", "pushButton" },
	{ "search_token_control_", "pushButton" },
	{ "search_quote_control_", "toggleSwitch" },
	{ "search_pdf_control_", "toggleSwitch" },
	{ "search_run_control_", "pushButton" },
	{ "search_terminal_", "computerTerminal" },
}

local SUFFIX = {
	{ "_console", "controlConsole" },
	{ "_terminal", "computerTerminal" },
	{ "_crate", "crate" },
	{ "_cabinet", "cabinet" },
	{ "_printer", "printer" },
	{ "_speaker", "speaker" },
	{ "_shelf", "shelf" },
}
local PRELOAD = {
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
}

SemanticAssets.Preload(PRELOAD)
print("[CER-ASSET] preload requested for free semantic assets")

local watched = setmetatable({}, { __mode = "k" })

local function normalize(name)
	local separated = string.gsub(name, "(%u)(%u%l)", "%1_%2")
	separated = string.gsub(separated, "(%l)(%u)", "%1_%2")
	separated = string.gsub(separated, "[^%w]+", "_")
	separated = string.gsub(separated, "_+", "_")
	return string.lower(separated)
end

local function inferKey(name)
	local normalized = normalize(name)
	local exact = EXACT[normalized]
	if exact then
		return exact
	end
	for _, rule in ipairs(PREFIX) do
		if string.sub(normalized, 1, #rule[1]) == rule[1] then
			return rule[2]
		end
	end
	for _, rule in ipairs(SUFFIX) do
		if #normalized >= #rule[1] and string.sub(normalized, -#rule[1]) == rule[1] then
			return rule[2]
		end
	end
	return nil
end
local function missionRoot(instance)
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") and string.sub(current.Name, 1, 8) == "Mission_" then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function hasSemanticAncestor(instance)
	local current = instance.Parent
	while current and current ~= workspace do
		if current:GetAttribute("SemanticAssetKey") then
			return true
		end
		current = current.Parent
	end
	return false
end

local function decorate(part)
	if not part:IsA("BasePart") or hasSemanticAncestor(part) then
		return
	end
	if part:GetAttribute("SemanticDecorated") then
		return
	end
	local key = inferKey(part.Name)
	if not key then
		return
	end
	local root = missionRoot(part)
	if not root then
		return
	end
	if math.max(part.Size.X, part.Size.Y, part.Size.Z) < 1 then
		return
	end

	part:SetAttribute("SemanticDecorated", true)
	task.spawn(function()
		local visual, reason = SemanticAssets.Place(key, root, part.CFrame, part.Size, "Semantic_" .. part.Name)
		if visual then
			part:SetAttribute("SemanticAssetKey", key)
			part:SetAttribute("SemanticAssetId", visual:GetAttribute("SemanticAssetId"))
			part:SetAttribute("SemanticAssetFallback", false)
			part.Transparency = 1
			print(
				string.format(
					"[CER-ASSET] placed object=%s key=%s id=%s",
					part.Name,
					key,
					tostring(visual:GetAttribute("SemanticAssetId"))
				)
			)
		else
			part:SetAttribute("SemanticAssetFallback", true)
			warn(
				string.format(
					"[CER-ASSET] fallback primitive object=%s key=%s reason=%s",
					part:GetFullName(),
					key,
					tostring(reason)
				)
			)
		end
	end)
end
local function watchMission(root)
	if watched[root] or not root:IsA("Model") or string.sub(root.Name, 1, 8) ~= "Mission_" then
		return
	end
	watched[root] = true
	for _, item in ipairs(root:GetDescendants()) do
		decorate(item)
	end
	root:SetAttribute("SemanticDecorationScanned", true)
	root.DescendantAdded:Connect(function(item)
		task.defer(decorate, item)
	end)
end

local function watchContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		watchMission(child)
	end
	container.ChildAdded:Connect(watchMission)
end

for _, child in ipairs(workspace:GetChildren()) do
	if child.Name == "PlayerMissions" then
		watchContainer(child)
	else
		watchMission(child)
	end
end

workspace.ChildAdded:Connect(function(child)
	if child.Name == "PlayerMissions" then
		watchContainer(child)
	else
		watchMission(child)
	end
end)

print("[CER-ASSET] semantic Creator Store decorator ready")