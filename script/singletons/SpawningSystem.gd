# script/singletons/SpawningSystem.gd
extends Node

var _spawn_lists: Dictionary = {}

func _ready() -> void:
	_load_all_spawn_lists()

func _load_all_spawn_lists() -> void:
	_spawn_lists.clear()
	var path = Config.SPAWN_LIST_PATH
	var dir = DirAccess.open(path)
	if not dir:
		printerr("[SPAWNER] Spawn lists directory not found: ", path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var full_path = path.path_join(file_name)
			var list_id = file_name.get_basename()
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					_spawn_lists[list_id] = json.get_data()
				else:
					printerr("Failed to parse spawn list JSON '%s'. Error: %s at line %s" % [full_path, json.get_error_message(), json.get_error_line()])

		file_name = dir.get_next()
	
	print("[SYSTEM] Loaded %s spawn lists." % _spawn_lists.size())

func execute_spawn_list(list_id: String, base_position: Vector3 = Vector3.ZERO) -> Array[String]:
	if not _spawn_lists.has(list_id):
		printerr("[SPAWNER] Spawn list not found: '", list_id, "'")
		return []

	var list_data: Dictionary = _spawn_lists[list_id]
	var spawns: Array = list_data.get("spawns", [])
	var spawned_instance_ids: Array[String] = []

	print("[SPAWNER] Executing list: '%s' at position %s" % [list_id, str(base_position)])
	
	for spawn_info in spawns:
		var def_id = spawn_info.get("definition_id")
		if not def_id:
			push_warning("[SPAWNER] Spawn entry in list '%s' is missing 'definition_id'." % list_id)
			continue
			
		var pos_data = spawn_info.get("position", {"x": 0, "y": 0, "z": 0})
		var relative_position = Vector3(
			pos_data.get("x", 0.0), pos_data.get("y", 0.0), pos_data.get("z", 0.0)
		)
		
		# Allow spawn info to override the instance ID name.
		var name_override = spawn_info.get("name_override", "")

		print("[SPAWNER] -- Requesting entity '%s' at offset %s" % [def_id, str(relative_position)])
		var new_id = EntityManager.request_new_entity(def_id, base_position + relative_position, name_override)
		spawned_instance_ids.append(new_id)
		
	print("[SPAWNER] List execution finished.")
	return spawned_instance_ids
