# script/components/MovementComponent.gd
class_name MovementComponent
extends BaseComponent

var movement_speed: float = 3.0
var rotation_speed: float = 5.0 # Radians per second

@onready var _parent_body: CharacterBody3D = get_parent().get_parent() as CharacterBody3D
var _nav_component: NavigationComponent = null # Removed @onready

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# This function is only for loading data specific to MovementComponent.
	movement_speed = data.get("movement_speed", 3.0)
	rotation_speed = data.get("rotation_speed", 5.0)

# This function is called after all components are loaded.
func _post_initialize() -> void:
	# Now it's safe to get sibling components.
	_nav_component = get_sibling_component("NavigationComponent")
	
	# Connect to the NavigationComponent's signals if it exists.
	# This is commented out for now as we are debugging NavigationManager and its dependencies.
	# if is_instance_valid(_nav_component):
	# 	_nav_component.destination_reached.connect(on_destination_reached)
	# 	_nav_component.pathfinding_failed.connect(on_pathfinding_failed)
	# 	print("MovementComponent on '%s': Successfully connected to NavigationComponent." % _entity_name)
	# else:
	# 	printerr("MovementComponent on '%s': could not find NavigationComponent sibling." % _entity_name)

func _physics_process(delta: float) -> void:
	# If there is no valid parent or no active navigation path, do nothing.
	# Check validity of _nav_component here.
	if not is_instance_valid(_parent_body) or not is_instance_valid(_nav_component):
		# --- THIS IS A CRITICAL DEBUG PRINT ---
		print("MovementComponent on '%s': Bailing out of _physics_process. Parent or NavComponent invalid." % _entity_name)
		# --- END OF CRITICAL DEBUG PRINT ---
		return
		
	if not _nav_component.is_path_active():
		# --- THIS IS A CRITICAL DEBUG PRINT ---
		# print("MovementComponent on '%s': No active path in _physics_process. Velocity zero." % _entity_name) # Debug print
		# --- END OF CRITICAL DEBUG PRINT ---
		_parent_body.velocity = Vector3.ZERO
		return

	# --- THIS IS A CRITICAL DEBUG PRINT ---
	print("MovementComponent on '%s': Following active path." % _entity_name)

	# Get the current path and the next point to move towards.
	var path = _nav_component.get_current_path()
	if path.is_empty():
		return
		
	var next_point = path[0]
	
	# --- Movement and Rotation Logic ---
	var current_pos = _parent_body.global_position
	# We want to look towards the target but ignore any height difference (Y-axis).
	var direction = current_pos.direction_to(next_point)
	direction.y = 0
	
	# Only rotate if there's a valid direction (prevents looking at origin when at target)
	if direction.length_squared() > 0.0001:
		var target_basis = Basis.looking_at(direction.normalized())
		_parent_body.basis = _parent_body.basis.slerp(target_basis, delta * rotation_speed)
	
	# Move the character forward.
	# We use the character's forward vector (-Z) for movement.
	_parent_body.velocity = _parent_body.basis.z * -movement_speed
	_parent_body.move_and_slide()
	
	# Check if we've reached the current point in the path.
	# A distance threshold prevents getting stuck on a point.
	if current_pos.distance_to(next_point) < 0.5:
		_nav_component.advance_path()


# Called when the NavigationComponent signals that the final destination has been reached.
func on_destination_reached() -> void:
	# Stop all movement.
	if is_instance_valid(_parent_body):
		_parent_body.velocity = Vector3.ZERO
	print("MovementComponent on '%s': Destination reached, stopping movement." % _entity_name)
	
# Added handling for pathfinding failures
func on_pathfinding_failed() -> void:
	# Handle the failure, perhaps stop movement or enter an error state.
	if is_instance_valid(_parent_body):
		_parent_body.velocity = Vector3.ZERO
	print("MovementComponent on '%s': Pathfinding failed, stopping movement." % _entity_name)
