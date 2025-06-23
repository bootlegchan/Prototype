extends Node

const SPAWN_LIST_PATH = "res://data/definitions/spawn_lists/"

var _spawn_lists: Dictionary = {}

func _ready() -> void:
	_load_all_spawn_lists()

func _load_all_spawn_lists() -> void:
	var dir = DirAccess.open(SPAWN_LIST_PATH)
	if not dir:
		printerr("Spawn lists directory not found: ", SPAWN_LIST_PATH)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var list_id = file_name.get_basename()
			var file = FileAccess.open(SPAWN_LIST_PATH + file_name, FileAccess.READ)
			_spawn_lists[list_id] = JSON.parse_string(file.get_as_text())
		file_name = dir.get_next()
	
	print("Loaded %s spawn lists." % _spawn_lists.size())


# --- Public API ---

# The main function to execute a named spawn list.
func execute_spawn_list(list_id: String) -> void:
	if not _spawn_lists.has(list_id):
		printerr("Spawn list not found: '", list_id, "'")
		return

	var list_data: Dictionary = _spawn_lists[list_id]
	var spawns: Array = list_data.get("spawns", [])

	print("\n--- Executing Spawn List: '%s' ---" % list_id)
	
	for spawn_info in spawns:
		var def_id = spawn_info.get("definition_id")
		var pos_data = spawn_info.get("position", {"x": 0, "y": 0, "z": 0})
		
		if not def_id:
			push_warning("Spawn entry in list '%s' is missing a 'definition_id'." % list_id)
			continue
			
		var position = Vector3(
			pos_data.get("x", 0.0),
			pos_data.get("y", 0.0),
			pos_data.get("z", 0.0)
		)
		
		# Tell the EntityFactory to do the actual work of creating the entity.
		EntityFactory.spawn_entity(def_id, position)
		
	print("--- Spawn List Execution Finished ---")
