extends BaseComponent

var _nav_component: NavigationComponent = null
var _destination_marker_id: String = ""

func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called with data: %s" % data, "TravelToState on '%s'" % _entity_name)
	pass

func _post_initialize() -> void:
	var source_name = "TravelToState on '%s'" % _entity_name
	Debug.post("_post_initialize called.", source_name)

	_nav_component = get_sibling_component("NavigationComponent")
	
	Debug.post("NavigationComponent valid: %s" % is_instance_valid(_nav_component), source_name)

	if not is_instance_valid(_nav_component):
		printerr("TravelToState on '%s': Entity is missing a NavigationComponent or it's invalid." % _entity_name)


func on_enter(state_comp: Node, context: Dictionary) -> void:
	var source_name = "TravelToState on '%s'" % _entity_name
	Debug.post("on_enter called with context: %s" % context, source_name)

	_nav_component = state_comp.get_component("NavigationComponent")

	if not is_instance_valid(_nav_component):
		printerr("TravelToState on '%s': NavigationComponent not found." % _entity_name)
		state_comp.pop_state()
		return

	_destination_marker_id = context.get("destination_marker")
	if not _destination_marker_id:
		printerr("TravelToState on '%s': 'destination_marker' not found in context." % _entity_name)
		state_comp.pop_state()
		return

	var destination_marker = EntityManager.get_node_from_instance_id(_destination_marker_id)
	if not is_instance_valid(destination_marker):
		printerr("TravelToState on '%s': Destination marker '%s' not found." % [_entity_name, _destination_marker_id])
		state_comp.pop_state()
		return

	if is_instance_valid(_nav_component):
		if not _nav_component.destination_reached.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.destination_reached.connect(Callable(state_comp, "pop_state"))
			Debug.post("Connected destination_reached signal.", source_name)
		if not _nav_component.pathfinding_failed.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.pathfinding_failed.connect(Callable(state_comp, "pop_state"))
			Debug.post("Connected pathfinding_failed signal.", source_name)

	_nav_component.set_target_location(destination_marker.global_position)
	Debug.post("Called set_target_location with %s." % destination_marker.global_position, source_name)


func on_exit(state_comp: Node) -> void:
	var source_name = "TravelToState on '%s'" % _entity_name
	Debug.post("on_exit called.", source_name)
	if is_instance_valid(_nav_component):
		if _nav_component.destination_reached.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.destination_reached.disconnect(Callable(state_comp, "pop_state"))
			Debug.post("Disconnected destination_reached signal.", source_name)
		if _nav_component.pathfinding_failed.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.pathfinding_failed.disconnect(Callable(state_comp, "pop_state"))
			Debug.post("Disconnected pathfinding_failed signal.", source_name)
