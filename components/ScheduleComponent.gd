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
		time_system.hour_changed.connect(_on_hour_changed)
		# Set the entity's initial state based on the time it spawned in.
		# This is now the ONLY place the initial state is set.
		_on_hour_changed(time_system.current_hour)
	else:
		printerr("ScheduleComponent on '%s' could not find TimeSystem." % _entity_name)

func _on_hour_changed(new_hour: int) -> void:
	var hour_key = str(new_hour)
	if schedule.has(hour_key):
		var new_state_id: String = schedule[hour_key]
		var state_comp = get_parent().get_component("StateComponent")
		if state_comp:
			# This check is now crucial. We don't want to push the same state over and over.
			if state_comp.get_current_state_id() != new_state_id:
				state_comp.push_state(new_state_id)
				print("Time is now %02d:00. '%s' is now performing scheduled activity: '%s'" % [new_hour, _entity_name, new_state_id])
		else:
			printerr("ScheduleComponent on '%s' requires a StateComponent." % _entity_name)
