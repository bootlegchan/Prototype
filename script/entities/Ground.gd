# script/entities/Ground.gd
extends StaticBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	# This pattern ensures the manager is ready before we try to use it.
	if Engine.has_singleton("NavigationManager"):
		# We register our own mesh with the manager.
		NavigationManager.register_walkable_surface(mesh_instance.mesh, global_transform)
	else:
		# If the manager isn't ready for some reason, defer the call.
		call_deferred("register_with_nav_manager")

func register_with_nav_manager() -> void:
	if Engine.has_singleton("NavigationManager"):
		NavigationManager.register_walkable_surface(mesh_instance.mesh, global_transform)
