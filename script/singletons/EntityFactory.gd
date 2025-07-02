extends Node

var _entity_definitions: Dictionary = {}
var _component_map: Dictionary = {}

func _ready() -> void:
	print("EntityFactory: _ready called. Loading definitions.")
	_entity_definitions.clear()
	_component_map.clear()
	_recursive_load_definitions(Config.ENTITY_DEFINITION_PATH)
	print("Loaded %s entity definitions." % _entity_definitions.size())
	_register_all_components(Config.COMPONENT_PATH)
	print("Registered %s components: " % _component_map.size(), _component_map.keys())

func get_entity_definition(definition_id: String):
	return _entity_definitions.get(definition_id, null)

func create_entity_logic_node(root_node: Node, definition_id: String, saved_component_data: Dictionary = {}) -> Node:
	print("EntityFactory: create_entity_logic_node called for definition '%s'." % definition_id)
	var definition: Dictionary = get_entity_definition(definition_id)
	if not definition:
		printerr("EntityFactory: Definition '%s' not found." % definition_id)
		return null

	var base_entity_script = load("res://script/entities/BaseEntity.gd")
	if not base_entity_script:
		printerr("EntityFactory: Failed to load BaseEntity script.")
		return null

	var entity_logic_node = base_entity_script.new()
	entity_logic_node.name = "EntityLogic"
	root_node.add_child(entity_logic_node)
	print("EntityFactory: Created and added EntityLogic node.")

	var components_from_def = definition.get("components", {})
	var all_component_names = components_from_def.keys() + saved_component_data.keys()
	var unique_component_names = []
	for comp_name in all_component_names:
		if not unique_component_names.has(comp_name):
			unique_component_names.append(comp_name)

	print("EntityFactory: Found %d components to add: %s" % [unique_component_names.size(), unique_component_names])

	for component_name in unique_component_names:
		if not _component_map.has(component_name):
			printerr("EntityFactory: Component script '%s' is not registered." % component_name)
			continue
		var component_node = Node.new()
		component_node.name = component_name
		component_node.set_script(_component_map[component_name])
		entity_logic_node.add_component(component_name, component_node)
		print("EntityFactory: Added component '%s' to EntityLogic node." % component_name)

	print("EntityFactory: Initializing components.")
	for component_node in entity_logic_node.get_children():
		var component_name = component_node.name
		var initial_data = components_from_def.get(component_name, {}).duplicate()
		if saved_component_data.has(component_name):
			initial_data["saved_data"] = saved_component_data[component_name]

		if is_instance_valid(component_node) and component_node.has_method("initialize"):
			print("EntityFactory: Calling initialize on component '%s'." % component_name)
			Callable(component_node, "initialize").callv([initial_data, root_node, entity_logic_node])
		elif is_instance_valid(component_node):
			push_warning("EntityFactory: Component '%s' does not have an 'initialize' method." % component_name)
		else:
			printerr("EntityFactory: Invalid component node '%s' found after adding." % component_name)

	print("Successfully created entity logic node and components for definition '%s'." % definition_id)
	return entity_logic_node

func _recursive_load_definitions(path: String) -> void:
	print("EntityFactory: _recursive_load_definitions called for path '%s'." % path)
	var dir = DirAccess.open(path)
	if not dir:
		printerr("EntityFactory: Could not open entity definitions directory: ", path)
		return
	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue
		var full_path = path.path_join(item_name)
		if dir.current_is_dir():
			_recursive_load_definitions(full_path)
		elif item_name.ends_with(".json"):
			var relative_path = full_path.replace(Config.ENTITY_DEFINITION_PATH, "").lstrip("/")
			var definition_id = relative_path.trim_suffix(".json")

			print("EntityFactory: Attempting to load entity definition: %s from %s" % [definition_id, full_path])

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_entity_definitions[definition_id] = data
						print("EntityFactory: Successfully loaded entity definition: %s" % definition_id)
					else:
						printerr("EntityFactory: Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("EntityFactory: Failed to parse JSON for entity '%s'. Error at line %d: %s" % [full_path, json.get_error_line(), json.get_error_message()])

		item_name = dir.get_next()
	dir.list_dir_end()

func _register_all_components(path: String) -> void:
	print("EntityFactory: _register_all_components called for path '%s'." % path)
	var dir = DirAccess.open(path)
	if not dir:
		printerr("EntityFactory: Could not open components directory: ", path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			var full_path = path.path_join(file_name)
			var script: GDScript = load(full_path)
			if script:
				var component_name = file_name.get_basename()
				_component_map[component_name] = script
				print("EntityFactory: Registered component: %s" % component_name)
			else:
				printerr("EntityFactory: Failed to load script for component '%s' at %s." % [file_name.get_basename(), full_path])
		file_name = dir.get_next()
	dir.list_dir_end()
