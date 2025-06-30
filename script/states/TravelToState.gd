# script/states/TravelToState.gd
extends BaseComponent # Inherit from BaseComponent

var _nav_component: NavigationComponent = null
var _destination_marker_id: String = "" # Store the marker ID

func _load_data(data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("TravelToState on '%s': _load_data called with data: %s" % [_entity_name, data])
	# --- END DEBUG PRINT ---
	pass # No specific data loading for this state

func _post_initialize() -> void:
	# --- DEBUG PRINT ---
	print("TravelToState on '%s': _post_initialize called." % _entity_name)
	# --- END DEBUG PRINT ---

	# Get the NavigationComponent sibling
	_nav_component = get_sibling_component("NavigationComponent")
	
	# --- DEBUG PRINT ---
	print("TravelToState on '%s': NavigationComponent valid: %s" % [_entity_name, is_instance_valid(_nav_component)])
	# --- END DEBUG PRINT ---

	if not is_instance_valid(_nav_component):
		printerr("TravelToState on '%s': Entity is missing a NavigationComponent or it's invalid." % _entity_name)
		# We need to signal to the state machine that this state can't proceed.
		# The state machine would need a mechanism for this, or the component should handle it.
		# For now, we'll just log an error.

	# The context is passed in the push_state call and is stored by the StateComponent.
	# We need to access the context through the state_comp reference passed to on_enter.
	# The state_comp reference itself is passed to on_enter, which is an instance of StateComponent.
	# We need to get the context from the state_comp's internal stack.
	# This suggests a need for a method on StateComponent to retrieve current context.
	# For now, we'll retrieve it within on_enter.


func on_enter(state_comp: Node, context: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("TravelToState on '%s': on_enter called with context: %s" % [_entity_name, context])
	# --- END DEBUG PRINT ---

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

	# Connect to the navigation signals to know when to exit this state.
	# Ensure not already connected to prevent duplicate connections after re-staging.
	if _nav_component: # Check if navigation component is valid
		if not _nav_component.destination_reached.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.destination_reached.connect(Callable(state_comp, "pop_state"))
			print("TravelToState on '%s': Connected destination_reached signal." % _entity_name)
		if not _nav_component.pathfinding_failed.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.pathfinding_failed.connect(Callable(state_comp, "pop_state"))
			print("TravelToState on '%s': Connected pathfinding_failed signal." % _entity_name)


	# Command the navigation component to start moving.
	_nav_component.set_target_location(destination_marker.global_position)
	print("TravelToState on '%s': Called set_target_location with %s." % [_entity_name, destination_marker.global_position])


func on_exit(state_comp: Node) -> void:
	# --- DEBUG PRINT ---
	print("TravelToState on '%s': on_exit called." % _entity_name)
	# --- END DEBUG PRINT ---
	# It's crucial to disconnect from signals to prevent memory leaks and bugs
	# when the state is exited for any reason.
	if _nav_component: # Check if nav component is valid
		if _nav_component.destination_reached.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.destination_reached.disconnect(Callable(state_comp, "pop_state"))
			print("TravelToState on '%s': Disconnected destination_reached signal." % _entity_name)
		if _nav_component.pathfinding_failed.is_connected(Callable(state_comp, "pop_state")):
			_nav_component.pathfinding_failed.disconnect(Callable(state_comp, "pop_state"))
			print("TravelToState on '%s': Disconnected pathfinding_failed signal." % _entity_name)

# Add on_process if needed for state logic that runs every frame
# func on_process(state_comp: Node, delta: float) -> void:
# 	pass # Example on_process implementation
