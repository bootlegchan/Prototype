extends Node3D

var player_id = "player_character"
var merchant_id = ""

func _ready() -> void:
	print("Main scene ready. Starting Grand Integration Test.")
	# Set time to just before the market opens
	TimeSystem.current_hour = 9
	TimeSystem.current_minute = 58
	
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		time_system._seconds_per_minute = 0.1 # Fast, but observable
	
	EventSystem.subscribe("entity_staged", Callable(self, "_on_entity_staged"))
	
	# Wait for the merchant to spawn and then run the test
	var timer = get_tree().create_timer(4.0) # 4 real seconds should be enough
	timer.timeout.connect(run_interaction_phase)

func _on_entity_staged(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "")
	if instance_id.begins_with("merchant"):
		merchant_id = instance_id
		print("[TEST] Merchant has spawned with ID: '%s'" % merchant_id)

func run_interaction_phase() -> void:
	if merchant_id.is_empty():
		print("TEST FAILED: Merchant did not spawn in time.")
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
	
	var inventory_ok = false
	var tag_ok = false
	
	if player_inventory and player_inventory.get_item_count("consumable/apple") == 1:
		inventory_ok = true
		print("VERIFICATION PASSED: Player's inventory correctly contains 1 apple.")
	else:
		print("VERIFICATION FAILED: Player's inventory state was not preserved.")
		
	if player_tags and player_tags.has_tag("reputation/valued_customer"):
		tag_ok = true
		print("VERIFICATION PASSED: Player correctly has the 'valued_customer' tag.")
	else:
		print("VERIFICATION FAILED: Player's dynamic tag was not preserved.")
		
	if inventory_ok and tag_ok:
		print("\n--- Grand Integration Test Complete: SUCCESS ---")
	else:
		print("\n--- Grand Integration Test Complete: FAILURE ---")
