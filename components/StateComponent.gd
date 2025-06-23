class_name StateComponent
extends Node

var _state_stack: Array[Dictionary] = [] # Now stores the full definition, not just the ID.
var _entity_name: String = "Unnamed"

func initialize(entity_name: String, initial_stack: Array[Dictionary]) -> void:
	_entity_name = entity_name
	_state_stack = initial_stack
	
	if not _state_stack.is_empty():
		print("Entity '%s' initialized in state: '%s'" % [_entity_name, get_current_state_id()])
	else:
		print("Entity '%s' initialized with no state." % _entity_name)

# --- Public API for State Machine ---

func push_state(state_id: String) -> void:
	var state_data = StateRegistry.get_state_definition(state_id)
	if not state_data.is_empty():
		# --- THIS IS THE FIX ---
		var new_state_data = state_data.duplicate()
		new_state_data["id"] = state_id # Inject the ID
		_state_stack.push_back(new_state_data)
		print("Entity '%s' entered state: '%s'" % [_entity_name, state_id])
	else:
		push_warning("Attempted to push undefined state '%s'" % state_id)

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
	# We now get the ID that was injected.
	return get_current_state_data().get("id", "unknown")
