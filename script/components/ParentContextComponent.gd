class_name ParentContextComponent
extends BaseComponent

# Stores the unique instance ID of the parent entity.
var parent_instance_id: String = ""

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called with data: %s" % data, "ParentContextComponent on '%s'" % _entity_name)
	parent_instance_id = data.get("parent_id", "")
	Debug.post("Parent instance ID set to '%s'." % parent_instance_id, "ParentContextComponent on '%s'" % _entity_name)


# This function is called after all components are loaded.
func _post_initialize() -> void:
	Debug.post("_post_initialize called.", "ParentContextComponent on '%s'" % _entity_name)
	pass
