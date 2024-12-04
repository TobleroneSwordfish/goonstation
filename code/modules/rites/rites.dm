/datum/rite
	///Should assume nothing and check all conditions before calling parent
	///Can have any number of arguments passed down from the variadic macro
	proc/trigger(mob/user)
		grant_blessing(user)
		return TRUE

	proc/grant_blessing(mob/target)
		var/datum/targetable/bless/bless_ability = target.getAbility(/datum/targetable/bless)
		if (bless_ability)
			bless_ability.uses += 1
		else
			target.addAbility(/datum/targetable/bless)

/datum/rite/blood_to_void
	trigger(mob/user, obj/item/reagent_containers/container, turf/space/target)
		if (!istype(user) || !istype(container) || !istype_exact(target, /turf/space))
			return
		if (!user.traitHolder.hasTrait("training_chaplain"))
			return
		var/datum/reagent/blood = container.reagents?.get_reagent("blood") || container.reagents?.get_reagent("bloodc")
		var/datum/bioHolder/bioholder = blood?.data
		if (!bioholder)
			return
		if (bioholder.owner == user)
			boutput(user, SPAN_NOTICE("Self sacrifice feels... hollow."))
			return
		target.visible_message(SPAN_NOTICE("The blood freezes into glimmering crystals and disperses into the vacuum."))
		target.color = "red" //TODO: sparkles
		return ..()

/datum/rite/feeding_the_floor //too easy?
	trigger(mob/user, obj/item/reagent_containers/food/food, turf/simulated/floor/floor)
		if (!istype(user) || !istype(food) || !istype(floor))
			return
		if (!user.traitHolder.hasTrait("training_chaplain"))
			return
		boutput(user, SPAN_NOTICE("You hear a faint [pick("scratching", "buzzing", "scuffling")] from beneath the floor."))
		qdel(food)
		return ..()

/datum/rite/a_nest_of_wires
	//mmm yes bird
	trigger(mob/user, obj/item/item, obj/item/wire_nest/nest)
		if (!user.traitHolder.hasTrait("training_chaplain"))
			return
		if (istype(item, /obj/item/cell))
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
	var/uses = 1

	cast(atom/target)
		. = ..()
		if (!target.hasStatus("blessed"))
			target.setStatus("blessed", INFINITE_STATUS)
			uses -= 1
			if (uses < 1)
				src.holder.removeAbilityInstance(src)

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
