# script/singletons/Config.gd
extends Node

# This script centralizes all hardcoded paths for easy management.

# --- Core Definition Paths ---
const DEFINITIONS_BASE_PATH = "res://data/definitions/"

const ENTITY_DEFINITION_PATH = DEFINITIONS_BASE_PATH + "entities/"
const ITEM_DEFINITION_PATH = DEFINITIONS_BASE_PATH + "items/"
const SPAWN_LIST_PATH = DEFINITIONS_BASE_PATH + "spawn_lists/"
const STATE_DEFINITION_PATH = DEFINITIONS_BASE_PATH + "states/"
const TAG_DEFINITION_PATH = DEFINITIONS_BASE_PATH + "tags/"
const SCHEDULES_DEFINITION_PATH = DEFINITIONS_BASE_PATH + "schedules/"
const SETTINGS_PATH = DEFINITIONS_BASE_PATH + "settings/"
const WORLD_DATA_PATH = DEFINITIONS_BASE_PATH + "world/"

# --- Specific File Paths ---
const CALENDER_FILE_PATH = WORLD_DATA_PATH + "calender.json"
const WORLD_STATE_FILE_PATH = WORLD_DATA_PATH + "world_state.json"
const TIME_SETTINGS_FILE_PATH = SETTINGS_PATH + "time_settings.json"

# --- Component Paths ---
# Corrected path after moving the components folder into the 'script' folder
const COMPONENT_PATH = "res://script/components/"

func _init() -> void:
	# --- DIAGNOSTIC PRINT ---
	print("[DIAGNOSTIC] Config.gd _init() called.")
