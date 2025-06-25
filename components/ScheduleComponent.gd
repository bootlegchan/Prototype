class_name ScheduleComponent
extends Node

var schedule_layer_ids: Array[String] = []
var weekly_schedule: Dictionary = {}
var specific_events: Array = []
var priority: int = 0
var _entity_name: String = "Unnamed"

func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	
	schedule_layer_ids = data.get("layers", [])
	weekly_schedule = data.get("weekly_schedule", {})
	specific_events = data.get("specific_events", [])
	priority = data.get("priority", 0)

	# We add to group here, as the parent is guaranteed to exist.
	get_parent().get_parent().add_to_group("has_schedule")
	print("ScheduleComponent on '%s' initialized." % _entity_name)

# Using _ready() is the most reliable way to connect signals after instantiation.
func _ready() -> void:
	if TimeSystem:
		# Check if already connected to prevent duplicates if unstaged/staged
		if not TimeSystem.time_updated.is_connected(_on_time_updated):
			TimeSystem.time_updated.connect(_on_time_updated)
		
		# Manually fire the first check to synchronize with the current time.
		_on_time_updated(TimeSystem.get_current_date_info())
	else:
		# This case should ideally never happen with correct Autoload order.
		printerr("ScheduleComponent on '%s' could not find TimeSystem on ready." % _entity_name)


func _on_time_updated(date_info: Dictionary) -> void:
	var entity_node = get_parent().get_parent()
	if not is_instance_valid(entity_node): return
	
	var potential_activities = SchedulingSystem.get_potential_activities(self, date_info)
	if potential_activities.is_empty(): return
		
	var final_activity_data = ConflictResolutionSystem.resolve(potential_activities)
	if final_activity_data.is_empty(): return
		
	_execute_activity(entity_node, final_activity_data, date_info)

func _execute_activity(entity: Node, activity_data: Dictionary, date_info: Dictionary) -> void:
	var state_to_enter = activity_data.get("state")
	if not state_to_enter: return

	var state_comp = entity.get_node("EntityLogic").get_component("StateComponent")
	if state_comp and state_comp.get_current_state_id() != state_to_enter:
		var context = activity_data.duplicate()
		context.erase("state")
		context.erase("priority")
		state_comp.push_state(state_to_enter, context)
		var time_str = "%02d:%02d" % [date_info.hour, date_info.minute]
		print("[SCHEDULER] '%s' new activity: '%s' at %s" % [entity.name, state_to_enter, time_str])
		
		var state_data = StateRegistry.get_state_definition(state_to_enter)
		if state_data.has("on_enter_spawn"):
			var spawn_list_id = state_data["on_enter_spawn"]
			print("State change for '%s' is triggering spawn list: '%s'" % [entity.name, spawn_list_id])
			var entity_node_3d = entity as Node3D
			if entity_node_3d:
				SpawningSystem.execute_spawn_list(spawn_list_id, entity_node_3d.global_position)
