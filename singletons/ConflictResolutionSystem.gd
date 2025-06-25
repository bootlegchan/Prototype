extends Node

func resolve(potential_activities: Array[Dictionary]) -> String:
	if potential_activities.is_empty():
		return ""
	if potential_activities.size() == 1:
		return potential_activities[0]["activity_id"]

	print("[CONFLICT] Multiple activities scheduled: %s. Resolving..." % str(potential_activities))
	var winning_activity = potential_activities[0]
	for i in range(1, potential_activities.size()):
		if potential_activities[i]["priority"] > winning_activity["priority"]:
			winning_activity = potential_activities[i]
			
	print("[CONFLICT] Resolution: '%s' wins with priority %s." % [winning_activity["activity_id"], winning_activity["priority"]])
	return winning_activity["activity_id"]
