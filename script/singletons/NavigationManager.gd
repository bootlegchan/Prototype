# script/singletons/NavigationManager.gd
extends Node

var _map: RID
var _created_regions: Array[RID] = [] # Store RIDs of regions we create

func _ready() -> void:
	print("NavigationManager: _ready called. Initializing navigation map.")
	# --- THIS IS THE CHANGE ---
	# Get the NavigationServer3D static class.
	var nav_server = NavigationServer3D
	if NavigationServer3D: # Check if the static class is available (it should be)
		_map = nav_server.map_create()
		nav_server.map_set_cell_size(_map, 0.25)
		nav_server.map_set_edge_connection_margin(_map, 0.25)
		nav_server.map_set_active(_map, true)
		print("NavigationManager: Main navigation map created (RID: %s)." % _map)
	else:
		printerr("NavigationManager: Failed to access NavigationServer3D. Navigation may not work.")
	# --- END OF CHANGE ---

func _exit_tree() -> void:
	print("NavigationManager: _exit_tree called. Attempting cleanup.")
	# --- THIS IS THE CHANGE ---
	# Use the static NavigationServer3D class for cleanup.
	var nav_server = NavigationServer3D
	if is_instance_valid(nav_server):
		print("NavigationManager: NavigationServer3D static class is valid during _exit_tree.")
		# Destroy all created regions
		for region_rid in _created_regions:
			if region_rid.is_valid():
				nav_server.region_destroy(region_rid)
				print("NavigationManager: Destroyed region %s." % region_rid)
		_created_regions.clear()

		# Destroy the main navigation map
		if _map.is_valid():
			nav_server.map_destroy(_map)
			print("NavigationManager: Destroyed navigation map %s." % _map)
	else:
		printerr("NavigationManager: NavigationServer3D static class is NOT valid during _exit_tree. Cannot cleanup RIDs.")
	# --- END OF CHANGE ---


func bake_nav_mesh_from_group(group_name: String) -> void:
	print("NavigationManager: bake_nav_mesh_from_group called for group '%s'." % group_name)

	var nav_server = NavigationServer3D # Access the static class

	# Clean up any previous map and regions
	if _map.is_valid():
		if is_instance_valid(nav_server):
			for region_rid in _created_regions:
				if region_rid.is_valid():
					nav_server.region_destroy(region_rid)
			_created_regions.clear()
			nav_server.map_destroy(_map)
		else:
			printerr("NavigationManager: Could not get NavigationServer3D static class for pre-bake cleanup.")


	# Create the new map
	if is_instance_valid(nav_server):
		_map = nav_server.map_create()
		nav_server.map_set_cell_size(_map, 0.25)
		nav_server.map_set_edge_connection_margin(_map, 0.25)
		nav_server.map_set_active(_map, true)
		print("NavigationManager: New navigation map created for baking (RID: %s)." % _map)
	else:
		printerr("NavigationManager: Could not get NavigationServer3D static class to create map.")
		_map = RID()
		return

	var walkable_meshes: Array = get_tree().get_nodes_in_group(group_name)
	print("NavigationManager: Found %d nodes in group '%s'." % [walkable_meshes.size(), group_name])

	if walkable_meshes.is_empty():
		push_warning("NavigationManager: No nodes found in group '%s' for baking." % group_name)
		return

	if not is_instance_valid(nav_server):
		printerr("NavigationManager: Could not get NavigationServer3D static class for baking regions.")
		return

	var unified_nav_mesh = NavigationMesh.new()
	for mesh_node in walkable_meshes:
		if is_instance_valid(mesh_node) and mesh_node is MeshInstance3D and is_instance_valid(mesh_node.mesh):
			var mesh_transform = mesh_node.global_transform
			unified_nav_mesh.add_mesh(mesh_node.mesh, mesh_transform)
			print("NavigationManager: Added mesh from '%s' to unified NavigationMesh." % mesh_node.name)
		else:
			push_warning("NavigationManager: Node '%s' in group '%s' is not a valid MeshInstance3D with a Mesh, skipping." % [mesh_node.name, group_name])

	if is_instance_valid(nav_server) and unified_nav_mesh.get_meshes().size() > 0:
		var region_rid = nav_server.region_create()
		nav_server.region_set_map(region_rid, _map)
		nav_server.region_set_transform(region_rid, Transform3D.IDENTITY)
		nav_server.region_set_navigation_mesh(region_rid, unified_nav_mesh)
		_created_regions.append(region_rid)
		print("NavigationManager: Created and set NavigationMesh for region %s." % region_rid)
		call_deferred("_check_baked_navmesh_polygons")
	elif is_instance_valid(nav_server):
		push_warning("NavigationManager: No valid meshes found after processing group '%s'. Cannot bake regions." % group_name)
	else:
		printerr("NavigationManager: Could not get NavigationServer3D static class to create region after baking.")

	print("NavigationManager: Baking process finished.")

func _check_baked_navmesh_polygons() -> void:
	if _map.is_valid():
		var nav_server = NavigationServer3D # Access static class
		if is_instance_valid(nav_server):
			var polygon_count = nav_server.map_get_polygon_count(_map)
			print("NavigationManager: Baked NavMesh has %d polygons." % polygon_count)
			if polygon_count == 0:
				push_warning("NavigationManager: NavMesh baked with 0 polygons. Pathfinding will fail.")
		else:
			printerr("NavigationManager: NavigationServer3D singleton not available in _check_baked_navmesh_polygons.")

func get_navigation_path(start_position: Vector3, target_position: Vector3) -> PackedVector3Array:
	if _map.is_valid():
		var entity_name = "N/A"
		if is_instance_valid(get_parent().get_parent()):
			entity_name = get_parent().get_parent().name

		var agent_map_rid = RID()
		var agent_rid = RID()
		if is_instance_valid(get_parent().get_parent()) and get_parent().get_parent().has_method("get_rid"):
			agent_rid = get_parent().get_parent().get_rid()
			NavigationServer3D.agent_set_map(agent_rid, _map)
			agent_map_rid = NavigationServer3D.agent_get_map(agent_rid)

		var agent_map_string = str(agent_map_rid) if agent_map_rid.is_valid() else "N/A (Agent not assigned to a map?)"

		print("NavigationComponent on '%s': Requesting path from %s to %s on map %s. Agent RID: %s" % [entity_name, start_position, target_position, agent_map_string, agent_rid])

		if not agent_map_rid.is_valid():
			push_warning("NavigationManager: Agent '%s' is requesting a path but is not assigned to any map." % entity_name)

		var path = NavigationServer3D.map_get_path(_map, start_position, target_position, true)

		print("NavigationComponent on '%s': Received path with %d points. Path data: %s" % [entity_name, path.size(), str(path)])

		return path
	else:
		printerr("NavigationManager: Map is not valid, cannot get path.")
		return []

func get_closest_point_on_navmesh(to_position: Vector3) -> Vector3:
	if _map.is_valid():
		return NavigationServer3D.map_get_closest_point(_map, to_position)
	else:
		printerr("NavigationManager: Map is not valid, cannot get closest point.")
		return to_position
