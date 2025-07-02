class_name MovementComponent
extends BaseComponent

var movement_speed: float = 3.0
var rotation_speed: float = 5.0 # Radians per second

@onready var _parent_body: CharacterBody3D = get_parent().get_parent() as CharacterBody3D
var _nav_component: NavigationComponent = null

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	movement_speed = data.get("movement_speed", 3.0)
	rotation_speed = data.get("rotation_speed", 5.0)

# This function is called after all components are loaded.
func _post_initialize() -> void:
	_nav_component = get_sibling_component("NavigationComponent")
	
	if is_instance_valid(_nav_component):
		_nav_component.destination_reached.connect(on_destination_reached)
		_nav_component.pathfinding_failed.connect(on_pathfinding_failed)
		Debug.post("Successfully connected to NavigationComponent.", "MovementComponent on '%s'" % _entity_name)
	else:
		printerr("MovementComponent on '%s': could not find NavigationComponent sibling." % _entity_name)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_parent_body) or not is_instance_valid(_nav_component):
		Debug.post("Bailing out of _physics_process. Parent or NavComponent invalid.", "MovementComponent on '%s'" % _entity_name)
		return
		
	if not _nav_component.is_path_active():
		_parent_body.velocity = Vector3.ZERO
		return

	Debug.post("Following active path.", "MovementComponent on '%s'" % _entity_name)

	var path = _nav_component.get_current_path()
	if path.is_empty():
		return
		
	var next_point = path[0]
	
	var current_pos = _parent_body.global_position
	var direction = current_pos.direction_to(next_point)
	direction.y = 0
	
	if direction.length_squared() > 0.0001:
		var target_basis = Basis.looking_at(direction.normalized())
		_parent_body.basis = _parent_body.basis.slerp(target_basis, delta * rotation_speed)
	
	_parent_body.velocity = _parent_body.basis.z * -movement_speed
	_parent_body.move_and_slide()
	
	if current_pos.distance_to(next_point) < 0.5:
		_nav_component.advance_path()


# Called when the NavigationComponent signals that the final destination has been reached.
func on_destination_reached() -> void:
	if is_instance_valid(_parent_body):
		_parent_body.velocity = Vector3.ZERO
	Debug.post("Destination reached, stopping movement.", "MovementComponent on '%s'" % _entity_name)
	
# Added handling for pathfinding failures
func on_pathfinding_failed() -> void:
	if is_instance_valid(_parent_body):
		_parent_body.velocity = Vector3.ZERO
	Debug.post("Pathfinding failed, stopping movement.", "MovementComponent on '%s'" % _entity_name)
