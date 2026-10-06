from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
harness = (root / "tools/ReleaseSmokeHarness.server.lua").read_text(encoding="utf-8")
client_probe = (root / "tools/ReleaseClientProbe.client.lua").read_text(encoding="utf-8")
builder = (root / "tools/build_release_smoke.ps1").read_text(encoding="utf-8")
checker = (root / "tools/check_release_smoke.ps1").read_text(encoding="utf-8")
gitignore = (root / ".gitignore").read_text(encoding="utf-8")

cases = [
    ("SP4", 3), ("SP4", 4), ("SP4", 5), ("SP4", 6), ("SP4", 7), ("SP4", 8),
    ("SP5", 3), ("SP5", 5), ("SP5", 7), ("SP5", 8),
    ("SP6", 4), ("SP6", 5), ("SP6", 7), ("SP6", 9),
    ("SP7", 5), ("SP7", 8), ("SP7", 10),
    ("SP8", 4), ("SP8", 5), ("SP8", 6), ("SP8", 7), ("SP8", 8), ("SP8", 9), ("SP8", 10),
    ("LO1", 3), ("LO1", 4), ("LO1", 6), ("LO1", 7), ("LO1", 8), ("LO1", 9), ("LO1", 10),
    ("LO2", 3), ("LO2", 4), ("LO2", 5), ("LO2", 6), ("LO2", 7), ("LO2", 8), ("LO2", 9), ("LO2", 10),
    ("LO3", 3), ("LO3", 4), ("LO3", 5), ("LO3", 6), ("LO3", 7), ("LO3", 8), ("LO3", 9), ("LO3", 10),
]

