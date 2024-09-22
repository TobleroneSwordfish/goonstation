#define EGGS_FILE "data/eggs.sav"
#define MAX_EGGS 10

/obj/item/reagent_containers/food/snacks/ingredient/egg
	name = "egg"
	desc = "An egg!"
	icon_state = "egg"
	food_color = "#FFFFFF"
	initial_volume = 20
	initial_reagents = list("egg"=5)
	fill_amt = 0.5
	doants = 0 // They're protected by a shell

	New()
		. = ..()
		START_TRACKING

	disposing()
		STOP_TRACKING
		. = ..()

	throw_impact(atom/A, datum/thrown_thing/thr)
		var/turf/T = get_turf(A)
		src.visible_message(SPAN_ALERT("[src] splats onto the floor messily!"))
		playsound(src.loc, 'sound/impact_sounds/Slimy_Splat_1.ogg', 100, 1)
		make_cleanable(/obj/decal/cleanable/eggsplat,T)
		qdel (src)

/obj/item/reagent_containers/food/snacks/ingredient/egg/hardboiled
	name = "hard-boiled egg"
	desc = "You're a loose cannon, egg. I'm taking you off the menu."
	icon_state = "egg-hardboiled"
	food_color = "#FFFFFF"
	initial_volume = 20
	food_effects = list("food_brute", "food_cateyes")

	New()
		..()
		reagents.add_reagent("egg", 5)

	throw_impact(atom/A, datum/thrown_thing/thr)
		src.visible_message(SPAN_ALERT("[src] flops onto the floor!"))

	attackby(obj/item/W, mob/user)
		if (istool(W, TOOL_CUTTING | TOOL_SNIPPING))
			boutput(user, SPAN_NOTICE("You cut [src] in half"))
			new /obj/item/reagent_containers/food/snacks/deviledegg(get_turf(src))
			new /obj/item/reagent_containers/food/snacks/deviledegg(get_turf(src))
			if (prob(25))
				JOB_XP(user, "Chef", 1)
			qdel(src)
		else ..()

//why am I doing this
/obj/item/reagent_containers/food/snacks/ingredient/egg/century
	name = "century egg"
	desc = "A dubiously \"preserved\" and certainly very old egg. Might be delicious!"
	icon_state = "century-egg"
	food_color = "#68634B" //eww
	heal_amt = 5 //tasty treat
	var/timestamp_created = null

	heal(mob/living/M)
		. = ..()
		boutput(M, SPAN_NOTICE("[src] tastes like it has been aged for [src.timestamp_created ? approx_time_text(world.realtime - src.timestamp_created) : "not very long"]."))

//mostly adapted from pickle jars because imcargoculter and it's not really generalizable

proc/save_intraround_eggs()
	var/savefile/egg_save = new(EGGS_FILE)
	var/list/egglist
	egg_save[global.map_settings.name] >> egglist
	if (!length(egglist))
		egglist = list()

	for (var/coord_string in egglist)
		var/coords = splittext(coord_string, ",")
		var/turf/simulated/floor/floor = locate(text2num_safe(coords[1]), text2num_safe(coords[2]), Z_LEVEL_STATION)
		//check for missing eggs
		if (!istype(floor) || !locate(/obj/item/reagent_containers/food/snacks/ingredient/egg/century) in floor.hidden_contents)
			egglist -= coord_string
			continue

	for_by_tcl(egg, /obj/item/reagent_containers/food/snacks/ingredient/egg)
		if (length(egglist) >= MAX_EGGS) //finite eggs
			break
		if (istype(egg, /obj/item/reagent_containers/food/snacks/ingredient/egg/century)) //already pickled
			continue
		if (!istype(egg.loc, /obj/effects/hidden_contents_holder)) //this means "is hidden under a floor tile"
			continue
		var/turf/egg_turf = get_turf(egg)
		if (egg_turf.z != Z_LEVEL_STATION)
			continue
		if (prob(50))
			continue
		var/coord_string = "[egg_turf.x],[egg_turf.y]"
		if (egglist[coord_string]) //don't replace older eggs
			continue
		egglist[coord_string] = toIso8601(subtractTime(world.realtime, hours = world.timezone)) //cargo culted from poll handling idk
		logTheThing(LOG_DEBUG, null, "<b>Persistent eggs:</b> Egg saved at [log_loc(egg)]")

	egg_save[global.map_settings.name] << egglist
	egg_save.Flush()

proc/load_intraround_eggs()
	set background = 1

	fdel(EGGS_FILE + ".lk") //force unlock, thank you pali

	var/savefile/egg_save = new(EGGS_FILE)
	var/list/egglist
	egg_save[global.map_settings.name] >> egglist
	for (var/coord_string in egglist)
		var/coords = splittext(coord_string, ",")
		var/turf/simulated/floor/floor = locate(text2num_safe(coords[1]), text2num_safe(coords[2]), Z_LEVEL_STATION)
		if (istype(floor) && floor.intact)
			var/obj/item/reagent_containers/food/snacks/ingredient/egg/century/new_old_egg = new()
			new_old_egg.timestamp_created = fromIso8601(egglist[coord_string])
			floor.hide_inside(new_old_egg)
		else
			egglist -= coord_string //heehoo haha list modification in a for loop but byond handles that, right??

	egg_save[global.map_settings.name] << egglist
	egg_save.Flush()

#undef EGGS_FILE
#undef MAX_EGGS
