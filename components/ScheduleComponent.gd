class_name ScheduleComponent
extends Node

# A simple list of schedule definition IDs that apply to this entity.
# Example: ["roles/student", "jobs/part_time_cleaner", "personal/alex"]
var schedule_layer_ids: Array[String] = []

func initialize(entity_name: String, data: Dictionary) -> void:
	# --- THIS IS THE FIX ---
	# Clear the array to ensure it's empty before populating.
	schedule_layer_ids.clear()
	
	var layers_from_json = data.get("layers", [])
	
	# Ensure the data from the JSON is actually an array before looping.
	if layers_from_json is Array:
		# Iterate through the generic array and add each string to our typed array.
		for layer_id in layers_from_json:
			if layer_id is String:
				schedule_layer_ids.append(layer_id)
			else:
				# Warn the designer if the data is malformed.
				push_warning("Non-string value '%s' found in schedule layers for entity '%s'." % [str(layer_id), entity_name])

	# Add this entity to a group so the SchedulingSystem can find it.
	get_parent().get_parent().add_to_group("has_schedule")
	
	print("ScheduleComponent on '%s' initialized with layers: %s" % [entity_name, str(schedule_layer_ids)])
