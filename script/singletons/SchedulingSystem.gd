# script/singletons/SchedulingSystem.gd
extends Node

var _schedule_layers: Dictionary = {}

func _ready() -> void:
	# --- DEBUG PRINT ---
	print("SchedulingSystem: _ready called. Loading schedule layers.")
	# --- END DEBUG PRINT ---
	_schedule_layers.clear()
	_load_all_schedule_layers(Config.SCHEDULES_DEFINITION_PATH)
	print("Loaded %s schedule layer definitions." % _schedule_layers.size())

	# --- DEBUG PRINT ---
	print("SchedulingSystem: Connecting to TimeSystem signal.")
	# --- END DEBUG PRINT ---
	if get_node_or_null("/root/TimeSystem"):
		TimeSystem.time_updated.connect(_on_time_updated)
		# --- DEBUG PRINT ---
		print("SchedulingSystem: Successfully connected to TimeSystem in _ready.")
		# --- END DEBUG PRINT ---
	else:
		call_deferred("connect_to_time_system")
		# --- DEBUG PRINT ---
		print("SchedulingSystem: TimeSystem not ready, deferred connection.")
		# --- END DEBUG PRINT ---

	print("SchedulingSystem ready.")

func connect_to_time_system() -> void:
	# --- DEBUG PRINT ---
	print("SchedulingSystem: connect_to_time_system (deferred) called.")
	# --- END DEBUG PRINT ---
	if Engine.has_singleton("TimeSystem"):
		var time_system_node = Engine.get_singleton("TimeSystem") as Node
		if is_instance_valid(time_system_node) and not time_system_node.time_updated.is_connected(Callable(self, "_on_time_updated")):
			time_system_node.time_updated.connect(Callable(self, "_on_time_updated"))
			# --- DEBUG PRINT ---
			print("SchedulingSystem: Successfully connected to TimeSystem via call_deferred.")
			# --- END DEBUG PRINT ---
		elif !is_instance_valid(time_system_node):
			# --- DEBUG PRINT ---
			printerr("SchedulingSystem: TimeSystem singleton instance is invalid.")
			# --- END DEBUG PRINT ---
		elif time_system_node.time_updated.is_connected(Callable(self, "_on_time_updated")):
			# --- DEBUG PRINT ---
			print("SchedulingSystem: Already connected to TimeSystem.")
			# --- END DEBUG PRINT ---
	else:
		# --- DEBUG PRINT ---
		printerr("SchedulingSystem: TimeSystem singleton not found even after deferring.")
		# --- END DEBUG PRINT ---


func _load_all_schedule_layers(path: String) -> void:
	# --- DEBUG PRINT ---
	print("SchedulingSystem: _load_all_schedule_layers called for path '%s'." % path)
	# --- END DEBUG PRINT ---
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

			# --- DEBUG PRINT ---
			print("SchedulingSystem: Attempting to load schedule layer definition: %s from %s." % [definition_id, full_path])
			# --- END DEBUG PRINT ---

			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					if data is Dictionary:
						_schedule_layers[definition_id] = data
						# --- DEBUG PRINT ---
						print("SchedulingSystem: Successfully loaded schedule layer definition: %s" % definition_id)
						# --- END DEBUG PRINT ---
					else:
						printerr("SchedulingSystem: Parsed JSON for '%s' is not a Dictionary." % full_path)
				else:
					printerr("SchedulingSystem: Failed to parse JSON for schedule layer '%s'. Error at line %d: %s" % [full_path, json.get_error_message(), json.get_error_line()])

		item_name = dir.get_next()
	dir.list_dir_end()


