# script/components/ScheduleComponent.gd
class_name ScheduleComponent
extends BaseComponent

var schedule_layer_ids: Array[String] = []
var weekly_schedule: Dictionary = {}
var specific_events: Array = []
var priority: int = 0

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# _entity_name is inherited from BaseComponent
	
	schedule_layer_ids.clear()
	var layers_from_data = data.get("layers", [])
	if layers_from_data is Array:
		for layer in layers_from_data:
			if layer is String:
				schedule_layer_ids.append(layer)

	weekly_schedule = data.get("weekly_schedule", {})
	specific_events = data.get("specific_events", [])
	priority = data.get("priority", 0)
	print("ScheduleComponent on '%s' initialized." % _entity_name)
