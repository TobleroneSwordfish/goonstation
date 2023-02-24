

/datum/spawn_event
	var/thing_to_spawn = null
	///If true, only a single ghost will be spawned and placed directly into the mob
	var/spawn_directly = FALSE
	///A custom location to spawn the mobs (can also be a landmark string or list of landmarks)
	var/turf/spawn_loc = LANDMARK_PESTSTART
	///How long does the popup stay up for?
	var/ghost_confirmation_delay = 30 SECONDS
	///How many copies of thing_to_spawn do we want?
	var/amount_to_spawn = 1
	///Antag role ID to assign to the players on spawn
	var/antag_role = null
	///Custom objective text to display to players on spawn
	var/objective_text = ""

	proc/get_spawn_loc()
		if (isturf(src.spawn_loc))
			return src.spawn_loc
		else if (islist(src.spawn_loc))
			return pick_landmark(pick(src.spawn_loc)) //pick pick pick
		return pick_landmark(src.spawn_loc)

	proc/get_mob_name()
		if (ismob(src.thing_to_spawn))
			var/mob/mob = src.thing_to_spawn
			return mob.real_name || mob.name
		if (ispath(src.thing_to_spawn, /mob))
			var/mob/mob = src.thing_to_spawn
			return initial(mob.name)
		if (ispath(src.thing_to_spawn, /datum/job))
			var/datum/job/job = src.thing_to_spawn
			return initial(job.name)

	proc/get_mob_instance()
		if (ismob(src.thing_to_spawn))
			if (src.spawn_directly)
				return src.thing_to_spawn
			else
				return semi_deep_copy(src.thing_to_spawn, src.get_spawn_loc())
		if (ispath(src.thing_to_spawn, /mob))
			return new src.thing_to_spawn(src.get_spawn_loc())
		if (ispath(src.thing_to_spawn, /datum/job))
			var/datum/job/job = src.thing_to_spawn
			var/mob/living/carbon/human/normal/M = new/mob/living/carbon/human/normal(src.get_spawn_loc())
			SPAWN(0)
				M.JobEquipSpawned(job.name)
			return M

	proc/do_spawn()
		if (src.spawn_directly)
			src.amount_to_spawn = 1
		var/mob_name = src.get_mob_name()
		// 1: alert | 2: alert (chatbox) | 3: alert acknowledged (chatbox) | 4: no longer eligible (chatbox) | 5: waited too long (chatbox)
		var/list/text_messages = list()
		text_messages.Add("Would you like to respawn as [src.amount_to_spawn > 1 ? "part of a group of" : "a"] [mob_name][src.amount_to_spawn > 1 ? "s" : ""]?")
		text_messages.Add("You are eligible to be respawned as a [mob_name]. You have [src.ghost_confirmation_delay / 10] seconds to respond to the offer.")
		text_messages.Add("You have been added to the list of respawns. Please wait...")

		// The proc takes care of all the necessary work (job-banned etc checks, confirmation delay).
		message_admins("Sending offer to eligible ghosts. They have [src.ghost_confirmation_delay / 10] seconds to respond.")
		var/list/datum/mind/candidates = dead_player_list(TRUE, src.ghost_confirmation_delay, text_messages, allow_dead_antags = TRUE, require_client = TRUE)

		for (var/datum/mind/mind in candidates)
			var/mob/new_mob = src.get_mob_instance()
			mind.transfer_to(new_mob)
			if (src.antag_role == TRUE) //no datum, but we still want them to be a generic antag
				antagify(new_mob, agimmick = TRUE, do_objectives = FALSE)
			else if (src.antag_role)
				mind.add_antagonist(src.antag_role, do_relocate = FALSE, do_objectives = FALSE, source = ANTAGONIST_SOURCE_ADMIN)
			else
				remove_antag(new_mob, usr, TRUE, TRUE)
				mind = new_mob.mind
			if (length(src.objective_text))
				if (src.antag_role)
					new /datum/objective/regular(src.objective_text, mind, mind.get_antagonist(src.antag_role))
				else
					new /datum/objective/crew/custom(src.objective_text, mind)

/datum/spawn_event/fire_ele
	thing_to_spawn = /mob/living/critter/fire_elemental
	spawn_loc = list(LANDMARK_PESTSTART, LANDMARK_MONKEY, LANDMARK_BLOBSTART, LANDMARK_KUDZUSTART)
	amount_to_spawn = 3
	antag_role = TRUE

/datum/spawn_event_editor
	var/datum/spawn_event/spawn_event = new()

	ui_interact(mob/user, datum/tgui/ui)
		ui = tgui_process.try_update_ui(user, src, ui)
		if (!ui)
			ui = new(user, src, "SpawnEvent")
			ui.open()

	ui_data()
		var/spawn_type = ""
		if (ismob(src.spawn_event.thing_to_spawn))
			spawn_type = "mob_ref"
		else if (ispath(src.spawn_event.thing_to_spawn, /mob))
			spawn_type = "mob_type"
		else if (ispath(src.spawn_event.thing_to_spawn, /datum/job))
			spawn_type = "job_type"

		var/loc_type = ""
		if (isturf(src.spawn_event.spawn_loc))
			loc_type = "turf_ref"
		else if (src.spawn_event.spawn_loc)
			loc_type = "landmark"

		//lol sure
		return list(
			"thing_to_spawn" = src.spawn_event.get_mob_name(),
			"spawn_directly" = src.spawn_event.spawn_directly,
			"spawn_loc" = src.spawn_event.spawn_loc,
			"ghost_confirmation_delay" = src.spawn_event.ghost_confirmation_delay,
			"amount_to_spawn" = src.spawn_event.amount_to_spawn,
			"antag_role" = src.spawn_event.antag_role,
			"objective_text" = src.spawn_event.objective_text,
			"spawn_type" = spawn_type,
			"loc_type" = loc_type,
		)

	ui_static_data(mob/user)
		return list(
			"landmarks" = landmarks
		)

	ui_state(mob/user)
		return tgui_admin_state

	ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
		switch (action)
			if ("select_mob")
				var/mob/selected = pick_ref(ui.user)
				if (istype(selected))
					src.spawn_event.thing_to_spawn = selected
				else
					boutput(ui.user, "That's not a mob dingus.")
			if ("select_mob_type")
				src.spawn_event.thing_to_spawn = tgui_input_list(ui.user, "Select mob type", "Select type", concrete_typesof(/mob/living))
			if ("select_job_type")
				src.spawn_event.thing_to_spawn = tgui_input_list(ui.user, "Select job type", "Select type", concrete_typesof(/datum/job))
			if ("select_turf")
				src.spawn_event.spawn_loc = get_turf(pick_ref(ui.user))
			if ("select_landmark")
				src.spawn_event.spawn_loc = tgui_input_list(ui.user, "Select landmark", "Select", landmarks)
			if ("set_spawn_delay")
				src.spawn_event.ghost_confirmation_delay = params["spawn_delay"] //no validation, admins may href exploit if they wish
			if ("set_amount")
				src.spawn_event.amount_to_spawn = params["amount"]
			if ("spawn") //no accidental double clicks
				if (!ON_COOLDOWN(ui.user, "custom_spawn_event", 1 SECOND))
					src.spawn_event.do_spawn()
		return TRUE

/client/proc/cmd_custom_spawn_event()
	SET_ADMIN_CAT(ADMIN_CAT_FUN)
	set name = "Custom Spawn Event"
	set desc = "Set up a custom player spawn event."
	ADMIN_ONLY

	var/datum/spawn_event_editor/E = new /datum/spawn_event_editor(src.mob)
	E.ui_interact(mob)
