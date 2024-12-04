//macro'd so we can pass variadic arguments down to the trigger proc
#define TRIGGER_RITE(rite_type, user, rest...)\
	do {\
		var/datum/rite/rite = get_singleton(rite_type);\
		rite.trigger(user, ##rest)\
	} while(FALSE);
