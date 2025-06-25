extends Node3D

var player_id: String = "player_character"
var barrel_id: String = "suspicious_barrel"

func _ready() -> void:
	print("Main scene ready. World state loaded. Starting complex test sequence...")
	TimeSystem.current_hour = 8
	TimeSystem.current_minute = 0
	# Wait for the scheduled event to fire.
	# The ScheduleComponent connects to the minute_changed signal.
	# We will wait for the barrel to become active, then interact.
	var timer = get_tree().create_timer(4.0) # ~4 minutes of game time
	timer.timeout.connect(run_interaction_test)

func run_interaction_test() -> void:
	print("\n--- Running Interaction Test ---")
	
	# 1. Simulate player interacting with the barrel
	print("\n[Phase 1: Player interacts with the 'active' barrel]")
	EntityManager.add_tag_to_entity(player_id, "status/cursed")
	
	# 2. Unstage the player to test persistence
	print("\n[Phase 2: Unstaging player]")
	EntityManager.unstage_entity(player_id)
	
	# 3. Stage the player again
	print("\n[Phase 3: Staging player]")
	EntityManager.stage_entity(player_id)
	
	call_deferred("verify_player_state")


func verify_player_state() -> void:
	print("\n[Phase 4: Verifying player's tags after respawn]")
	var player_tag_comp = EntityManager.get_entity_component(player_id, "TagComponent")
	
	if player_tag_comp and player_tag_comp.has_tag("status/cursed"):
		print("VERIFICATION PASSED: Player correctly has the 'cursed' tag.")
	else:
		print("VERIFICATION FAILED: Player is missing the 'cursed' tag after being restaged.")
		
	print("\n--- Complex Test Complete ---")
