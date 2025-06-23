extends Node

var _entity_registry: Dictionary = {}
var _node_to_instance_id_map: Dictionary = {}
var _next_uid: int = 0

# --- Public API ---
func request_new_entity(definition_id: String, position: Vector3) -> String:
	var base_name = definition_id.get_slice("/", -1)
	var instance_id = "%s_%s" % [base_name, str(_get_next_uid())]
	
	_entity_registry[instance_id] = {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"position": position,
		"rotation": Vector3.ZERO,
		"component_data": {} # Prepare to store component state
	}
	
	EventSystem.emit_event("entity_record_created", {"instance_id": instance_id})
	stage_entity(instance_id)
	return instance_id

func stage_entity(instance_id: String) -> void:
	if not _entity_registry.has(instance_id):
		printerr("Cannot stage entity: Unknown instance ID '", instance_id, "'")
		return

	var entity_data = _entity_registry[instance_id]
	var entity_node = EntityFactory.create_entity_node(entity_data["definition_id"], entity_data["position"])
	
	if is_instance_valid(entity_node):
		# We now also need to re-initialize components with saved data, but we'll skip that for now.
		_node_to_instance_id_map[entity_node] = instance_id
		entity_node.name = instance_id
		
		get_tree().current_scene.add_child(entity_node)
		EventSystem.emit_event("entity_staged", {"instance_id": instance_id, "node": entity_node})

# --- THIS IS THE NEW IMPLEMENTATION ---
func unstage_entity(instance_id: String) -> void:
	var entity_node = get_node_from_instance_id(instance_id)
	if not is_instance_valid(entity_node):
		printerr("Cannot unstage entity: Node for instance '%s' not found." % instance_id)
		return
		
	print("Unstaging entity '%s'..." % instance_id)

	# --- 1. Save State ---
	var entity_data = _entity_registry[instance_id]
	
	# Save transform
	if entity_node is Node3D:
		entity_data["position"] = entity_node.position
		entity_data["rotation"] = entity_node.rotation_degrees

	# Save component data
	var logic_node = entity_node.get_node_or_null("EntityLogic")
	if logic_node:
		for component in logic_node.get_children():
			if component.has_method("get_persistent_data"):
				entity_data["component_data"][component.name] = component.get_persistent_data()

	# --- 2. Remove from World ---
	_node_to_instance_id_map.erase(entity_node)
	entity_node.queue_free()
	
	EventSystem.emit_event("entity_unstaged", {"instance_id": instance_id})
	print("Entity '%s' unstaged. Data saved: %s" % [instance_id, entity_data])

func get_node_from_instance_id(instance_id: String) -> Node:
	for node in _node_to_instance_id_map:
		if _node_to_instance_id_map[node] == instance_id:
			return node
	return null

func _get_next_uid() -> int:
	_next_uid += 1
	return _next_uid
