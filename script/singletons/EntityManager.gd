# script/singletons/EntityManager.gd
extends Node

var _entity_registry: Dictionary = {}
var _node_to_instance_id_map: Dictionary = {}
var _next_uid: int = 0

func _ready() -> void:
	load_world_state()

func load_world_state() -> void:
	var file = FileAccess.open(Config.WORLD_STATE_FILE_PATH, FileAccess.READ)
	if not file: return
	var json = JSON.new(); json.parse(file.get_as_text()); file.close()
	var world_data: Dictionary = json.get_data()
	var entities_to_load = world_data.get("entities", [])
	_entity_registry.clear()
	for entity_record in entities_to_load:
		var instance_id = entity_record.get("instance_id")
		if instance_id and not _entity_registry.has(instance_id):
			_entity_registry[instance_id] = {
				"instance_id": instance_id, "definition_id": entity_record["definition_id"],
				"position": Vector3(entity_record.get("position",{}).get("x",0.0), entity_record.get("position",{}).get("y",0.0), entity_record.get("position",{}).get("z",0.0)),
				"rotation": Vector3.ZERO, "component_data": entity_record.get("component_data", {})
			}
	for entity_record in entities_to_load:
		stage_entity(entity_record["instance_id"])

func request_new_entity(definition_id: String, position: Vector3, name_override: String = "", parent_id: String = "") -> String:
	var base_name = definition_id.get_file().get_basename()
	var instance_id = name_override if not name_override.is_empty() else "%s_dyn_%s" % [base_name, str(_get_next_uid())]
	if _entity_registry.has(instance_id):
		if not is_instance_valid(get_node_from_instance_id(instance_id)): stage_entity(instance_id)
		return instance_id
	_entity_registry[instance_id] = {
		"instance_id": instance_id, "definition_id": definition_id,
		"position": position, "rotation": Vector3.ZERO, "component_data": {}
	}
	if not parent_id.is_empty():
		_entity_registry[instance_id]["component_data"]["ParentContextComponent"] = {"parent_id": parent_id}
	EventSystem.emit_event("entity_record_created", {"instance_id": instance_id})
	stage_entity(instance_id)
	return instance_id

func stage_entity(instance_id: String) -> void:
	if not _entity_registry.has(instance_id) or is_instance_valid(get_node_from_instance_id(instance_id)): return
	var entity_data = _entity_registry[instance_id]
	var definition = EntityFactory.get_entity_definition(entity_data.definition_id)
	if not definition: return
	var root_node = ClassDB.instantiate(definition.get("base_node_type", "Node3D"))
	if not is_instance_valid(root_node): return
	
	root_node.name = instance_id
	if root_node is Node3D:
		root_node.position = entity_data.position
		if entity_data.has("rotation"): root_node.rotation_degrees = entity_data.rotation
		if definition.has("scale"): root_node.scale = Vector3(definition.scale.x, definition.scale.y, definition.scale.z)
	
	var logic_node = EntityFactory.create_entity_logic_node(root_node, entity_data.definition_id, entity_data.get("component_data", {}))
	if not logic_node: root_node.queue_free(); return
	
	var components_def = definition.get("components", {})
	if components_def.has("VisualComponent") and root_node is CollisionObject3D:
		_add_collision_shape_to_entity(root_node, components_def.VisualComponent)

	_node_to_instance_id_map[root_node] = instance_id
	if logic_node.has_component("ScheduleComponent"): root_node.add_to_group("has_schedule")
	get_tree().current_scene.add_child(root_node)
	EventSystem.emit_event("entity_staged", {"instance_id": instance_id, "node": root_node})
	
	if definition.has("child_entities"):
		for child_data in definition.child_entities:
			var child_rel_pos = Vector3(child_data.get("position",{}).get("x",0), child_data.get("position",{}).get("y",0), child_data.get("position",{}).get("z",0))
			if root_node is Node3D:
				request_new_entity(child_data.definition_id, root_node.global_transform * child_rel_pos, child_data.get("name_override", ""), instance_id)

