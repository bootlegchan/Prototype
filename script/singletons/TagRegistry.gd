# script/singletons/TagRegistry.gd
extends Node

var _tag_definitions: Dictionary = {}

func _ready() -> void:
	_tag_definitions.clear()
	_recursive_load_definitions(Config.TAG_DEFINITION_PATH)
	print("Loaded %s tag definitions." % _tag_definitions.size())
	print("Discovered Tag IDs: ", _tag_definitions.keys())

## Returns the dictionary definition for a given tag ID, or an empty dictionary if not found.
func get_tag_definition(tag_id: String) -> Dictionary:
	return _tag_definitions.get(tag_id, {})

func is_tag_defined(tag_id: String) -> bool:
	return _tag_definitions.has(tag_id)

func _recursive_load_definitions(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		printerr("Could not open tag definitions directory: ", path)
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
			var base_path = Config.TAG_DEFINITION_PATH
			if not base_path.ends_with("/"):
				base_path += "/"
			var relative_path = full_path.lstrip(base_path)
			var definition_id = relative_path.trim_suffix(".json")

			# --- DEBUG PRINT ---
			print("TagRegistry: Attempting to load tag definition: %s from %s" % [definition_id, full_path])
			# --- END DEBUG PRINT ---

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_tag_definitions[definition_id] = data
						# --- DEBUG PRINT ---
						print("TagRegistry: Successfully loaded tag definition: %s" % definition_id)
						# --- END DEBUG PRINT ---
					else:
						printerr("Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("Failed to parse JSON for tag '%s'. Error at line %d: %s" % [full_path, json.get_error_message(), json.get_error_line()])

		item_name = dir.get_next()
	dir.list_dir_end()