checks = {
    "matrix_current": harness.count('{ "') >= len(cases) and "families=%d" in harness,
    "all_matrix_entries": all(f'{{ "{grade}", {lesson},' in harness for grade, lesson in cases),
    "uses_real_curriculum": "Curriculum[grade]" in harness and "MissionRules.GetForLesson" in harness,
    "uses_real_engine": "MissionEngine.Start" in harness and "MissionEngine.Stop" in harness,
    "checks_variant": 'model:GetAttribute("MissionVariant")' in harness,
    "checks_world_density": "descendants >= 20" in harness,
    "checks_semantic_asset_resolution": "semanticFallbacks == 0" in harness
    and "semanticLoaded == semanticCandidates" in harness
    and "SemanticAssetFallback" in harness
    and "SemanticAssetId" in harness
    and "semantic=%d/%d" in harness,
    "checks_sp4_software_semantic_upgrade": 'grade == "SP4" and lessonNo == 3' in harness
    and "semanticLoaded >= 11" in harness
    and 'FindFirstChild("Semantic_SoftwareModule" .. index)' in harness
    and '"Semantic_BootTowerScreen"' in harness
    and '"Semantic_SoftwareGraphicsDesktop"' in harness
    and '"Semantic_SoftwareTeamTablet"' in harness
    and '"Semantic_SoftwareSystemInstallControl_1"' in harness
    and '"Semantic_SoftwareSystemInstallControl_2"' in harness
    and '"Semantic_SoftwareAppInstallControl_1"' in harness
    and '"Semantic_SoftwareAppInstallControl_2"' in harness,
    "checks_sp4_warehouse_semantic_upgrade": 'grade == "SP4" and lessonNo == 4' in harness
    and "semanticLoaded >= 11" in harness
    and 'FindFirstChild("Semantic_DataPackage" .. index)' in harness
    and 'FindFirstChild("Semantic_ExtensionScanner")' in harness
    and 'FindFirstChild("Semantic_ScannerPanel")' in harness
    and 'FindFirstChild("Semantic_WarehouseFolderCabinet_" .. index)' in harness,
    "checks_sp4_cloud_semantic_upgrade": 'grade == "SP4" and lessonNo == 5' in harness
    and "semanticLoaded >= 9" in harness
    and '"Semantic_LAPTOPShell"' in harness
    and '"Semantic_TABLETShell"' in harness
    and '"Semantic_CloudUploadControl_LAPTOP"' in harness
    and '"Semantic_CloudUploadControl_TABLET"' in harness
    and '"Semantic_CloudDownloadControl_LAPTOP"' in harness
    and '"Semantic_CloudDownloadControl_TABLET"' in harness
    and '"Semantic_CloudShareControl_PUBLIC"' in harness
    and '"Semantic_CloudShareControl_PASSWORD_NAME"' in harness
    and '"Semantic_CloudShareControl_PEOPLE"' in harness,
    "checks_sp4_cyber_semantic_upgrade": 'grade == "SP4" and lessonNo == 6' in harness
    and "semanticLoaded >= 20" in harness
    and '"Semantic_CyberShieldArmLever"' in harness
    and '"Semantic_MessageScanner"' in harness
    and '"Semantic_CyberPasswordControl_LONG"' in harness
    and '"Semantic_CyberPasswordControl_UNIQUE"' in harness
    and '"Semantic_CyberPasswordControl_MANAGER"' in harness
    and '"Semantic_CyberPasswordControl_123456"' in harness
    and '"Semantic_CyberPasswordControl_NAMEYEAR"' in harness
    and '"Semantic_CyberPasswordControl_REUSE"' in harness
    and '"Semantic_CyberMessageControl_Block"' in harness
    and '"Semantic_CyberMessageControl_Allow"' in harness
    and '"Semantic_CyberMFAKeyControl"' in harness
    and '"Semantic_CyberMFALockConsole"' in harness
    and '"Semantic_CyberShieldStatusMonitor"' in harness
    and '"Semantic_CyberShieldGeneratorConsole"' in harness
    and '"Semantic_CyberAttackStatusMonitor"' in harness
    and '"Semantic_CyberSOCDesk"' in harness
    and '"Semantic_CyberSOCKeyboard"' in harness
    and '"Semantic_CyberSOCMouse"' in harness
    and '"Semantic_CyberPhishingTerminal"' in harness
    and '"Semantic_CyberMFAServiceRack"' in harness
    and "SP4/06 shield arm lever too far" in harness,
    "checks_sp4_newsroom_semantic_upgrade": 'grade == "SP4" and lessonNo == 7' in harness
    and "semanticLoaded >= 4" in harness
    and 'FindFirstChild("Semantic_NewsroomFieldCamera")' in harness
    and 'FindFirstChild("Semantic_NewsroomEditorDesk")' in harness
    and 'FindFirstChild("Semantic_NewsroomEditorMonitor")' in harness
    and 'FindFirstChild("Semantic_NewsroomSourceScanner")' in harness,
    "checks_sp4_paint_semantic_upgrade": 'grade == "SP4" and lessonNo == 8' in harness
    and "semanticLoaded >= 4" in harness
    and 'FindFirstChild("Semantic_PaintStudioOperatorDesk")' in harness
    and 'FindFirstChild("Semantic_PaintStudioPreviewMonitor")' in harness
    and 'FindFirstChild("Semantic_PaintStudioKeyboard")' in harness
    and 'FindFirstChild("Semantic_PaintStudioMouse")' in harness,
    "checks_sp5_timeline_entry_gate": 'grade == "SP5" and lessonNo == 3' in harness
    and "semanticLoaded >= 11" in harness
    and '"Semantic_TimelineEntryScanner"' in harness
    and "SP5/03 ticket scanner too far" in harness,
    "checks_sp5_search_semantic_upgrade": 'grade == "SP5" and lessonNo == 5' in harness
    and "semanticLoaded >= 24" in harness
    and 'FindFirstChild("Semantic_SearchTerminal_" .. stage)' in harness
    and 'Semantic_SearchTokenControl_%d_%d' in harness
    and 'FindFirstChild("Semantic_SearchQuoteControl_" .. stage)' in harness
    and 'FindFirstChild("Semantic_SearchPdfControl_" .. stage)' in harness
    and 'FindFirstChild("Semantic_SearchRunControl_" .. stage)' in harness,
    "checks_sp5_problem_semantic_upgrade": 'grade == "SP5" and lessonNo == 7' in harness
    and "semanticLoaded >= 13" in harness
    and '"Semantic_ConveyorCrate"' in harness
    and '"Semantic_DiagnosticConsole"' in harness
    and '"Semantic_LoadTestConsole"' in harness
    and '"Semantic_ProblemLoadTestControl"' in harness
    and '"Semantic_ProblemMeasureControl_" .. probeId' in harness
    and '"Semantic_ProblemDiagnosisControl_" .. probeId' in harness
    and '"Semantic_ProblemRepairControl_" .. repairId' in harness,
    "checks_sp5_typing_semantic_upgrade": 'grade == "SP5" and lessonNo == 8' in harness
    and "semanticLoaded >= 8" in harness
    and '"Semantic_TypingTerminal"' in harness
    and '"Semantic_TypingCourierBody"' in harness
    and '"Semantic_DataCrate"' in harness
    and '"Semantic_FileCrate"' in harness
    and '"Semantic_TypingOperatorDesk"' in harness
    and '"Semantic_TypingTerminalKeyboard"' in harness
    and '"Semantic_TypingTerminalMouse"' in harness
    and '"Semantic_TypingAccuracyMonitor"' in harness,
    "checks_sp6_inventor_semantic_upgrade": 'grade == "SP6" and lessonNo == 4' in harness
    and "semanticLoaded >= 14" in harness
    and '"Semantic_InventorComponentRack"' in harness
    and '"Semantic_InventorTestConsole"' in harness
    and '"Semantic_InventorModuleControl_MOTION_SENSOR"' in harness
    and '"Semantic_InventorModuleControl_CONTROLLER"' in harness
    and '"Semantic_InventorModuleControl_MOTOR"' in harness
    and '"Semantic_InventorModuleControl_BATTERY"' in harness
    and '"Semantic_InventorModuleControl_STORAGE"' in harness
    and '"Semantic_InventorModuleControl_ANTENNA"' in harness
    and '"Semantic_InventorSlotControl_INPUT"' in harness
    and '"Semantic_InventorSlotControl_PROCESSOR"' in harness
    and '"Semantic_InventorSlotControl_OUTPUT"' in harness
    and '"Semantic_InventorCableControl_INPUT_PROCESSOR"' in harness
    and '"Semantic_InventorCableControl_INPUT_OUTPUT"' in harness
    and '"Semantic_InventorCableControl_PROCESSOR_OUTPUT"' in harness,
    "checks_sp6_photo_semantic_upgrade": 'grade == "SP6" and lessonNo == 5' in harness
    and "semanticLoaded >= 9" in harness
    and '"Semantic_PhotoCameraBody"' in harness
    and '"Semantic_PhotoPrinter"' in harness
    and '"Semantic_PhotoOrientationControl"' in harness
    and '"Semantic_PhotoPanLeft"' in harness
    and '"Semantic_PhotoPanRight"' in harness
    and '"Semantic_PhotoDarker"' in harness
    and '"Semantic_PhotoBrighter"' in harness
    and '"Semantic_PhotoContrastDial"' in harness
    and '"Semantic_PhotoShutter"' in harness,
    "checks_sp6_scratch_loop_semantic_upgrade": 'grade == "SP6" and lessonNo == 7' in harness
    and "semanticLoaded >= 17" in harness
    and '"Semantic_ScratchLoopStartControl"' in harness
    and "SP6/07 start program too far" in harness
    and '"Semantic_ScratchLoopRobot"' in harness
    and '"Semantic_ScratchProgramRack"' in harness
    and '"Semantic_ScratchXConsole"' in harness
    and '"Semantic_ScratchYConsole"' in harness
    and '"Semantic_ScratchRunConsole"' in harness
    and '"Semantic_ScratchVariableBoard"' in harness
    and '"Semantic_ScratchLoopStatusBoard"' in harness
    and '"Semantic_ScratchLoopRunControl"' in harness
    and '"Semantic_ScratchLoopDebugMonitor"' in harness
    and '"Semantic_ScratchLoopOperatorDesk"' in harness
    and '"Semantic_ScratchLoopOperatorKeyboard"' in harness
    and '"Semantic_ScratchLoopOperatorMouse"' in harness
    and '"Semantic_ScratchLoopXControl_Minus"' in harness
    and '"Semantic_ScratchLoopXControl_Plus"' in harness
    and '"Semantic_ScratchLoopYControl_Minus"' in harness
    and '"Semantic_ScratchLoopYControl_Plus"' in harness,
    "checks_sp6_animation_semantic_upgrade": 'grade == "SP6" and lessonNo == 9' in harness
    and "semanticLoaded >= 9" in harness
    and 'FindFirstChild("Semantic_AnimationPathControl_" .. objectId)' in harness
    and 'FindFirstChild("Semantic_AnimationTriggerControl_" .. objectId)' in harness
    and '"Semantic_AnimationPathTestConsole"' in harness
    and '"Semantic_AnimationTriggerTestConsole"' in harness
    and '"Semantic_AnimationFinalConsole"' in harness,
    "checks_sp8_spreadsheet_semantic_upgrade": 'grade == "SP8" and lessonNo == 4' in harness
    and "semanticLoaded >= 18" in harness
    and '"Semantic_SpreadsheetEntryConsole"' in harness
    and '"Semantic_SpreadsheetInstructionBoard"' in harness
    and "SP8/04 entry console too far" in harness
    and '"Semantic_FormulaRepairDesk"' in harness
    and '"Semantic_SpreadsheetRunConsole"' in harness
    and '"Semantic_SpreadsheetQuantityConsole"' in harness
    and '"Semantic_SpreadsheetSyncConsole"' in harness
    and '"Semantic_SpreadsheetRunControl"' in harness
    and '"Semantic_SpreadsheetQtyMinusControl"' in harness
    and '"Semantic_SpreadsheetQtyPlusControl"' in harness
    and '"Semantic_SpreadsheetSyncControl"' in harness
    and '"Semantic_SpreadsheetFormulaControl_%s_%d"' in harness,
    "checks_sp8_number_foundry_semantic_upgrade": 'grade == "SP8" and lessonNo == 7' in harness
    and "semanticLoaded >= 7" in harness
    and '"Semantic_NumberModuloScanner"' in harness
    and '"Semantic_NumberDivisorControl_2"' in harness
    and '"Semantic_NumberDivisorControl_3"' in harness
    and '"Semantic_NumberDivisorControl_5"' in harness
    and '"Semantic_NumberDivisorControl_7"' in harness
    and '"Semantic_NumberClassifyControl_Prime"' in harness
    and '"Semantic_NumberClassifyControl_Composite"' in harness,
    "checks_sp8_sorting_semantic_upgrade": 'grade == "SP8" and lessonNo == 9' in harness
    and "semanticLoaded >= 14" in harness
    and '"Semantic_SortingCalibrationConsole"' in harness
    and '"Semantic_SortingInstructionBoard"' in harness
    and "SP8/09 calibration console too far" in harness
    and '"Semantic_SortingScannerTop"' in harness
    and '"Semantic_SortingDecisionKeepControl"' in harness
    and '"Semantic_SortingDecisionSwapControl"' in harness
    and '"Semantic_SortingSpeedControl"' in harness
    and '"Semantic_SortingProductionControl"' in harness
    and '"Semantic_SortingSpeedConsole"' in harness
    and '"Semantic_SortingProductionConsole"' in harness
    and '"Semantic_SorterPackage_" .. packageIndex' in harness,
    "checks_sp8_sports_semantic_upgrade": 'grade == "SP8" and lessonNo == 10' in harness
    and "semanticLoaded >= 14" in harness
    and 'FindFirstChild("Semantic_SportsFactScanControl_" .. factId)' in harness
    and 'FindFirstChild("Semantic_SportsChartControl_" .. controlId)' in harness
    and 'FindFirstChild("Semantic_SportsChartValidateControl")' in harness
    and 'FindFirstChild("Semantic_SportsCameraControl_" .. direction)' in harness
    and 'FindFirstChild("Semantic_SportsPhotoCaptureControl")' in harness
    and 'FindFirstChild("Semantic_SportsCameraDrone")' in harness
    and 'FindFirstChild("Semantic_SportsBroadcastDesk")' in harness,
    "checks_sp7_chapter_finale_semantic_upgrade": 'grade == "SP7" and lessonNo == 5' in harness
    and "semanticLoaded >= 20" in harness
    and 'FindFirstChild("Semantic_ChapterEntryScanner")' in harness
    and 'FindFirstChild("Semantic_ChapterInstructionBoard")' in harness
    and "SP7/05 entry scanner too far" in harness
    and 'FindFirstChild("Semantic_ChapterAlgorithmConsole")' in harness
    and 'FindFirstChild("Semantic_ChapterDataScanner")' in harness
    and 'FindFirstChild("Semantic_ChapterSecurityTerminal")' in harness
    and 'FindFirstChild("Semantic_ChapterAlgorithmButton_" .. index)' in harness
    and 'FindFirstChild("Semantic_ChapterBitSwitch_" .. index)' in harness
    and 'FindFirstChild("Semantic_ChapterSecurityButton_" .. index)' in harness,
    "checks_lo1_language_semantic_upgrade": 'grade == "LO1" and lessonNo == 3' in harness
    and "semanticLoaded >= 10" in harness
    and '"Semantic_LanguageCargo_" .. projectId' in harness
    and '"Semantic_LanguageDockControl_" .. languageId' in harness
    and 'FindFirstChild("Semantic_LanguagePortScannerBase")' in harness
    and 'FindFirstChild("Semantic_LanguagePortLaunchConsole")' in harness,
    "checks_lo1_command_yard_semantic_upgrade": 'grade == "LO1" and lessonNo == 4' in harness
    and "semanticLoaded >= 9" in harness
    and '"Semantic_MissionTerminal"' in harness
    and '"Semantic_RescueRobot"' in harness
    and '"Semantic_CommandYardRobot"' in harness
    and '"Semantic_CommandYardCart"' in harness
    and '"Semantic_CommandYardOperatorDesk"' in harness
    and '"Semantic_CommandYardKeyboard"' in harness
    and '"Semantic_CommandYardMouse"' in harness
    and '"Semantic_CommandYardSignalMonitor"' in harness
    and '"Semantic_CommandYardToolbox"' in harness,
    "checks_lo1_parameter_semantic_upgrade": 'grade == "LO1" and lessonNo == 5' in harness
    and "semanticLoaded >= 7" in harness
    and '"Semantic_ParameterControlConsole"' in harness
    and '"Semantic_ParameterMonitor"' in harness
    and '"Semantic_ParameterAutomationRack"' in harness
    and '"Semantic_ParameterRobot"' in harness
    and '"Semantic_ParameterLiftCargo"' in harness
    and '"Semantic_ParameterPistonCargo_Left"' in harness
    and '"Semantic_ParameterPistonCargo_Right"' in harness,
    "checks_lo1_math_semantic_upgrade": 'grade == "LO1" and lessonNo == 6' in harness
    and "semanticLoaded >= 12" in harness
    and '"Semantic_MathCalibrationConsole"' in harness
    and "LO1/06 calibration console too far" in harness
    and '"Semantic_MathFunctionControl_SQRT"' in harness
    and '"Semantic_MathFunctionControl_FLOOR"' in harness
    and '"Semantic_MathFunctionControl_CEIL"' in harness
    and '"Semantic_MathEngineLaunchConsole"' in harness
    and '"Semantic_MathEngineStatus"' in harness
    and '"Semantic_MathEngineResult"' in harness
    and '"Semantic_MathEngineExplanation"' in harness
    and '"Semantic_MathOperatorDesk"' in harness
    and '"Semantic_MathOperatorKeyboard"' in harness
    and '"Semantic_MathOperatorMouse"' in harness
    and '"Semantic_MathEngineCoreRack"' in harness,
    "checks_lo1_decision_drone_semantic_upgrade": 'grade == "LO1" and lessonNo == 7' in harness
    and "semanticLoaded >= 9" in harness
    and 'FindFirstChild("Semantic_DecisionOperatorControl_" .. operatorId)' in harness
    and 'FindFirstChild("Semantic_DecisionThresholdControl_" .. tostring(threshold))' in harness
    and 'FindFirstChild("Semantic_DecisionDroneBody")' in harness
    and 'FindFirstChild("Semantic_DecisionDroneTestConsole")' in harness
    and 'FindFirstChild("Semantic_DecisionDroneLaunchConsole")' in harness,
    "checks_lo2_vault_semantic_upgrade": 'grade == "LO2" and lessonNo == 3' in harness
    and "semanticLoaded >= 19" in harness
    and '"Semantic_VaultEntryConsole"' in harness
    and '"Semantic_VaultInstructionBoard"' in harness
    and "LO2/03 entry console too far" in harness
    and 'FindFirstChild("Semantic_VaultBinarySwitch_" .. index)' in harness
    and "Semantic_VaultDecimalAdjustControl_" in harness
    and "Semantic_VaultHexAdjustControl_" in harness
    and "Semantic_VaultValidateControl_" in harness,
    "checks_lo2_conversion_semantic_upgrade": 'grade == "LO2" and lessonNo == 4' in harness
    and "semanticLoaded >= 14" in harness
    and '"Semantic_BinaryConversionConsole"' in harness
    and '"Semantic_BinaryRemainder0"' in harness
    and '"Semantic_BinaryDivisionCrank"' in harness
    and '"Semantic_HexConversionValidate"' in harness
    and '"Semantic_HexAdjust_" .. key .. "_" .. suffix' in harness
    and '"Semantic_ReverseConversionValidate"' in harness,
    "checks_lo2_rail_semantic_upgrade": 'grade == "LO2" and lessonNo == 5' in harness
    and "semanticLoaded >= 15" in harness
    and 'FindFirstChild("Semantic_RailManifestScanner")' in harness
    and "LO2/05 manifest scanner too far" in harness
    and 'FindFirstChild("Semantic_RailDispatchConsole")' in harness
    and 'FindFirstChild("Semantic_RailStageSwitch")' in harness
    and 'FindFirstChild("Semantic_RailSwapControl_" .. index)' in harness
    and '"Semantic_RailSortOrderBoard"' in harness
    and '"Semantic_RailSortCostBoard"' in harness
    and '"Semantic_RailSortStatusBoard"' in harness
    and '"Semantic_RailSortOperatorDesk"' in harness
    and '"Semantic_RailSortOperatorKeyboard"' in harness
    and '"Semantic_RailSortOperatorMouse"' in harness
    and '"Semantic_RailSortStageMonitor"' in harness
    and '"Semantic_RailSortDepartureMonitor"' in harness,
    "checks_lo2_message_semantic_upgrade": 'grade == "LO2" and lessonNo == 6' in harness
    and "semanticLoaded >= 10" in harness
    and '"Semantic_MessageCleanScanner"' in harness
    and '"Semantic_MessageReplaceConsole"' in harness
    and '"Semantic_MessageSliceScanner"' in harness
    and '"Semantic_MessagePreviewMonitor"' in harness
    and '"Semantic_MessageOperatorDesk"' in harness
    and '"Semantic_MessageOperatorKeyboard"' in harness
    and '"Semantic_MessageOperatorMouse"' in harness
    and '"Semantic_MessageStageMonitor"' in harness
    and '"Semantic_MessagePipelineRack"' in harness
    and '"Semantic_MessageArchiveMonitor"' in harness,
    "checks_lo2_forensics_semantic_upgrade": 'grade == "LO2" and lessonNo == 7' in harness
    and "semanticLoaded >= 10" in harness
    and '"Semantic_ForensicPatternScanner"' in harness
    and '"Semantic_ForensicPatternControl_Left"' in harness
    and '"Semantic_ForensicPatternControl_Right"' in harness
    and '"Semantic_ForensicPatternControl_Check"' in harness
    and '"Semantic_ForensicCountMonitor"' in harness
    and '"Semantic_ForensicCountControl_Match"' in harness
    and '"Semantic_ForensicCountControl_Skip"' in harness
    and '"Semantic_ForensicPalindromeTerminal"' in harness
    and '"Semantic_ForensicPalindromeControl_Equal"' in harness
    and '"Semantic_ForensicPalindromeControl_Different"' in harness,
    "checks_lo2_caesar_semantic_upgrade": 'grade == "LO2" and lessonNo == 8' in harness
    and "semanticLoaded >= 14" in harness
    and '"Semantic_CaesarEntryConsole"' in harness
    and '"Semantic_CaesarInstructionBoard"' in harness
    and "LO2/08 entry console too far" in harness
    and '"Semantic_CaesarShiftControl_Minus"' in harness
    and '"Semantic_CaesarShiftControl_Plus"' in harness
    and '"Semantic_CaesarShiftControl_Lock"' in harness
    and '"Semantic_CaesarRotorTerminal"' in harness
    and '"Semantic_CaesarModeControl_Toggle"' in harness
    and '"Semantic_CaesarRunControl_Execute"' in harness
    and '"Semantic_CaesarShiftReadoutMonitor"' in harness
    and '"Semantic_CaesarRingMechanismConsole"' in harness
    and '"Semantic_CaesarModeStatusMonitor"' in harness
    and '"Semantic_CaesarRotorDriveRack"' in harness
    and '"Semantic_CaesarVaultStatusMonitor"' in harness
    and '"Semantic_CaesarVaultLockConsole"' in harness,
    "checks_lo2_mail_merge_semantic_upgrade": 'grade == "LO2" and lessonNo == 9' in harness
    and "semanticLoaded >= 10" in harness
    and '"Semantic_MailMergeIntakeCrate"' in harness
    and "LO2/09 intake crate too far" in harness
    and 'FindFirstChild("Semantic_MailMergeMappingControl_" .. index)' in harness
    and 'FindFirstChild("Semantic_MailMergePreviewControl_" .. index)' in harness
    and 'FindFirstChild("Semantic_MailMergePrintControl")' in harness
    and 'FindFirstChild("Semantic_MailMergeMappingConsole")' in harness
    and 'FindFirstChild("Semantic_MailMergePrinter")' in harness,
    "checks_lo2_data_import_semantic_upgrade": 'grade == "LO2" and lessonNo == 10' in harness
    and "semanticLoaded >= 9" in harness
    and '"Semantic_DataDockEntryConsole"' in harness
    and '"Semantic_DataDockInstructionBoard"' in harness
    and "LO2/10 intake console too far" in harness
    and '"Semantic_DataDockSeparatorControl"' in harness
    and '"Semantic_DataDockHeaderControl"' in harness
    and '"Semantic_DataDockImportScanner"' in harness
    and '"Semantic_DataDockTypeControl_1"' in harness
    and '"Semantic_DataDockTypeControl_2"' in harness
    and '"Semantic_DataDockTypeControl_3"' in harness
    and '"Semantic_DataDockTypeValidateConsole"' in harness,
    "checks_lo3_chrono_semantic_upgrade": 'grade == "LO3" and lessonNo == 3' in harness
    and "semanticLoaded >= 15" in harness
    and '"Semantic_ChronoTimeSyncConsole"' in harness
    and '"Semantic_ChronoInstructionBoard"' in harness
    and "LO3/03 time-sync console too far" in harness
    and '"Semantic_ChronoDialControl_" .. chronoId' in harness
    and '"Semantic_ChronoStabilizeControl_" .. chronoId' in harness
    and '"Semantic_ChronoScanControl_" .. chronoId' in harness
    and 'FindFirstChild("Semantic_ChronoSyncConsole")' in harness,
    "checks_lo3_decision_semantic_upgrade": 'grade == "LO3" and lessonNo == 4' in harness
    and "semanticLoaded >= 17" in harness
    and '"Semantic_DecisionCityPlanningConsole"' in harness
    and "LO3/04 planning console too far" in harness
    and "Semantic_DecisionProfileControl_" in harness
    and "Semantic_DecisionValidateControl_" in harness,
    "checks_lo3_pc_er_semantic_upgrade": 'grade == "LO3" and lessonNo == 5' in harness
    and "semanticLoaded >= 21" in harness
    and '"Semantic_PCEmergencyCheckIn"' in harness
    and '"Semantic_PCEmergencyInstructionBoard"' in harness
    and "LO3/05 check-in too far" in harness
    and '"Semantic_PCEmergencyPC_"' in harness
    and '"Semantic_PCEmergencyDesk_"' in harness
    and '"Semantic_PCEmergencyScanner_"' in harness
    and '"Semantic_PCEmergencyRepairConsole_"' in harness
    and '"Semantic_PCEmergencyVerify_"' in harness
    and '"Semantic_PCEmergencyTool_"' in harness,
    "checks_lo3_internet_entry_upgrade": 'grade == "LO3" and lessonNo == 6' in harness
    and "semanticLoaded >= 7" in harness
    and '"Semantic_InternetSiteCheck"' in harness
    and '"Semantic_InternetInstructionBoard"' in harness
    and "LO3/06 site-check too far" in harness,
    "checks_lo3_service_semantic_upgrade": 'grade == "LO3" and lessonNo == 7' in harness
    and "semanticLoaded >= 12" in harness
    and "distance <= 24" in harness
    and "LO3/07 entry scanner too far" in harness
    and '"Semantic_ServiceRequestScanner"' in harness
    and '"Semantic_ServiceDispatchConsole"' in harness
    and '"Semantic_ServiceRequestBoard"' in harness
    and '"Semantic_ServiceBackboneHub"' in harness
    and '"Semantic_ServiceDNSTower"' in harness
    and '"Semantic_ServiceDNSResult"' in harness
    and '"Semantic_ServiceWebServerRack"' in harness
    and '"Semantic_ServiceWebResult"' in harness
    and '"Semantic_ServiceMailPrinter"' in harness
    and '"Semantic_ServiceMailResult"' in harness
    and '"Semantic_ServiceCloudServerRack"' in harness
    and '"Semantic_ServiceCloudResult"' in harness,
    "checks_lo3_html_semantic_upgrade": 'grade == "LO3" and lessonNo == 8' in harness
    and "semanticLoaded >= 14" in harness
    and '"Semantic_HTMLDeveloperDesk"' in harness
    and '"Semantic_HTMLDeveloperLaptop"' in harness
    and '"Semantic_HTMLDeveloperMouse"' in harness
    and '"Semantic_HTMLDeveloperChair"' in harness
    and 'FindFirstChild("Semantic_HTMLTagControl_" .. tagId)' in harness
    and 'FindFirstChild("Semantic_HTMLAttributeControl_" .. attributeId)' in harness
    and 'FindFirstChild("Semantic_HTMLValidatorControl")' in harness,
    "checks_lo3_css_semantic_upgrade": 'grade == "LO3" and lessonNo == 9' in harness
    and "semanticLoaded >= 16" in harness
    and '"Semantic_CSSStyleControl_color_contrast"' in harness
    and '"Semantic_CSSStyleControl_layout_absolute"' in harness
    and '"Semantic_CSSAuditConsole"' in harness,
    "checks_lo3_launch_semantic_upgrade": 'grade == "LO3" and lessonNo == 10' in harness
    and "semanticLoaded >= 13" in harness
    and '"Semantic_LaunchTemplateControl_portfolio"' in harness
    and '"Semantic_LaunchStyleControl_coherent"' in harness
    and '"Semantic_LaunchCTAControl_contact"' in harness
    and '"Semantic_LaunchConsole"' in harness,
    "checks_sp7_dock_semantic_upgrade": 'grade == "SP7" and lessonNo == 10' in harness
    and "semanticLoaded >= 10" in harness
    and '"Semantic_PythonDockRobot"' in harness
    and '"Semantic_PythonDockServerTower"' in harness
    and '"Semantic_PythonDockControlConsole"' in harness
    and '"Semantic_PythonDockStatus"' in harness
    and '"Semantic_PythonDockChipCargo"' in harness
    and '"Semantic_PythonCommandTower_1"' in harness
    and '"Semantic_PythonCommandTower_5"' in harness,
    "checks_sp8_maze_semantic_upgrade": 'grade == "SP8" and lessonNo == 5' in harness
    and "semanticLoaded >= 10" in harness
    and '"Semantic_PythonMazeRobot"' in harness
    and '"Semantic_PythonMazeServerTower"' in harness
    and '"Semantic_PythonMazeControlConsole"' in harness
    and '"Semantic_PythonMazeStatus"' in harness
    and '"Semantic_PythonMazeSensor"' in harness
    and '"Semantic_PythonMazeChipCargo"' in harness
    and '"Semantic_PythonLaserPost_1_0"' in harness
    and '"Semantic_PythonLaserPost_3_3"' in harness,
    "checks_sp8_power_semantic_upgrade": 'grade == "SP8" and lessonNo == 6' in harness
    and "semanticLoaded >= 10" in harness
    and '"Semantic_PythonPowerRobot"' in harness
    and '"Semantic_PythonPowerControlConsole"' in harness
    and '"Semantic_PythonRack"' in harness
    and '"Semantic_PythonPowerStatusMonitor"' in harness
    and '"Semantic_PythonPowerCoreRack"' in harness
    and '"Semantic_PythonPowerTurbineConsole"' in harness
    and '"Semantic_PythonPowerSystemConsole_PUMP"' in harness
    and '"Semantic_PythonPowerSystemConsole_CORE"' in harness,
    "checks_lo1_logic_semantic_upgrade": 'grade == "LO1" and lessonNo == 8' in harness
    and "semanticLoaded >= 17" in harness
    and '"Semantic_LogicPowerLever"' in harness
    and '"Semantic_LogicInstructionBoard"' in harness
    and "LO1/08 power lever too far" in harness
    and '"Semantic_LogicSwitch_AND_A"' in harness
    and '"Semantic_LogicSwitch_OR_B"' in harness
    and '"Semantic_LogicSwitch_NOT_A"' in harness
    and '"Semantic_LogicGateHardware_AND"' in harness
    and '"Semantic_LogicOutputMonitor_AND"' in harness
    and '"Semantic_LogicTestControl_AND"' in harness
    and '"Semantic_LogicCoreRack"' in harness,
    "checks_lo1_loop_semantic_upgrade": 'grade == "LO1" and lessonNo == 9' in harness
    and "semanticLoaded >= 11" in harness
    and '"Semantic_LoopFactoryControlConsole"' in harness
    and '"Semantic_LoopFactoryAutomationRack"' in harness
    and '"Semantic_LoopFactoryShippingCrate"' in harness
    and '"Semantic_LoopFactoryStamper"' in harness
    and '"Semantic_LoopFactoryScannerTop"' in harness
    and '"Semantic_LoopFactoryPackage_" .. packageIndex' in harness,
    "checks_lo1_sequence_semantic_upgrade": 'grade == "LO1" and lessonNo == 10' in harness
    and "semanticLoaded >= 24" in harness
    and '"Semantic_SequenceRepairScanner"' in harness
    and '"Semantic_SequenceGeneratorControlConsole"' in harness
    and '"Semantic_SequenceReactorOverviewScreen"' in harness
    and '"Semantic_SequenceRuleMinus"' in harness
    and '"Semantic_SequenceNextLever"' in harness
    and '"Semantic_SequenceRepairScanControl_"' in harness
    and '"Semantic_SequenceGeneratorMinus_"' in harness
    and '"Semantic_SequenceGeneratorPlus_"' in harness
    and '"Semantic_SequenceGenerateButton"' in harness,
    "checks_initial_interaction": "enabledMissionPrompts" in harness and "promptCount >= 1" in harness,
    "checks_semantic_prompt_anchor": "local function promptHasVisibleAnchor(part)" in harness
    and 'part:GetAttribute("SemanticAssetId") ~= nil' in harness
    and 'part:GetAttribute("SemanticAssetFallback") == false' in harness,
    "checks_first_action_distance": "MAX_FIRST_ACTION_DISTANCE = 80" in harness
    and "nearestEnabledPrompt" in harness
    and "distance <= MAX_FIRST_ACTION_DISTANCE" in harness,
    "checks_prompt_activation": "MIN_PROMPT_ACTIVATION_DISTANCE = 8" in harness
    and "firstPrompt.MaxActivationDistance >= MIN_PROMPT_ACTIVATION_DISTANCE" in harness,
    "checks_prompt_no_los": "not missionPrompt.RequiresLineOfSight" in harness
    and "active prompt requires line of sight" in harness,
    "checks_prompt_copy": 'firstPrompt.ActionText ~= "" and firstPrompt.ObjectText ~= ""' in harness,
    "checks_spawn_humanoid": 'FindFirstChildOfClass("Humanoid")' in harness
    and 'FindFirstChild("HumanoidRootPart")' in harness
    and "humanoid.Health > 0" in harness,
    "waits_initial_character": "local function waitForPlayableCharacter(player)" in harness
    and "for _ = 1, 80 do" in harness
    and "task.wait(0.1)" in harness
    and "after bounded wait" in harness,
    "checks_spawn_mobility": "MIN_WALK_SPEED = 8" in harness
    and "humanoid.WalkSpeed >= MIN_WALK_SPEED" in harness
    and "not root.Anchored" in harness,
    "checks_spawn_ground": "GROUND_PROBE_DISTANCE = 16" in harness
    and "workspace:Raycast" in harness
    and "groundCollidable" in harness,
    "logs_mobility": "walk=%.1f ground=%.1f" in harness,
    "logs_first_action_distance": "first=%.1f" in harness,
    "harness_build_id_placeholder": '__RELEASE_BUILD_ID__' in harness
    and "[CER-RELEASE] BUILD_ID " in harness,
    "client_probe_handshake": 'reportRemote:FireServer({ ready = true })' in client_probe
    and "waitForClientReady" in harness,
    "client_report_wait_allows_recovery": "local function waitForClientReport(player)" in harness
    and "for _ = 1, 60 do" in harness,
    "client_probe_camera": "camera.CameraType == Enum.CameraType.Custom" in client_probe
    and "player.CameraMinZoomDistance" in client_probe
    and "player.CameraMaxZoomDistance" in client_probe
    and "camera.FieldOfView" in client_probe,
    "client_probe_camera_sabotage": 'replacement.Name = "CER_CameraRecoveryProbe"' in client_probe
    and "replacement.CameraType = Enum.CameraType.Scriptable" in client_probe
    and "replacement.FieldOfView = 95" in client_probe
    and "workspace.CurrentCamera = replacement" in client_probe
    and "cameraReplacementProbeDone = workspace.CurrentCamera == replacement" in client_probe
    and "player.CameraMinZoomDistance = 12" in client_probe
    and "player.CameraMaxZoomDistance = 48" in client_probe,
    "client_probe_camera_sabotage_retry": "local function scheduleCameraRecoveryProbe()" in client_probe
    and "scheduleCameraRecoveryProbe()" in client_probe
    and "recoveryProbeScheduled" in client_probe
    and "recoveryProbeDone = true" in client_probe,
    "client_probe_sabotage_survives_hud_updates": "local function scheduleInputRecoveryProbe()" in client_probe
    and "local function scheduleConstraintRecoveryProbe()" in client_probe
    and "scheduleInputRecoveryProbe()" in client_probe
    and "scheduleConstraintRecoveryProbe()" in client_probe
    and "scheduleInputRecoveryProbe(token)" not in client_probe
    and "scheduleConstraintRecoveryProbe(token)" not in client_probe,
    "client_probe_hud_throttle": "local latestHudMessage = nil" in client_probe
    and "local reportScheduled = false" in client_probe
    and "latestHudMessage = message" in client_probe
    and "if reportScheduled then" in client_probe
    and "local currentMessage = latestHudMessage" in client_probe
    and 'title = tostring(currentMessage.title or "")' in client_probe
    and "token ~= reportToken" not in client_probe
    and "local reportToken = 0" not in client_probe,
    "client_probe_waits_for_recovery": "local function waitForRecoveryProbes()" in client_probe
    and "recoveryProbeDone and inputRecoveryProbeDone and constraintRecoveryProbeDone" in client_probe
    and "local deadline = os.clock() + 3.0" in client_probe
    and "waitForRecoveryProbes()" in client_probe,
    "client_probe_waits_for_first_action_guide": "local function waitForFirstActionGuide()" in client_probe
    and 'object:IsA("ProximityPrompt") and object.Enabled' in client_probe
    and 'FindFirstChild("CER_FirstActionGuide", true)' in client_probe
    and 'FindFirstChild("CER_FirstActionBeacon", true)' in client_probe
    and "local deadline = os.clock() + 1.5" in client_probe
    and "waitForFirstActionGuide()" in client_probe,
    "client_probe_hidden_focus_sabotage": 'probeBox.Name = "HiddenFocusProbe"' in client_probe
    and "probeBox:CaptureFocus()" in client_probe
    and "local function waitForFocusState" in client_probe
    and "waitForFocusState(probeBox, true, 0.6)" in client_probe
    and "probeBox.Visible = false" in client_probe
    and "waitForFocusState(probeBox, false, 0.8)" in client_probe
    and "inputRecoveryProbePassed = captured and released" in client_probe,
    "client_probe_hidden_focus_runtime": "UserInputService:GetFocusedTextBox()" in client_probe
    and "hiddenFocusedTextBox" in client_probe
    and "focusedTextBox" in client_probe,
    "client_probe_constraint_count": "local function textConstraintStatus" in client_probe
    and "constraint-count=%d" in client_probe
    and "count ~= 1" in client_probe,
    "client_probe_constraint_race": 'screenLabel.Name = "LateScreenConstraintProbe"' in client_probe
    and 'worldLabel.Name = "LateWorldConstraintProbe"' in client_probe
    and "lateScreen.Parent = screenLabel" in client_probe
    and "lateWorld.Parent = worldLabel" in client_probe
    and "constraintRecoveryProbePassed" in client_probe,
    "client_probe_hud": 'object.Text:sub(1, 4) == "CEL:"' in client_probe
    and "hudObjectiveVisible" in client_probe
    and "hudObjectiveTextSize" in client_probe
    and "objective.TextBounds.X <= objective.AbsoluteSize.X + 1" in client_probe
    and "objective.TextBounds.Y <= objective.AbsoluteSize.Y + 1" in client_probe
    and "hudObjectiveFits" in client_probe,
    "client_probe_scaled_text": "scaledTextReadable" in client_probe
    and "textConstraintStatus(object, 16)" in client_probe,
    "client_probe_world_text": "worldTextReadable" in client_probe
    and "worldGuiTextVisible" in client_probe
    and "if not gui.Enabled or not object.Visible then" in client_probe
    and "if object.AbsoluteSize.X <= 0 or object.AbsoluteSize.Y <= 0 then" in client_probe
    and "textConstraintStatus(object, 18)" in client_probe
    and "object.TextSize < 18" in client_probe
    and "object.TextStrokeTransparency > 0.66" in client_probe
    and "object.TextBounds.X > object.AbsoluteSize.X + 1" in client_probe
    and "object.TextBounds.Y > object.AbsoluteSize.Y + 1" in client_probe
    and "text bounds clipped bounds=%.0fx%.0f size=%.0fx%.0f" in client_probe
    and "not object.TextFits" not in client_probe
    and "object.LightInfluence > 0.01" in client_probe
    and "object.Brightness < 1.09" in client_probe
    and "brightness below 1.1" in client_probe,
    "client_probe_first_action": 'FindFirstChild("CER_FirstActionGuide", true)' in client_probe
    and 'FindFirstChild("CER_FirstActionBeacon", true)' in client_probe
    and "firstActionBeaconVisible" in client_probe,
    "client_probe_rejects_spurious_mission_update": 'FindFirstChild("MissionNotification", true)' in client_probe
    and 'missionNotification.Text == "Aktualizacja misji"' in client_probe
    and "spuriousMissionUpdateVisible" in client_probe,
    "client_probe_python": 'panelVisible("PythonConsoleGui", "Panel")' in client_probe,
    "client_probe_typing": 'FindFirstChild("TypingTerminalUI")' in client_probe,
    "server_requires_client_camera": "clientReport.cameraCustom" in harness
    and "clientReport.cameraClassic" in harness
    and "clientReport.cameraSubjectHumanoid" in harness,
    "server_requires_camera_recovery_probe": "cameraRecoveryProbeDone" in harness
    and "cameraReplacementProbeDone" in harness
    and "camera recovery sabotage probe did not run" in harness
    and "CurrentCamera replacement probe did not run" in harness,
    "server_requires_input_recovery_probe": "inputRecoveryProbeDone" in harness
    and "inputRecoveryProbePassed" in harness
    and "hidden TextBox focus was not released" in harness,
    "server_requires_constraint_recovery_probe": "constraintRecoveryProbeDone" in harness
    and "constraintRecoveryProbePassed" in harness
    and "late text constraint probe did not run" in harness
    and "text constraint dedupe/recovery failed" in harness,
    "server_rejects_hidden_focus": "not clientReport.hiddenFocusedTextBox" in harness
    and "hidden TextBox still focused" in harness,
    "server_rejects_spurious_mission_update": "not clientReport.spuriousMissionUpdateVisible" in harness
    and "spurious mission update toast visible" in harness,
    "server_logs_input_freedom": " input=1 " in harness,
    "server_logs_constraint_recovery": " constraints=1 " in harness,
    "search_race_entry_gate": 'grade == "SP8" and lessonNo == 8' in harness
    and "SP8/08 expected one initial START WYSZUKIWANIA prompt" in harness
    and "SP8/08 entry console too far" in harness
    and "semanticLoaded >= 29" in harness
    and '"Semantic_SearchRaceEntryConsole"' in harness
    and '"Semantic_SearchRaceInstructionBoard"' in harness,
    "server_restarts_same_title": "originalModel = model" in harness
    and "MissionEngine.Start(player, lesson, mission, missionInfo)" in harness
    and "restartedModel ~= originalModel" in harness
    and "restartReport.firstActionGuideVisible" in harness
    and "restartReport.firstActionBeaconVisible" in harness
    and "RESTART_GUIDE_OK SP4/03" in harness,
    "server_real_character_respawn": "player:LoadCharacter()" in harness
    and "waitForCharacterReplacement" in harness
    and "mission model lost across respawn" in harness
    and "MAX_RESPAWN_DISTANCE = 8" in harness,
    "server_respawn_client_state": "respawnReport.cameraCustom" in harness
    and "respawnReport.hudObjectiveVisible" in harness
    and "respawnReport.hudObjectiveFits" in harness
    and "respawnReport.firstActionGuideVisible" in harness
    and "respawnReport.firstActionBeaconVisible" in harness
    and "hidden TextBox focused after respawn" in harness
    and "RESPAWN_OK SP4/03" in harness,
    "server_requires_client_hud": "clientReport.hudObjectiveVisible" in harness
    and "clientReport.hudObjectivePrefix" in harness
    and "clientReport.hudObjectiveTextSize" in harness
    and "clientReport.hudObjectiveFits" in harness
    and "CEL clipped" in harness,
    "server_requires_client_readability": "clientReport.scaledTextReadable" in harness,
    "server_requires_world_readability": "clientReport.worldTextReadable" in harness
    and "clientReport.worldTextCount" in harness
    and "world text unreadable" in harness,
    "server_requires_client_guide": "clientReport.firstActionGuideVisible" in harness
    and "clientReport.firstActionBeaconVisible" in harness
    and "First Action beacon not visible" in harness,
    "server_requires_python_console": "clientReport.pythonConsoleVisible" in harness,
    "server_requires_typing_ui": "clientReport.typingUiPresent" in harness,
    "python_exception_explicit": '{ "SP7", 10, "Python Lab", false }' in harness,
    "core_locked": 'findPrompt(model, "RDZEŃ MISJI • ETAP 2/3", "MissionCore")' in harness
    and "not corePrompt.Enabled" in harness,
    "exit_locked": 'findPrompt(model, "WYJŚCIE", "ExitGate")' in harness
    and "not exitPrompt.Enabled" in harness,
    "final_gate_prompt_scope": "local function findPrompt(model, objectText, parentName)" in harness
    and "parent.Name == parentName" in harness,
    "fail_fast": "pcall(runCase" in harness and "[CER-RELEASE] FAIL" in harness and "error(err)" in harness,
    "success_marker": "[CER-RELEASE] ALL_OK" in harness,
    "manual_gate_marker": "MANUAL_GATE camera rotation + zoom 5-16 + HUD/CEL + world text + First Action Guide/beacon" in harness,
    "builder_temp_harness": "StudioSmokeRelease.server.lua" in builder,
    "builder_temp_client_probe": "StudioReleaseClientProbe.client.lua" in builder
    and "ReleaseClientProbe.client.lua" in builder,
    "builder_cleanup": "finally" in builder
    and "Remove-Item -Force $harnessTarget" in builder
    and "Remove-Item -Force $clientProbeTarget" in builder,
    "builder_playtest_output": "CyberEscapeRoom_RELEASE_QA.rbxlx" in builder,
    "builder_rejects_stale_smoke": "stale Studio smoke source present" in builder
    and "StudioSmoke*.server.lua" in builder
    and "StudioRelease*.client.lua" in builder
    and "$staleServerSmoke.Count -gt 0" in builder
    and "$staleClientSmoke.Count -gt 0" in builder,
    "builder_unique_build_id": "release-smoke-build-id.txt" in builder
    and "[Guid]::NewGuid()" in builder
    and ".Replace('__RELEASE_BUILD_ID__', $buildId)" in builder
    and "RELEASE_SMOKE_BUILD_ID=" in builder,
    "builder_relative_rojo": "..\\..\\tools\\rojo\\rojo.exe" in builder,
    "gitignore_smoke": "StudioSmoke*.server.lua" in gitignore
    and "StudioRelease*.client.lua" in gitignore,
    "checker_build_id_file": "release-smoke-build-id.txt" in checker
    and "$expectedBuildId" in checker,
    "checker_build_id_marker": "[CER-RELEASE] BUILD_ID " in checker
    and "$buildMarker" in checker,
    "checker_finds_matching_log": "foreach ($candidate in (Get-ChildItem $logDir -File | Sort-Object LastWriteTime -Descending))" in checker
    and "$candidateLines = Get-Content $candidate.FullName" in checker
    and "$candidateLines[$i].Contains($buildMarker)" in checker
    and "if ($candidateBuildIndex -ge 0)" in checker,
    "checker_scopes_after_build_marker": "$buildIndex" in checker
    and "$lines[$buildIndex..($lines.Count - 1)]" in checker,
    "checker_reports_build_match": "RELEASE_SMOKE_BUILD_MATCH" in checker,
    "checker_rejects_build_mismatch": "Release smoke log does not match the current release QA build ID." in checker,
    "checker_dynamic_matrix_count": "$matrixLines" in checker
    and "$expectedFamilies = $matrixLines.Count" in checker
    and "$expectedPromptFamilies" in checker,
    "checker_dynamic_pass_format": "$passPattern" in checker
    and "$allOkPattern" in checker
    and "$expectedFamilies" in checker,
    "checker_requires_dynamic_passes": "RELEASE_SMOKE_PASS_COUNT" in checker
    and "$passes.Count -ne $expectedFamilies" in checker,
    "checker_requires_dynamic_client_passes": "RELEASE_SMOKE_CLIENT_PASS_COUNT" in checker
    and "$clientPasses.Count -ne $expectedFamilies" in checker,
    "checker_requires_dynamic_prompt_distances": "RELEASE_SMOKE_FIRST_ACTION_COUNT" in checker
    and "$firstActionDistances.Count -ne $expectedPromptFamilies" in checker,
    "checker_reports_max_first_action": "RELEASE_SMOKE_MAX_FIRST_ACTION_DISTANCE" in checker,
    "checker_rejects_far_first_action": "$maxFirstAction -gt 80" in checker,
    "checker_requires_dynamic_mobility": "RELEASE_SMOKE_MOBILITY_COUNT" in checker
    and "$walkSpeeds.Count -ne $expectedFamilies" in checker
    and "$groundDistances.Count -ne $expectedFamilies" in checker,
    "checker_reports_mobility": "RELEASE_SMOKE_MIN_WALK_SPEED" in checker
    and "RELEASE_SMOKE_MAX_GROUND_DISTANCE" in checker,
    "checker_requires_dynamic_world_text": "RELEASE_SMOKE_WORLD_TEXT_COUNT" in checker
    and "$worldTextCounts.Count -ne $expectedFamilies" in checker,
    "checker_reports_min_world_text": "RELEASE_SMOKE_MIN_WORLD_TEXT" in checker,
    "checker_rejects_zero_world_text": "$minWorldTextCount -lt 1" in checker,
    "checker_requires_dynamic_input_freedom": "RELEASE_SMOKE_INPUT_FREEDOM_COUNT" in checker
    and "$inputFreedom.Count -ne $expectedFamilies" in checker,
    "checker_reports_input_freedom": "RELEASE_SMOKE_MIN_INPUT_FREEDOM" in checker,
    "checker_rejects_hidden_focus": "$minInputFreedom -lt 1" in checker,
    "checker_requires_dynamic_constraint_recovery": "RELEASE_SMOKE_CONSTRAINT_RECOVERY_COUNT" in checker
    and "$constraintRecovery.Count -ne $expectedFamilies" in checker,
    "checker_reports_constraint_recovery": "RELEASE_SMOKE_MIN_CONSTRAINT_RECOVERY" in checker,
    "checker_rejects_constraint_duplicates": "$minConstraintRecovery -lt 1" in checker
    and "duplicate or unreadable UITextSizeConstraint state" in checker,
    "checker_requires_restart_guide": "RELEASE_SMOKE_RESTART_GUIDE" in checker
    and "$restartGuide.Count -ne 1" in checker
    and "First Action Guide after same-title restart" in checker,
    "checker_requires_respawn": "RELEASE_SMOKE_RESPAWN_OK" in checker
    and "$respawnOk.Count -ne 1" in checker
    and "mission recovery after character respawn" in checker,
    "checker_rejects_low_walk": "$minWalkSpeed -lt 8" in checker,
    "checker_rejects_far_ground": "$maxGroundDistance -gt 16" in checker,
    "checker_rejects_fail": "$fails.Count -gt 0" in checker and "Release smoke contains FAIL entries." in checker,
    "checker_requires_all_ok": "$allOkPattern" in checker and "RELEASE_SMOKE_VERIFIED=1" in checker,
    "checker_requires_manual_gate": "MANUAL_GATE" in checker and "RELEASE_SMOKE_MANUAL_GATE" in checker,
}

combined_public_tools = "\n".join([harness, client_probe, builder, checker])
private_patterns = [
    r"[A-Za-z]:\\Users\\[^\\\s]+",
    r"\b(?:10(?:\.\d{1,3}){3}|192\.168(?:\.\d{1,3}){2}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2})\b",
    r"(?i)\b(?:desktop|laptop|node|dc|srv|server)-[A-Z0-9-]{3,}\b",
]
checks["no_private_identifiers"] = not any(
    re.search(pattern, combined_public_tools) for pattern in private_patterns
)

bad = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[RELEASE-SMOKE-QA] {'PASS' if ok else 'FAIL'} {name}")
if bad:
    raise SystemExit("RELEASE_SMOKE_QA_FAILED: " + ",".join(bad))
print("[RELEASE-SMOKE-QA] ALL_OK")