extends Node

var _entity_registry: Dictionary = {}
var _node_to_instance_id_map: Dictionary = {}
var _spawn_lists: Dictionary = {}
var _next_uid: int = 0

func _ready() -> void:
	_load_all_spawn_lists()
	load_world_state()

func _load_all_spawn_lists() -> void:
	_spawn_lists.clear()
	var dir = DirAccess.open(Config.SPAWN_LIST_PATH)
	if not dir:
		printerr("Spawn lists directory not found: ", Config.SPAWN_LIST_PATH)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var list_id = file_name.get_basename()
			var file = FileAccess.open(Config.SPAWN_LIST_PATH + file_name, FileAccess.READ)
			_spawn_lists[list_id] = JSON.parse_string(file.get_as_text())
		file_name = dir.get_next()
	print("Loaded %s spawn lists." % _spawn_lists.size())

func load_world_state() -> void:
	var file = FileAccess.open(Config.WORLD_STATE_PATH, FileAccess.READ)
	if not file:
		printerr("FATAL: Could not open world state file at: ", Config.WORLD_STATE_PATH)
		return
	var world_data = JSON.parse_string(file.get_as_text())
	var entities_to_load = world_data.get("entities", [])
	_entity_registry.clear()
	for entity_record in entities_to_load:
		var instance_id = entity_record["instance_id"]
		_entity_registry[instance_id] = { "instance_id": instance_id, "definition_id": entity_record["definition_id"],
			"position": Vector3( entity_record["position"].get("x",0.0), entity_record["position"].get("y",0.0), entity_record["position"].get("z",0.0)),
			"rotation": Vector3.ZERO, "component_data": entity_record.get("component_data", {})
		}
		stage_entity(instance_id)
	print("Loaded and staged %s persistent entities from world state." % _entity_registry.size())

func execute_spawn_list(list_id: String, base_position: Vector3 = Vector3.ZERO) -> Array[String]:
	if not _spawn_lists.has(list_id):
		printerr("Spawn list not found: '", list_id, "'")
		return []
	var list_data: Dictionary = _spawn_lists[list_id]
	var spawns: Array = list_data.get("spawns", [])
	var spawned_instance_ids: Array[String] = []
	print("\n--- EntityManager executing spawn list: '%s' ---" % list_id)
	for spawn_info in spawns:
		var def_id = spawn_info.get("definition_id")
		var pos_data = spawn_info.get("position", {"x": 0, "y": 0, "z": 0})
		if not def_id:
			push_warning("Spawn entry in list '%s' is missing a 'definition_id'." % list_id)
			continue
		var relative_position = Vector3( pos_data.get("x", 0.0), pos_data.get("y", 0.0), pos_data.get("z", 0.0) )
		var new_id = request_new_entity(def_id, base_position + relative_position)
		spawned_instance_ids.append(new_id)
	print("--- Spawn List Execution Finished ---")
	return spawned_instance_ids

func request_new_entity(definition_id: String, position: Vector3) -> String:
	var base_name = definition_id.get_slice("/", -1)
	var instance_id = "%s_dyn_%s" % [base_name, str(_get_next_uid())]
	_entity_registry[instance_id] = { "instance_id": instance_id, "definition_id": definition_id, "position": position, "rotation": Vector3.ZERO, "component_data": {} }
	EventSystem.emit_event("entity_record_created", {"instance_id": instance_id})
	stage_entity(instance_id)
	return instance_id

func stage_entity(instance_id: String) -> void:
	if not _entity_registry.has(instance_id): return
	var entity_data = _entity_registry[instance_id]
	var entity_node = EntityFactory.create_entity_node(entity_data["definition_id"], entity_data["position"], entity_data.get("component_data", {}))
	if is_instance_valid(entity_node):
		_node_to_instance_id_map[entity_node] = instance_id
		entity_node.name = instance_id
		if entity_node is Node3D and entity_data.has("rotation"): entity_node.rotation_degrees = entity_data["rotation"]
		get_tree().current_scene.add_child(entity_node)
		EventSystem.emit_event("entity_staged", {"instance_id": instance_id, "node": entity_node})

func unstage_entity(instance_id: String) -> void:
	var entity_node = get_node_from_instance_id(instance_id)
	if not is_instance_valid(entity_node): return
	print("Unstaging entity '%s'..." % instance_id)
	var entity_data = _entity_registry[instance_id]
	if entity_node is Node3D:
		entity_data["position"] = entity_node.position
		entity_data["rotation"] = entity_node.rotation_degrees
	entity_data["component_data"].clear()
	var logic_node = entity_node.get_node_or_null("EntityLogic")
	if logic_node:
		for component in logic_node.get_children():
			entity_data["component_data"][component.name] = {} 
			if component.has_method("get_persistent_data"):
				entity_data["component_data"][component.name] = component.get_persistent_data()
	_node_to_instance_id_map.erase(entity_node)
	entity_node.queue_free()
	EventSystem.emit_event("entity_unstaged", {"instance_id": instance_id})
	print("Entity '%s' unstaged. Data preserved." % instance_id)

func destroy_entity_permanently(instance_id: String) -> void:
	if not _entity_registry.has(instance_id): return
	unstage_entity(instance_id)
	if _entity_registry.has(instance_id): _entity_registry.erase(instance_id)
	EventSystem.emit_event("entity_destroyed", {"instance_id": instance_id})

func add_tag_to_entity(instance_id: String, tag_id: String) -> void:
	var component = get_entity_component(instance_id, "TagComponent")
	if component:
		component.add_tag(tag_id)

func set_entity_state(instance_id: String, state_id: String) -> void:
	var state_comp = get_entity_component(instance_id, "StateComponent")
	if state_comp:
		state_comp.push_state(state_id)

func get_entity_component(instance_id: String, component_name: String) -> Node:
	var node = get_node_from_instance_id(instance_id)
	if is_instance_valid(node):
		var logic_node = node.get_node_or_null("EntityLogic")
		if is_instance_valid(logic_node): return logic_node.get_component(component_name)
	return null

func get_node_from_instance_id(instance_id: String) -> Node:
	for node in _node_to_instance_id_map:
		if _node_to_instance_id_map[node] == instance_id: return node
	return null

func _get_next_uid() -> int:
	_next_uid += 1
	return _next_uid
