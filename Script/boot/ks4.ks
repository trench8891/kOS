// load variables and functions for kerbsat-alpha
@LAZYGLOBAL OFF.

// load libraries
PRINT("loadinng libraries...").
RUNONCEPATH("/lib/comms-lib").
RUNONCEPATH("/lib/io-lib").
RUNONCEPATH("/lib/kac-lib").
RUNONCEPATH("/lib/launch-lib").
RUNONCEPATH("/lib/maneuver-lib").
RUNONCEPATH("/lib/orbit-lib").
RUNONCEPATH("/lib/sat4-lib").
RUNONCEPATH("/lib/ship-lib").
RUNONCEPATH("/lib/store-lib").
debug("all libraries loaded").
debug("").

// set thresholds
LOCAL threshold_a IS 2000.
debug("semi-major axis threshold: " + threshold_a).
LOCAL threshold_i IS 1.
debug("inclination threshold: " + threshold_i).
LOCAL threshold_e IS 0.01.
debug("eccentricity threshold: " + threshold_e).
LOCAL threshold_aop IS 1.
debug("AoP threshold: " + threshold_aop).
debug("").

// define local args
PRINT("initializing parameters...").
LOCAL action_file IS "0:/action/execute-delegates.ks".
debug("action_file: " + action_file).
LOCAL action_target IS "1:/execute.ksm".
debug("action_target: " + action_target).
LOCAL history_key IS "kerbsat-alpha-launches".
debug("history_key: " + history_key).
LOCAL alarm_name IS "kerbsat-alpha-launch".
debug("alarm_name: " + alarm_name).
LOCAL target_i IS 33.
debug("target_i: " + target_i).
LOCAL target_e IS 0.28.
debug("target_e: " + target_e).
LOCAL target_aop IS 90.
debug("target_aop: " + target_aop).
LOCAL parent IS KERBIN.
debug("parent: " + parent).
debug("").

LOCAL min_a IS sat4_min_a(parent).
debug("min_a: " + min_a).
LOCAL target_t IS ROUND(parent:ROTATIONPERIOD * (5/3)).
debug("target_t: " + target_t).
LOCAL target_a IS
	find_semimajor_axis(parent:MU, target_t).
debug("target_a: " + target_a).
LOCAL target_periaps IS
	find_periapsis(parent:RADIUS, target_e, target_a).
debug("target_periaps: " + target_periaps).
LOCAL target_apoaps IS
	find_apoapsis(parent:RADIUS, target_e, target_a).
debug("target_apoaps: " + target_apoaps).
LOCAL max_distance IS sat4_max_distance(
	find_apocenter(target_e, target_a), 
	target_a
).
debug("max_distance: " + max_distance).
LOCAL alarm_increment IS 
	ROUND(parent:ROTATIONPERIOD * (5/4)).
debug("alarm_increment: " + alarm_increment).
debug("").

// determine launch history
PRINT("reading launch history from store...").
LOCAL launch_num IS (value_from_store(history_key, 0) + 1).
debug("launch_num: " + launch_num).
IF (MOD(launch_num, 2) = 1) {
	SET target_aop TO 270.
	debug("target_aop: " + target_aop).
}
debug("").

// print parameters
PRINT("--------------------------------------------------").
PRINT("Parent body: " + parent:NAME).
PRINT("minimum SAT-4 semi-major axis: " + min_a + "m").
PRINT("launch number: " + launch_num).
PRINT("alarm increment: " + alarm_increment + "s").
PRINT("target inclination: " + target_i + "°").
PRINT("target eccentricity: " + target_e).
PRINT("target argument of periapsis: " + target_aop + "°").
PRINT("target period: " + target_t + "s").
PRINT("target semi-major axis: " + target_a + "m").
PRINT("target periapsis: " + target_periaps + "m").
PRINT("target apoapsis: " + target_apoaps + "m").
PRINT("satellite max distance: " + max_distance + "m").
PRINT("--------------------------------------------------").

PRINT("verifying parameters...").
IF ((launch_num > 4) OR (launch_num < 1)) {
	terminate("bad launch number").
}
IF (target_a < min_a) {
	terminate("semi-major axis too low").
}

LOCAL delegates IS LIST(). // delegates go here
debug("initializing list of delegates").
debug("").

