class_name VisualComponent
extends BaseComponent

func _load_data(data: Dictionary) -> void:
	print("VisualComponent on '%s': _load_data called." % _entity_name)

	# --- THIS IS THE FIX ---
	# The component now has a direct reference to the entity's 3D root node.
	# We must clear old visuals from the root, not from the component itself.
	if is_instance_valid(_entity_root):
		for child in _entity_root.get_children():
			if child is MeshInstance3D:
				child.queue_free()
	print("VisualComponent on '%s': Cleared old visuals." % _entity_name)

	if data.has("asset_path"):
		var asset_path = data.get("asset_path")
		if asset_path:
			var scene = load(asset_path)
			if scene:
				var instance = scene.instantiate()
				_entity_root.add_child(instance)
				print("VisualComponent on '%s': Instanced scene '%s' onto root." % [_entity_name, asset_path])
			else:
				printerr("VisualComponent on '%s': Failed to load scene at '%s'." % [_entity_name, asset_path])
		return

	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	print("VisualComponent on '%s': Created new MeshInstance3D and StandardMaterial3D." % _entity_name)

	if data.has("color"):
		material.albedo_color = Color(data["color"])
		print("VisualComponent on '%s': Set color to %s." % [_entity_name, data["color"]])

	if data.has("shape"):
		var shape_name = data["shape"]
		match shape_name.to_lower():
			"box": mesh_instance.mesh = BoxMesh.new()
			"sphere": mesh_instance.mesh = SphereMesh.new()
			"cylinder": mesh_instance.mesh = CylinderMesh.new()
			"capsule": mesh_instance.mesh = CapsuleMesh.new()
			_:
				push_warning("VisualComponent on '%s': Unknown shape '%s'." % [_entity_name, shape_name])
				mesh_instance.mesh = BoxMesh.new()
		print("VisualComponent on '%s': Set shape to %s." % [_entity_name, shape_name])
	else:
		mesh_instance.mesh = BoxMesh.new()

	if is_instance_valid(mesh_instance.mesh):
		mesh_instance.set_surface_override_material(0, material)

	# Add the mesh directly to the entity's root 3D node.
	if is_instance_valid(_entity_root):
		_entity_root.add_child(mesh_instance)
		print("VisualComponent on '%s': Added MeshInstance3D as child of root." % _entity_name)
	else:
		printerr("VisualComponent on '%s': Entity root is not valid. Cannot add visual." % _entity_name)
	# --- END OF FIX ---
