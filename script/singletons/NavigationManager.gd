extends Node

var _nav_region: NavigationRegion3D

func register_nav_region(region: NavigationRegion3D) -> void:
	if is_instance_valid(region):
		_nav_region = region
		Debug.post("Successfully registered NavigationRegion3D.", "NavigationManager")
	else:
		printerr("NavigationManager: Attempted to register an invalid NavigationRegion3D.")


func bake_nav_mesh_from_group(group_name: String) -> void:
	if not is_instance_valid(_nav_region):
		printerr("NavigationManager: NavigationRegion3D node is not available. Cannot bake mesh.")
		return

	# We must create a NavigationMesh resource and assign it to the region
	# before we can tell it to bake.
	var nav_mesh = NavigationMesh.new()
	_nav_region.navigation_mesh = nav_mesh

	Debug.post("Baking navigation mesh for region. Using geometry from group: %s" % group_name, "NavigationManager")
	_nav_region.bake_navigation_mesh(true)
	Debug.post("Navigation mesh bake initiated.", "NavigationManager")
