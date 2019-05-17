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
LOCAL common_script IS "0:/boot-common.ks".
debug("common_script: " + common_script).
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

PRINT("performing common boot actions").
debug("performing common boot actions").
debug("").
RUNPATH(common_script, 
  KERBIN, 
  action_file, 
  action_target, 
  delegates
).

PRINT("boot sequence complete").
