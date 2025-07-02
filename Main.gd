extends Node3D

var player_id = "player_character"
var merchant_instance_id_from_spawn: String = "" # To store the dynamically spawned merchant's ID
var test_phase_complete = false # A flag to prevent the main test phases from running multiple times

func _ready() -> void:
	# Register the NavRegion with the NavigationManager as soon as the scene is ready.
	var nav_region = get_node_or_null("NavRegion")
	if is_instance_valid(nav_region):
		NavigationManager.register_nav_region(nav_region)
	else:
		printerr("Main.gd: Could not find NavRegion child node!")

	Debug.post("Main scene ready. Starting Grand Integration Test.", "Main")
	
	# Set time to just before the market opens to trigger the spawn list early.
	TimeSystem.current_hour = 9
	TimeSystem.current_minute = 58
	# Set a very fast time scale for rapid testing.
	if TimeSystem.has_method("_set_seconds_per_minute"): # Check for method existence
		TimeSystem._set_seconds_per_minute(0.01) # Call via method if available
	else:
		TimeSystem._seconds_per_minute = 0.01 # Direct access if method not present

	# Subscribe to entity_staged to detect when the scheduled merchant appears.
	EventSystem.subscribe("entity_staged", Callable(self, "_on_entity_staged"))
	Debug.post("Test is now waiting for the scheduler to spawn Silas Croft...", "Main")


func _on_entity_staged(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "")
	# --- THIS IS THE FIX ---
	# Prefix the 'node' variable with an underscore as it's not directly used in this function's logic.
	var _node = payload.get("node") # The actual spawned Node3D instance (now prefixed)
	# --- END OF FIX ---

	# The dynamically spawned merchant will have an instance ID like "silas_croft_dyn_X"
	if instance_id.begins_with("silas_croft_dyn") and not test_phase_complete:
		test_phase_complete = true # Prevent re-triggering the test phases
		merchant_instance_id_from_spawn = instance_id
		Debug.post("[TEST] The scheduled merchant '%s' has spawned." % merchant_instance_id_from_spawn, "Main")
		
		# All initial entities are staged, and the scheduled entity has appeared.
		# Now we can start the core test phases.
		call_deferred("run_all_test_phases")


func run_all_test_phases() -> void:
	if not test_phase_complete:
		Debug.post("TEST FAILED: run_all_test_phases called prematurely.", "Main")
		return

	Debug.post("\n--- Starting Grand Integration Test Phases ---", "Main")

	# Phase 1: Player buys an apple from the initially spawned merchant
	var initial_merchant_id = "test_merchant" # This ID is from world_state.json
	var player_inventory = EntityManager.get_entity_component(player_id, "InventoryComponent")
	var initial_merchant_inventory = EntityManager.get_entity_component(initial_merchant_id, "InventoryComponent")
	
	if is_instance_valid(player_inventory) and is_instance_valid(initial_merchant_inventory):
		Debug.post("\n[Phase 1: Player buys an apple from initial merchant]", "Main")
		InventoryComponent.transfer_item(initial_merchant_inventory, player_inventory, "consumable/apple", 1)
		EntityManager.add_tag_to_entity(player_id, "reputation/valued_customer")
		Debug.post("Player attempted to buy apple. Player inventory count: %s" % player_inventory.get_item_count("consumable/apple"), "Main")
	else:
		Debug.post("TEST FAILED (Phase 1): Could not find required inventories for initial merchant.", "Main")
		call_deferred("verify_final_state") # Proceed to verification to log failure
		return

	# Phase 2: Unstage and restage the player to test persistence
	Debug.post("\n[Phase 2: Unstage and Restage Player]", "Main")
	EntityManager.unstage_entity(player_id)
	EntityManager.stage_entity(player_id)
	Debug.post("Player unstaged and restaged.", "Main")

	# Phase 3: Command the player to move to the destination marker
	Debug.post("\n[Phase 3: Player Movement Test]", "Main")
	var player_nav_comp = EntityManager.get_entity_component(player_id, "NavigationComponent")
	var destination_marker_node = get_node_or_null("test_destination_marker")
	
	if is_instance_valid(player_nav_comp) and is_instance_valid(destination_marker_node):
		Debug.post("Commanding player to move to destination marker at: %s" % destination_marker_node.global_position, "Main")
		player_nav_comp.set_target_location(destination_marker_node.global_position)
		
		# Connect to the destination_reached signal to proceed to the next phase.
		# Ensure we only connect once to prevent duplicate signal connections on multiple runs/re-stages.
		if not player_nav_comp.destination_reached.is_connected(Callable(self, "_on_player_movement_complete")):
			player_nav_comp.destination_reached.connect(Callable(self, "_on_player_movement_complete"))
		if not player_nav_comp.pathfinding_failed.is_connected(Callable(self, "_on_player_movement_failed")):
			player_nav_comp.pathfinding_failed.connect(Callable(self, "_on_player_movement_failed"))
	else:
		Debug.post("TEST FAILED (Phase 3): Could not find player NavigationComponent or destination marker.", "Main")
		call_deferred("verify_final_state") # Proceed to verification to log failure
		return

