extends Node

# --- THIS IS THE FIX ---
# This path now correctly points to the items folder inside the entities folder,
# matching your project's file structure.
const ITEM_DEFINITION_PATH = "res://data/definitions/entities/items/"

var _item_definitions: Dictionary = {}

func _ready() -> void:
	_item_definitions.clear()
	_recursive_load_definitions(ITEM_DEFINITION_PATH)
	
	print("Loaded %s item definitions." % _item_definitions.size())
	print("Discovered Item IDs: ", _item_definitions.keys())

# --- Public API ---

func get_item_definition(item_id: String) -> Dictionary:
	return _item_definitions.get(item_id, {})

func is_item_defined(item_id: String) -> bool:
	return _item_definitions.has(item_id)

# --- Private Helper Functions ---

func _recursive_load_definitions(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		printerr("Could not open item definitions directory: ", path)
		return

	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue

		var full_path = "%s/%s" % [path.trim_suffix("/"), item_name]
		
		if dir.current_is_dir():
			_recursive_load_definitions(full_path)
		elif item_name.ends_with(".json"):
			var relative_path = full_path.replace(ITEM_DEFINITION_PATH, "")
			var definition_id = relative_path.trim_suffix(".json")
			
			var file = FileAccess.open(full_path, FileAccess.READ)
			var json_data = JSON.parse_string(file.get_as_text())
			_item_definitions[definition_id] = json_data
		
		item_name = dir.get_next()
