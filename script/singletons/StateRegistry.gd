extends Node

var _state_definitions: Dictionary = {}

func _ready() -> void:
	Debug.post("_ready called.", "StateRegistry")
	_load_definitions()
	Debug.post("Loaded %s state definitions." % _state_definitions.size(), "StateRegistry")
	Debug.post("Discovered State IDs: " + str(_state_definitions.keys()), "StateRegistry")

func _load_definitions() -> void:
	_state_definitions.clear()
	# Call the recursive function, passing the initial base path
	_recursive_load_definitions(Config.STATE_DEFINITION_PATH, Config.STATE_DEFINITION_PATH)

func get_state_definition(state_id: String) -> Dictionary:
	return _state_definitions.get(state_id, {})

func is_state_defined(state_id: String) -> bool:
	return _state_definitions.has(state_id)

# --- THIS IS THE FIX ---
# Added 'base_load_path' argument to correctly build definition IDs.
func _recursive_load_definitions(current_path: String, base_load_path: String) -> void:
	Debug.post("_recursive_load_definitions called for path '%s'." % current_path, "StateRegistry")
	var dir = DirAccess.open(current_path)
	if not dir:
		printerr("StateRegistry: Could not open state definitions directory: ", current_path)
		return

	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue

		var full_path = current_path.path_join(item_name)
		if dir.current_is_dir():
			# Pass the original base_load_path down to the recursive call.
			_recursive_load_definitions(full_path, base_load_path)
		elif item_name.ends_with(".json"):
			# Construct definition ID relative to the *original* base_load_path
			var relative_path = full_path.replace(base_load_path, "").lstrip("/")
			var definition_id = relative_path.trim_suffix(".json")

			Debug.post("Attempting to load state definition: '%s' from path: %s" % [definition_id, full_path], "StateRegistry")

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_state_definitions[definition_id] = data
						Debug.post("Successfully loaded state definition: '%s'" % definition_id, "StateRegistry")
					else:
						printerr("StateRegistry: Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("StateRegistry: Failed to parse JSON for state '%s'. Error at line %d: %s" % [full_path, json.get_error_line(), json.get_error_message()])

		item_name = dir.get_next()
	dir.list_dir_end()
# --- END OF FIX ---
