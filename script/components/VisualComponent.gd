# script/components/VisualComponent.gd
class_name VisualComponent
extends BaseComponent

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	# Clear any previous visuals if this component is being re-initialized.
	for child in get_children():
		child.queue_free()

	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()

	# Set color from the hex string in the JSON
	if data.has("color"):
		material.albedo_color = Color(data["color"])

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
				push_warning("Unknown visual shape '%s' for entity '%s', defaulting to 'box'." % [shape_name, _entity_name])
				mesh_instance.mesh = BoxMesh.new()
	else:
		# Default to a box if no shape is specified
		mesh_instance.mesh = BoxMesh.new()

	# Apply the material to the mesh instance using the correct Godot 4 property.
	mesh_instance.set_surface_override_material(0, material)
	
	add_child(mesh_instance)