// define launch profile
// launch to incline, adjust for rotation
// burn up to target periaps
PRINT("preparing launch profile...").
debug("preparing launch delegate").
LOCAL launch_heading IS target_i.
IF (target_aop > 180) {
	// provide negative value to launch from descending node
	SET launch_heading TO (0 - target_i).
}
debug("launch_heading: " + launch_heading).
IF (launch_num = 1) {
	// manually trigger first launch
	delegates:ADD(
		launch_button@:bind(target_periaps, launch_heading)
	).
} ELSE {
	// launch from alarm
	LOCAL alarm IS get_alarm(alarm_name).
	debug("launch alarm: " + alarm).
	LOCAL launch_time IS (TIME + alarm:REMAINING).
	debug("launch time: " + launch_time).
	PRINT(
		"launching at " + 
		launch_time:CALENDAR + " - " + 
		launch_time:CLOCK
	).
	delegates:ADD(
		launch_at_time@:bind(
			launch_time:SECONDS, 
			target_periaps, 
			launch_heading
		)
	).
	debug("").
}
debug("launch delegate: "+delegates[delegates:LENGTH - 1]).
debug("").

// define function for orbital insertion
debug("preparing insertion delegate").
delegates:ADD({
	PRINT("preparing for orbital insertion...").
	debug("preparing for orbital insertion at " + TIME).
	LOCAL time_to_node IS (TIME:SECONDS + ETA:APOAPSIS).
	debug("time to node: " + time_to_node).
	LOCAL delta_v IS semimajor_axis_change(
		SHIP:ORBIT, 
		SHIP:ORBIT:APOAPSIS + parent:RADIUS
	).
	debug("delta v: " + delta_v).
	ADD NODE(time_to_node, 0, 0, delta_v).
	debug("insertion node: " + NEXTNODE).
	LOCAL engstat IS engine_breakdown().
	debug("engstat: " + engstat).
	execute_grade_node(engstat, 120).
}).
debug("insertion delegate: "+delegates[delegates:LENGTH-1]).
debug("").

// fix inclination
debug("preparing fix delegate").
delegates:ADD({
	debug("checking inclination at " + TIME).
	LOCAL diff_i IS (OBT:INCLINATION - target_i).
	debug("inclination diff: " + diff_i).
	IF (ABS(diff_i) > 1) {
		PRINT("preparing to fix inclination...").
		debug("preparing to fix inclination").
		LOCAL an IS time_to_an(SHIP:ORBIT).
		debug("time to ascending node: " + an).
		LOCAL dn IS time_to_dn(SHIP:ORBIT).
		debug("time to descending node: " + dn).
		LOCAL delta_v IS inclination_change(
			OBT:VELOCITY:ORBIT:MAG, 
			diff_i
		).
		IF (an > dn) {
			debug("selected descending node").
			debug("delta v: " + delta_v).
			ADD NODE(TIME:SECONDS + dn, 0, delta_v, 0).
		} ELSE {
			debug("selected ascending node").
			debug("delta v: " + (-delta_v)).
			ADD NODE(TIME:SECONDS + an, 0, -delta_v, 0).
		}

		debug("fix node: " + NEXTNODE).
		LOCAL engstat IS engine_breakdown().
		debug("engstat: " + engstat).
		execute_normal_node(engstat, 90).
		debug("").
	}
}).
debug("fix delegate: " + delegates[delegates:LENGTH - 1]).
debug("").

// raise to apoaps when at desired AoP
debug("preparing apoaps delegate").
delegates:ADD({
	PRINT("preparing to raise apoapsis...").
	debug("preparing to raise apoapsis at " + TIME).
	LOCAL time_to_node IS (
		TIME:SECONDS + time_to_argument(SHIP:ORBIT, target_aop)
	).
	debug("time to node: " + time_to_node).
	LOCAL delta_v IS 
		semimajor_axis_change(SHIP:ORBIT, target_a).
	debug("delta v: " + delta_v).
	ADD NODE(time_to_node, 0, 0, delta_v).
	debug("apoaps node: " + NEXTNODE).
	LOCAL engstat IS engine_breakdown().
	debug("engstat: " + engstat).
	execute_grade_node(engstat, 120).
	debug("").
}).
debug("apoaps delegate: "+delegates[delegates:LENGTH - 1]).
debug("").

