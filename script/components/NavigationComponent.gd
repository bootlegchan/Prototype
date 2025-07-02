class_name NavigationComponent
extends BaseComponent

signal pathfinding_failed
signal destination_reached

var _nav_agent: NavigationAgent3D

func _post_initialize() -> void:
	var source_name = "NavigationComponent on '%s'" % _entity_name
	Debug.post("_post_initialize called.", source_name)
	
	_nav_agent = NavigationAgent3D.new()
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = 0.5
	
	# The NavigationAgent3D must be a direct child of the CharacterBody3D (entity root)
	_entity_root.add_child(_nav_agent)
	_nav_agent.set_owner(_entity_root) # Important for proper scene tree management

	_nav_agent.target_reached.connect(_on_target_reached)
	_nav_agent.path_changed.connect(_on_path_changed)
	
	Debug.post("NavigationAgent3D created and initialized.", source_name)

func _physics_process(_delta: float) -> void:
	# This _physics_process is actually handled by MovementComponent.
	# We can remove the body of this function, as MovementComponent will query the agent.
	pass # Remove the content if MovementComponent is driving physics_process.

func set_target_location(new_target_pos: Vector3):
	var source_name = "NavigationComponent on '%s'" % _entity_name
	Debug.post("Setting target location to: %s" % str(new_target_pos), source_name)
	if is_instance_valid(_nav_agent):
		_nav_agent.target_position = new_target_pos
	else:
		printerr("NavigationComponent on '%s': NavigationAgent3D is not valid." % _entity_name)
		emit_signal("pathfinding_failed")

func get_next_path_position() -> Vector3:
	if is_instance_valid(_nav_agent):
		return _nav_agent.get_next_path_position()
	return _entity_root.global_position

func is_navigation_finished() -> bool:
	if is_instance_valid(_nav_agent):
		return _nav_agent.is_navigation_finished()
	return true

func _on_target_reached():
	var source_name = "NavigationComponent on '%s'" % _entity_name
	Debug.post("Target reached.", source_name)
	emit_signal("destination_reached")

func _on_path_changed():
	var source_name = "NavigationComponent on '%s'" % _entity_name
	Debug.post("Path changed.", source_name)

# --- THIS IS THE FIX ---
# New getter to safely provide the NavigationAgent3D instance.
func get_navigation_agent() -> NavigationAgent3D:
	return _nav_agent
# --- END OF FIX ---
