extends Node

var _spawn_lists: Dictionary = {}

func _ready() -> void:
	_load_all_spawn_lists()

func _load_all_spawn_lists() -> void:
	_spawn_lists.clear()
	var dir = DirAccess.open(Config.SPAWN_LIST_PATH)
	if not dir:
		printerr("[SPAWNER] Spawn lists directory not found: ", Config.SPAWN_LIST_PATH)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var list_id = file_name.get_basename()
			var file = FileAccess.open(Config.SPAWN_LIST_PATH + file_name, FileAccess.READ)
			_spawn_lists[list_id] = JSON.parse_string(file.get_as_text())
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
		var pos_data = spawn_info.get("position", {"x": 0, "y": 0, "z": 0})
		if not def_id:
			push_warning("[SPAWNER] Spawn entry in list '%s' is missing 'definition_id'." % list_id)
			continue
			
		var relative_position = Vector3(
			pos_data.get("x", 0.0), pos_data.get("y", 0.0), pos_data.get("z", 0.0)
		)
		print("[SPAWNER] -- Requesting entity '%s' at offset %s" % [def_id, str(relative_position)])
		var new_id = EntityManager.request_new_entity(def_id, base_position + relative_position)
		spawned_instance_ids.append(new_id)
		
	print("[SPAWNER] List execution finished.")
	return spawned_instance_ids
