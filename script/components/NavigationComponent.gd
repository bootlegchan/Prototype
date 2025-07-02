class_name NavigationComponent
extends BaseComponent

signal path_updated(new_path: PackedVector3Array)
signal pathfinding_failed
signal destination_reached

var target_position: Vector3
var current_path: PackedVector3Array = []
var _parent_body: CharacterBody3D = null

func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called with data: %s" % data, "NavigationComponent on '%s'" % _entity_name)
	pass

func _post_initialize() -> void:
	Debug.post("_post_initialize called. Attempting to get parent CharacterBody3D.", "NavigationComponent on '%s'" % _entity_name)
	_parent_body = get_parent().get_parent() as CharacterBody3D
	if not is_instance_valid(_parent_body):
		printerr("NavigationComponent on '%s': has no valid parent CharacterBody3D after post-initialize." % _entity_name)

func set_target_location(new_target: Vector3) -> void:
	Debug.post("set_target_location called with new_target: %s" % new_target, "NavigationComponent on '%s'" % _entity_name)
	if not is_instance_valid(NavigationManager):
		printerr("NavigationComponent on '%s': NavigationManager singleton not available." % _entity_name)
		emit_signal("pathfinding_failed")
		return

	target_position = NavigationManager.get_closest_point_on_navmesh(new_target)
	
	Debug.post("New target set to %s" % target_position, "NavigationComponent on '%s'" % _entity_name)
	_request_new_path()

func _request_new_path() -> void:
	Debug.post("_request_new_path called.", "NavigationComponent on '%s'" % _entity_name)
	if not is_instance_valid(_parent_body):
		printerr("NavigationComponent on '%s': has no valid parent CharacterBody3D when requesting path." % _entity_name)
		emit_signal("pathfinding_failed")
		return

	current_path.clear()
	
	Debug.post("Requesting path from %s to %s on map %s" % [_parent_body.global_position, target_position, NavigationServer3D.agent_get_map(_parent_body.get_rid())], "NavigationComponent on '%s'" % _entity_name)

	var new_path = NavigationManager.get_navigation_path(_parent_body.global_position, target_position)
	
	Debug.post("Received path: %s" % str(new_path), "NavigationComponent on '%s'" % _entity_name)

	if new_path.is_empty():
		printerr("NavigationComponent on '%s': Pathfinding failed to find a path." % _entity_name)
		emit_signal("pathfinding_failed")
	else:
		current_path = new_path
		Debug.post("New path found with %s points." % current_path.size(), "NavigationComponent on '%s'" % _entity_name)
		emit_signal("path_updated", current_path)

func advance_path() -> void:
	Debug.post("advance_path called. Current path size: %d" % current_path.size(), "NavigationComponent on '%s'" % _entity_name)
	if not current_path.is_empty(): current_path.remove_at(0)
	if current_path.is_empty():
		Debug.post("Path is now empty, emitting destination_reached.", "NavigationComponent on '%s'" % _entity_name)
		emit_signal("destination_reached")

func get_current_path() -> PackedVector3Array: return current_path
func is_path_active() -> bool: return not current_path.is_empty()
