// helpful KAC functions and globals
// kac mod inclusion is assumed

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

// get a single alarm by name
// name is not guaranteed to be unique, only the first alarm found with the given name will be returned
//
// PARAMETER name: name of the alarm to get
//
// RETURN the KACAlarm structure if found, false otherwise
GLOBAL FUNCTION get_alarm {
	PARAMETER name.

	debug("fetching alarm with name: " + name).

	FOR alarm in ADDONS:KAC:alarms() {
		IF alarm:NAME = name {
			debug("found alarm: " + alarm).
			RETURN alarm.
		}
	}

	// no alarm found
	debug("alarm not found").
	RETURN false.
}

// add a new alarm
// is a wrapper around ADDALARM()
// accepts an increment
// creates new alarm at mission start + increment
//
// PARAMETER type: alarm type
// PARAMETER name: name for the alarm
// PARAMETER notes: alarm description
// PARAMETER increment: time after mission start for alarm
//
// RETURN the new alarm
GLOBAL FUNCTION add_alarm_with_increment {
	PARAMETER type.
	PARAMETER name.
	PARAMETER notes.
	PARAMETER increment.

	debug(
		"setting alarm with increment " + increment + 
		" from " + TIME
	).

	LOCAL alarm_time IS TIME + increment - MISSIONTIME.

	debug(
		"ADDALARM(" + 
			type + ", " + 
			alarm_time:SECONDS + ", " + 
			name + ", " + 
			notes + 
		")."
	).
	RETURN ADDALARM(type, alarm_time:SECONDS, name, notes).
}
