# script/singletons/StateRegistry.gd
extends Node

var _state_definitions: Dictionary = {}

func _ready() -> void:
	# --- DEBUG PRINT ---
	print("StateRegistry: _ready called.")
	# --- END DEBUG PRINT ---
	_state_definitions.clear()
	_recursive_load_definitions(Config.STATE_DEFINITION_PATH)
	print("Loaded %s state definitions." % _state_definitions.size())
	print("Discovered State IDs: ", _state_definitions.keys())

## Returns the dictionary definition for a given state ID, or an empty dictionary if not found.
func get_state_definition(state_id: String) -> Dictionary:
	# --- DEBUG PRINT ---
	# print("StateRegistry: get_state_definition called for '%s'." % state_id) # Very verbose
	# --- END DEBUG PRINT ---
	return _state_definitions.get(state_id, {})

func is_state_defined(state_id: String) -> bool:
	# --- DEBUG PRINT ---
	# print("StateRegistry: is_state_defined called for '%s'." % state_id) # Very verbose
	# --- END DEBUG PRINT ---
	return _state_definitions.has(state_id)

func _recursive_load_definitions(path: String) -> void:
	# --- DEBUG PRINT ---
	print("StateRegistry: _recursive_load_definitions called for path '%s'." % path)
	# --- END DEBUG PRINT ---
	var dir = DirAccess.open(path)
	if not dir:
		printerr("StateRegistry: Could not open state definitions directory: ", path)
		return

	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue

		var full_path = path.path_join(item_name)
		if dir.current_is_dir():
			_recursive_load_definitions(full_path)
		elif item_name.ends_with(".json"):
			# --- THIS IS THE FIX ---
			# Construct definition ID robustly by removing the base path and extension.
			var base_path_to_remove = Config.STATE_DEFINITION_PATH
			if not base_path_to_remove.ends_with("/"):
				base_path_to_remove += "/"
			
			var relative_path = full_path.replace(base_path_to_remove, "") # Remove the base path prefix
			var definition_id = relative_path.trim_suffix(".json") # Remove the .json extension

			# --- DEBUG PRINT ---
			print("StateRegistry: Attempting to load state definition: '%s' from path: %s" % [definition_id, full_path])
			# --- END DEBUG PRINT ---

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_state_definitions[definition_id] = data
						# --- DEBUG PRINT ---
						print("StateRegistry: Successfully loaded state definition: '%s'" % definition_id)
						# --- END DEBUG PRINT ---
					else:
						printerr("StateRegistry: Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("StateRegistry: Failed to parse JSON for state '%s'. Error at line %d: %s" % [full_path, json.get_error_line(), json.get_error_message()])

		item_name = dir.get_next()
	dir.list_dir_end() # Ensure directory is closed
