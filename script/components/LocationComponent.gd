# script/components/LocationComponent.gd
class_name LocationComponent
extends BaseComponent

# Defines the functional role of a location entity.
var location_type: String = "generic"
var location_name: String = "Unnamed Location"

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("LocationComponent on '%s': _load_data called with data: %s" % [_entity_name, data])
	# --- END DEBUG PRINT ---
	location_type = data.get("type", "generic")
	location_name = data.get("name", "Unnamed Location")

# This function is called after all components are loaded.
func _post_initialize() -> void:
	# --- DEBUG PRINT ---
	print("LocationComponent on '%s': _post_initialize called." % _entity_name)
	# --- END DEBUG PRINT ---
	pass
