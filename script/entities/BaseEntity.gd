class_name BaseEntity
extends Node

var components: Dictionary = {}

# This function now correctly handles replacing components.
func add_component(component_name: String, component_node: Node) -> void:
	Debug.post("add_component called for '%s'." % component_name, "BaseEntity on '%s'" % name)
	# If a component of this type already exists, remove the old one first.
	if components.has(component_name):
		Debug.post("Replacing existing component: '%s'" % component_name, "BaseEntity on '%s'" % name)
		var old_component = components[component_name]
		remove_child(old_component)
		old_component.queue_free()

	components[component_name] = component_node
	add_child(component_node)
	Debug.post("Component '%s' added as child." % component_name, "BaseEntity on '%s'" % name)


func get_component(component_name: String) -> Node:
	Debug.post("get_component called for '%s'." % component_name, "BaseEntity on '%s'" % name)
	var component = components.get(component_name, null)
	Debug.post("get_component for '%s' returned %s." % [component_name, is_instance_valid(component)], "BaseEntity on '%s'" % name)
	return component


func has_component(component_name: String) -> bool:
	Debug.post("has_component called for '%s'." % component_name, "BaseEntity on '%s'" % name)
	return components.has(component_name)
