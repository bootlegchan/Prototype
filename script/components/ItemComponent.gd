class_name ItemComponent
extends BaseComponent

var definition_id: String = ""
var display_name: String = "Unnamed Item"
var description: String = ""
var stackable: bool = false
var max_stack_size: int = 1
var quantity: int = 1

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# If loading from a save, the data will contain the saved state.
	# Otherwise, it's the component block from the entity definition.
	definition_id = data.get("definition_id", "")
	display_name = data.get("display_name", "Unnamed Item")
	description = data.get("description", "")
	stackable = data.get("stackable", false)
	max_stack_size = data.get("max_stack_size", 1)
	quantity = data.get("quantity", 1)

# We are replacing the parent's persistence function.
func get_persistent_data() -> Dictionary:
	return {
		"definition_id": definition_id,
		"quantity": quantity
		# Other properties like display_name are loaded from the definition, so no need to save.
	}
