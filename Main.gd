extends Node3D

func _ready() -> void:
	print("Main scene ready. Requesting initial spawn...")
	
	# We just tell the SpawningSystem which layout to load.
	# We use call_deferred to ensure all singletons are ready.
	call_deferred("request_spawn")

func request_spawn() -> void:
	SpawningSystem.execute_spawn_list("initial_town_square")
