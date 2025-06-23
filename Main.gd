extends Node3D

func _ready() -> void:
	print("Main scene ready. Spawning and testing state system...")
	
	if not EntityFactory:
		printerr("EntityFactory not found!")
		return

	var guard = EntityFactory.spawn_entity("characters/town_guard", Vector3(5, 0, 0))
	
	# We wait a frame to ensure the node is fully ready.
	call_deferred("test_guard_state", guard)

func test_guard_state(guard_node: Node3D) -> void:
	if not is_instance_valid(guard_node):
		print("Guard node is not valid.")
		return
	
	var logic_node = guard_node.get_node_or_null("EntityLogic")
	if logic_node:
		var state_comp = logic_node.get_component("StateComponent")
		if state_comp:
			print("\n--- Found guard's StateComponent. Testing states. ---")
			
			# 1. Read the initial state
			var initial_activity = state_comp.get_state("activity", "none")
			print("Guard's initial activity is: '%s'" % initial_activity)
			
			var initial_mood = state_comp.get_state("mood", "unknown")
			print("Guard's initial mood is: '%s'" % initial_mood)
			
			# 2. Change the state
			print("\nSomething happens... The player gives the guard a gift.")
			state_comp.set_state("mood", "happy")
			state_comp.set_state("activity", "chatting_with_player")
			
			# 3. Read the new state
			var new_mood = state_comp.get_state("mood")
			print("Guard's new mood is: '%s'" % new_mood)
			
			print("--- State test complete. ---\n")
		else:
			print("Could not find StateComponent on the guard.")
	else:
		print("Could not find EntityLogic node on the guard.")
