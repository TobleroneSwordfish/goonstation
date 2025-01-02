//macro'd so we can pass variadic arguments down to the trigger proc
#define TRIGGER_RITE(rite_type, user, rest...)\
	do {\
		var/datum/rite/rite = get_singleton(rite_type);\
		if (rite.can_trigger(user, ##rest)) {\
			rite.grant_blessing(user, ##rest);\
		};\
	} while(FALSE);

//javascript time
#define SPREAD(args...) ##args
