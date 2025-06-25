class_name ScheduleComponent
extends Node

# This single component can hold either layered schedule IDs for characters,
# or direct schedule data for locations.
var schedule_layer_ids: Array[String] = []
var weekly_schedule: Dictionary = {}
var specific_events: Array = []
var priority: int = 0
var _entity_name: String = "Unnamed"


func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	
	# --- THIS IS THE FIX ---
	# We must manually iterate and append to the strongly-typed array.
	schedule_layer_ids.clear()
	var layers_from_json = data.get("layers", [])
	if layers_from_json is Array:
		for layer_id in layers_from_json:
			if layer_id is String:
				schedule_layer_ids.append(layer_id)
			else:
				push_warning("Non-string value '%s' found in schedule layers for entity '%s'." % [str(layer_id), _entity_name])

	# It loads whatever other data it's given from the JSON definition.
	weekly_schedule = data.get("weekly_schedule", {})
	specific_events = data.get("specific_events", [])
	priority = data.get("priority", 0)

	# All scheduled entities go into one group for the system to find.
	get_parent().get_parent().add_to_group("has_schedule")
	print("ScheduleComponent on '%s' initialized." % _entity_name)
