class_name BaseEntity
extends Node3D

# A dictionary to hold direct references to component nodes for fast access.
# Key: Component's class name (String), Value: Component node (Node).
var components: Dictionary = {}

# Called by the EntityFactory to attach a new component.
func add_component(component_node: Node) -> void:
	# Use the component script's class_name as the key.
	var component_name = component_node.get_script().get_instance_base_type()
	if not components.has(component_name):
		components[component_name] = component_node
		add_child(component_node)
	else:
		printerr("Entity '%s' already has a component of type '%s'." % [name, component_name])

# Public method to retrieve a component from this entity.
func get_component(component_name: String) -> Node:
	return components.get(component_name, null)

# Public method to check if a component exists.
func has_component(component_name: String) -> bool:
	return components.has(component_name)
