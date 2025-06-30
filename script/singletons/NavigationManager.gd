# script/singletons/NavigationManager.gd
extends Node

# The unique RID for our game's main navigation map.
var _map: RID

func _ready() -> void:
	# Create a new navigation map on the NavigationServer.
	_map = NavigationServer3D.map_create()
	# Set some default parameters. Cell size is important for performance and accuracy.
	NavigationServer3D.map_set_cell_size(_map, 0.25)
	NavigationServer3D.map_set_edge_connection_margin(_map, 0.25)
	# Make this map the default active map for all pathfinding queries.
	# Note: This doesn't mean agents will use it automatically.
	# Agents (or our components) must be explicitly told which map to use.
	NavigationServer3D.map_set_active(_map, true)
	print("NavigationManager ready. Main navigation map created.")

# --- THIS IS THE CORRECTED FUNCTION ---
## Called by ground/landscape entities to add their geometry to the navigation map.
func register_walkable_surface(mesh: Mesh, transform: Transform3D) -> void:
	if not mesh is Mesh:
		printerr("NavigationManager: Attempted to register an invalid mesh.")
		return
	
	# 1. Create a new navigation region on the server.
	var region_rid = NavigationServer3D.region_create()
	
	# 2. Assign our main map to this new region.
	NavigationServer3D.region_set_map(region_rid, _map)
	
	# 3. Set the region's transform. For static ground, this is usually the global origin.
	NavigationServer3D.region_set_transform(region_rid, transform)
	
	# 4. Create a new NavigationMesh resource and add the source mesh data to it.
	var nav_mesh = NavigationMesh.new()
	nav_mesh.add_mesh(mesh) # This prepares the mesh data for baking.
	
	# 5. Provide the baked NavigationMesh data to the region.
	NavigationServer3D.region_set_navigation_mesh(region_rid, nav_mesh)

	print("NavigationManager: Registered new walkable surface region.")


## The centralized pathfinding function for all navigation components.
## It queries the server for a path on our main map.
func get_navigation_path(start_position: Vector3, target_position: Vector3) -> PackedVector3Array:
	# This function can be expanded later to allow for different agent sizes, etc.
	# For now, it finds the simplest, most direct path.
	if _map.is_valid():
		# The `true` argument optimizes the path.
		return NavigationServer3D.map_get_path(_map, start_position, target_position, true)
	else:
		printerr("NavigationManager: Map is not valid, cannot get path.")
		return []

## A helper to get the closest valid point on the NavMesh.
## Useful for ensuring targets are on a walkable surface.
func get_closest_point_on_navmesh(to_position: Vector3) -> Vector3:
	if _map.is_valid():
		return NavigationServer3D.map_get_closest_point(_map, to_position)
	else:
		printerr("NavigationManager: Map is not valid, cannot get closest point.")
		return to_position
