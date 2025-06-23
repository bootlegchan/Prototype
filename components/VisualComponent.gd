class_name VisualComponent
extends Node

# This function will be called by the EntityFactory to pass in data from the JSON file.
func initialize(data: Dictionary) -> void:
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
			"capsule": # <-- ADDED THIS NEW SHAPE
				mesh_instance.mesh = CapsuleMesh.new()
			_:
				push_warning("Unknown shape '%s', defaulting to 'box'." % shape_name)
				mesh_instance.mesh = BoxMesh.new()
	else:
		mesh_instance.mesh = BoxMesh.new()

	# Apply the material to the mesh instance using the correct Godot 4 property.
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
