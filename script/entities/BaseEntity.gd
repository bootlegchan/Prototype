class_name BaseEntity
extends Node

var components: Dictionary = {}

# This function now correctly handles replacing components.
func add_component(component_name: String, component_node: Node) -> void:
	# If a component of this type already exists, remove the old one first.
	if components.has(component_name):
		print("Replacing existing component: '%s'" % component_name)
		var old_component = components[component_name]
		remove_child(old_component)
		old_component.queue_free()

	components[component_name] = component_node
	add_child(component_node)


func get_component(component_name: String) -> Node:
	return components.get(component_name, null)


func has_component(component_name: String) -> bool:
	return components.has(component_name)
