extends Node

var _state_definitions: Dictionary = {}

func _ready() -> void:
	_state_definitions.clear()
	_recursive_load_definitions(Config.STATE_DEFINITION_PATH)
	print("Loaded %s state definitions." % _state_definitions.size())
	print("Discovered State IDs: ", _state_definitions.keys())

func get_state_definition(state_id: String) -> Dictionary:
	return _state_definitions.get(state_id, {})

func is_state_defined(state_id: String) -> bool:
	return _state_definitions.has(state_id)

func _recursive_load_definitions(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		printerr("Could not open state definitions directory: ", path)
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
			# --- THIS IS THE FIX ---
			var relative_path = full_path.replace(Config.STATE_DEFINITION_PATH, "")
			var definition_id = relative_path.trim_prefix("/").trim_suffix(".json")
			var file = FileAccess.open(full_path, FileAccess.READ)
			var json_data = JSON.parse_string(file.get_as_text())
			_state_definitions[definition_id] = json_data
		item_name = dir.get_next()
