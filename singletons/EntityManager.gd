extends Node

var _entity_registry: Dictionary = {}
var _node_to_instance_id_map: Dictionary = {}
var _next_uid: int = 0

func request_new_entity(definition_id: String, position: Vector3) -> String:
	var base_name = definition_id.get_slice("/", -1)
	var instance_id = "%s_%s" % [base_name, str(_get_next_uid())]
	_entity_registry[instance_id] = {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"position": position,
		"rotation": Vector3.ZERO,
	}
	print("New entity record created: '%s'" % instance_id)
	stage_entity(instance_id)
	return instance_id

func stage_entity(instance_id: String) -> void:
	if not _entity_registry.has(instance_id):
		printerr("Cannot stage entity: Unknown instance ID '", instance_id, "'")
		return
	var entity_data = _entity_registry[instance_id]
	var entity_node = EntityFactory.create_entity_node(entity_data["definition_id"], entity_data["position"])
	if is_instance_valid(entity_node):
		_node_to_instance_id_map[entity_node] = instance_id
		entity_node.name = instance_id
		get_tree().current_scene.add_child(entity_node)
		print("Staged entity '%s' into the world." % instance_id)

func unstage_entity(instance_id: String) -> void:
	print("Unstaging entity '%s'." % instance_id)

func _get_next_uid() -> int:
	_next_uid += 1
	return _next_uid
