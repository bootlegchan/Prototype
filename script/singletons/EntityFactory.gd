# script/singletons/EntityFactory.gd
extends Node

var _entity_definitions: Dictionary = {}
var _component_map: Dictionary = {}

func _ready() -> void:
	_entity_definitions.clear()
	_component_map.clear()
	_recursive_load_definitions(Config.ENTITY_DEFINITION_PATH)
	_register_all_components(Config.COMPONENT_PATH)

func get_entity_definition(definition_id: String):
	return _entity_definitions.get(definition_id, null)

func create_entity_logic_node(root_node: Node, definition_id: String, saved_component_data: Dictionary = {}) -> Node:
	var definition: Dictionary = get_entity_definition(definition_id)
	if definition == null: return null

	var base_entity_script = load("res://script/entities/BaseEntity.gd")
	var entity_logic_node = base_entity_script.new()
	entity_logic_node.name = "EntityLogic"
	root_node.add_child(entity_logic_node)

	var components_from_def = definition.get("components", {})
	var all_component_names = components_from_def.keys() + saved_component_data.keys()
	var unique_component_names = []
	for comp_name in all_component_names:
		if not unique_component_names.has(comp_name):
			unique_component_names.append(comp_name)

	for component_name in unique_component_names:
		if not _component_map.has(component_name): continue
		var component_node = Node.new()
		component_node.name = component_name
		component_node.set_script(_component_map[component_name])
		entity_logic_node.add_component(component_name, component_node)

	for component_node in entity_logic_node.get_children():
		var component_name = component_node.name
		var initial_data = components_from_def.get(component_name, {}).duplicate()
		if saved_component_data.has(component_name):
			initial_data["saved_data"] = saved_component_data[component_name]

		if component_node.has_method("initialize"):
			Callable(component_node, "initialize").callv([initial_data, entity_logic_node])

	return entity_logic_node

func _recursive_load_definitions(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir: return
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
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var json = JSON.new()
				if json.parse(file.get_as_text()) == OK:
					_entity_definitions[definition_id] = json.get_data()
				file.close()
		item_name = dir.get_next()
	dir.list_dir_end()

func _register_all_components(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir: return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			var script: GDScript = load(path.path_join(file_name))
			if script: _component_map[file_name.get_basename()] = script
		file_name = dir.get_next()
