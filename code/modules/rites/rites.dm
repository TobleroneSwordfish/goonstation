ABSTRACT_TYPE(/datum/rite)
/datum/rite
	///The `/datum/targetable` blessing to add on success
	var/blessing_type = null

	///Should assume nothing and check all conditions
	///Can have any number of arguments passed down from the variadic macro
	proc/can_trigger(mob/user)
		SHOULD_CALL_PARENT(TRUE)
		return user?.traitHolder?.hasTrait("training_chaplain")

	///Success side effects go here for now
	proc/grant_blessing(mob/target)
		if (target.getAbility(/datum/targetable/bless))
			return FALSE
		target.addAbility(src.blessing_type)
		return TRUE

/datum/rite/blood_to_void
	blessing_type = /datum/targetable/bless/living
	can_trigger(mob/user, obj/item/reagent_containers/container, turf/space/target)
		if (!..())
			return FALSE
		if (!istype(user) || !istype(container) || !istype_exact(target, /turf/space))
			return FALSE
		var/datum/reagent/blood = container.reagents?.get_reagent("blood") || container.reagents?.get_reagent("bloodc")
		var/datum/bioHolder/bioholder = blood?.data
		if (!bioholder)
			return FALSE
		if (bioholder.owner == user)
			boutput(user, SPAN_NOTICE("Self sacrifice feels... hollow."))
			return FALSE
		return TRUE

	grant_blessing(mob/user, obj/item/reagent_containers/container, turf/space/target)
		target.visible_message(SPAN_NOTICE("The blood freezes into glimmering crystals and disperses into the vacuum."))
		target.color = "red" //TODO: sparkles
		return ..()

/datum/rite/feeding_the_floor //too easy?
	can_trigger(mob/user, obj/item/reagent_containers/food/food, turf/simulated/floor/floor)
		if (!..())
			return FALSE
		if (!istype(user) || !istype(food) || !istype(floor))
			return FALSE
		if (!user.traitHolder.hasTrait("training_chaplain"))
			return FALSE
		return TRUE

	grant_blessing(mob/user, obj/item/reagent_containers/food/food, turf/simulated/floor/floor)
		boutput(user, SPAN_NOTICE("You hear a faint [pick("scratching", "buzzing", "scuffling")] from beneath the floor."))
		qdel(food)
		return ..()

/datum/rite/a_nest_of_wires
	blessing_type = /datum/targetable/bless/machine
	//mmm yes bird
	can_trigger(mob/user, obj/item/item, obj/item/wire_nest/nest)
		if (!..())
			return FALSE
		return istype(item, /obj/item/cell)

	grant_blessing(mob/user, obj/item/item, obj/item/wire_nest/nest)
		elecflash(nest, 1)
		qdel(item)
		qdel(nest)
		return ..()

/obj/item/wire_nest
	name = "tangle of wires"
	desc = "A messy tangle of wires."
	icon = 'icons/obj/items/nest.dmi'
	icon_state = "nest0"
	var/stage = 1

	New(loc, obj/item/cable_coil/coil)
		. = ..()
		if (coil)
			src.icon_state = null
			var/image/new_overlay = image(src.icon, "nest0")
			new_overlay.color = coil.color
			src.AddOverlays(new_overlay, "wires0")

	attackby(obj/item/item, mob/user, params)
		if (src.stage >= 6 && isturf(src.loc))
			user.drop_item(item, FALSE)
			item.set_loc(src.loc)
			item.pixel_x = src.pixel_x
			item.pixel_y = src.pixel_y
			TRIGGER_RITE(/datum/rite/a_nest_of_wires, user, item, src)
			return
		if (istype(item, /obj/item/cable_coil) && stage < 6)
			var/image/new_overlay = image(src.icon, "nest[src.stage + 1]")
			new_overlay.color = item.color
			src.AddOverlays(new_overlay, "wires[src.stage]")
			src.stage += 1
			return
		. = ..()


/datum/targetable/bless
	name = "Bless"
	targeted = TRUE
	target_anything = TRUE
	var/allowed_types = list(/atom)
	var/disallowed_types = list()

	tryCast(atom/target, params)
		if (!istypes(target, src.allowed_types) || istypes(target, src.disallowed_types))
			boutput(holder.owner, SPAN_ALERT("This blessing is not for such a thing."))
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		. = ..()

	cast(atom/target)
		. = ..()
		if (!target.hasStatus("blessed"))
			target.setStatus("blessed", INFINITE_STATUS)
			src.holder.removeAbilityInstance(src)

/datum/targetable/bless/living
	name = "Bless living"
	allowed_types = list(/mob/living)
	disallowed_types = list(/mob/living/silicon, /mob/living/critter/robotic) //machines

/datum/targetable/bless/machine
	name = "Bless machine"
	allowed_types = list(/obj/machinery, /obj/submachine, /mob/living/silicon, /mob/living/critter/robotic)

/datum/targetable/bless/tool
	name = "Bless tool"
	allowed_types = list(/obj/item) //look, anything can be a tool if you can hold it

/datum/statusEffect/blessed
	id = "blessed"
	name = "Blessed"
	visible = FALSE

	onAdd(optional)
		. = ..()
		APPLY_ATOM_PROPERTY(src.owner, PROP_ATOM_LUCK, src, 10)

	onRemove()
		REMOVE_ATOM_PROPERTY(src.owner, PROP_ATOM_LUCK, src)
		. = ..()
