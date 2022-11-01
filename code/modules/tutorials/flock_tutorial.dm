/datum/tutorial_base/regional/flock
	name = "Flock tutorial"
	var/mob/living/intangible/flock/flockmind/fowner = null
	region_type = /datum/mapPrefab/allocated/flock_tutorial
	var/obj/landmark/center = null

	New(mob/M)
		. = ..()
		src.AddStep(new /datum/tutorialStep/flock/deploy)
		src.AddStep(new /datum/tutorialStep/flock/gatecrash)
		src.AddStep(new /datum/tutorialStep/flock/move)
		src.AddStep(new /datum/tutorialStep/flock/control)
		src.AddStep(new /datum/tutorialStep/flock/gather)
		src.AddStep(new /datum/tutorialStep/flock/convert_window)
		src.AddStep(new /datum/tutorialStep/flock/floorrun)
		src.AddStep(new /datum/tutorialStep/flock/release_drone)
		src.AddStep(new /datum/tutorialStep/flock/kill)
		src.exit_point = pick_landmark(LANDMARK_OBSERVER)
		for(var/turf/T in landmarks[LANDMARK_TUTORIAL_FLOCKCONVERSION])
			if(src.region.turf_in_region(T))
				center = T
				break
		if (!center)
			throw EXCEPTION("Okay who removed the goddamn [LANDMARK_TUTORIAL_FLOCKCONVERSION] landmark")
		src.fowner = M

	Finish()
		. = ..()
		if (!.)
			return FALSE
		fowner.reset()
		fowner.tutorial = null


/datum/tutorialStep/flock
	name = "Flock tutorial step"
	instructions = "If you see this, tell a coder!!!11"
	var/static/image/marker = null
	var/datum/tutorial_base/regional/flock/ftutorial = null

	New()
		..()
		if (!marker)
			marker = image('icons/effects/VR.dmi', "lightning_marker")
			marker.filters= filter(type="outline", size=1)
	SetUp()
		. = ..()
		src.ftutorial = src.tutorial

	PerformAction(action, context)
		return FALSE //fuck you, no action

/datum/tutorialStep/flock/deploy
	name = "Realizing"
	instructions = "If at any point this tutorial glitches up and leaves in a stuck state, use the emergency tutorial stop verb. Choose a suitable area to spawn your rift. Try to choose an out of the way area with plenty of resources and delicious computers to eat."
	var/turf/must_deploy = null

	SetUp()
		..()
		must_deploy = locate(ftutorial.initial_turf.x, ftutorial.initial_turf.y + 1, ftutorial.initial_turf.z)
		must_deploy.UpdateOverlays(marker,"marker")

	PerformAction(var/action, var/context)
		if (action == "spawn rift" && context == must_deploy)
			return TRUE
		else if (action == "rift complete")
			src.finished = TRUE
			return TRUE
		return FALSE

	TearDown()
		must_deploy.UpdateOverlays(null,"marker")

/datum/tutorialStep/flock/gatecrash
	name = "Gatecrash"
	instructions = "Your flockdrone is stuck in this room, use your Gatecrash ability to force the door open."

	PerformAction(action, context)
		if (action == "gatecrash")
			src.finished = TRUE
			return TRUE

/datum/tutorialStep/flock/move
	name = "Move"
	instructions = "Now move your flockdrone through the door by clicking and dragging it."

	PerformAction(action, context)
		if (action == "click drag move")
			src.finished = TRUE
			return TRUE

/datum/tutorialStep/flock/control
	name = "Control drone"
	instructions = "Sometimes you may want to take direct control of a single drone, for combat or fine movement control. Click drag yourself over the flockdrone to take control of it."

	PerformAction(action, context)
		if (action == "control drone")
			src.finished = TRUE
			return TRUE

/datum/tutorialStep/flock/gather
	name = "Gather resources"
	instructions = "In order to convert the station around you, you are going to need resources. Pick up some items using your manipulator hand and place them into your disintigrator (equip hotkey) to break them down into resources."
	var/amount = 30

	PerformAction(action, context)
		if (action == "gain resources" && context >= amount)
			src.finished = TRUE
			return TRUE

/datum/tutorialStep/flock/convert_window
	name = "Conversion"
	instructions = "Convert the window in front of you to allow you to pass through it. Convert it by clicking on it with your nanite spray (middle) hand."

	PerformAction(var/action, var/context)
		if (action == "start conversion" && locate(/obj/window) in get_turf(context))
			return TRUE
		if (action == "claim turf" && locate(/obj/window) in context)
			finished = TRUE
			return TRUE

/datum/tutorialStep/flock/floorrun
	name = "Floor running"
	instructions = "While controlling a flockdrone you can press your sprint key to disappear into the floor, becoming untargetable and passing through flock walls and windows. Use it to pass through the window you just converted."

	PerformAction(action, context)
		if (action == "floorrun")
			src.finished = TRUE
			return TRUE
/datum/tutorialStep/flock/release_drone
	name = "Release control"
	instructions = "Now use the eject button at the bottom right of your HUD to release control of this drone."

	SetUp()
		..()
		SPAWN(1 SECOND)
			flock_spiral_conversion(src.ftutorial.center, ftutorial.fowner.flock, 0.1 SECONDS)
		for (var/i = 1 to 4)
			var/mob/living/critter/flock/drone/flockdrone = new(locate(src.ftutorial.center.x + rand(-3,3), src.ftutorial.center.y + rand(-3,3), src.ftutorial.center.z), ftutorial.fowner.flock)
			spawn_animation1(flockdrone)
			sleep(0.2 SECONDS)
		for (var/i = 1 to 2)
			var/mob/living/critter/flock/bit/flockdrone = new(locate(src.ftutorial.center.x + rand(-3,3), src.ftutorial.center.y + rand(-3,3), src.ftutorial.center.z), ftutorial.fowner.flock)
			spawn_animation1(flockdrone)
			sleep(0.2 SECONDS)

	PerformAction(action, context)
		if (action == "release drone")
			finished = TRUE
			return TRUE

/datum/tutorialStep/flock/kill
	name = "Eliminate threat"
	instructions = "That human has just violated causality to teleport right into your flock! Mark them for elimination using your \"designate enemy\" ability and watch as your drones attack."

	SetUp()
		..()
		var/obj/portal/portal = new(locate(src.ftutorial.center.x, src.ftutorial.center.y + 3, src.ftutorial.center.z))
		sleep(1 SECOND)
		animate_portal_tele(portal)
		playsound(portal.loc, "warp", 50, 1, 0.2, 1.2)
		var/mob/living/carbon/human/normal/jerk = new(get_turf(portal))
		step(jerk, SOUTH)
		sleep(0.5 SECONDS)
		qdel(portal)

	PerformAction(action, context)
		if (action == "designate enemy")
			return TRUE
		if (action == "cage")
			finished = TRUE
			return TRUE

/mob/living/intangible/flock/flockmind/verb/help_my_tutorial_is_being_a_massive_shit()
	set name = "EMERGENCY TUTORIAL STOP"
	if (!tutorial)
		boutput(src, "<span class='alert'>You're not in a tutorial, doofus. It's real. IT'S ALL REAL.</span>")
		return
	src.tutorial.Finish()
	src.tutorial = null

/obj/machinery/junk_spawner
	var/stuff = list(/obj/item/extinguisher, /obj/item/crowbar, /obj/item/wrench)
	process(mult)
		if (!(locate(/obj/item) in get_turf(src)))
			var/type = pick(src.stuff)
			new type(src.loc)
