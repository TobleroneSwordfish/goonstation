/datum/antagonist/follower
	id = ROLE_FOLLOWER
	display_name = "follower"
	var/datum/mind/target

	is_compatible_with(datum/mind/mind)
		return ishuman(mind.current)

	assign_objectives()
		..()
		for (var/datum/objective/objective in target.objectives)
			var/datum/objective/specialist/follower/new_objective = new(null, src.owner, objective)

/datum/antagonist/follower/flock
	assign_objectives()
		new /datum/objective("Help the Flock accomplish its goals by any means necessary.", src.owner)

/datum/antagonist/follower/blob
	assign_objectives()
		new /datum/objective("Help the Blob accomplish its goals by any means necessary.", src.owner)
