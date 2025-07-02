class_name LocationComponent
extends BaseComponent

# Defines the functional role of a location entity.
var location_type: String = "generic"
var location_name: String = "Unnamed Location"

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called with data: %s" % data, "LocationComponent on '%s'" % _entity_name)
	location_type = data.get("type", "generic")
	location_name = data.get("name", "Unnamed Location")

# This function is called after all components are loaded.
func _post_initialize() -> void:
	Debug.post("_post_initialize called.", "LocationComponent on '%s'" % _entity_name)
	pass
