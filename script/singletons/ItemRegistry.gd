# script/singletons/ItemRegistry.gd
extends Node

var _item_definitions: Dictionary = {}

func _ready() -> void:
	_item_definitions.clear()
	_recursive_load_definitions(Config.ITEM_DEFINITION_PATH)
	print("Loaded %s item definitions." % _item_definitions.size())
	print("Discovered Item IDs: ", _item_definitions.keys())

## Returns the dictionary definition for a given item ID, or an empty dictionary if not found.
func get_item_definition(item_id: String) -> Dictionary:
	return _item_definitions.get(item_id, {})

func is_item_defined(item_id: String) -> bool:
	return _item_definitions.has(item_id)

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

		var full_path = path.path_join(item_name)
		if dir.current_is_dir():
			_recursive_load_definitions(full_path)
		elif item_name.ends_with(".json"):
			var base_path = Config.ITEM_DEFINITION_PATH
			if not base_path.ends_with("/"):
				base_path += "/"
			var relative_path = full_path.lstrip(base_path)
			var definition_id = relative_path.trim_suffix(".json")

			# --- DEBUG PRINT ---
			print("ItemRegistry: Attempting to load item definition: %s from %s" % [definition_id, full_path])
			# --- END DEBUG PRINT ---

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_item_definitions[definition_id] = data
						# --- DEBUG PRINT ---
						print("ItemRegistry: Successfully loaded item definition: %s" % definition_id)
						# --- END DEBUG PRINT ---
					else:
						printerr("Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("Failed to parse JSON for item '%s'. Error at line %d: %s" % [full_path, json.get_error_line(), json.get_error_message()])

		item_name = dir.get_next()
	dir.list_dir_end()
