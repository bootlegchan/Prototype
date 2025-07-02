extends Node

# --- THIS IS THE FIX ---
# All paths are now simple, direct, and logically correct.
const ENTITY_DEFINITION_PATH = "res://data/definitions/entities/"
const ITEM_DEFINITION_PATH = "res://data/definitions/items/"
const STATE_DEFINITION_PATH = "res://data/definitions/states/"
const SCHEDULES_DEFINITION_PATH = "res://data/definitions/schedules/"
const SPAWN_LIST_PATH = "res://data/definitions/spawn_lists/"
const TAG_DEFINITION_PATH = "res://data/definitions/tags/"
const TIME_SETTINGS_FILE_PATH = "res://data/definitions/settings/time_settings.json"

# World data is now in its own top-level directory.
const CALENDER_FILE_PATH = "res://data/world/calender.json"
const WORLD_STATE_FILE_PATH = "res://data/world/world_state.json"

const COMPONENT_PATH = "res://script/components/"
# --- END OF FIX ---

func _init() -> void:
	print("[DIAGNOSTIC] Config.gd _init() called.")
	pass