func _on_player_movement_complete() -> void:
	Debug.post("\n[Phase 3: Player movement complete!]", "Main")
	# Disconnect signals to prevent them from firing multiple times if the player moves again.
	var player_nav_comp = EntityManager.get_entity_component(player_id, "NavigationComponent")
	if is_instance_valid(player_nav_comp):
		if player_nav_comp.destination_reached.is_connected(Callable(self, "_on_player_movement_complete")):
			player_nav_comp.destination_reached.disconnect(Callable(self, "_on_player_movement_complete"))
		if player_nav_comp.pathfinding_failed.is_connected(Callable(self, "_on_player_movement_failed")):
			player_nav_comp.pathfinding_failed.disconnect(Callable(self, "_on_player_movement_failed"))

	# Proceed to final verification.
	call_deferred("verify_final_state")

func _on_player_movement_failed() -> void:
	Debug.post("\n[Phase 3: Player movement FAILED!]", "Main")
	# Disconnect signals.
	var player_nav_comp = EntityManager.get_entity_component(player_id, "NavigationComponent")
	if is_instance_valid(player_nav_comp):
		if player_nav_comp.destination_reached.is_connected(Callable(self, "_on_player_movement_complete")):
			player_nav_comp.destination_reached.disconnect(Callable(self, "_on_player_movement_complete"))
		if player_nav_comp.pathfinding_failed.is_connected(Callable(self, "_on_player_movement_failed")):
			player_nav_comp.pathfinding_failed.disconnect(Callable(self, "_on_player_movement_failed"))
			
	# Proceed to final verification, indicating failure.
	call_deferred("verify_final_state")


func verify_final_state() -> void:
	Debug.post("\n--- Running Final Verification Phase ---", "Main")
	var player_inventory = EntityManager.get_entity_component(player_id, "InventoryComponent")
	var player_tags = EntityManager.get_entity_component(player_id, "TagComponent")
	
	var inventory_ok = player_inventory and player_inventory.get_item_count("consumable/apple") == 1
	var tag_ok = player_tags and player_tags.has_tag("reputation/valued_customer")
	
	if inventory_ok:
		Debug.post("VERIFICATION PASSED: Player's inventory correctly contains 1 apple.", "Main")
	else:
		Debug.post("VERIFICATION FAILED: Player's inventory state was not preserved.", "Main")
		
	if tag_ok:
		Debug.post("VERIFICATION PASSED: Player correctly has the 'valued_customer' tag.", "Main")
	else:
		Debug.post("VERIFICATION FAILED: Player's dynamic tag was not preserved.", "Main")
		
	if inventory_ok and tag_ok:
		Debug.post("\n--- Grand Integration Test Complete: SUCCESS ---", "Main")
	else:
		Debug.post("\n--- Grand Integration Test Complete: FAILURE ---", "Main")