// verify orbit
debug("preparing verification delegate").
delegates:ADD({
	PRINT("verifying orbit...").
	debug("verifying orbit at " + TIME).
	LOCAL ship_comm_range IS comm_range(SHIP).
	debug("ship comm range: " + ship_comm_range).
	LOCAL go_comms IS (ship_comm_range > max_distance).
	debug("go comms: " + go_comms).
	LOCAL ship_semimajor_axis IS OBT:SEMIMAJORAXIS.
	debug("semi-major axis: " + ship_semimajor_axis).
	LOCAL diff_a IS ABS(ship_semimajor_axis - target_a).
	debug("semi-major axis diff: " + diff_a).
	LOCAL go_a IS (diff_a < threshold_a).
	debug("go semi-major axis: " + go_a).
	LOCAL ship_inclination IS OBT:INCLINATION.
	debug("ship inclination: " + ship_inclination).
	LOCAL diff_i IS ABS(ship_inclination - target_i).
	debug("inclination diff: " + diff_i).
	LOCAL go_i IS (diff_i < threshold_i).
	debug("go inclination: " + go_i).
	LOCAL ship_eccentricity IS OBT:ECCENTRICITY.
	debug("ship eccentricity: " + ship_eccentricity).
	LOCAL diff_e IS ABS(ship_eccentricity - target_e).
	debug("eccentricity diff: " + diff_e).
	LOCAL go_e IS (diff_e < threshold_e).
	debug("go eccentricity: " + go_e).
	LOCAL ship_aop IS OBT:ARGUMENTOFPERIAPSIS.
	debug("ship AoP: " + ship_aop).
	LOCAL diff_aop IS ABS(ship_aop - target_aop).
	debug("AoP diff: " + diff_aop).
	LOCAL go_aop IS (diff_aop < threshold_aop).
	debug("go AoP: " + go_aop).
	IF (go_comms AND go_a AND go_i AND go_e AND go_aop) {
		PRINT("all orbital parameters within tolerance").
		debug("go orbit").
		IF ADDONS:RT:HASKSCCONNECTION(SHIP) {
			PRINT("registering success with store...").
			debug("registering success").
			add_to_store(history_key, launch_num).
		} ELSE {
			PRINT("comms down, update store manually").
			debug("no connection").
		}
	} ELSE {
		PRINT("unable to verify orbital parameters").
		debug("orbit no-go").
		PRINT("review parameters and either revert flight").
		PRINT("or update store manually").
		PRINT("----------------------------------------------").
		PRINT("comm range").
		PRINT(" required: " + max_distance + "m").
		PRINT("   actual: " + ship_comm_range + "m").
		PRINT("semi-major axis").
		PRINT("		actual: " + ship_semimajor_axis + "m").
		PRINT("		target: " + target_a + "m").
		PRINT("inclination").
		PRINT("		actual: " + ship_inclination + "°").
		PRINT("		target: " + target_i + "°").
		PRINT("eccentricity").
		PRINT("		actual: " + ship_eccentricity).
		PRINT("		target: " + target_e).
		PRINT("argument of periapsis").
		PRINT("		actual: " + ship_aop + "°").
		PRINT("		target: " + target_aop + "°").
		PRINT("----------------------------------------------").
	}
	debug("").
}).
debug("verification delegate: "+delegates[delegates:length-1]).
debug("").

// prep next alarm
debug("checking alarm trigger").
IF (launch_num < 4) {
	PRINT("preparing alarm chain...").
	debug("preparing alarm chain").
	WHEN STATUS = "FLYING" THEN {
		LOCAL alarm IS add_alarm_with_increment(
			"Raw",
			alarm_name,
			"launch kerbsat-alpha-" + (launch_num + 1),
			alarm_increment
		).
		LOCAL alarm_time IS TIME(
			TIME:SECONDS + alarm:REMAINING
		).
		LOCAL alarm_clock IS 
			(alarm_time:CALENDAR + " " + alarm_time:CLOCK).
		PRINT("next alarm set at: " + alarm_clock).
		debug("alarm: " + alarm).
		debug("alarm time: " + alarm_clock).
	}
}

// trigger to release fairings when above atmosphere
PRINT("setting fairing trigger...").
debug("setting fairing trigger").
WHEN(ALTITUDE > parent:ATM:HEIGHT) THEN {
	PRINT("releasing fairings").
	debug("releasing fairings at " + TIME).
	FOR fairing IN SHIP:MODULESNAMED("ModuleProceduralFairing") {
		fairing:DOEVENT("DEPLOY").
		debug("DEPLOY " + fairing).
	}
	debug("").
}

// trigger to deploy peripherals when a bit higher
PRINT("setting deploy trigger...").
debug("setting deploy trigger").
WHEN (ALTITUDE > (parent:ATM:HEIGHT + 1000)) THEN {
	PRINT("deploying peripherals...").
	debug("deploying peripherals at " + TIME).

	// deploy solar panels
	PANELS ON.
	debug("PANELS ON").

	// deploy comms
	FOR comm IN get_all_comms(SHIP) {
		comm:DOACTION("ACTIVATE", true).
		debug("ACTIVATE " + comm).
	}
	debug("").
}

// compile the script
PRINT("compiling action script...").
COMPILE action_file TO action_target.
debug("COMPILE " + action_file + " TO " + action_target).

// run the script
PRINT("executing launch procedure...").
debug("executing " + action_target).
debug("with parameters: " + delegates).
debug("").
RUNPATH(action_target, delegates).

// unset boot script
PRINT("unsetting boot script...").
debug("unsetting boot script").
SET CORE:BOOTFILENAME TO "None".