func unstage_entity(instance_id: String) -> void:
	var entity_node = get_node_from_instance_id(instance_id)
	if not is_instance_valid(entity_node): return
	if entity_node.is_in_group("has_schedule"):
		entity_node.remove_from_group("has_schedule")
	var entity_data = _entity_registry[instance_id]
	if entity_node is Node3D:
		entity_data.position = entity_node.position
		entity_data.rotation = entity_node.rotation_degrees
	var new_component_data = {}
	var logic_node = entity_node.get_node_or_null("EntityLogic")
	if logic_node:
		for component in logic_node.get_children():
			if component.has_method("get_persistent_data"):
				var persistent_data = component.get_persistent_data()
				if persistent_data and not persistent_data.is_empty():
					new_component_data[component.name] = persistent_data
	entity_data.component_data = new_component_data
	_node_to_instance_id_map.erase(entity_node)
	entity_node.queue_free()
	EventSystem.emit_event("entity_unstaged", {"instance_id": instance_id})

func destroy_entity_permanently(instance_id: String) -> void:
	if not _entity_registry.has(instance_id): return
	unstage_entity(instance_id)
	if _entity_registry.has(instance_id):
		_entity_registry.erase(instance_id)
	EventSystem.emit_event("entity_destroyed", {"instance_id": instance_id})

func destroy_all_with_tag(tag_id: String) -> void:
	var nodes_to_destroy = []
	for node in _node_to_instance_id_map.keys():
		if not is_instance_valid(node): continue
		var logic_node = node.get_node_or_null("EntityLogic")
		if logic_node:
			var tag_comp = logic_node.get_component("TagComponent")
			if tag_comp and tag_comp.has_tag(tag_id):
				nodes_to_destroy.append(node.name)
	for id_to_destroy in nodes_to_destroy:
		destroy_entity_permanently(id_to_destroy)

func add_tag_to_entity(instance_id: String, tag_id: String) -> void:
	var component = get_entity_component(instance_id, "TagComponent")
	if component: component.add_tag(tag_id)

func set_entity_state(instance_id: String, state_id: String) -> void:
	var component = get_entity_component(instance_id, "StateComponent")
	if component: component.push_state(state_id)

func get_entity_component(instance_id: String, component_name: String) -> Node:
	var node = get_node_from_instance_id(instance_id)
	if is_instance_valid(node):
		var logic_node = node.get_node_or_null("EntityLogic")
		if is_instance_valid(logic_node): return logic_node.get_component(component_name)
	return null

func get_node_from_instance_id(instance_id: String) -> Node:
	for node in _node_to_instance_id_map:
		if _node_to_instance_id_map.get(node) == instance_id: return node
	return null

func _get_next_uid() -> int: _next_uid += 1; return _next_uid

func _add_collision_shape_to_entity(physics_body, visual_data) -> void:
	var shape_type = visual_data.get("shape", "").to_lower()
	if shape_type.is_empty(): return
	var collision_shape_node = CollisionShape3D.new()
	var shape_resource: Shape3D
	match shape_type:
		"box":
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(visual_data.get("size",{}).get("x",1.0), visual_data.get("size",{}).get("y",1.0), visual_data.get("size",{}).get("z",1.0))
			shape_resource = box_shape
		"sphere":
			var sphere_shape = SphereShape3D.new(); sphere_shape.radius = visual_data.get("radius", 0.5); shape_resource = sphere_shape
		"cylinder":
			var cylinder_shape = CylinderShape3D.new(); cylinder_shape.height = visual_data.get("height", 2.0); cylinder_shape.radius = visual_data.get("radius", 0.5); shape_resource = cylinder_shape
		"capsule":
			var capsule_shape = CapsuleShape3D.new(); capsule_shape.height = visual_data.get("height", 2.0); capsule_shape.radius = visual_data.get("radius", 0.5); shape_resource = capsule_shape
		_:
			collision_shape_node.queue_free(); return
	collision_shape_node.shape = shape_resource
	physics_body.add_child(collision_shape_node)
