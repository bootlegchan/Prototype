extends Node3D

var player_id = "player_character"
var initial_merchant_id = "test_merchant" # The merchant spawned from world_state.json

# This flag ensures our test logic runs only once after initial setup.
var setup_complete = false

func _ready() -> void:
	Debug.post("Main scene ready. Starting Phase 1 Test.", "Main")

	# 1. Register the NavRegion with the NavigationManager as soon as the scene is ready.
	# This is a general setup step required for navigation features later.
	var nav_region = get_node_or_null("NavRegion")
	if is_instance_valid(nav_region):
		NavigationManager.register_nav_region(nav_region)
	else:
		printerr("Main.gd: Could not find NavRegion child node! Navigation will not function.")

	# 2. Set Time System for rapid testing.
	# This ensures the test runs quickly, as TimeSystem affects scheduling and movement delays.
	if TimeSystem.has_method("_set_seconds_per_minute"):
		TimeSystem._set_seconds_per_minute(0.01)
	else:
		TimeSystem._seconds_per_minute = 0.01

	# 3. Wait for all initial world_state entities to be staged.
	# We rely on EntityManager to stage everything before we proceed.
	# The EntityManager already calls bake_nav_mesh_after_staging() which is deferred.
	# A small timer ensures all systems have processed their _ready/deferred calls.
	await get_tree().create_timer(0.1).timeout # Wait for 0.1 seconds after all singletons are ready.

	Debug.post("Phase 1: Initial setup complete. Running Player Interaction & Persistence Test.", "Main")
	run_phase_1_player_interaction_and_persistence()


func run_phase_1_player_interaction_and_persistence() -> void:
	if setup_complete:
		return
	setup_complete = true

	Debug.post("\n--- Phase 1: Player Interaction & Persistence Test ---", "Main")
	
	var player_inventory = EntityManager.get_entity_component(player_id, "InventoryComponent")
	var initial_merchant_inventory = EntityManager.get_entity_component(initial_merchant_id, "InventoryComponent")
	
	var pre_check_passed = true

	if not is_instance_valid(player_inventory):
		Debug.post("TEST FAILED (Phase 1): Player InventoryComponent not found.", "Main")
		pre_check_passed = false
	elif player_inventory.get_item_count("consumable/apple") != 0:
		Debug.post("TEST FAILED (Phase 1): Player initial apple count incorrect. (Expected 0, Got %s)" % player_inventory.get_item_count("consumable/apple"), "Main")
		pre_check_passed = false
	else:
		Debug.post("Pre-check PASSED: Player initially has no apple.", "Main")

	if not is_instance_valid(initial_merchant_inventory):
		Debug.post("TEST FAILED (Phase 1): Initial Merchant InventoryComponent not found.", "Main")
		pre_check_passed = false
	elif initial_merchant_inventory.get_item_count("consumable/apple") != 1:
		Debug.post("TEST FAILED (Phase 1): Initial merchant apple count incorrect. (Expected 1, Got %s)" % initial_merchant_inventory.get_item_count("consumable/apple"), "Main")
		pre_check_passed = false
	else:
		Debug.post("Pre-check PASSED: Initial merchant has 1 apple.", "Main")

	if not pre_check_passed:
		verify_final_state_phase_1(false, false)
		return

	Debug.post("Attempting: Player buys 1 apple from initial merchant ('%s')." % initial_merchant_id, "Main")
	InventoryComponent.transfer_item(initial_merchant_inventory, player_inventory, "consumable/apple", 1)
	EntityManager.add_tag_to_entity(player_id, "reputation/valued_customer")
	Debug.post("Interaction: Player attempted to buy apple. Player inventory now: %s" % player_inventory.get_item_count("consumable/apple"), "Main")

	Debug.post("Attempting: Unstage and Restage Player ('%s') to test persistence." % player_id, "Main")
	EntityManager.unstage_entity(player_id)
	EntityManager.stage_entity(player_id)
	
	await get_tree().create_timer(0.1).timeout
	player_inventory = EntityManager.get_entity_component(player_id, "InventoryComponent")
	var player_tags = EntityManager.get_entity_component(player_id, "TagComponent")

	var inventory_persisted_ok = false
	if is_instance_valid(player_inventory):
		inventory_persisted_ok = player_inventory.get_item_count("consumable/apple") == 1
	else:
		Debug.post("VERIFICATION FAILED (Phase 1): Player InventoryComponent NOT valid after restage.", "Main")
		
	var tag_persisted_ok = false
	if is_instance_valid(player_tags):
		tag_persisted_ok = player_tags.has_tag("reputation/valued_customer")
	else:
		Debug.post("VERIFICATION FAILED (Phase 1): Player TagComponent NOT valid after restage.", "Main")

	verify_final_state_phase_1(inventory_persisted_ok, tag_persisted_ok)


func verify_final_state_phase_1(inventory_ok: bool, tag_ok: bool) -> void:
	Debug.post("\n--- Phase 1: Final Verification ---", "Main")
	
	if inventory_ok:
		Debug.post("VERIFICATION PASSED: Player's inventory correctly persists 1 apple.", "Main")
	else:
		var current_apple_count = "N/A"
		var current_player_inventory_comp = EntityManager.get_entity_component(player_id, "InventoryComponent")
		if is_instance_valid(current_player_inventory_comp):
			current_apple_count = str(current_player_inventory_comp.get_item_count("consumable/apple"))
		Debug.post("VERIFICATION FAILED: Player's inventory state was NOT preserved. (Expected 1, Got %s)" % current_apple_count, "Main")
		
	if tag_ok:
		Debug.post("VERIFICATION PASSED: Player correctly persists 'valued_customer' tag.", "Main")
	else:
		var current_player_tags_comp = EntityManager.get_entity_component(player_id, "TagComponent")
		var current_tags_str = "N/A"
		if is_instance_valid(current_player_tags_comp):
			current_tags_str = str(current_player_tags_comp.tags.keys())
		Debug.post("VERIFICATION FAILED: Player's dynamic tag was NOT preserved. (Expected 'valued_customer', Has %s)" % current_tags_str, "Main")
		
	if inventory_ok and tag_ok:
		Debug.post("\n--- Phase 1 Test Complete: SUCCESS ---", "Main")
	else:
		Debug.post("\n--- Phase 1 Test Complete: FAILURE ---", "Main")

	# For now, end the test here. In subsequent steps, we'll chain to Phase 2.
	# get_tree().quit() # Uncomment to quit automatically after this phase.
