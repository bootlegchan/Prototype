# script/components/ParentContextComponent.gd
class_name ParentContextComponent
extends BaseComponent

# Stores the unique instance ID of the parent entity.
var parent_instance_id: String = ""

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	parent_instance_id = data.get("parent_id", "")
