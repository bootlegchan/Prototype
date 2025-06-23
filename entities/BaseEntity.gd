class_name BaseEntity
# We extend Node, which gives us access to `add_child` and other scene tree methods.
extends Node

# A dictionary to hold direct references to component nodes for fast access.
# Key: Component's name (String), Value: Component node (Node).
var components: Dictionary = {}


# The component_name is provided by the factory.
func add_component(component_name: String, component_node: Node) -> void:
	if not components.has(component_name):
		components[component_name] = component_node
		add_child(component_node)
	else:
		printerr("Entity '%s' already has a component of type '%s'." % [owner.name, component_name])


# Public method to retrieve a component from this entity.
func get_component(component_name: String) -> Node:
	return components.get(component_name, null)


# Public method to check if a component exists.
func has_component(component_name: String) -> bool:
	return components.has(component_name)
