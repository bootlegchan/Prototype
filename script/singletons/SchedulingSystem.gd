extends Node

var _schedule_layers: Dictionary = {}

func _ready() -> void:
	Debug.post("_ready called. Loading schedule layers.", "SchedulingSystem")
	_schedule_layers.clear()
	_load_all_schedule_layers(Config.SCHEDULES_DEFINITION_PATH)
	Debug.post("Loaded %s schedule layer definitions." % _schedule_layers.size(), "SchedulingSystem")

	Debug.post("Connecting to TimeSystem signal.", "SchedulingSystem")
	if get_node_or_null("/root/TimeSystem"):
		TimeSystem.time_updated.connect(_on_time_updated)
		Debug.post("Successfully connected to TimeSystem in _ready.", "SchedulingSystem")
	else:
		call_deferred("connect_to_time_system")
		Debug.post("TimeSystem not ready, deferred connection.", "SchedulingSystem")

	Debug.post("SchedulingSystem ready.", "SchedulingSystem")

func connect_to_time_system() -> void:
	Debug.post("connect_to_time_system (deferred) called.", "SchedulingSystem")
	if Engine.has_singleton("TimeSystem"):
		var time_system_node = Engine.get_singleton("TimeSystem") as Node
		if is_instance_valid(time_system_node) and not time_system_node.time_updated.is_connected(Callable(self, "_on_time_updated")):
			time_system_node.time_updated.connect(Callable(self, "_on_time_updated"))
			Debug.post("Successfully connected to TimeSystem via call_deferred.", "SchedulingSystem")
		elif !is_instance_valid(time_system_node):
			printerr("SchedulingSystem: TimeSystem singleton instance is invalid.")
		elif time_system_node.time_updated.is_connected(Callable(self, "_on_time_updated")):
			Debug.post("Already connected to TimeSystem.", "SchedulingSystem")
	else:
		printerr("SchedulingSystem: TimeSystem singleton not found even after deferring.")


