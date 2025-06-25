class_name ItemComponent
extends Node

var definition_id: String = "" # NEW: To remember what this item is.
var display_name: String = "Unnamed Item"
var description: String = ""
var stackable: bool = false
var max_stack_size: int = 1
var quantity: int = 1

func initialize(data: Dictionary) -> void:
	definition_id = data.get("definition_id", "")
	display_name = data.get("display_name", "Unnamed Item")
	description = data.get("description", "")
	stackable = data.get("stackable", false)
	max_stack_size = data.get("max_stack_size", 1)
	quantity = data.get("quantity", 1)

# NEW: We need to be able to save this component's state.
func get_persistent_data() -> Dictionary:
	return {
		"definition_id": definition_id,
		"quantity": quantity
		# Other properties like display_name are loaded from the definition, so no need to save.
	}
