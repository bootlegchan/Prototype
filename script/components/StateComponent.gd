# script/components/StateComponent.gd
class_name StateComponent
extends BaseComponent

# Stack now stores dictionaries: { "state_id": "...", "context": {...} }
var _state_stack: Array[Dictionary] = []

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("StateComponent on '%s': _load_data called with data: %s" % [_entity_name, data])
	# --- END DEBUG PRINT ---
	_state_stack.clear() # Always start with a clean slate.
	
	if data.has("saved_data"):
		# Re-hydrating from a saved state.
		var saved_stack_data = data.get("saved_data", {}).get("state_stack", [])
		# --- DEBUG PRINT ---
		print("StateComponent on '%s': Loading from saved_data. Stack size: %d" % [_entity_name, saved_stack_data.size() if saved_stack_data is Array else 0])
		# --- END DEBUG PRINT ---
		if saved_stack_data is Array:
			for state_instance in saved_stack_data:
				if state_instance is Dictionary:
					_state_stack.append(state_instance)
				else:
					push_warning("StateComponent on '%s': Malformed data found in saved state stack." % _entity_name)
		print("StateComponent for '%s' re-hydrated." % _entity_name)
	else:
		# Initializing from an entity definition for the first time.
		var initial_state = data.get("initial_state", "common/idle")
		# --- DEBUG PRINT ---
		print("StateComponent on '%s': Loading initial state from definition: '%s'" % [_entity_name, initial_state])
		# --- END DEBUG PRINT ---
		push_state(initial_state)

	# --- DEBUG PRINT ---
	print("StateComponent on '%s': _load_data finished. Stack size: %d" % [_entity_name, _state_stack.size()])
	# --- END DEBUG PRINT ---

# This function is called after all components are loaded.
func _post_initialize() -> void:
	# --- DEBUG PRINT ---
	print("StateComponent on '%s': _post_initialize called." % _entity_name)
	# --- END DEBUG PRINT ---
	pass

# We are replacing the parent's persistence function.
func get_persistent_data() -> Dictionary:
	# --- DEBUG PRINT ---
	print("StateComponent on '%s': get_persistent_data called." % _entity_name)
	# --- END DEBUG PRINT ---
	# We only want to save the state_id and context, not the script instance.
	var persistent_stack = []
	for state_instance in _state_stack:
		if state_instance is Dictionary: # Check if it's a valid state instance dictionary
			persistent_stack.append({
				"state_id": state_instance.get("state_id", ""),
				"context": state_instance.get("context", {})
			})
	# --- DEBUG PRINT ---
	print("StateComponent on '%s': get_persistent_data returning stack size: %d" % [_entity_name, persistent_stack.size()])
	# --- END DEBUG PRINT ---
	return { "state_stack": persistent_stack }


func push_state(state_id: String, context: Dictionary = {}) -> void:
	# --- DEBUG PRINT ---
	print("StateComponent on '%s': push_state called for '%s' with context: %s" % [_entity_name, state_id, context])
	# --- END DEBUG PRINT ---
	if not StateRegistry.is_state_defined(state_id):
		push_warning("StateComponent on '%s': Attempted to push undefined state '%s'" % [_entity_name, state_id])
		return

	# Pop the current state first, if one exists, to trigger its on_exit logic.
	if not _state_stack.is_empty():
		var old_state_instance = _state_stack.back()
		var old_script_instance = old_state_instance.get("script_instance")
		if is_instance_valid(old_script_instance) and old_script_instance.has_method("on_exit"):
			# --- DEBUG PRINT ---
			print("StateComponent on '%s': Calling on_exit for state '%s'." % [_entity_name, old_state_instance.get("state_id", "unknown")])
			# --- END DEBUG PRINT ---
			old_script_instance.on_exit(self)

	var state_def = StateRegistry.get_state_definition(state_id)
	var new_state_instance = {
		"state_id": state_id,
		"context": context,
		"script_instance": null # Default to null
	}

	# If the new state has a script, instantiate it and call on_enter
	if state_def.has("script_path"):
		# --- DEBUG PRINT ---
		print("StateComponent on '%s': State '%s' has script at path '%s'. Loading script." % [_entity_name, state_id, state_def.script_path])
		# --- END DEBUG PRINT ---
		var script = load(state_def.script_path)
		if script:
			var script_instance = script.new()
			script_instance.name = "StateLogic_%s" % state_id.replace("/", "_")
			new_state_instance["script_instance"] = script_instance
			add_child(script_instance) # Add it to the scene tree
			# --- DEBUG PRINT ---
			print("StateComponent on '%s': Script instance created and added as child: '%s'." % [_entity_name, script_instance.name])
			# --- END DEBUG PRINT ---

			if script_instance.has_method("on_enter"):
				# --- DEBUG PRINT ---
				print("StateComponent on '%s': Calling on_enter for state '%s'." % [_entity_name, state_id])
				# --- END DEBUG PRINT ---
				script_instance.on_enter(self, context)
			else:
				# --- DEBUG PRINT ---
				push_warning("StateComponent on '%s': State script '%s' does not have an on_enter method." % [_entity_name, state_def.script_path])
				# --- END DEBUG PRINT ---
		else:
			# --- DEBUG PRINT ---
			printerr("StateComponent on '%s': Failed to load state script at path '%s'." % [_entity_name, state_def.script_path])
			# --- END DEBUG PRINT ---

	_state_stack.push_back(new_state_instance)
	print("Entity '%s' entered state: '%s' with context: %s" % [_entity_name, state_id, str(context)])


