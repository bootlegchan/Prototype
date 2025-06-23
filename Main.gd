extends Node3D

func _ready() -> void:
	print("Main scene ready. Spawning from categorized definitions...")
	
	if not EntityFactory:
		printerr("EntityFactory not found!")
		return

	# Spawn using the new, full-path definition IDs.
	EntityFactory.spawn_entity("characters/player", Vector3.ZERO)
	EntityFactory.spawn_entity("scenery/buildings/house", Vector3(0, 0, -20))
	EntityFactory.spawn_entity("scenery/props/market_stall", Vector3(-20, 0, 0))
	EntityFactory.spawn_entity("scenery/lighting/lamppost", Vector3(20, 0, 0))
	EntityFactory.spawn_entity("characters/town_guard", Vector3(0, 0, 20))

	print("Categorized spawn test completed.")
