extends Node

# This system resolves scheduling conflicts.
# It returns the full dictionary of the winning activity.
func resolve(potential_activities: Array[Dictionary]) -> Dictionary:
	Debug.post("resolve called with %d potential activities: %s" % [potential_activities.size(), potential_activities], "ConflictResolutionSystem")
	if potential_activities.is_empty():
		return {}

	if potential_activities.size() == 1:
		Debug.post("Resolved to single activity: %s" % potential_activities[0], "ConflictResolutionSystem")
		return potential_activities[0]

	Debug.post("[CONFLICT] Resolving conflicts among: %s" % str(potential_activities), "ConflictResolutionSystem")
	var winning_activity = potential_activities[0]
	for i in range(1, potential_activities.size()):
		if potential_activities[i].get("priority", 0) > winning_activity.get("priority", 0):
			winning_activity = potential_activities[i]

	Debug.post("[CONFLICT] Resolution: '%s' wins." % str(winning_activity), "ConflictResolutionSystem")
	Debug.post("Resolved to winning activity: %s" % winning_activity, "ConflictResolutionSystem")
	return winning_activity
