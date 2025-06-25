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
	
	# It loads whatever data it's given from the JSON definition.
	# If "layers" exists, it's a character schedule.
	# If "weekly_schedule" or "specific_events" exists, it's a direct/location schedule.
	schedule_layer_ids = data.get("layers", [])
	weekly_schedule = data.get("weekly_schedule", {})
	specific_events = data.get("specific_events", [])
	priority = data.get("priority", 0)

	# All scheduled entities go into one group for the system to find.
	get_parent().get_parent().add_to_group("has_schedule")
	print("ScheduleComponent on '%s' initialized." % _entity_name)
