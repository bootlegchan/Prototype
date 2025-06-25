extends Node3D

func _ready() -> void:
	print("Main scene ready. Testing layered schedule conflicts.")
	
	# Spawn our test character using their new, unique, permanent ID.
	EntityManager.request_new_entity("characters/alex_smith", Vector3.ZERO)
	
	# Set time to a conflict point: Monday at 18:00
	# The student schedule is free, but the cleaner schedule has work.
	TimeSystem.current_year = 1
	TimeSystem.current_month_index = 5 # June
	# Assuming Day 1 is Monday for this test.
	# A more robust TimeSystem would calculate the day of the week.
	TimeSystem.current_day = 1 # A Monday
	TimeSystem.current_hour = 17
	TimeSystem.current_minute = 58
	
	# Speed up time for quick testing.
	# The property must be accessed via the node as it's not a const.
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		time_system._seconds_per_minute = 0.5
