# script/components/VisualComponent.gd
class_name VisualComponent
extends BaseComponent

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	print("VisualComponent on '%s': _load_data called." % _entity_name)

	# Clear any previous visuals if this component is being re-initialized.
	for child in get_children():
		child.queue_free()
	print("VisualComponent on '%s': Cleared old visuals." % _entity_name)

	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	print("VisualComponent on '%s': Created new MeshInstance3D and StandardMaterial3D." % _entity_name)


	# Set color from the hex string in the JSON
	if data.has("color"):
		material.albedo_color = Color(data["color"])
		print("VisualComponent on '%s': Set color to %s." % [_entity_name, data["color"]])
	else:
		print("VisualComponent on '%s': No color specified in data." % _entity_name)


	# Set shape based on the string in the JSON
	if data.has("shape"):
		var shape_name = data["shape"]
		match shape_name.to_lower():
			"box":
				mesh_instance.mesh = BoxMesh.new()
			"sphere":
				mesh_instance.mesh = SphereMesh.new()
			"cylinder":
				mesh_instance.mesh = CylinderMesh.new()
			"capsule":
				mesh_instance.mesh = CapsuleMesh.new()
			_:
				push_warning("VisualComponent on '%s': Unknown visual shape '%s', defaulting to 'box'." % [_entity_name, shape_name])
				mesh_instance.mesh = BoxMesh.new()
		print("VisualComponent on '%s': Set shape to %s. Mesh created: %s" % [_entity_name, shape_name, is_instance_valid(mesh_instance.mesh)]) # Debug print
	else:
		# Default to a box if no shape is specified
		mesh_instance.mesh = BoxMesh.new()
		print("VisualComponent on '%s': No shape specified, defaulting to 'box'. Mesh created: %s" % [_entity_name, is_instance_valid(mesh_instance.mesh)]) # Debug print


	# Apply the material to the mesh instance.
	if is_instance_valid(mesh_instance) and is_instance_valid(mesh_instance.mesh): # Ensure mesh is valid before applying material
		mesh_instance.set_surface_override_material(0, material)
		mesh_instance.material_override = material # Fallback
		print("VisualComponent on '%s': Applied material %s to mesh %s." % [_entity_name, is_instance_valid(material), is_instance_valid(mesh_instance.mesh)]) # Debug print
	else:
		printerr("VisualComponent on '%s': Cannot apply material, MeshInstance or Mesh is invalid." % _entity_name)

	# Add the mesh instance as a child.
	if is_instance_valid(mesh_instance): # Ensure mesh_instance is valid before adding
		add_child(mesh_instance)
		print("VisualComponent on '%s': Added MeshInstance3D as child. Child count: %d" % [_entity_name, get_child_count()]) # Debug print
	else:
		printerr("VisualComponent on '%s': Cannot add MeshInstance3D as child, it is invalid." % _entity_name)