func pop_state() -> void:
	# --- DEBUG PRINT ---
	print("StateComponent on '%s': pop_state called." % _entity_name)
	# --- END DEBUG PRINT ---
	if _state_stack.size() <= 1:
		push_warning("StateComponent on '%s': Attempted to pop the base state." % _entity_name)
		return

	# Pop the current state and trigger its on_exit logic
	var old_state_instance = _state_stack.pop_back()
	var old_script_instance = old_state_instance.get("script_instance")
	
	if is_instance_valid(old_script_instance):
		if old_script_instance.has_method("on_exit"):
			# --- DEBUG PRINT ---
			print("StateComponent on '%s': Calling on_exit for state '%s'." % [_entity_name, old_state_instance.get("state_id", "unknown")])
			# --- END DEBUG PRINT ---
			old_script_instance.on_exit(self)
		old_script_instance.queue_free() # Clean up the script node
		# --- DEBUG PRINT ---
		print("StateComponent on '%s': Script instance for state '%s' queued for free." % [_entity_name, old_state_instance.get("state_id", "unknown")])
		# --- END DEBUG PRINT ---


	print("Entity '%s' exited state: '%s'" % [_entity_name, old_state_instance.get("state_id", "unknown")])

	# Re-activate the new top state on the stack (if any)
	if not _state_stack.is_empty():
		var new_top_state = _state_stack.back()
		var new_script_instance = new_top_state.get("script_instance")
		if is_instance_valid(new_script_instance) and new_script_instance.has_method("on_enter"):
			# We can call on_enter again if we want to "re-awaken" the previous state
			# For now, we assume states resume without needing a re-initialization.
			# --- DEBUG PRINT ---
			# print("StateComponent on '%s': Re-entering previous state '%s'." % [_entity_name, new_top_state.get("state_id", "unknown")]) # Very verbose
			# new_script_instance.on_enter(self, new_top_state.get("context", {})) # Uncomment to re-enter previous state
			# --- END DEBUG PRINT ---
			pass


func get_current_state_data() -> Dictionary:
	# --- DEBUG PRINT ---
	# print("StateComponent on '%s': get_current_state_data called." % _entity_name) # Very verbose
	# --- END DEBUG PRINT ---
	if _state_stack.is_empty():
		return {}
	var current_state_id = _state_stack.back().get("state_id", "unknown")
	return StateRegistry.get_state_definition(current_state_id)


func get_current_state_id() -> String:
	# --- DEBUG PRINT ---
	# print("StateComponent on '%s': get_current_state_id called." % _entity_name) # Very verbose
	# --- END DEBUG PRINT ---
	if _state_stack.is_empty():
		return ""
	var current_instance = _state_stack.back()
	return current_instance.get("state_id", "unknown")


func get_current_state_context() -> Dictionary:
	# --- DEBUG PRINT ---
	# print("StateComponent on '%s': get_current_state_context called." % _entity_name) # Very verbose
	# --- END DEBUG PRINT ---
	if _state_stack.is_empty():
		return {}
	var current_instance = _state_stack.back()
	return current_instance.get("context", {})
