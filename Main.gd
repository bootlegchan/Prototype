extends Node3D

func _ready() -> void:
	print("Main scene ready. Spawning a scheduled entity.")
	
	if not EntityFactory:
		printerr("EntityFactory not found!")
		return

	EntityFactory.spawn_entity("characters/town_guard", Vector3.ZERO)
	
	print("\n--- Simulation running. Watch the output log as in-game hours pass. ---")
	print("An in-game minute passes every real-world second.")
