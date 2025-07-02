class_name StateComponent
extends BaseComponent

var _state_stack: Array[Dictionary] = []

func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called with data: %s" % data, "StateComponent on '%s'" % _entity_name)
	_state_stack.clear()
	
	if data.has("saved_data"):
		var saved_stack_data = data.get("saved_data", {}).get("state_stack", [])
		Debug.post("Loading from saved_data. Stack size: %d" % saved_stack_data.size(), "StateComponent on '%s'" % _entity_name)
		if saved_stack_data is Array:
			for state_instance in saved_stack_data:
				if state_instance is Dictionary:
					_state_stack.append(state_instance)
				else:
					push_warning("StateComponent on '%s': Malformed data found in saved state stack." % _entity_name)
		Debug.post("re-hydrated.", "StateComponent for '%s'" % _entity_name)
	else:
		var initial_state = data.get("initial_state", "common/idle")
		Debug.post("Loading initial state from definition: '%s'" % initial_state, "StateComponent on '%s'" % _entity_name)
		push_state(initial_state)

	Debug.post("_load_data finished. Stack size: %d" % _state_stack.size(), "StateComponent on '%s'" % _entity_name)

func _post_initialize() -> void:
	Debug.post("_post_initialize called.", "StateComponent on '%s'" % _entity_name)
	pass

func get_persistent_data() -> Dictionary:
	Debug.post("get_persistent_data called.", "StateComponent on '%s'" % _entity_name)
	var persistent_stack = []
	for state_instance in _state_stack:
		if state_instance is Dictionary:
			persistent_stack.append({
				"state_id": state_instance.get("state_id", ""),
				"context": state_instance.get("context", {})
			})
	Debug.post("get_persistent_data returning stack size: %d" % persistent_stack.size(), "StateComponent on '%s'" % _entity_name)
	return { "state_stack": persistent_stack }


func push_state(state_id: String, context: Dictionary = {}) -> void:
	Debug.post("push_state called for '%s' with context: %s" % [state_id, context], "StateComponent on '%s'" % _entity_name)
	if not StateRegistry.is_state_defined(state_id):
		push_warning("StateComponent on '%s': Attempted to push undefined state '%s'" % [_entity_name, state_id])
		return

	if not _state_stack.is_empty():
		var old_state_instance = _state_stack.back()
		var old_script_instance = old_state_instance.get("script_instance")
		if is_instance_valid(old_script_instance) and old_script_instance.has_method("on_exit"):
			Debug.post("Calling on_exit for state '%s'." % old_state_instance.get("state_id", "unknown"), "StateComponent on '%s'" % _entity_name)
			old_script_instance.on_exit(self)

	var state_def = StateRegistry.get_state_definition(state_id)
	var new_state_instance = {
		"state_id": state_id,
		"context": context,
		"script_instance": null
	}

	if state_def.has("script_path"):
		Debug.post("State '%s' has script at path '%s'. Loading script." % [state_id, state_def.script_path], "StateComponent on '%s'" % _entity_name)
		var script = load(state_def.script_path)
		if script:
			var script_instance = script.new()
			script_instance.name = "StateLogic_%s" % state_id.replace("/", "_")
			new_state_instance["script_instance"] = script_instance
			add_child(script_instance)
			Debug.post("Script instance created and added as child: '%s'." % script_instance.name, "StateComponent on '%s'" % _entity_name)

			if script_instance.has_method("on_enter"):
				Debug.post("Calling on_enter for state '%s'." % state_id, "StateComponent on '%s'" % _entity_name)
				script_instance.on_enter(self, context)
			else:
				push_warning("StateComponent on '%s': State script '%s' does not have an on_enter method." % [_entity_name, state_def.script_path])
		else:
			printerr("StateComponent on '%s': Failed to load state script at path '%s'." % [_entity_name, state_def.script_path])

	_state_stack.push_back(new_state_instance)
	Debug.post("Entity '%s' entered state: '%s' with context: %s" % [_entity_name, state_id, str(context)], "StateComponent")


func pop_state() -> void:
	Debug.post("pop_state called.", "StateComponent on '%s'" % _entity_name)
	if _state_stack.size() <= 1:
		push_warning("StateComponent on '%s': Attempted to pop the base state." % _entity_name)
		return

	var old_state_instance = _state_stack.pop_back()
	var old_script_instance = old_state_instance.get("script_instance")
	
	if is_instance_valid(old_script_instance):
		if old_script_instance.has_method("on_exit"):
			Debug.post("Calling on_exit for state '%s'." % old_state_instance.get("state_id", "unknown"), "StateComponent on '%s'" % _entity_name)
			old_script_instance.on_exit(self)
		old_script_instance.queue_free()
		Debug.post("Script instance for state '%s' queued for free." % old_state_instance.get("state_id", "unknown"), "StateComponent on '%s'" % _entity_name)

	Debug.post("Entity '%s' exited state: '%s'" % [_entity_name, old_state_instance.get("state_id", "unknown")], "StateComponent")

	if not _state_stack.is_empty():
		var new_top_state = _state_stack.back()
		var new_script_instance = new_top_state.get("script_instance")
		if is_instance_valid(new_script_instance) and new_script_instance.has_method("on_enter"):
			pass

func get_current_state_data() -> Dictionary:
	if _state_stack.is_empty():
		return {}
	var current_state_id = _state_stack.back().get("state_id", "unknown")
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