func _on_time_updated(date_info: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("SchedulingSystem: _on_time_updated called. Current time: %s" % date_info)
	# --- END DEBUG PRINT ---
	var entities = get_tree().get_nodes_in_group("has_schedule")
	# --- DEBUG PRINT ---
	print("SchedulingSystem: Found %d entities in 'has_schedule' group." % entities.size())
	# --- END DEBUG PRINT ---

	for entity in entities:
		if not is_instance_valid(entity): continue

		var logic_node = entity.get_node_or_null("EntityLogic")
		if not is_instance_valid(logic_node): continue

		var schedule_comp = logic_node.get_component("ScheduleComponent")
		if not is_instance_valid(schedule_comp):
			# --- DEBUG PRINT ---
			printerr("SchedulingSystem: Entity '%s' is missing a ScheduleComponent or it's invalid." % entity.name)
			# --- END DEBUG PRINT ---
			continue


		var potential_activities = _get_potential_activities_for_entity(schedule_comp, date_info)
		# --- DEBUG PRINT ---
		print("SchedulingSystem: Found %d potential activities for entity '%s'." % [potential_activities.size(), entity.name])
		# --- END DEBUG PRINT ---
		if potential_activities.is_empty(): continue

		var final_activity_data = ConflictResolutionSystem.resolve(potential_activities)
		# --- DEBUG PRINT ---
		print("SchedulingSystem: ConflictResolutionSystem resolved to activity: %s" % final_activity_data)
		# --- END DEBUG PRINT ---
		if final_activity_data.is_empty(): continue

		_execute_activity(entity, final_activity_data)

func _get_potential_activities_for_entity(schedule_comp, date_info: Dictionary) -> Array[Dictionary]:
	# --- DEBUG PRINT ---
	print("SchedulingSystem: _get_potential_activities_for_entity called for '%s' at time %s." % [schedule_comp._entity_name, date_info])
	# --- END DEBUG PRINT ---
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
	# --- DEBUG PRINT ---
	print("SchedulingSystem: _extract_activities_from_schedule_data called for time %s. Checking schedule data with keys: %s" % [date_info, schedule_data.keys()])
	# --- END DEBUG PRINT ---
	var found: Array[Dictionary] = []
	var time_key = "%02d:%02d" % [date_info.hour, date_info.minute]
	var priority = schedule_data.get("priority", 0)

	# --- DEBUG PRINT ---
	print("SchedulingSystem: Checking specific events for time_key '%s'." % time_key)
	# --- END DEBUG PRINT ---
	for event in schedule_data.get("specific_events", []):
		if event.get("day") == date_info.day and event.get("month") == date_info.month_name and event.get("time") == time_key:
			var activity = event.get("activity", {}).duplicate()
			activity["priority"] = priority
			found.append(activity)
			# --- DEBUG PRINT ---
			print("SchedulingSystem: Found specific event activity: %s" % activity)
			# --- END DEBUG PRINT ---


	var weekly = schedule_data.get("weekly_schedule", {})
	var day_name = date_info.day_of_week_name.to_lower()
	# --- DEBUG PRINT ---
	print("SchedulingSystem: Checking weekly schedule for day '%s' at time_key '%s'. Weekly keys: %s" % [day_name, time_key, weekly.keys()])
	# --- END DEBUG PRINT ---
	if weekly.has(day_name) and weekly[day_name].has(time_key):
		var activity = weekly[day_name][time_key].duplicate()
		activity["priority"] = priority
		found.append(activity)
		# --- DEBUG PRINT ---
		print("SchedulingSystem: Found weekly schedule activity: %s" % activity)
		# --- END DEBUG PRINT ---


	return found

func _execute_activity(entity: Node, activity_data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("SchedulingSystem: _execute_activity called for entity '%s' with activity: %s" % [entity.name, activity_data])
	# --- END DEBUG PRINT ---
	var state_to_enter = activity_data.get("state")
	if not state_to_enter:
		# --- DEBUG PRINT ---
		push_warning("SchedulingSystem: Activity data for '%s' is missing a 'state'." % entity.name)
		# --- END DEBUG PRINT ---
		return

	var logic_node = entity.get_node("EntityLogic")
	var state_comp = logic_node.get_component("StateComponent")
	if not is_instance_valid(state_comp): # Added validity check
		# --- DEBUG PRINT ---
		printerr("SchedulingSystem: Scheduled entity '%s' is missing a StateComponent or it's invalid." % entity.name)
		# --- END DEBUG PRINT ---
		return

	if state_comp.get_current_state_id() == state_to_enter:
		# --- DEBUG PRINT ---
		print("SchedulingSystem: Entity '%s' is already in state '%s'. Skipping." % [entity.name, state_to_enter]) # Very verbose
		# --- END DEBUG PRINT ---
		return

	var state_def = StateRegistry.get_state_definition(state_to_enter)
	var required_tag = state_def.get("tag_to_apply_on_enter")

	var tag_comp = logic_node.get_component("TagComponent")
	if is_instance_valid(tag_comp) and required_tag and tag_comp.has_tag(required_tag):
		# --- DEBUG PRINT ---
		print("SchedulingSystem: Entity '%s' already has required tag '%s' for state '%s'. Skipping." % [entity.name, required_tag, state_to_enter]) # Very verbose
		# --- END DEBUG PRINT ---
		return
	elif !is_instance_valid(tag_comp) and required_tag:
		# --- DEBUG PRINT ---
		push_warning("SchedulingSystem: Entity '%s' needs tag '%s' for state '%s' but has no TagComponent." % [entity.name, required_tag, state_to_enter])
		# --- END DEBUG PRINT ---


	var context = activity_data.duplicate()
	context.erase("state")
	context.erase("priority")
	state_comp.push_state(state_to_enter, context)
	print("[SCHEDULER] Entity '%s' new activity: '%s'" % [entity.name, state_to_enter])

	if is_instance_valid(tag_comp) and required_tag: # Added validity check
		EntityManager.add_tag_to_entity(entity.name, required_tag)

	if state_def.has("on_enter_spawn"):
		var spawn_list_id = state_def["on_enter_spawn"]
		print("State change on '%s' is triggering spawn list: '%s'" % [entity.name, spawn_list_id])
		# --- DEBUG PRINT ---
		print("SchedulingSystem: Calling SpawningSystem.execute_spawn_list for '%s' at position %s." % [spawn_list_id, entity.global_position])
		# --- END DEBUG PRINT ---
		if entity is Node3D: SpawningSystem.execute_spawn_list(spawn_list_id, entity.global_position)
		elif entity is Node2D: SpawningSystem.execute_spawn_list(spawn_list_id, Vector3(entity.global_position.x, entity.global_position.y, 0)) # Handle Node2D spawn position


	if state_def.has("on_enter_despawn_by_tag"):
		var tag_to_despawn = state_def["on_enter_despawn_by_tag"]
		print("State change on '%s' is triggering despawn for tag: '%s'" % [entity.name, tag_to_despawn])
		# --- DEBUG PRINT ---
		print("SchedulingSystem: Calling EntityManager.destroy_all_with_tag for tag '%s'." % tag_to_despawn)
		# --- END DEBUG PRINT ---
		EntityManager.destroy_all_with_tag(tag_to_despawn)
