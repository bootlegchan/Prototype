extends Node

var _spawn_lists: Dictionary = {}

func _ready() -> void:
	print("SpawningSystem: _ready called. Loading spawn lists.")
	_load_all_spawn_lists()
	print("[SYSTEM] Loaded %s spawn lists." % _spawn_lists.size())

func _load_all_spawn_lists() -> void:
	_spawn_lists.clear()
	_recursive_load(Config.SPAWN_LIST_PATH)

func _recursive_load(path: String) -> void:
	print("SpawningSystem: _recursive_load called for path '%s'." % path)
	var dir = DirAccess.open(path)
	if not dir:
		printerr("[SPAWNER] Spawn lists directory not found: ", path)
		return

	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue

		var full_path = path.path_join(item_name)
		if dir.current_is_dir():
			_recursive_load(full_path)
		elif item_name.ends_with(".json"):
			var base_path = Config.SPAWN_LIST_PATH
			if not base_path.ends_with("/"):
				base_path += "/"
			var relative_path = full_path.lstrip(base_path)
			var definition_id = relative_path.trim_suffix(".json")

			print("SpawningSystem: Attempting to load spawn list definition: %s from %s." % [definition_id, full_path])

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_spawn_lists[definition_id] = data
						print("SpawningSystem: Successfully loaded spawn list: %s" % definition_id)
					else:
						printerr("SpawningSystem: Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("SpawningSystem: Failed to parse JSON for spawn list '%s'. Error: %s at line %d: %s" % [full_path, json.get_error_message(), json.get_error_line()])

		item_name = dir.get_next()
	dir.list_dir_end()

func execute_spawn_list(list_id: String, base_position: Vector3 = Vector3.ZERO) -> Array[String]:
	print("SpawningSystem: execute_spawn_list called for list '%s' at base position %s." % [list_id, base_position])
	if not _spawn_lists.has(list_id):
		printerr("[SPAWNER] Spawn list not found: '", list_id, "'")
		return []

	var list_data: Dictionary = _spawn_lists[list_id]
	var spawns: Array = list_data.get("spawns", [])
	var spawned_instance_ids: Array[String] = []

	print("[SPAWNER] Executing list: '%s' at position %s" % [list_id, str(base_position)])
	print("SpawningSystem: Found %d spawn entries in list '%s'." % [spawns.size(), list_id])

	for spawn_info in spawns:
		var def_id = spawn_info.get("definition_id")
		if not def_id:
			push_warning("[SPAWNER] Spawn entry in list '%s' is missing 'definition_id'." % list_id)
			continue

		var pos_data = spawn_info.get("position", {"x": 0, "y": 0, "z": 0})
		var relative_position = Vector3(
			pos_data.get("x", 0.0), pos_data.get("y", 0.0), pos_data.get("z", 0.0)
		)

		var name_override = spawn_info.get("name_override", "")

		print("[SPAWNER] -- Requesting entity '%s' at offset %s" % [def_id, str(relative_position)])
		var new_id = EntityManager.request_new_entity(def_id, base_position + relative_position, name_override)
		spawned_instance_ids.append(new_id)
		print("SpawningSystem: Requested new entity '%s', received instance ID '%s'." % [def_id, new_id])

	print("[SPAWNER] List execution finished.")
	print("SpawningSystem: execute_spawn_list finished for list '%s'. Spawned IDs: %s" % [list_id, spawned_instance_ids])
	return spawned_instance_ids
