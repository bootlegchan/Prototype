extends Node3D

func _ready() -> void:
	print("Main scene ready. Testing layered schedule conflicts.")
	
	# Spawn our test character. The simulation will run automatically
	# from the start time defined in time_settings.json.
	EntityManager.request_new_entity("characters/alex_smith", Vector3.ZERO)
	
	print("\n--- Simulation running. Watch the log as time passes. ---")
