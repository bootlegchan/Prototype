class_name ScheduleComponent
extends Node

var schedule: Dictionary = {}
var _entity_name: String = "Unnamed"

func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	schedule = data.get("schedule", {})
	call_deferred("connect_to_time_system")

func connect_to_time_system() -> void:
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		time_system.hour_changed.connect(_on_time_changed)
		time_system.current_minute_changed.connect(_on_time_changed) # NEW: Listen to minutes too
		# Set initial state
		_on_time_changed(time_system.current_hour, time_system.current_minute)
	else:
		printerr("ScheduleComponent on '%s' could not find TimeSystem." % _entity_name)

# Updated to handle minutes for more precise scheduling.
func _on_time_changed(new_hour: int, new_minute: int) -> void:
	var time_key = "%02d:%02d" % [new_hour, new_minute]

	if schedule.has(time_key):
		var schedule_entry = schedule[time_key]
		var new_state_id = schedule_entry.get("state")
		
		var state_comp = get_parent().get_component("StateComponent")
		if state_comp and state_comp.get_current_state_id() != new_state_id:
			state_comp.push_state(new_state_id)
			print("Time is now %s. '%s' is now performing scheduled activity: '%s'" % [time_key, _entity_name, new_state_id])

			# NEW: Check if this state change should spawn something.
			var state_data = StateRegistry.get_state_definition(new_state_id)
			if state_data.has("on_enter_spawn"):
				var spawn_list_id = state_data["on_enter_spawn"]
				print("State change for '%s' is triggering spawn list: '%s'" % [_entity_name, spawn_list_id])
				SpawningSystem.execute_spawn_list(spawn_list_id)
