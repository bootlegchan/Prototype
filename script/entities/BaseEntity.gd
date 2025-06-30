# script/entities/BaseEntity.gd
class_name BaseEntity
extends Node

var components: Dictionary = {}

# This function now correctly handles replacing components.
func add_component(component_name: String, component_node: Node) -> void:
	# --- DEBUG PRINT ---
	print("BaseEntity on '%s': add_component called for '%s'." % [name, component_name])
	# --- END DEBUG PRINT ---
	# If a component of this type already exists, remove the old one first.
	if components.has(component_name):
		print("Replacing existing component: '%s'" % component_name)
		var old_component = components[component_name]
		remove_child(old_component)
		old_component.queue_free()

	components[component_name] = component_node
	add_child(component_node)
	# --- DEBUG PRINT ---
	print("BaseEntity on '%s': Component '%s' added as child." % [name, component_name])
	# --- END DEBUG PRINT ---


func get_component(component_name: String) -> Node:
	# --- DEBUG PRINT ---
	print("BaseEntity on '%s': get_component called for '%s'." % [name, component_name])
	# --- END DEBUG PRINT ---
	var component = components.get(component_name, null)
	# --- DEBUG PRINT ---
	print("BaseEntity on '%s': get_component for '%s' returned %s." % [name, component_name, is_instance_valid(component)])
	# --- END DEBUG PRINT ---
	return component


func has_component(component_name: String) -> bool:
	# --- DEBUG PRINT ---
	print("BaseEntity on '%s': has_component called for '%s'." % [name, component_name])
	# --- END DEBUG PRINT ---
	return components.has(component_name)
