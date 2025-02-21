///A modified telepad
/obj/machinery/networked/telepad/prisoner
	device_tag = "PNET_S_TELEPAD_PRISONER"
//yes this is a lot of parsing boilerplate, blame years of machinery/networked being awful
/obj/machinery/networked/telepad/prisoner/receive_signal(datum/signal/signal)
	if (!..())
		return //parent says the signal is dodgy, abort

	var/sigcommand = lowertext(signal.data["command"])
	if(!sigcommand || !signal.data["sender"])
		return
	var/target = signal.data["sender"]

	switch(sigcommand)
		if("term_message","term_file")
			if(target != src.host_id) //Huh, who is this?
				return

			var/list/data = params2list(signal.data["data"])
			if(!data)
				return

			session = data["session"]

			switch(data["command"])
				if ("transmit")
					if (ON_COOLDOWN(src, "transmit", 10 SECONDS))
						message_host("command=nack") //TODO: handle this maybe
						return
					var/turf/target_turf = get_turf(landmarks[LANDMARK_BALOR_START][1])
					for (var/mob/living/M in get_turf(src))
						do_teleport(M, target_turf, use_teleblocks = FALSE)
					showswirl_out(src.loc)
					leaveresidual(src.loc)
					showswirl(target_turf)
					leaveresidual(target_turf)
					use_power(1500)
					message_host("command=ack")

///A mainframe for the Balor entrance area, includes the custom teleport programs
/obj/machinery/networked/mainframe/balor
	setup_drive_type = /obj/item/disk/data/memcard/balor

/obj/item/disk/data/memcard/balor
	file_amount = 1024

	New()
		..()
		var/datum/computer/folder/newfolder = new /datum/computer/folder(  )
		newfolder.name = "sys"
		newfolder.metadata["permission"] = COMP_HIDDEN
		src.root.add_file( newfolder )
		newfolder.add_file( new /datum/computer/file/mainframe_program/os/kernel(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/shell(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/login(src) )

		var/datum/computer/folder/subfolder = new /datum/computer/folder
		subfolder.name = "drvr" //Driver prototypes.
		newfolder.add_file( subfolder )
		subfolder.add_file( new /datum/computer/file/mainframe_program/driver/mountable/databank(src) )
		subfolder.add_file( new /datum/computer/file/mainframe_program/driver/mountable/user_terminal(src) )
		subfolder.add_file( new /datum/computer/file/mainframe_program/driver/telepad_prisoner(src) )
		subfolder.add_file( new /datum/computer/file/mainframe_program/driver/apc(src) )

		subfolder = new /datum/computer/folder
		subfolder.name = "srv"
		newfolder.add_file( subfolder )
		subfolder.add_file( new /datum/computer/file/mainframe_program/srv/email(src) )
		subfolder.add_file( new /datum/computer/file/mainframe_program/srv/print(src) )
		subfolder.add_file( new /datum/computer/file/mainframe_program/srv/telecontrol(src) )
		subfolder.add_file( new /datum/computer/file/mainframe_program/srv/telecontrol_prisoner(src) )

		newfolder = new /datum/computer/folder
		newfolder.name = "bin" //Applications available to all users.
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		src.root.add_file( newfolder )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/cd(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/ls(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/rm(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/cat(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/mkdir(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/ln(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/chmod(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/chown(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/su(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/cp(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/mv(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/utility/mount(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/hept_interface(src) )
		newfolder.add_file( new /datum/computer/file/mainframe_program/guardbot_interface(src) )

		newfolder = new /datum/computer/folder
		newfolder.name = "mnt"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		src.root.add_file( newfolder )

		newfolder = new /datum/computer/folder
		newfolder.name = "conf"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		src.root.add_file( newfolder )

		var/datum/computer/file/record/testR = new
		testR.name = "motd"
		testR.fields += "Welcome to DWAINE System VI!"
		testR.fields += "Hafgan Robotics Distribution"
		newfolder.add_file( testR )

		newfolder.add_file( new /datum/computer/file/record/dwaine_help(src) )

		newfolder = new /datum/computer/folder
		newfolder.name = "etc"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		src.root.add_file( newfolder )

/obj/item/paper/balor_IT
	name = "Note from IT"
	icon_state = "paper"
	info = {"Since some of you (Kingfisher) seem incapable of operating the damn teleporter without waking me up, here's an idiots guide:<br>
	Ensure the prisoner is restrained, this should be obvious but we've had multiple angry emails from Lero just this month about improperly restrained prisoners.<br>
	Run the control program, it's all preconfigured now so there should be no more incidents of prisoners ending up 2 lightyears the wrong way because <i>Kingfisher</i> can't do basic linear algebra.<br>
	You can find the program in /sys/srv, and you'll need to SU to access it. Why is it there? Look, this entire OS is held together with duct tape and patent infringment, don't even ask.<br>
	And above all DO NOT stand on the pad when it's active, unless you feel like reciting code phrases to Lero security for the next 6 hours.<br><br>
	- Technical Operative Banks
	"}

/obj/balor_teleporter
	name = "short-range teleporter"
	desc = "A precise teleporter that only works across short distances."
	icon = 'icons/misc/32x64.dmi'
	icon_state = "lrport"
	var/landmark = LANDMARK_BALOR_START

	Crossed(atom/movable/AM)
		. = ..()

		if (istype(AM, /obj/port_a_prisoner) || istype(AM, /mob/living))
			var/target_turf =  get_turf(landmarks[landmark][1])
			do_teleport(AM, target_turf, use_teleblocks = FALSE)
			showswirl_out(src.loc)
			leaveresidual(src.loc)
			showswirl(target_turf)
			leaveresidual(target_turf)
