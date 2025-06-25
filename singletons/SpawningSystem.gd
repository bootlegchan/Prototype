extends Node

const SPAWN_LIST_PATH = "res://data/definitions/spawn_lists/"

var _spawn_lists: Dictionary = {}

func _ready() -> void:
	_load_all_spawn_lists()

func _load_all_spawn_lists() -> void:
	_spawn_lists.clear()
	var dir = DirAccess.open(SPAWN_LIST_PATH)
	if not dir:
		printerr("Spawn lists directory not found: ", SPAWN_LIST_PATH)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			# You can add recursion here if you want categorized spawn lists.
			# For now, we'll keep it flat.
			pass
		elif file_name.ends_with(".json"):
			var list_id = file_name.get_basename()
			var file = FileAccess.open(SPAWN_LIST_PATH + file_name, FileAccess.READ)
			_spawn_lists[list_id] = JSON.parse_string(file.get_as_text())
		file_name = dir.get_next()
	print("Loaded %s spawn lists." % _spawn_lists.size())

# --- Public API ---
# Executes a spawn list, creating dynamic entities via the EntityManager.
func execute_spawn_list(list_id: String, base_position: Vector3 = Vector3.ZERO) -> Array[String]:
	if not _spawn_lists.has(list_id):
		printerr("Spawn list not found: '", list_id, "'")
		return []

	var list_data: Dictionary = _spawn_lists[list_id]
	var spawns: Array = list_data.get("spawns", [])
	var spawned_instance_ids: Array[String] = []

	print("\n--- SpawningSystem executing list: '%s' ---" % list_id)
	
	for spawn_info in spawns:
		var def_id = spawn_info.get("definition_id")
		var pos_data = spawn_info.get("position", {"x": 0, "y": 0, "z": 0})
		if not def_id:
			push_warning("Spawn entry in list '%s' is missing a 'definition_id'." % list_id)
			continue
			
		var relative_position = Vector3(
			pos_data.get("x", 0.0), pos_data.get("y", 0.0), pos_data.get("z", 0.0)
		)
		
		# Correctly asks the EntityManager to create a new dynamic entity.
		var new_id = EntityManager.request_new_entity(def_id, base_position + relative_position)
		spawned_instance_ids.append(new_id)
		
	print("--- Spawn List Execution Finished ---")
	return spawned_instance_ids
