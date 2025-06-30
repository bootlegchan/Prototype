# script/components/NavigationComponent.gd
class_name NavigationComponent
extends BaseComponent

signal path_updated(new_path: PackedVector3Array)
signal pathfinding_failed
signal destination_reached

var target_position: Vector3
var current_path: PackedVector3Array = []
var _parent_body: CharacterBody3D = null

func _load_data(data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("NavigationComponent on '%s': _load_data called with data: %s" % [_entity_name, data])
	# --- END DEBUG PRINT ---
	pass

func _post_initialize() -> void:
	# --- DEBUG PRINT ---
	print("NavigationComponent on '%s': _post_initialize called. Attempting to get parent CharacterBody3D." % _entity_name)
	# --- END DEBUG PRINT ---
	_parent_body = get_parent().get_parent() as CharacterBody3D
	if not is_instance_valid(_parent_body):
		# --- DEBUG PRINT ---
		printerr("NavigationComponent on '%s': has no valid parent CharacterBody3D after post-initialize." % _entity_name)
		# --- END DEBUG PRINT ---

func set_target_location(new_target: Vector3) -> void:
	# --- DEBUG PRINT ---
	print("NavigationComponent on '%s': set_target_location called with new_target: %s" % [_entity_name, new_target])
	# --- END DEBUG PRINT ---
	if not is_instance_valid(NavigationManager):
		# --- DEBUG PRINT ---
		printerr("NavigationComponent on '%s': NavigationManager singleton not available." % _entity_name)
		# --- END DEBUG PRINT ---
		emit_signal("pathfinding_failed")
		return

	target_position = NavigationManager.get_closest_point_on_navmesh(new_target)
	
	print("NavigationComponent on '%s': New target set to %s" % [_entity_name, target_position])
	_request_new_path()

func _request_new_path() -> void:
	# --- DEBUG PRINT ---
	print("NavigationComponent on '%s': _request_new_path called." % _entity_name)
	# --- END DEBUG PRINT ---
	if not is_instance_valid(_parent_body):
		# --- DEBUG PRINT ---
		printerr("NavigationComponent on '%s': has no valid parent CharacterBody3D when requesting path." % _entity_name)
		# --- END DEBUG PRINT ---
		emit_signal("pathfinding_failed")
		return

	current_path.clear()
	
	# --- THIS IS THE CRITICAL DEBUG PRINT ---
	print("NavigationComponent on '%s': Requesting path from %s to %s on map %s" % [_entity_name, _parent_body.global_position, target_position, NavigationServer3D.agent_get_map(_parent_body.get_rid())])
	# --- END CRITICAL DEBUG PRINT ---

	var new_path = NavigationManager.get_navigation_path(_parent_body.global_position, target_position)
	
	# --- THIS IS THE CRITICAL DEBUG PRINT ---
	print("NavigationComponent on '%s': Received path: %s" % [_entity_name, str(new_path)])
	# --- END CRITICAL DEBUG PRINT ---

	if new_path.is_empty():
		# --- DEBUG PRINT ---
		printerr("NavigationComponent on '%s': Pathfinding failed to find a path." % _entity_name)
		# --- END DEBUG PRINT ---
		emit_signal("pathfinding_failed")
	else:
		current_path = new_path
		# --- DEBUG PRINT ---
		print("NavigationComponent on '%s': New path found with %s points." % [_entity_name, current_path.size()])
		# --- END DEBUG PRINT ---
		emit_signal("path_updated", current_path)

func advance_path() -> void:
	# --- DEBUG PRINT ---
	print("NavigationComponent on '%s': advance_path called. Current path size: %d" % [_entity_name, current_path.size()])
	# --- END DEBUG PRINT ---
	if not current_path.is_empty(): current_path.remove_at(0)
	if current_path.is_empty():
		# --- DEBUG PRINT ---
		print("NavigationComponent on '%s': Path is now empty, emitting destination_reached." % _entity_name)
		# --- END DEBUG PRINT ---
		emit_signal("destination_reached")

func get_current_path() -> PackedVector3Array: return current_path
func is_path_active() -> bool: return not current_path.is_empty()
