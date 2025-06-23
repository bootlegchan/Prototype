class_name StateComponent
extends Node

# A dictionary to hold any simulation-relevant data.
# Examples: "mood": "happy", "hunger": 50, "energy": 100
var _states: Dictionary = {}
var _entity_name: String = "Unnamed"

# This function is now called with the entity's name and its state data.
func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	_states = data.duplicate() # Make a copy to avoid shared references.
	print("StateComponent initialized on entity '%s' with states: %s" % [_entity_name, _states])


# --- Public API for other systems ---

func set_state(key: String, value) -> void:
	var old_value = _states.get(key)
	_states[key] = value
	print("State changed for entity '%s': '%s' changed from %s to %s" % [_entity_name, key, str(old_value), str(value)])


func get_state(key: String, default = null):
	return _states.get(key, default)


func has_state(key: String) -> bool:
	return _states.has(key)


func get_all_states() -> Dictionary:
	return _states.duplicate(true)
