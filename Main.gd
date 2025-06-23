extends Node3D

func _ready() -> void:
	print("Main scene ready. Requesting initial spawn from SpawningSystem...")
	
	# We defer the call to ensure all singletons are fully initialized and in the tree.
	call_deferred("request_spawn")


func request_spawn() -> void:
	# --- THIS IS THE FIX ---
	# Get a direct and safe reference to the SpawningSystem singleton.
	var spawning_system = get_node_or_null("/root/SpawningSystem")
	
	if spawning_system:
		# Tell the SpawningSystem which layout to load.
		# The SpawningSystem will then correctly call the EntityManager.
		spawning_system.execute_spawn_list("initial_town_square")
	else:
		printerr("FATAL: SpawningSystem singleton not found at /root/SpawningSystem!")
