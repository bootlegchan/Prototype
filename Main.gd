extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Main scene ready. Beginning test spawn...")
	
	# Check if the factory is ready (it should be, as an autoload)
	if not EntityFactory:
		printerr("EntityFactory not found!")
		return
	
	# Spawn a player entity at the world origin
	EntityFactory.spawn_entity("player", Vector3.ZERO)
	
	# Spawn two goblin entities at different positions
	EntityFactory.spawn_entity("goblin", Vector3(3, 0, 0))
	EntityFactory.spawn_entity("goblin", Vector3(-3, 0, 0))
	
	print("Test spawn completed.")
