extends Node

const DEFINITION_PATH = "res://data/definitions/entities/"
const COMPONENT_PATH = "res://components/"

var _entity_definitions: Dictionary = {}
var _component_map: Dictionary = {}

func _ready() -> void:
	_entity_definitions.clear()
	_component_map.clear()
	
	_recursive_load_definitions(DEFINITION_PATH)
	print("Loaded %s entity definitions." % _entity_definitions.size())
	
	_register_all_components()


func spawn_entity(definition_id: String, position: Vector3 = Vector3.ZERO) -> Node:
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
	
	physics_body.name = definition.get("name", "UnnamedEntity")
	physics_body.position = position
	
	var scale_vector = Vector3.ONE
	if definition.has("scale"):
		var scale_data: Dictionary = definition["scale"]
		scale_vector = Vector3(scale_data.get("x", 1.0), scale_data.get("y", 1.0), scale_data.get("z", 1.0))
	physics_body.scale = scale_vector

	var entity_logic_node = BaseEntity.new()
	entity_logic_node.name = "EntityLogic"
	physics_body.add_child(entity_logic_node)

	if definition.has("components") and definition["components"].has("VisualComponent"):
		var visual_data = definition["components"]["VisualComponent"]
		var shape_type_str = visual_data.get("shape", "box")
		_add_collision_shape_to_entity(physics_body, shape_type_str)

	if definition.has("components"):
		var components_to_add: Dictionary = definition["components"]
		
		for component_name in components_to_add:
			if not _component_map.has(component_name):
				printerr("Component '%s' is not registered." % component_name)
				continue
			var component_node = Node.new()
			component_node.name = component_name
			component_node.set_script(_component_map[component_name])
			entity_logic_node.add_component(component_name, component_node)

		for component_name in components_to_add:
			var component_node = entity_logic_node.get_component(component_name)
			if component_node and component_node.has_method("initialize"):
				_initialize_component(component_node, component_name, definition)

	get_tree().current_scene.add_child(physics_body)
	
	print("Successfully spawned entity '%s' (ID: %s) of type '%s'." % [physics_body.name, definition_id, base_node_type])
	return physics_body


# --- Private Helper Functions ---
func _initialize_component(component_node: Node, component_name: String, entity_definition: Dictionary) -> void:
	var entity_name = entity_definition.get("name", "UnnamedEntity")
	var data_for_init
	
	match component_name:
		"StateComponent", "ScheduleComponent", "InventoryComponent":
			var component_data = entity_definition["components"].get(component_name, {})
			data_for_init = [entity_name, component_data]
		
		"TagComponent":
			var resolved_tags: Dictionary = {}
			var tag_comp_data = entity_definition["components"].get(component_name, {})
			var tags_to_resolve = tag_comp_data.get("tags", [])
			for tag_id in tags_to_resolve:
				if TagRegistry.is_tag_defined(tag_id):
					resolved_tags[tag_id] = TagRegistry.get_tag_definition(tag_id)
				else:
					push_warning("Undefined tag '%s' for entity '%s'." % [tag_id, entity_name])
			data_for_init = [resolved_tags]
		
		_:
			var component_data = entity_definition["components"].get(component_name, {})
			data_for_init = [component_data]
	
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
			var relative_path = full_path.replace(DEFINITION_PATH, "")
			var definition_id = relative_path.trim_suffix(".json")
			var file = FileAccess.open(full_path, FileAccess.READ)
			var json_data = JSON.parse_string(file.get_as_text())
			_entity_definitions[definition_id] = json_data
		item_name = dir.get_next()

func _register_all_components() -> void:
	var dir = DirAccess.open(COMPONENT_PATH)
	if not dir:
		printerr("Components directory not found: ", COMPONENT_PATH)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			var script: GDScript = load(COMPONENT_PATH + file_name)
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
