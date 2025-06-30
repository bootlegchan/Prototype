# script/entities/Ground.gd
extends StaticBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _navigation_region_rid: RID

func _ready() -> void:
	print("Ground.gd: _ready called for entity '%s'." % name)

	# Apply a simple solid color material in code
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.3, 0.5, 0.3, 1) # A simple green/grey color
	
	if is_instance_valid(mesh_instance):
		print("Ground.gd: MeshInstance is valid.")
		if mesh_instance.mesh is Mesh:
			print("Ground.gd: Mesh is valid.")
			mesh_instance.set_surface_override_material(0, ground_material)
			mesh_instance.material_override = ground_material # Fallback
			print("Ground.gd: Attempted to apply material.")
			mesh_instance.add_to_group("walkable_geometry")
			print("Ground.gd: Added MeshInstance3D to 'walkable_geometry' group.")
		else:
			printerr("Ground.gd: Mesh is not valid on MeshInstance.")
	else:
		printerr("Ground.gd: MeshInstance is not valid.")

	# Register with the navigation manager
	# --- THIS IS THE CHANGE ---
	# Get the NavigationManager singleton instance.
	var nav_manager_node = get_node_or_null("/root/NavigationManager")
	if is_instance_valid(nav_manager_node):
		if is_instance_valid(mesh_instance) and mesh_instance.mesh is Mesh:
			print("Ground.gd: Registering walkable surface with NavigationManager.")
			_navigation_region_rid = nav_manager_node.create_and_register_walkable_surface_region(mesh_instance.mesh, global_transform)
			print("Ground.gd: Registered walkable surface with NavigationManager. Region RID: %s" % _navigation_region_rid)
		else:
			printerr("Ground.gd: MeshInstance or Mesh is invalid, cannot register walkable surface.")
	else:
		# Defer registration if the singleton isn't ready yet.
		call_deferred("register_with_nav_manager")
	# --- END OF CHANGE ---

func register_with_nav_manager() -> void:
	# --- THIS IS THE CHANGE ---
	# Get the NavigationManager singleton instance in the deferred call.
	var nav_manager_node = get_node_or_null("/root/NavigationManager")
	if is_instance_valid(nav_manager_node):
		if is_instance_valid(mesh_instance) and mesh_instance.mesh is Mesh:
			print("Ground.gd: Registering walkable surface (deferred). Mesh: %s, Transform: %s" % [mesh_instance.mesh, global_transform])
			_navigation_region_rid = nav_manager_node.create_and_register_walkable_surface_region(mesh_instance.mesh, global_transform)
			print("Ground.gd: Registered walkable surface with NavigationManager (deferred). Region RID: %s" % _navigation_region_rid)
		else:
			printerr("Ground.gd: MeshInstance or Mesh is invalid, cannot register walkable surface (deferred call).")
	else:
		printerr("Ground.gd: NavigationManager singleton not available for deferred call.")
	# --- END OF CHANGE ---
