extends Node3D

var player_id = "player_character"
var merchant_id = ""
var test_phase_complete = false # A flag to prevent the test from running multiple times

func _ready() -> void:
	# --- THIS IS THE FIX ---
	# Get the NavRegion node and register it with the manager.
	# This must be done BEFORE anything tries to use the nav system.
	var nav_region = get_node_or_null("NavRegion")
	if is_instance_valid(nav_region):
		NavigationManager.register_nav_region(nav_region)
	else:
		printerr("Main.gd: Could not find NavRegion child node!")
	# --- END OF FIX ---

	print("Main scene ready. Starting Grand Integration Test.")
	
	# Set time to just before the market opens.
	TimeSystem.current_hour = 9
	TimeSystem.current_minute = 58
	
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		# Set a very fast time scale so 10:00 arrives almost instantly.
		time_system._seconds_per_minute = 0.01

	# Listen for the specific entity we are waiting for.
	EventSystem.subscribe("entity_staged", Callable(self, "_on_entity_staged"))
	print("Test is now waiting for the scheduler to spawn the merchant...")


func _on_entity_staged(payload: Dictionary) -> void:
	# This function will be called for every entity that spawns.
	# We only care about the merchant for this test.
	var instance_id = payload.get("instance_id", "")
	
	# Check if this is the merchant and if we haven't already run the test.
	if instance_id.begins_with("merchant") and not test_phase_complete:
		test_phase_complete = true # Set the flag to true
		merchant_id = instance_id
		print("[TEST] The expected merchant has spawned with ID: '%s'" % merchant_id)
		
		# Now that we know the merchant exists, proceed to the next phase of the test.
		# Use call_deferred to ensure we don't do this in the middle of the event signal.
		call_deferred("run_interaction_phase")


func run_interaction_phase() -> void:
	if merchant_id.is_empty():
		# This case is a failsafe.
		print("TEST FAILED: Interaction phase ran before merchant was spawned.")
		return

	print("\n--- Running Interaction Phase ---")
	
	# 1. Simulate Player buying an apple from the Merchant
	var player_inventory = EntityManager.get_entity_component(player_id, "InventoryComponent")
	var merchant_inventory = EntityManager.get_entity_component(merchant_id, "InventoryComponent")
	
	if player_inventory and merchant_inventory:
		print("\n[Phase 1: Player buys an apple]")
		InventoryComponent.transfer_item(merchant_inventory, player_inventory, "consumable/apple", 1)
		EntityManager.add_tag_to_entity(player_id, "reputation/valued_customer")
	else:
		print("TEST FAILED: Could not find required inventories.")
		return

	# 2. Unstage and restage the player to test persistence
	print("\n[Phase 2: Unstage and Restage Player]")
	EntityManager.unstage_entity(player_id)
	EntityManager.stage_entity(player_id)
	
	call_deferred("verify_final_state")


func verify_final_state() -> void:
	print("\n[Phase 3: Verifying Final State]")
	var player_inventory = EntityManager.get_entity_component(player_id, "InventoryComponent")
	var player_tags = EntityManager.get_entity_component(player_id, "TagComponent")
	
	var inventory_ok = player_inventory and player_inventory.get_item_count("consumable/apple") == 1
	var tag_ok = player_tags and player_tags.has_tag("reputation/valued_customer")
	
	if inventory_ok:
		print("VERIFICATION PASSED: Player's inventory correctly contains 1 apple.")
	else:
		print("VERIFICATION FAILED: Player's inventory state was not preserved.")
		
	if tag_ok:
		print("VERIFICATION PASSED: Player correctly has the 'valued_customer' tag.")
	else:
		print("VERIFICATION FAILED: Player's dynamic tag was not preserved.")
		
	if inventory_ok and tag_ok:
		print("\n--- Grand Integration Test Complete: SUCCESS ---")
	else:
		print("\n--- Grand Integration Test Complete: FAILURE ---")
