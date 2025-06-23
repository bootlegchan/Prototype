extends Node3D

var mimic_instance_id: String

func _ready() -> void:
	print("Main scene ready. Testing dynamic component modification...")
	call_deferred("run_test")


func run_test() -> void:
	# --- Phase 1: Spawn a normal barrel ---
	print("\n--- Phase 1: Spawning Barrel ---")
	mimic_instance_id = EntityManager.request_new_entity("scenery/props/barrel", Vector3.ZERO)
	
	# Wait a frame to ensure the barrel is fully in the tree before modifying it.
	call_deferred("transform_barrel_into_mimic")


func transform_barrel_into_mimic() -> void:
	# --- Phase 2: Dynamically turn it into a mimic ---
	print("\n--- Phase 2: Transforming Barrel into a Mimic ---")
	
	# Add a StateComponent so it can have states.
	EntityManager.add_component_to_entity(mimic_instance_id, "StateComponent", {"initial_state": "common/sleeping"})
	
	# Add a hostile tag.
	# Note: This currently overwrites existing tags. A more robust TagComponent
	# would have an `add_tags` method. For this test, it's fine.
	EntityManager.add_component_to_entity(mimic_instance_id, "TagComponent", {"tags": ["roles/hostile"]})
	
	# Wait a moment, then unstage it.
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_on_despawn_timer_timeout)


func _on_despawn_timer_timeout() -> void:
	# --- Phase 3: Unstage the mimic barrel ---
	print("\n--- Phase 3: Unstaging Mimic Barrel ---")
	EntityManager.unstage_entity(mimic_instance_id)
	
	# Wait a moment, then bring it back.
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_on_respawn_timer_timeout)


func _on_respawn_timer_timeout() -> void:
	# --- Phase 4: Stage the mimic barrel again ---
	print("\n--- Phase 4: Staging Mimic Barrel Again ---")
	EntityManager.stage_entity(mimic_instance_id)
	
	# Verify it came back with its new components.
	call_deferred("verify_mimic_state")


func verify_mimic_state() -> void:
	var mimic_node = EntityManager.get_node_from_instance_id(mimic_instance_id)
	if not is_instance_valid(mimic_node):
		print("VERIFICATION FAILED: Mimic node is not valid.")
		return
		
	var logic_node = mimic_node.get_node("EntityLogic")
	if logic_node:
		var state_comp = logic_node.get_component("StateComponent")
		var tag_comp = logic_node.get_component("TagComponent")
		
		if state_comp and tag_comp:
			print("\nVERIFICATION PASSED: Restaged entity has both StateComponent and TagComponent.")
			if tag_comp.has_tag("roles/hostile"):
				print("VERIFICATION PASSED: Restaged entity correctly has the 'hostile' tag.")
			else:
				print("VERIFICATION FAILED: Restaged entity is missing the 'hostile' tag.")
		else:
			print("VERIFICATION FAILED: Restaged entity is missing dynamically added components.")
	
	print("\n--- Dynamic Modification Test Complete ---")
