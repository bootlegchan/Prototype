class_name BaseEntity
extends Node3D

# A dictionary to hold direct references to component nodes for fast access.
# Key: Component's name (String), Value: Component node (Node).
var components: Dictionary = {}

# The factory now provides the component's name directly.
# This is the corrected function signature that accepts two arguments.
func add_component(component_name: String, component_node: Node) -> void:
	if not components.has(component_name):
		components[component_name] = component_node
		add_child(component_node)
	else:
		# This error message is now more useful as it will show the proper component name.
		printerr("Entity '%s' already has a component of type '%s'." % [name, component_name])

# Public method to retrieve a component from this entity.
func get_component(component_name: String) -> Node:
	return components.get(component_name, null)

# Public method to check if a component exists.
func has_component(component_name: String) -> bool:
	return components.has(component_name)
