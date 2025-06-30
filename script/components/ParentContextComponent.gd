# script/components/ParentContextComponent.gd
class_name ParentContextComponent
extends BaseComponent

# Stores the unique instance ID of the parent entity.
var parent_instance_id: String = ""

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("ParentContextComponent on '%s': _load_data called with data: %s" % [_entity_name, data])
	# --- END DEBUG PRINT ---
	parent_instance_id = data.get("parent_id", "")
	# --- DEBUG PRINT ---
	print("ParentContextComponent on '%s': Parent instance ID set to '%s'." % [_entity_name, parent_instance_id])
	# --- END DEBUG PRINT ---


# This function is called after all components are loaded.
func _post_initialize() -> void:
	# --- DEBUG PRINT ---
	print("ParentContextComponent on '%s': _post_initialize called." % _entity_name)
	# --- END DEBUG PRINT ---
	pass
