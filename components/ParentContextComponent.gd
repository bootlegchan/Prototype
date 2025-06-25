class_name ParentContextComponent
extends Node

# Stores the unique instance ID of the parent entity.
var parent_instance_id: String = ""

func initialize(data: Dictionary) -> void:
	parent_instance_id = data.get("parent_id", "")
