# script/singletons/ConflictResolutionSystem.gd
extends Node

# This system resolves scheduling conflicts.
# It returns the full dictionary of the winning activity.
func resolve(potential_activities: Array[Dictionary]) -> Dictionary:
	# --- DEBUG PRINT ---
	print("ConflictResolutionSystem: resolve called with %d potential activities: %s" % [potential_activities.size(), potential_activities]) # Keeping activity details
	# --- END DEBUG PRINT ---
	if potential_activities.is_empty():
		return {}

	if potential_activities.size() == 1:
		# --- DEBUG PRINT ---
		print("ConflictResolutionSystem: Resolved to single activity: %s" % potential_activities[0])
		# --- END DEBUG PRINT ---
		return potential_activities[0]

	print("[CONFLICT] Resolving conflicts among: %s" % str(potential_activities))
	var winning_activity = potential_activities[0]
	for i in range(1, potential_activities.size()):
		if potential_activities[i].get("priority", 0) > winning_activity.get("priority", 0):
			winning_activity = potential_activities[i]

	print("[CONFLICT] Resolution: '%s' wins." % str(winning_activity))
	# --- DEBUG PRINT ---
	print("ConflictResolutionSystem: Resolved to winning activity: %s" % winning_activity)
	# --- END DEBUG PRINT ---
	return winning_activity
