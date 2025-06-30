# script/components/StateComponent.gd
class_name StateComponent
extends BaseComponent

# Stack now stores dictionaries: { "state_id": "...", "context": {...} }
var _state_stack: Array[Dictionary] = []

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	_state_stack.clear() # Always start with a clean slate.
	
	if data.has("saved_data"):
		# Re-hydrating from a saved state.
		var saved_stack_data = data.get("saved_data", {}).get("state_stack", [])
		if saved_stack_data is Array:
			for state_instance in saved_stack_data:
				if state_instance is Dictionary:
					_state_stack.append(state_instance)
				else:
					push_warning("Malformed data found in saved state stack for '%s'." % _entity_name)
		print("StateComponent for '%s' re-hydrated." % _entity_name)
	else:
		# Initializing from an entity definition for the first time.
		var initial_state = data.get("initial_state", "common/idle")
		push_state(initial_state)

# We are replacing the parent's persistence function.
func get_persistent_data() -> Dictionary:
	return { "state_stack": _state_stack }


func push_state(state_id: String, context: Dictionary = {}) -> void:
	if not StateRegistry.is_state_defined(state_id):
		push_warning("Attempted to push undefined state '%s' for '%s'" % [state_id, _entity_name])
		return

	var new_state_instance = {
		"state_id": state_id,
		"context": context
	}
	_state_stack.push_back(new_state_instance)
	print("Entity '%s' entered state: '%s' with context: %s" % [_entity_name, state_id, str(context)])


func pop_state() -> void:
	if _state_stack.size() > 1:
		var old_state = _state_stack.pop_back()
		print("Entity '%s' exited state: '%s'" % [_entity_name, old_state.get("state_id", "unknown")])
	else:
		push_warning("Attempted to pop the base state for '%s'." % _entity_name)


func get_current_state_data() -> Dictionary:
	if _state_stack.is_empty():
		return {}
	var current_state_id = _state_stack.back()["state_id"]
	return StateRegistry.get_state_definition(current_state_id)


func get_current_state_id() -> String:
	if _state_stack.is_empty():
		return ""
	var current_instance = _state_stack.back()
	return current_instance.get("state_id", "unknown")


func get_current_state_context() -> Dictionary:
	if _state_stack.is_empty():
		return {}
	var current_instance = _state_stack.back()
	return current_instance.get("context", {})
