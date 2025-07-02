class_name MovementComponent
extends BaseComponent

var movement_speed: float = 3.0
var rotation_speed: float = 5.0 # Radians per second

var _character_body: CharacterBody3D = null
# --- THIS IS THE FIX ---
# Instead of storing NavigationAgent3D directly, we will get it via NavigationComponent.
var _nav_component_ref: NavigationComponent = null 
# --- END OF FIX ---

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	var source_name = "MovementComponent on '%s'" % _entity_name
	Debug.post("_load_data called with data: %s" % data, source_name)
	movement_speed = data.get("movement_speed", 3.0)
	rotation_speed = data.get("rotation_speed", 5.0)

# This function is called after all components are loaded.
func _post_initialize() -> void:
	var source_name = "MovementComponent on '%s'" % _entity_name
	Debug.post("_post_initialize called.", source_name)
	
	if is_instance_valid(_entity_root) and _entity_root is CharacterBody3D:
		_character_body = _entity_root
	else:
		printerr("MovementComponent on '%s': _entity_root is not a valid CharacterBody3D. Movement will not function." % _entity_name)
		return # Cannot proceed if parent is not a CharacterBody3D.
	
	# --- THIS IS THE FIX ---
	# Get a reference to the sibling NavigationComponent.
	_nav_component_ref = get_sibling_component("NavigationComponent")

	if not is_instance_valid(_nav_component_ref):
		printerr("MovementComponent on '%s': could not find NavigationComponent sibling. Movement will not function." % _entity_name)
	# --- END OF FIX ---


func _physics_process(_delta: float) -> void:
	# --- THIS IS THE FIX ---
	# Access the NavigationAgent3D safely via the NavigationComponent.
	if not is_instance_valid(_character_body) or not is_instance_valid(_nav_component_ref):
		return
	
	var _nav_agent = _nav_component_ref.get_navigation_agent() # Get the agent instance from the sibling.
	if not is_instance_valid(_nav_agent):
		return # Agent not ready or invalid.

	if _nav_agent.is_navigation_finished():
		_character_body.velocity = Vector3.ZERO
		return

	var current_location = _character_body.global_transform.origin
	var next_location = _nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * movement_speed

	_character_body.velocity = new_velocity
	_character_body.move_and_slide()
	
	var direction = _character_body.velocity.normalized()
	if direction.length() > 0:
		var look_at_basis = Basis.looking_at(direction)
		_character_body.basis = _character_body.basis.slerp(look_at_basis, rotation_speed * _delta)
# --- END OF FIX ---

func on_destination_reached() -> void:
	var source_name = "MovementComponent on '%s'" % _entity_name
	if is_instance_valid(_character_body):
		_character_body.velocity = Vector3.ZERO
	Debug.post("Destination reached, stopping movement.", source_name)
	
func on_pathfinding_failed() -> void:
	var source_name = "MovementComponent on '%s'" % _entity_name
	if is_instance_valid(_character_body):
		_character_body.velocity = Vector3.ZERO
	Debug.post("Pathfinding failed, stopping movement.", source_name)
