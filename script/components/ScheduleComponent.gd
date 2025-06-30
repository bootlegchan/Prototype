# script/components/ScheduleComponent.gd
class_name ScheduleComponent
extends BaseComponent

var schedule_layer_ids: Array[String] = []
var weekly_schedule: Dictionary = {}
var specific_events: Array = []
var priority: int = 0

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("ScheduleComponent on '%s': _load_data called with data: %s" % [_entity_name, data])
	# --- END DEBUG PRINT ---

	schedule_layer_ids.clear()
	var layers_from_data = data.get("layers", [])
	if layers_from_data is Array:
		for layer in layers_from_data:
			if layer is String:
				schedule_layer_ids.append(layer)
	# --- DEBUG PRINT ---
	print("ScheduleComponent on '%s': schedule_layer_ids loaded: %s" % [_entity_name, schedule_layer_ids])
	# --- END DEBUG PRINT ---


	weekly_schedule = data.get("weekly_schedule", {})
	# --- DEBUG PRINT ---
	print("ScheduleComponent on '%s': weekly_schedule loaded (keys): %s" % [_entity_name, weekly_schedule.keys()])
	# --- END DEBUG PRINT ---

	specific_events = data.get("specific_events", [])
	# --- DEBUG PRINT ---
	print("ScheduleComponent on '%s': specific_events loaded (count): %d" % [_entity_name, specific_events.size()])
	# --- END DEBUG PRINT ---

	priority = data.get("priority", 0)
	# --- DEBUG PRINT ---
	print("ScheduleComponent on '%s': priority loaded: %d" % [_entity_name, priority])
	# --- END DEBUG PRINT ---

	print("ScheduleComponent on '%s' _load_data finished." % _entity_name)


# This function is called after all components are loaded.
func _post_initialize() -> void:
	# --- DEBUG PRINT ---
	print("ScheduleComponent on '%s': _post_initialize called." % _entity_name)
	# --- END DEBUG PRINT ---
	pass
