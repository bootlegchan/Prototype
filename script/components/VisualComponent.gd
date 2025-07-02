class_name VisualComponent
extends BaseComponent

func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called.", "VisualComponent on '%s'" % _entity_name)

	if is_instance_valid(_entity_root):
		for child in _entity_root.get_children():
			if child is MeshInstance3D:
				child.queue_free()
	Debug.post("Cleared old visuals.", "VisualComponent on '%s'" % _entity_name)

	if data.has("asset_path"):
		var asset_path = data.get("asset_path")
		if asset_path:
			var scene = load(asset_path)
			if scene:
				var instance = scene.instantiate()
				_entity_root.add_child(instance)
				Debug.post("Instanced scene '%s' onto root." % asset_path, "VisualComponent on '%s'" % _entity_name)
			else:
				printerr("VisualComponent on '%s': Failed to load scene at '%s'." % [_entity_name, asset_path])
		return

	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	Debug.post("Created new MeshInstance3D and StandardMaterial3D.", "VisualComponent on '%s'" % _entity_name)

	if data.has("color"):
		material.albedo_color = Color(data["color"])
		Debug.post("Set color to %s." % data["color"], "VisualComponent on '%s'" % _entity_name)

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
		Debug.post("Set shape to %s." % shape_name, "VisualComponent on '%s'" % _entity_name)
	else:
		mesh_instance.mesh = BoxMesh.new()

	if is_instance_valid(mesh_instance.mesh):
		mesh_instance.set_surface_override_material(0, material)

	if is_instance_valid(_entity_root):
		_entity_root.add_child(mesh_instance)
		Debug.post("Added MeshInstance3D as child of root.", "VisualComponent on '%s'" % _entity_name)
	else:
		printerr("VisualComponent on '%s': Entity root is not valid. Cannot add visual." % _entity_name)
