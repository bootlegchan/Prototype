extends Node

var _entity_definitions: Dictionary = {}
var _component_map: Dictionary = {}


func _ready() -> void:
	_entity_definitions.clear()
	_component_map.clear()
	_recursive_load_definitions(Config.ENTITY_DEFINITION_PATH)
	print("Loaded %s entity definitions." % _entity_definitions.size())
	_register_all_components(Config.COMPONENT_PATH)


func create_entity_node(definition_id: String, position: Vector3, saved_component_data: Dictionary = {}) -> Node:
	if not _entity_definitions.has(definition_id):
		printerr("Entity definition not found: '", definition_id, "'")
		return null

	var definition: Dictionary = _entity_definitions[definition_id]
	var base_node_type = definition.get("base_node_type", "Node3D")
	var physics_body = ClassDB.instantiate(base_node_type)
	if not physics_body is Node3D:
		printerr("Failed to instantiate a valid Node3D for definition: '", definition_id, "'")
		if is_instance_valid(physics_body): physics_body.free()
		return null
	
	physics_body.position = position
	var scale_vector = Vector3.ONE
	if definition.has("scale"):
		var scale_data = definition["scale"]
		scale_vector = Vector3(scale_data.get("x", 1.0), scale_data.get("y", 1.0), scale_data.get("z", 1.0))
	physics_body.scale = scale_vector

	var entity_logic_node = BaseEntity.new()
	entity_logic_node.name = "EntityLogic"
	physics_body.add_child(entity_logic_node)

	var components_from_def = definition.get("components", {})
	
	if components_from_def.has("VisualComponent"):
		var visual_data = components_from_def["VisualComponent"]
		_add_collision_shape_to_entity(physics_body, visual_data.get("shape", "box"))

	var all_component_names = components_from_def.keys() + saved_component_data.keys()
	var unique_component_names = []
	for comp_name in all_component_names:
		if not comp_name in unique_component_names:
			unique_component_names.append(comp_name)
	
	if not unique_component_names.is_empty():
		for component_name in unique_component_names:
			if not _component_map.has(component_name):
				printerr("Component '%s' is not registered." % component_name)
				continue
			var component_node = Node.new()
			component_node.name = component_name
			component_node.set_script(_component_map[component_name])
			entity_logic_node.add_component(component_name, component_node)
		
		for component_name in unique_component_names:
			var component_node = entity_logic_node.get_component(component_name)
			if component_node and component_node.has_method("initialize"):
				var entity_name = definition.get("name", "UnnamedEntity")
				var initial_data = components_from_def.get(component_name, {}).duplicate()
				
				if saved_component_data.has(component_name):
					initial_data["saved_data"] = saved_component_data[component_name]
				
				_initialize_component(component_node, component_name, initial_data, entity_name)

	print("Entity node created for definition '%s'." % definition_id)
	return physics_body
	

func create_and_initialize_component(component_name: String, initial_data: Dictionary, entity_name: String) -> Node:
	if not _component_map.has(component_name):
		printerr("Component '%s' is not registered." % component_name)
		return null
		
	var component_node = Node.new()
	component_node.name = component_name
	component_node.set_script(_component_map[component_name])
	
	_initialize_component(component_node, component_name, initial_data.duplicate(), entity_name)
	return component_node


func _initialize_component(component_node: Node, component_name: String, initial_data: Dictionary, entity_name: String) -> void:
	var data_for_init
	
	match component_name:
		"StateComponent", "ScheduleComponent", "InventoryComponent", "LocationComponent":
			data_for_init = [entity_name, initial_data]
		
		"ParentContextComponent":
			# --- THIS IS THE FIX ---
			# This component only ever takes its own direct data block, whether it's
			# fresh or being re-hydrated. It doesn't need the entity name.
			# We check for saved_data and pass the inner dictionary if it exists.
			if initial_data.has("saved_data"):
				data_for_init = [initial_data["saved_data"]]
			else:
				data_for_init = [initial_data]

		"TagComponent":
			if initial_data.has("saved_data"):
				data_for_init = [initial_data]
			else:
				var resolved_tags: Dictionary = {}
				var tags_to_resolve = initial_data.get("tags", [])
				for tag_id in tags_to_resolve:
					if TagRegistry.is_tag_defined(tag_id):
						resolved_tags[tag_id] = TagRegistry.get_tag_definition(tag_id)
					else:
						push_warning("Undefined tag '%s' for entity '%s'." % [tag_id, entity_name])
				data_for_init = [resolved_tags]
		
		_: # Default handler for ItemComponent, VisualComponent, etc.
			data_for_init = [initial_data]
	
	Callable(component_node, "initialize").callv(data_for_init)


func _recursive_load_definitions(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		printerr("Could not open definitions directory: ", path)
		return
	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue
		var full_path = "%s/%s" % [path.trim_suffix("/"), item_name]
		if dir.current_is_dir():
			_recursive_load_definitions(full_path)
		elif item_name.ends_with(".json"):
			var relative_path = full_path.replace(Config.ENTITY_DEFINITION_PATH, "")
			var definition_id = relative_path.trim_prefix("/").trim_suffix(".json")
			var file = FileAccess.open(full_path, FileAccess.READ)
			var json_data = JSON.parse_string(file.get_as_text())
			_entity_definitions[definition_id] = json_data
		item_name = dir.get_next()


func _register_all_components(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		printerr("Components directory not found: ", path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			var script: GDScript = load(path + file_name)
			var component_name = file_name.get_basename()
			if not component_name.is_empty():
				_component_map[component_name] = script
		file_name = dir.get_next()
	print("Registered %s components: " % _component_map.size(), _component_map.keys())


func _add_collision_shape_to_entity(physics_body: Node3D, shape_type: String) -> void:
	var collision_shape_node = CollisionShape3D.new()
	var shape_resource: Shape3D
	match shape_type.to_lower():
		"box":
			shape_resource = BoxShape3D.new()
		"sphere":
			shape_resource = SphereShape3D.new()
		"cylinder":
			shape_resource = CylinderShape3D.new()
		"capsule":
			shape_resource = CapsuleShape3D.new()
		_:
			printerr("Cannot create collision shape. Unknown shape type: ", shape_type)
			return
	collision_shape_node.shape = shape_resource
	physics_body.add_child(collision_shape_node)
