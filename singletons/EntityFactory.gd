extends Node

const DEFINITION_PATH = "res://data/definitions/entities/"
const COMPONENT_PATH = "res://components/"

var _entity_definitions: Dictionary = {}
var _component_map: Dictionary = {}


func _ready() -> void:
	_load_all_definitions()
	_register_all_components()


func _load_all_definitions() -> void:
	var dir = DirAccess.open(DEFINITION_PATH)
	if not dir:
		printerr("Entity definitions directory not found: ", DEFINITION_PATH)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var definition_id = file_name.get_basename()
			var file = FileAccess.open(DEFINITION_PATH + file_name, FileAccess.READ)
			var json_data = JSON.parse_string(file.get_as_text())
			_entity_definitions[definition_id] = json_data
		file_name = dir.get_next()
	print("Loaded %s entity definitions." % _entity_definitions.size())


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
			# Use the script's class_name as the official component name
			var component_name = script.get_instance_base_type()
			if not component_name.is_empty():
				_component_map[component_name] = script
		file_name = dir.get_next()
	print("Registered %s components." % _component_map.size())


func spawn_entity(definition_id: String, position: Vector3 = Vector3.ZERO) -> BaseEntity:
	if not _entity_definitions.has(definition_id):
		printerr("Entity definition not found: ", definition_id)
		return null

	var definition: Dictionary = _entity_definitions[definition_id]
	
	# 1. Create the BaseEntity node from code
	var entity = BaseEntity.new()
	entity.name = definition.get("name", "UnnamedEntity")
	entity.position = position

	# 2. Add components defined in the JSON
	if definition.has("components"):
		var components_data: Dictionary = definition["components"]
		for component_name in components_data:
			_add_component_to_entity(entity, component_name, components_data[component_name])

	# 3. Add the fully constructed entity to the scene tree
	get_tree().current_scene.add_child(entity)
	
	print("Successfully spawned entity '%s' at %s." % [entity.name, entity.position])
	return entity


func _add_component_to_entity(entity: BaseEntity, component_name: String, data: Dictionary) -> void:
	if not _component_map.has(component_name):
		printerr("Component '%s' is not registered. Check component script and class_name." % component_name)
		return

	# 1. Create a generic Node to hold the component script
	var component_node = Node.new()
	component_node.name = component_name
	
	# 2. Attach the registered component script
	var component_script: GDScript = _component_map[component_name]
	component_node.set_script(component_script)
	
	# 3. Call the component's initialize function with its data
	if component_node.has_method("initialize"):
		component_node.initialize(data)
	
	# 4. Add the component to the entity
	entity.add_component(component_node)
