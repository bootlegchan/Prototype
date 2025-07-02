class_name BaseComponent
extends Node

var _entity_name: String = "Unnamed"
var _entity_logic_node: Node = null
var _entity_root: Node3D = null # This will hold the reference to the main 3D node.

# --- THIS IS THE FIX ---
# The initialize function now takes the entity's root node directly.
func initialize(data: Dictionary, entity_root: Node3D, entity_logic_node: Node) -> void:
	self._entity_root = entity_root
	self._entity_logic_node = entity_logic_node
	if is_instance_valid(entity_root):
		_entity_name = entity_root.name
# --- END OF FIX ---
	
	_load_data(data)
	_post_initialize()


## This is a "virtual" function intended to be overridden by child components.
func _load_data(data: Dictionary) -> void:
	pass


## This is a "virtual" function intended to be overridden by child components.
func _post_initialize() -> void:
	pass


## This is a "virtual" function for persistence.
func get_persistent_data() -> Dictionary:
	return {}


## A helper function that child components can use to easily find their siblings.
func get_sibling_component(component_name: String) -> BaseComponent:
	if is_instance_valid(_entity_logic_node):
		return _entity_logic_node.get_component(component_name)
	return null
