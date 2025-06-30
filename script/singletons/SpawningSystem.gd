# script/singletons/SpawningSystem.gd
extends Node

var _spawn_lists: Dictionary = {}

func _ready() -> void:
	# --- DEBUG PRINT ---
	print("SpawningSystem: _ready called. Loading spawn lists.")
	# --- END DEBUG PRINT ---
	_load_all_spawn_lists()
	print("[SYSTEM] Loaded %s spawn lists." % _spawn_lists.size())

# --- THIS IS THE FIX ---
# The function should accept the path argument for recursion.
func _load_all_spawn_lists(path: String = Config.SPAWN_LIST_PATH) -> void:
# --- END OF FIX ---
	# --- DEBUG PRINT ---
	print("SpawningSystem: _load_all_spawn_lists called for path '%s'." % path)
	# --- END DEBUG PRINT ---
	_spawn_lists.clear()
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
			# --- THIS IS THE FIX ---
			# The recursive call should pass the full_path.
			_load_all_spawn_lists(full_path)
			# --- END OF FIX ---
		elif item_name.ends_with(".json"):
			var base_path = Config.SPAWN_LIST_PATH
			if not base_path.ends_with("/"):
				base_path += "/"
			var relative_path = full_path.lstrip(base_path)
			var definition_id = relative_path.trim_suffix(".json")

			# --- DEBUG PRINT ---
			print("SpawningSystem: Attempting to load spawn list definition: %s from %s." % [definition_id, full_path])
			# --- END DEBUG PRINT ---

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_spawn_lists[definition_id] = data
						# --- DEBUG PRINT ---
						print("SpawningSystem: Successfully loaded spawn list: %s" % definition_id)
						# --- END DEBUG PRINT ---
					else:
						printerr("SpawningSystem: Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("SpawningSystem: Failed to parse JSON for spawn list '%s'. Error: %s at line %d: %s" % [full_path, json.get_error_message(), json.get_error_line()])

		item_name = dir.get_next()
	dir.list_dir_end()

func execute_spawn_list(list_id: String, base_position: Vector3 = Vector3.ZERO) -> Array[String]:
	# --- DEBUG PRINT ---
	print("SpawningSystem: execute_spawn_list called for list '%s' at base position %s." % [list_id, base_position])
	# --- END DEBUG PRINT ---
	if not _spawn_lists.has(list_id):
		printerr("[SPAWNER] Spawn list not found: '", list_id, "'")
		return []

	var list_data: Dictionary = _spawn_lists[list_id]
	var spawns: Array = list_data.get("spawns", [])
	var spawned_instance_ids: Array[String] = []

	print("[SPAWNER] Executing list: '%s' at position %s" % [list_id, str(base_position)])
	# --- DEBUG PRINT ---
	print("SpawningSystem: Found %d spawn entries in list '%s'." % [spawns.size(), list_id])
	# --- END DEBUG PRINT ---

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
		# --- DEBUG PRINT ---
		print("SpawningSystem: Requested new entity '%s', received instance ID '%s'." % [def_id, new_id])
		# --- END DEBUG PRINT ---


	print("[SPAWNER] List execution finished.")
	# --- DEBUG PRINT ---
	print("SpawningSystem: execute_spawn_list finished for list '%s'. Spawned IDs: %s" % [list_id, spawned_instance_ids])
	# --- END DEBUG PRINT ---
	return spawned_instance_ids
