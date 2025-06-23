extends Node3D

var guard_instance_id: String

func _ready() -> void:
	print("Main scene ready. Testing staging and unstaging...")
	call_deferred("run_test")

func run_test() -> void:
	# --- Phase 1: Spawn the guard ---
	print("\n--- Phase 1: Spawning Guard ---")
	guard_instance_id = EntityManager.request_new_entity("characters/town_guard", Vector3.ZERO)
	
	# Create a timer that will wait for 30 real seconds (5 in-game hours)
	var timer = get_tree().create_timer(30.0)
	# When the timer finishes, it will call the _on_despawn_timer_timeout function.
	timer.timeout.connect(_on_despawn_timer_timeout)
	
	print("Guard spawned. Waiting 30 seconds (5 game hours) before unstaging...")


func _on_despawn_timer_timeout() -> void:
	# --- Phase 2: Unstage the guard ---
	print("\n--- Phase 2: Unstaging Guard ---")
	EntityManager.unstage_entity(guard_instance_id)
	
	# Wait 2 seconds before bringing them back.
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_on_respawn_timer_timeout)


func _on_respawn_timer_timeout() -> void:
	# --- Phase 3: Stage the guard again ---
	print("\n--- Phase 3: Staging Guard Again ---")
	EntityManager.stage_entity(guard_instance_id)
	
	print("\n--- Test Complete ---")
	print("Check the log to see that the guard's state was saved and that they respawned.")
