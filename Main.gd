extends Node3D
func _ready() -> void:
	print("Main scene ready. Spawning a nested entity.")
	call_deferred("verify_spawn")
func verify_spawn() -> void:
	var school = EntityManager.get_node_from_instance_id("school_main")
	var classroom = EntityManager.get_node_from_instance_id("Classroom 101")
	if is_instance_valid(school) and is_instance_valid(classroom):
		print("VERIFICATION PASSED: School and Classroom nodes exist.")
		var context_comp = EntityManager.get_entity_component("Classroom 101", "ParentContextComponent")
		if context_comp and context_comp.parent_instance_id == "school_main":
			print("VERIFICATION PASSED: Classroom context correctly points to school.")
		else:
			print("VERIFICATION FAILED: Classroom context is incorrect.")
	else:
		print("VERIFICATION FAILED: School or Classroom did not spawn correctly.")
