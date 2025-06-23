class_name ItemComponent
extends Node

var display_name: String = "Unnamed Item"
var description: String = ""
var stackable: bool = false
var max_stack_size: int = 1
var quantity: int = 1

func initialize(data: Dictionary) -> void:
	display_name = data.get("display_name", "Unnamed Item")
	description = data.get("description", "")
	stackable = data.get("stackable", false)
	max_stack_size = data.get("max_stack_size", 1)
	quantity = data.get("quantity", 1)
