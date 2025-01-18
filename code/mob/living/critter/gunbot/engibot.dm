/mob/living/critter/robotic/gunbot/engineerbot
	name = "Syndicate MULTI Unit"
	real_name = "Syndicate MULTI Unit"
	icon_state = "engineerbot"
	base_icon_state = "engineerbot"
	desc = "An engnieering unit, you can somehow feel that it's angry at you."
	health_brute = 20
	health_burn = 10
	health_burn_vuln = 0.8

	ai_type = /datum/aiHolder/aggressive

	New()
		..()
		APPLY_ATOM_PROPERTY(src, PROP_MOB_NIGHTVISION_WEAK, src)
		abilityHolder.addAbility(/datum/targetable/critter/nano_repair)

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.limb = new /datum/limb/solder
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "welderhand"
		HH.name = "Soldering Iron"
		HH.limb_name = "soldering iron"

		HH = hands[2]
		HH.limb = new /datum/limb/solder
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "hand_martian"
		HH.name = "Soldering Iron"
		HH.limb_name = "soldering iron"

	get_melee_protection(zone, damage_type)
		return 4

	get_ranged_protection()
		return 2

	setup_equipment_slots()
		return

/mob/living/critter/robotic/gunbot/engineerbot/strong // Midrounds
	hand_count = 3
	health_brute = 75
	health_brute_vuln = 1
	health_burn = 50
	health_burn_vuln = 1
	is_npc = FALSE

	setup_hands()
		. = ..()
		var/datum/handHolder/HH = hands[2]
		HH.limb = new /datum/limb/deconstructor
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "hand_martian"
		HH.name = "Deconstructor"
		HH.limb_name = "deconstructor"

		HH = hands[3]
		HH.limb = new /datum/limb/small_critter/strong
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "handn"
		HH.name = "gunbothand"
		HH.limb_name = "gunbot hands"

/datum/limb/solder
	can_pickup_item = FALSE

	help(mob/target, var/mob/living/user)
		..()
		harm(target, user, 0)

	harm(mob/target, var/mob/living/user)
		if(check_target_immunity( target ))
			return FALSE

		var/datum/attackResults/msgs = user.calculate_melee_attack(target, 15, 15, 0, can_punch = FALSE, can_kick = FALSE)
		user.attack_effects(target, user.zone_sel?.selecting)
		var/action = "burn"
		msgs.base_attack_message = "<b><span class='alert'>[user] [action]s [target] with [src.holder]!</span></b>"
		msgs.played_sound = 'sound/impact_sounds/generic_hit_2.ogg'
		msgs.damage_type = DAMAGE_BURN
		msgs.flush(SUPPRESS_LOGS)
		user.lastattacked = target
		ON_COOLDOWN(src, "limb_cooldown", 3 SECONDS)

/datum/targetable/critter/nano_repair
	name = "nano-bot repair"
	desc = "Send out nano-bots to repair robotics in a 5 tile radius."
	icon_state = "roboheal"
	cooldown = 20 SECONDS
	targeted = FALSE

	cast(atom/target)
		if (..())
			return TRUE
		for (var/mob/living/robot in range(5, holder.owner))
			if (issilicon(robot) || istype(robot, /mob/living/critter/robotic))
				robot.HealDamage("all", 10, 10, 0)
		playsound(holder.owner, 'sound/items/welder.ogg', 80, 0)
		return FALSE

//Borrowing this, sorry Azrun!
/obj/item/salvager/gunbot
	use_power(watts)
		return TRUE

/datum/limb/deconstructor
	var/obj/item/salvager/gunbot/tool = new

	attack_hand(atom/target, mob/user, reach, params, location, control)
		tool.set_loc(user) //hehe hoohoo
		tool.AfterAttack(target, user, reach, params)
