extends Node

const DEFINITION_PATH = "res://data/definitions/"
const COMPONENT_PATH = "res://components/"

var _entity_definitions: Dictionary = {}
var _component_map: Dictionary = {}


func _ready() -> void:
	# Clear any previous data and load everything fresh.
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
		var components_data: Dictionary = definition["components"]
		for component_name in components_data:
			_add_component_to_entity(entity_logic_node, component_name, components_data[component_name])

	get_tree().current_scene.add_child(physics_body)
	
	print("Successfully spawned entity '%s' (ID: %s) of type '%s'." % [physics_body.name, definition_id, base_node_type])
	return physics_body


# --- Private Helper Functions ---

# RECURSIVE LOADER - This function calls itself to scan subdirectories.
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
			# If it's a directory, call this function again on the new path.
			_recursive_load_definitions(full_path)
		elif item_name.ends_with(".json"):
			# It's a file, so load it.
			# Create the unique ID from the path relative to the base DEFINITION_PATH.
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


func _add_component_to_entity(entity_logic_node: BaseEntity, component_name: String, data: Dictionary) -> void:
	if not _component_map.has(component_name):
		printerr("Component '%s' is not registered. Check component script and file name." % component_name)
		return

	var component_node = Node.new()
	component_node.name = component_name
	
	var component_script: GDScript = _component_map[component_name]
	component_node.set_script(component_script)
	
	if component_node.has_method("initialize"):
		component_node.initialize(data)
	
	entity_logic_node.add_component(component_name, component_node)