func _load_all_schedule_layers(path: String) -> void:
	Debug.post("_load_all_schedule_layers called for path '%s'." % path, "SchedulingSystem")
	var dir = DirAccess.open(path)
	if not dir:
		printerr("SchedulingSystem: Could not open schedule definitions directory: %s" % path)
		return

	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name == "." or item_name == "..":
			item_name = dir.get_next()
			continue

		var full_path = path.path_join(item_name)
		if dir.current_is_dir():
			_load_all_schedule_layers(full_path)
		elif item_name.ends_with(".json"):
			var base_path = Config.SCHEDULES_DEFINITION_PATH
			if not base_path.ends_with("/"):
				base_path += "/"
			var relative_path = full_path.lstrip(base_path)
			var definition_id = relative_path.trim_suffix(".json")

			Debug.post("Attempting to load schedule layer definition: %s from %s." % [definition_id, full_path], "SchedulingSystem")

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_schedule_layers[definition_id] = data
						Debug.post("Successfully loaded schedule layer definition: %s" % definition_id, "SchedulingSystem")
					else:
						printerr("SchedulingSystem: Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("SchedulingSystem: Failed to parse JSON for schedule layer '%s'. Error at line %d: %s" % [full_path, json.get_error_message(), json.get_error_line()])

		item_name = dir.get_next()
	dir.list_dir_end()


func _on_time_updated(date_info: Dictionary) -> void:
	Debug.post("_on_time_updated called. Current time: %s" % date_info, "SchedulingSystem")
	var entities = get_tree().get_nodes_in_group("has_schedule")
	Debug.post("Found %d entities in 'has_schedule' group." % entities.size(), "SchedulingSystem")

	for entity in entities:
		if not is_instance_valid(entity): continue

		var logic_node = entity.get_node_or_null("EntityLogic")
		if not is_instance_valid(logic_node): continue

		var schedule_comp = logic_node.get_component("ScheduleComponent")
		if not is_instance_valid(schedule_comp):
			printerr("SchedulingSystem: Entity '%s' is missing a ScheduleComponent or it's invalid." % entity.name)
			continue


		var potential_activities = _get_potential_activities_for_entity(schedule_comp, date_info)
		Debug.post("Found %d potential activities for entity '%s'." % [potential_activities.size(), entity.name], "SchedulingSystem")
		if potential_activities.is_empty(): continue

		var final_activity_data = ConflictResolutionSystem.resolve(potential_activities)
		Debug.post("ConflictResolutionSystem resolved to activity: %s" % final_activity_data, "SchedulingSystem")
		if final_activity_data.is_empty(): continue

		_execute_activity(entity, final_activity_data)

func _get_potential_activities_for_entity(schedule_comp, date_info: Dictionary) -> Array[Dictionary]:
	Debug.post("_get_potential_activities_for_entity called for '%s' at time %s." % [schedule_comp._entity_name, date_info], "SchedulingSystem")
	var activities: Array[Dictionary] = []
	for layer_id in schedule_comp.schedule_layer_ids:
		var schedule_data = _schedule_layers.get(layer_id)
		if schedule_data:
			activities.append_array(_extract_activities_from_schedule_data(schedule_data, date_info))

	if not schedule_comp.weekly_schedule.is_empty() or not schedule_comp.specific_events.is_empty():
		var direct_schedule_data = {
			"weekly_schedule": schedule_comp.weekly_schedule,
			"specific_events": schedule_comp.specific_events,
			"priority": schedule_comp.priority
		}
		activities.append_array(_extract_activities_from_schedule_data(direct_schedule_data, date_info))
		
	return activities

func _extract_activities_from_schedule_data(schedule_data: Dictionary, date_info: Dictionary) -> Array[Dictionary]:
	Debug.post("_extract_activities_from_schedule_data called for time %s. Checking schedule data with keys: %s" % [date_info, schedule_data.keys()], "SchedulingSystem")
	var found: Array[Dictionary] = []
	var time_key = "%02d:%02d" % [date_info.hour, date_info.minute]
	var priority = schedule_data.get("priority", 0)

	Debug.post("Checking specific events for time_key '%s'." % time_key, "SchedulingSystem")
	for event in schedule_data.get("specific_events", []):
		if event.get("day") == date_info.day and event.get("month") == date_info.month_name and event.get("time") == time_key:
			var activity = event.get("activity", {}).duplicate()
			activity["priority"] = priority
			found.append(activity)
			Debug.post("Found specific event activity: %s" % activity, "SchedulingSystem")


	var weekly = schedule_data.get("weekly_schedule", {})
	var day_name = date_info.day_of_week_name.to_lower()
	Debug.post("Checking weekly schedule for day '%s' at time_key '%s'. Weekly keys: %s" % [day_name, time_key, weekly.keys()], "SchedulingSystem")
	if weekly.has(day_name) and weekly[day_name].has(time_key):
		var activity = weekly[day_name][time_key].duplicate()
		activity["priority"] = priority
		found.append(activity)
		Debug.post("Found weekly schedule activity: %s" % activity, "SchedulingSystem")


	return found

func _execute_activity(entity: Node, activity_data: Dictionary) -> void:
	Debug.post("_execute_activity called for entity '%s' with activity: %s" % [entity.name, activity_data], "SchedulingSystem")
	var state_to_enter = activity_data.get("state")
	if not state_to_enter:
		push_warning("SchedulingSystem: Activity data for '%s' is missing a 'state'." % entity.name)
		return

	var logic_node = entity.get_node("EntityLogic")
	var state_comp = logic_node.get_component("StateComponent")
	if not is_instance_valid(state_comp):
		printerr("SchedulingSystem: Scheduled entity '%s' is missing a StateComponent or it's invalid." % entity.name)
		return

	if state_comp.get_current_state_id() == state_to_enter:
		Debug.post("Entity '%s' is already in state '%s'. Skipping." % [entity.name, state_to_enter], "SchedulingSystem")
		return

	var state_def = StateRegistry.get_state_definition(state_to_enter)
	var required_tag = state_def.get("tag_to_apply_on_enter")

	var tag_comp = logic_node.get_component("TagComponent")
	if is_instance_valid(tag_comp) and required_tag and tag_comp.has_tag(required_tag):
		Debug.post("Entity '%s' already has required tag '%s' for state '%s'. Skipping." % [entity.name, required_tag, state_to_enter], "SchedulingSystem")
		return
	elif !is_instance_valid(tag_comp) and required_tag:
		push_warning("SchedulingSystem: Entity '%s' needs tag '%s' for state '%s' but has no TagComponent." % [entity.name, required_tag, state_to_enter])


	var context = activity_data.duplicate()
	context.erase("state")
	context.erase("priority")
	state_comp.push_state(state_to_enter, context)
	Debug.post("[SCHEDULER] Entity '%s' new activity: '%s'" % [entity.name, state_to_enter], "SchedulingSystem")

	if is_instance_valid(tag_comp) and required_tag:
		EntityManager.add_tag_to_entity(entity.name, required_tag)

	if state_def.has("on_enter_spawn"):
		var spawn_list_id = state_def["on_enter_spawn"]
		Debug.post("State change on '%s' is triggering spawn list: '%s'" % [entity.name, spawn_list_id], "SchedulingSystem")
		Debug.post("Calling SpawningSystem.execute_spawn_list for '%s' at position %s." % [spawn_list_id, entity.global_position], "SchedulingSystem")
		if entity is Node3D: SpawningSystem.execute_spawn_list(spawn_list_id, entity.global_position)
		elif entity is Node2D: SpawningSystem.execute_spawn_list(spawn_list_id, Vector3(entity.global_position.x, entity.global_position.y, 0))


	if state_def.has("on_enter_despawn_by_tag"):
		var tag_to_despawn = state_def["on_enter_despawn_by_tag"]
		Debug.post("State change on '%s' is triggering despawn for tag: '%s'" % [entity.name, tag_to_despawn], "SchedulingSystem")
		Debug.post("Calling EntityManager.destroy_all_with_tag for tag '%s'." % tag_to_despawn, "SchedulingSystem")
		EntityManager.destroy_all_with_tag(tag_to_despawn)
