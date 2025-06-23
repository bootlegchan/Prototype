extends Node

const TAG_DEFINITION_PATH = "res://data/definitions/tags/"

var _tag_definitions: Dictionary = {}

func _ready() -> void:
	_tag_definitions.clear()
	_recursive_load_definitions(TAG_DEFINITION_PATH)
	
	print("Loaded %s tag definitions." % _tag_definitions.size())
	print("Discovered Tag IDs: ", _tag_definitions.keys())

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

		var full_path = "%s/%s" % [path.trim_suffix("/"), item_name]
		
		if dir.current_is_dir():
			_recursive_load_definitions(full_path)
		elif item_name.ends_with(".json"):
			var relative_path = full_path.replace(TAG_DEFINITION_PATH, "")
			var definition_id = relative_path.trim_suffix(".json")
			
			var file = FileAccess.open(full_path, FileAccess.READ)
			var json_data = JSON.parse_string(file.get_as_text())
			_tag_definitions[definition_id] = json_data
		
		item_name = dir.get_next()
