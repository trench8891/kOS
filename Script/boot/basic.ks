// boot script for a basic launch to circular orbit
@LAZYGLOBAL OFF.

// load libraries
PRINT("loadinng libraries...").
RUNONCEPATH("/lib/io-lib").
RUNONCEPATH("/lib/launch-lib").
RUNONCEPATH("/lib/maneuver-lib").
RUNONCEPATH("/lib/orbit-lib").
debug("all libraries loaded").
debug("").

// define local args
PRINT("initializing parameters...").
LOCAL action_file IS "0:/action/execute-delegates.ks".
debug("action_file: " + action_file).
LOCAL action_target IS "1:/execute.ksm".
debug("action_target: " + action_target).
debug("").

LOCAL delegates IS LIST(). // delegates go here
debug("initializing list of delegates").
debug("").

// define launch profile
PRINT("preparing launch profile...").
debug("preparing launch delegate").
delegates:ADD(basic_launch@).
debug("launch delegate: "+delegates[delegates:LENGTH - 1]).
debug("").

// define function for orbital insertion
debug("preparing insertion delegate").
delegates:ADD({
	PRINT("preparing for orbital insertion...").
	debug("preparing for orbital insertion at " + TIME).
	ADD circularize_at_apoaps().
	debug("insertion node: " + NEXTNODE).
	execute_node(30).
}).
debug("insertion delegate: "+delegates[delegates:LENGTH-1]).
debug("").
