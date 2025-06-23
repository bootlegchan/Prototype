extends Node3D

func _ready() -> void:
	print("Main scene ready. Spawning a test scene with a building...")
	
	if not EntityFactory:
		printerr("EntityFactory not found!")
		return

	# Player spawns at the absolute center of the world.
	EntityFactory.spawn_entity("player", Vector3.ZERO)

	# The new house is placed far behind the player.
	EntityFactory.spawn_entity("building_house", Vector3(0, 0, -20))
	
	# The market stall is placed far to the left.
	EntityFactory.spawn_entity("market_stall", Vector3(-20, 0, 0))
	
	# The lamppost is placed far to the right.
	EntityFactory.spawn_entity("lamppost", Vector3(20, 0, 0))
	
	# The Town Guard is placed far in front of the player.
	EntityFactory.spawn_entity("town_guard", Vector3(0, 0, 20))

	print("Building spawn test completed.")
