# script/components/BaseComponent.gd
class_name BaseComponent
extends Node

var _entity_name: String = "Unnamed"
var _entity_logic_node: Node = null

## This is the standard initialization function for all components.
## It is called by the EntityFactory when an entity is created.
## It stores references to the entity's name and its logic node for later use.
func initialize(data: Dictionary, entity_logic_node: Node) -> void:
	_entity_logic_node = entity_logic_node
	if is_instance_valid(entity_logic_node) and is_instance_valid(entity_logic_node.get_parent()):
		_entity_name = entity_logic_node.get_parent().name
	
	# Call the specific setup logic for the child component.
	_load_data(data)


## This is a "virtual" function intended to be overridden by child components.
## Each component that needs to load data from its definition or a save file
## will implement its specific logic here.
func _load_data(data: Dictionary) -> void:
	# Base implementation does nothing.
	pass


## This is a "virtual" function for persistence.
## Any component that needs to save its state must override this method.
## By default, a component saves nothing.
func get_persistent_data() -> Dictionary:
	return {}


## A helper function that child components can use to easily find their siblings.
func get_sibling_component(component_name: String) -> BaseComponent:
	if is_instance_valid(_entity_logic_node):
		return _entity_logic_node.get_component(component_name)
	return null
