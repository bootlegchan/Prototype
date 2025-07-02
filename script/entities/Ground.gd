extends StaticBody3D

# This script serves as the correct base type for the Ground scene.
# All navigation registration and baking is now handled automatically
# by the EntityManager and NavigationManager singletons.

func _ready() -> void:
	# You can add any specific logic for the ground entity here in the future,
	# but it no longer needs to handle its own navigation registration.
	pass
