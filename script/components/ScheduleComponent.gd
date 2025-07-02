class_name ScheduleComponent
extends BaseComponent

var schedule_layer_ids: Array[String] = []
var weekly_schedule: Dictionary = {}
var specific_events: Array = []
var priority: int = 0

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# --- THIS IS THE FIX ---
	# The source name is now created once and reused, which is cleaner
	# and avoids any string formatting errors within function arguments.
	var source_name = "ScheduleComponent on '%s'" % _entity_name
	Debug.post("_load_data called with data: %s" % [data], source_name)

	schedule_layer_ids.clear()
	var layers_from_data = data.get("layers", [])
	if layers_from_data is Array:
		for layer in layers_from_data:
			if layer is String:
				schedule_layer_ids.append(layer)
	Debug.post("schedule_layer_ids loaded: %s" % [schedule_layer_ids], source_name)


	weekly_schedule = data.get("weekly_schedule", {})
	Debug.post("weekly_schedule loaded (keys): %s" % [weekly_schedule.keys()], source_name)

	specific_events = data.get("specific_events", [])
	Debug.post("specific_events loaded (count): %d" % specific_events.size(), source_name)

	priority = data.get("priority", 0)
	Debug.post("priority loaded: %d" % priority, source_name)

	Debug.post("_load_data finished.", source_name)
	# --- END OF FIX ---


# This function is called after all components are loaded.
func _post_initialize() -> void:
	var source_name = "ScheduleComponent on '%s'" % _entity_name
	Debug.post("_post_initialize called.", source_name)
	pass
