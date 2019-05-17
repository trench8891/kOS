// actions common to multiple boot scripts
// can be run independently if desired
//
// PARAMETER parent: parent body of the vessel
// PARAMETER action_file: file on acrhive to run on ship
// PARAMETER action_target: location to compile file to
// PARAMETER delegates: list of delegates to run from ship

PARAMETER parent.
PARAMETER action_file.
PARAMETER action_target.
PARAMETER delegates.

RUNONCEPATH("/lib/comms-lib").
RUNONCEPATH("/lib/io-lib").

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
SWITCH TO 1.
RUNPATH(action_target, delegates).

// unset boot script
PRINT("unsetting boot script...").
debug("unsetting boot script").
SET CORE:BOOTFILENAME TO "None".
