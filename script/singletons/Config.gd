# script/singletons/Config.gd
extends Node

# Define paths to data definitions
const ENTITY_DEFINITION_PATH = "res://data/definitions/entities/"
const ITEM_DEFINITION_PATH = "res://data/definitions/items/"
const STATE_DEFINITION_PATH = "res://data/definitions/states/"
const SCHEDULES_DEFINITION_PATH = "res://data/definitions/schedules/"
const SPAWN_LIST_PATH = "res://data/definitions/spawn_lists/"
const TAG_DEFINITION_PATH = "res://data/definitions/tags/"
const TIME_SETTINGS_FILE_PATH = "res://data/definitions/settings/time_settings.json"
const CALENDER_FILE_PATH = "res://data/definitions/world/calender.json"
const WORLD_STATE_FILE_PATH = "res://data/world/world_state.json" # Assuming world_state is also in data/world

# Define paths to scripts
const COMPONENT_PATH = "res://script/components/"

func _init() -> void:
	# --- DEBUG PRINT ---
	print("[DIAGNOSTIC] Config.gd _init() called.")
	# --- END DEBUG PRINT ---
	pass # No specific initialization needed in Config itself
