extends Node

var _schedule_layers: Dictionary = {}

func _ready() -> void:
	_schedule_layers.clear()
	_load_all_schedule_layers(Config.SCHEDULES_DEFINITION_PATH)
	print("Loaded %s schedule layer definitions." % _schedule_layers.size())
	if get_node_or_null("/root/TimeSystem"):
		TimeSystem.time_updated.connect(_on_time_updated)
	else:
		call_deferred("connect_to_time_system")
	print("SchedulingSystem ready.")

func connect_to_time_system() -> void:
	if TimeSystem and not TimeSystem.time_updated.is_connected(_on_time_updated):
		TimeSystem.time_updated.connect(_on_time_updated)

func _load_all_schedule_layers(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir: return
	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue
		var full_path = "%s/%s" % [path.trim_suffix("/"), item_name]
		if dir.current_is_dir():
			_load_all_schedule_layers(full_path)
		elif item_name.ends_with(".json"):
			var relative_path = full_path.replace(Config.SCHEDULES_DEFINITION_PATH, "")
			var definition_id = relative_path.trim_prefix("/").trim_suffix(".json")
			var file = FileAccess.open(full_path, FileAccess.READ)
			_schedule_layers[definition_id] = JSON.parse_string(file.get_as_text())
		item_name = dir.get_next()

func _on_time_updated(date_info: Dictionary) -> void:
	var entities = get_tree().get_nodes_in_group("has_schedule")
	for entity in entities:
		if not is_instance_valid(entity): continue
		var logic_node = entity.get_node("EntityLogic")
		if not is_instance_valid(logic_node): continue
		var schedule_comp = logic_node.get_component("ScheduleComponent")
		if not schedule_comp: continue
			
		var potential_activities = _get_potential_activities_for_entity(schedule_comp, date_info)
		if potential_activities.is_empty(): continue
			
		var final_activity_data = ConflictResolutionSystem.resolve(potential_activities)
		if final_activity_data.is_empty(): continue
			
		_execute_activity(entity, final_activity_data, date_info)

func _get_potential_activities_for_entity(schedule_comp: ScheduleComponent, date_info: Dictionary) -> Array[Dictionary]:
	var activities: Array[Dictionary] = []
	
	# Case 1: Character with layered schedules
	if not schedule_comp.schedule_layer_ids.is_empty():
		for layer_id in schedule_comp.schedule_layer_ids:
			var schedule_data = _schedule_layers.get(layer_id)
			if schedule_data:
				activities.append_array(_extract_activities_from_schedule_data(schedule_data, date_info))
	# Case 2: Location with a direct schedule
	elif not schedule_comp.weekly_schedule.is_empty() or not schedule_comp.specific_events.is_empty():
		activities.append_array(_extract_activities_from_schedule_data(schedule_comp, date_info))
	
	return activities

func _extract_activities_from_schedule_data(schedule_data, date_info: Dictionary) -> Array[Dictionary]:
	var found_activities: Array[Dictionary] = []
	var time_key = "%02d:%02d" % [date_info.hour, date_info.minute]
	var priority = schedule_data.get("priority", 0)
	
	for event in schedule_data.get("specific_events", []):
		if event.get("day") == date_info.day and event.get("month") == date_info.month_name and event.get("time") == time_key:
			var activity_data = event.get("activity", {}).duplicate(); activity_data["priority"] = priority
			found_activities.append(activity_data)
			
	var weekly_schedule = schedule_data.get("weekly_schedule", {})
	var day_name = date_info.day_of_week_name.to_lower()
	if weekly_schedule.has(day_name) and weekly_schedule[day_name].has(time_key):
		var activity_data = weekly_schedule[day_name][time_key].duplicate(); activity_data["priority"] = priority
		found_activities.append(activity_data)
		 
	return found_activities

func _execute_activity(entity: Node, activity_data: Dictionary, date_info: Dictionary) -> void:
	var state_to_enter = activity_data.get("state")
	if not state_to_enter: return

	var state_comp = entity.get_node("EntityLogic").get_component("StateComponent")
	# Character schedules change state.
	if state_comp and state_comp.get_current_state_id() != state_to_enter:
		var context = activity_data.duplicate(); context.erase("state"); context.erase("priority")
		state_comp.push_state(state_to_enter, context)
		print("[SCHEDULER] '%s' new activity: '%s'" % [entity.name, state_to_enter])

	# Location schedules can trigger spawns.
	var state_data = StateRegistry.get_state_definition(state_to_enter)
	if state_data.has("on_enter_spawn"):
		var spawn_list_id = state_data["on_enter_spawn"]
		print("Scheduled event on '%s' triggering spawn list: '%s'" % [entity.name, spawn_list_id])
		if entity is Node3D:
			SpawningSystem.execute_spawn_list(spawn_list_id, entity.global_position)
