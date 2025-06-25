extends Node

var _schedules: Dictionary = {}

func _ready() -> void:
	_schedules.clear()
	_load_all_schedules(Config.SCHEDULES_DEFINITION_PATH)
	print("Loaded %s schedule definitions." % _schedules.size())
	
	if get_node_or_null("/root/TimeSystem"):
		TimeSystem.time_updated.connect(_on_time_updated)
	else:
		call_deferred("connect_to_time_system")
	print("SchedulingSystem ready.")

func connect_to_time_system() -> void:
	if TimeSystem and not TimeSystem.time_updated.is_connected(_on_time_updated):
		TimeSystem.time_updated.connect(_on_time_updated)

func _load_all_schedules(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue
		var full_path = "%s/%s" % [path.trim_suffix("/"), item_name]
		if dir.current_is_dir():
			_load_all_schedules(full_path)
		elif item_name.ends_with(".json"):
			var relative_path = full_path.replace(Config.SCHEDULES_DEFINITION_PATH, "")
			var definition_id = relative_path.trim_prefix("/").trim_suffix(".json")
			var file = FileAccess.open(full_path, FileAccess.READ)
			var json_data = JSON.parse_string(file.get_as_text())
			_schedules[definition_id] = json_data
		item_name = dir.get_next()

func _on_time_updated(date_info: Dictionary) -> void:
	var entities = get_tree().get_nodes_in_group("has_schedule")
	for entity in entities:
		if not is_instance_valid(entity):
			continue
		
		var logic_node = entity.get_node("EntityLogic")
		if not is_instance_valid(logic_node):
			continue
			
		var schedule_comp = logic_node.get_component("ScheduleComponent")
		if not schedule_comp:
			continue
			
		var potential_activities = _get_potential_activities(schedule_comp.schedule_layer_ids, date_info)
		if potential_activities.is_empty():
			continue
			
		var final_activity_id = ConflictResolutionSystem.resolve(potential_activities)
		
		var state_comp = logic_node.get_component("StateComponent")
		if state_comp and final_activity_id != "" and state_comp.get_current_state_id() != final_activity_id:
			state_comp.push_state(final_activity_id)
			var time_str = "%02d:%02d" % [date_info.hour, date_info.minute]
			print("[SCHEDULER] '%s' has resolved schedule. New activity: '%s' at %s on %s" % [entity.name, final_activity_id, time_str, date_info.day_of_week_name])


func _get_potential_activities(layer_ids: Array[String], date_info: Dictionary) -> Array[Dictionary]:
	var activities: Array[Dictionary] = []
	var time_key = "%02d:%02d" % [date_info.hour, date_info.minute]
	
	for layer_id in layer_ids:
		var schedule_data = _schedules.get(layer_id)
		if not schedule_data:
			continue

		# Check specific one-off events
		for event in schedule_data.get("specific_events", []):
			if event.get("day") == date_info.day and event.get("month") == date_info.month_name and event.get("time") == time_key:
				activities.append({"activity_id": event["activity"], "priority": schedule_data.get("priority", 0)})
		
		# Then check the weekly schedule
		var weekly_schedule = schedule_data.get("weekly_schedule", {})
		var day_name = date_info.day_of_week_name.to_lower()
		if weekly_schedule.has(day_name) and weekly_schedule[day_name].has(time_key):
			activities.append({"activity_id": weekly_schedule[day_name][time_key], "priority": schedule_data.get("priority", 0)})
			 
	return activities
