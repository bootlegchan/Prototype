extends Node

const ENTITY_DEFINITION_PATH = "res://data/definitions/entities/"
const ITEM_DEFINITION_PATH = "res://data/definitions/items/"
const STATE_DEFINITION_PATH = "res://data/definitions/states/"
const SCHEDULES_DEFINITION_PATH = "res://data/definitions/schedules/"
const SPAWN_LIST_PATH = "res://data/definitions/spawn_lists/"
const TAG_DEFINITION_PATH = "res://data/definitions/tags/"
const COMPONENT_PATH = "res://script/components/"

const TIME_SETTINGS_FILE_PATH = "res://data/settings/time_settings.json"
const DEBUG_SETTINGS_FILE_PATH = "res://data/settings/debug_settings.json"

const CALENDER_FILE_PATH = "res://data/world/calender.json"
const WORLD_STATE_FILE_PATH = "res://data/world/world_state.json"

# --- THIS IS THE FIX ---
# It is not safe to call other singletons from within _init().
# The _init() function should only initialize this script's own variables.
func _init() -> void:
	pass

# _ready() is the correct place to interact with other nodes and singletons,
# as it is guaranteed to run after everything is initialized.
func _ready() -> void:
	Debug.post("Config singleton ready.", "Config")
# --- END OF FIX ---
