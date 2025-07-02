class_name BaseComponent
extends Node

var _entity_name: String = "Unnamed"
var _entity_logic_node: Node = null
var _entity_root: Node3D = null

func initialize(data: Dictionary, entity_root: Node3D, entity_logic_node: Node) -> void:
	self._entity_root = entity_root
	self._entity_logic_node = entity_logic_node
	if is_instance_valid(entity_root):
		_entity_name = entity_root.name
	
	_load_data(data)
	_post_initialize()


# --- THIS IS THE FIX ---
# The parameter is prefixed with an underscore to indicate it's intentionally unused here.
func _load_data(_data: Dictionary) -> void:
	pass
# --- END OF FIX ---


func _post_initialize() -> void:
	pass


func get_persistent_data() -> Dictionary:
	return {}


func get_sibling_component(component_name: String) -> BaseComponent:
	if is_instance_valid(_entity_logic_node):
		return _entity_logic_node.get_component(component_name)
	return null
