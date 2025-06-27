extends Node

# This system resolves scheduling conflicts.
# It returns the full dictionary of the winning activity.
func resolve(potential_activities: Array[Dictionary]) -> Dictionary:
	if potential_activities.is_empty():
		# --- FIX: Return an empty dictionary if there are no activities ---
		return {}
		
	if potential_activities.size() == 1:
		return potential_activities[0]

	print("[CONFLICT] Resolving: %s" % str(potential_activities))
	var winning_activity = potential_activities[0]
	for i in range(1, potential_activities.size()):
		if potential_activities[i].get("priority", 0) > winning_activity.get("priority", 0):
			winning_activity = potential_activities[i]
			
	print("[CONFLICT] Resolution: '%s' wins." % str(winning_activity))
	return winning_activity
