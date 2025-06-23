extends Node3D

func _ready() -> void:
	print("Main scene ready. Spawning and testing state machine...")
	
	var guard = EntityFactory.spawn_entity("characters/town_guard")
	call_deferred("test_guard_state_machine", guard)

func test_guard_state_machine(guard_node: Node3D) -> void:
	if not is_instance_valid(guard_node): return
	
	var logic_node = guard_node.get_node_or_null("EntityLogic")
	if logic_node:
		var state_comp = logic_node.get_component("StateComponent")
		if state_comp:
			print("\n--- Testing Guard State Machine ---")
			# 1. Check initial state
			var initial_state_id = state_comp.get_current_state_id()
			var initial_state_data = state_comp.get_current_state_data()
			print("Guard's initial state is '%s', which is interruptible: %s" % [initial_state_id, initial_state_data.get("interruptible")])

			# 2. Player talks to the guard
			print("\nPlayer initiates conversation...")
			state_comp.push_state("guard/chatting")
			
			var new_state_id = state_comp.get_current_state_id()
			var new_state_data = state_comp.get_current_state_data()
			print("Guard is now in state '%s', which allows movement: %s" % [new_state_id, new_state_data.get("can_move", true)])
			
			# 3. Conversation ends
			print("\nConversation ends, returning to previous state...")
			state_comp.pop_state()
			
			var final_state_id = state_comp.get_current_state_id()
			print("Guard has returned to state: '%s'" % final_state_id)
			print("--- State Machine Test Complete ---\n")
