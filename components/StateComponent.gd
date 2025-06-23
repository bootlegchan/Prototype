class_name StateComponent
extends Node

var _state_stack: Array[Dictionary] = []
var _entity_name: String = "Unnamed"

func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	# When initializing from a save file later, we would load the stack here.
	# For now, we get the initial state from the entity definition.
	var initial_state_id = data.get("initial_state")
	if initial_state_id:
		# The ScheduleComponent is now responsible for pushing the initial state.
		print("StateComponent for '%s' is ready." % _entity_name)
	else:
		push_warning("StateComponent for '%s' has no initial state defined." % _entity_name)

# --- NEW FUNCTION ---
# Called by the EntityManager before unstaging to save the component's state.
func get_persistent_data() -> Dictionary:
	var state_ids = []
	for state_data in _state_stack:
		state_ids.append(state_data.get("id", "unknown"))
		
	return {
		"state_stack_ids": state_ids
	}

# --- Public API ---
func push_state(state_id: String) -> void:
	var state_data = StateRegistry.get_state_definition(state_id)
	if not state_data.is_empty():
		var new_state_data = state_data.duplicate()
		new_state_data["id"] = state_id
		_state_stack.push_back(new_state_data)
		print("Entity '%s' entered state: '%s'" % [_entity_name, state_id])
	else:
		push_warning("Attempted to push undefined state '%s' for '%s'" % [state_id, _entity_name])

func pop_state() -> void:
	if _state_stack.size() > 1:
		var old_state = _state_stack.pop_back()
		print("Entity '%s' exited state: '%s'" % [_entity_name, old_state.get("id", "unknown")])
	else:
		push_warning("Attempted to pop the base state for '%s'." % _entity_name)

func get_current_state_data() -> Dictionary:
	if _state_stack.is_empty():
		return {}
	return _state_stack.back()

func get_current_state_id() -> String:
	if _state_stack.is_empty():
		return ""
	return get_current_state_data().get("id", "unknown")
