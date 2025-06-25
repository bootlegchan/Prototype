extends Node

var _entity_registry: Dictionary = {}
var _node_to_instance_id_map: Dictionary = {}
var _next_uid: int = 0


func _ready() -> void:
	# The SpawningSystem is now defunct for this test, we load the world directly.
	load_world_state()


func load_world_state() -> void:
	var file = FileAccess.open(Config.WORLD_STATE_FILE_PATH, FileAccess.READ)
	if not file:
		printerr("FATAL: Could not open world state file at: ", Config.WORLD_STATE_FILE_PATH)
		return
	
	var world_data = JSON.parse_string(file.get_as_text())
	var entities_to_load = world_data.get("entities", [])
	
	_entity_registry.clear()
	
	# Pass 1: Create all data records first.
	for entity_record in entities_to_load:
		var instance_id = entity_record["instance_id"]
		if not _entity_registry.has(instance_id):
			_entity_registry[instance_id] = {
				"instance_id": instance_id,
				"definition_id": entity_record["definition_id"],
				"position": Vector3(
					entity_record["position"].get("x", 0.0),
					entity_record["position"].get("y", 0.0),
					entity_record["position"].get("z", 0.0)
				),
				"rotation": Vector3.ZERO,
				"component_data": entity_record.get("component_data", {})
			}
			
	# Pass 2: Now that all top-level records exist, stage them.
	# Staging may recursively create more records for child entities.
	for entity_record in entities_to_load:
		stage_entity(entity_record["instance_id"])
		
	print("Loaded and staged %s persistent root entities from world state." % entities_to_load.size())


# --- Public API ---

# The single point of entry for creating any new entity, dynamic or nested.
func request_new_entity(definition_id: String, position: Vector3, name_override: String = "", parent_id: String = "") -> String:
	var instance_id = name_override if not name_override.is_empty() else "%s_dyn_%s" % [definition_id.get_slice("/", -1), str(_get_next_uid())]
	
	# If the entity somehow already exists, just return its ID.
	if _entity_registry.has(instance_id):
		# If it's not currently in the world, stage it.
		if not is_instance_valid(get_node_from_instance_id(instance_id)):
			stage_entity(instance_id)
		return instance_id
	
	# Create the data record.
	_entity_registry[instance_id] = {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"position": position,
		"rotation": Vector3.ZERO,
		"component_data": {}
	}
	
	# If there's a parent, pre-populate the ParentContextComponent data.
	if not parent_id.is_empty():
		_entity_registry[instance_id]["component_data"]["ParentContextComponent"] = {"parent_id": parent_id}

	EventSystem.emit_event("entity_record_created", {"instance_id": instance_id})
	stage_entity(instance_id)
	return instance_id


func stage_entity(instance_id: String) -> void:
	if not _entity_registry.has(instance_id) or is_instance_valid(get_node_from_instance_id(instance_id)):
		return # Don't stage if it doesn't exist or is already staged.
		
	var entity_data = _entity_registry[instance_id]
	var entity_node = EntityFactory.create_entity_node(
		entity_data["definition_id"],
		entity_data["position"],
		entity_data.get("component_data", {})
	)
	
	if is_instance_valid(entity_node):
		_node_to_instance_id_map[entity_node] = instance_id
		entity_node.name = instance_id
		if entity_node is Node3D and entity_data.has("rotation"):
			entity_node.rotation_degrees = entity_data["rotation"]
			
		get_tree().current_scene.add_child(entity_node)
		EventSystem.emit_event("entity_staged", {"instance_id": instance_id, "node": entity_node})
		
		# --- RECURSIVE SPAWNING IS HANDLED HERE ---
		var definition = EntityFactory._entity_definitions[entity_data["definition_id"]]
		if definition.has("child_entities"):
			for child_data in definition["child_entities"]:
				var child_def_id = child_data["definition_id"]
				var child_pos_data = child_data.get("position", {})
				var child_relative_pos = Vector3(child_pos_data.get("x",0), child_pos_data.get("y",0), child_pos_data.get("z",0))
				var name_override = child_data.get("name_override", "")
				
				# The parent node's transform is now valid, so we can calculate the child's world position.
				var child_world_pos = entity_node.global_transform * child_relative_pos
				
				# Recursively call request_new_entity for each child, passing the parent's ID.
				request_new_entity(child_def_id, child_world_pos, name_override, instance_id)


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
	if _entity_registry.has(instance_id):
		_entity_registry.erase(instance_id)
	EventSystem.emit_event("entity_destroyed", {"instance_id": instance_id})


func get_node_from_instance_id(instance_id: String) -> Node:
	for node in _node_to_instance_id_map:
		if _node_to_instance_id_map[node] == instance_id: return node
	return null

func get_entity_component(instance_id: String, component_name: String) -> Node:
	var node = get_node_from_instance_id(instance_id)
	if is_instance_valid(node):
		var logic_node = node.get_node_or_null("EntityLogic")
		if is_instance_valid(logic_node): return logic_node.get_component(component_name)
	return null

func _get_next_uid() -> int:
	_next_uid += 1
	return _next_uid
