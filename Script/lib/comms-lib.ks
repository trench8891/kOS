// helpful functions for comms
// RT mod inclusion is assumed

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

LOCAL comms_module_name IS "ModuleRTAntenna".
LOCAL comms_dish_range IS "dish range".
LOCAL comms_omni_range IS "omni range".

// convert the comm range string to scalar
//
// PARAMETER str: string to convert
//
// RETURN the comm range in meters
LOCAL FUNCTION convert_comm {
  PARAMETER str.

  debug("parsing comstring: " + str).

  LOCAL multiplier IS 1.
  IF str:CONTAINS("k") {
    SET multiplier TO 1000.
  }
  IF str:CONTAINS("M") {
    SET multiplier TO 1000000.
  }

  RETURN (
    multiplier * 
    str:
      REPLACE("m", ""):
      REPLACE("k", ""):
      REPLACE("M", ""):
      TONUMBER
  ).
}

// get comm range of a part, must be a comms part
//
// PARAMETER module: the comm part module to check
//
// RETURN the comm range in meters for the part
LOCAL FUNCTION part_comm_range {
  PARAMETER module.

  debug("finding com range for module: " + module).

  IF module:HASFIELD(comms_dish_range) {
    debug("checking dish range").
    RETURN convert_comm(module:GETFIELD(comms_dish_range)).
  } ELSE IF module:HASFIELD(comms_omni_range) {
    debug("chcking omni range").
    RETURN convert_comm(module:GETFIELD(comms_omni_range)).
  } ELSE {
    // somehow this isn't a comms part, so return 0
    debug("somehow this isn't a comms part").
    RETURN 0.
  }
}

// get all comm part modules
//
// PARAMETER ves: the vessel to check
//
// RETURN a list with all comm part modules
GLOBAL FUNCTION get_all_comms {
  PARAMETER ves.

  debug("fetching all comms modules for " + ves) 
   .

  RETURN ves:MODULESNAMED(comms_module_name).
}

// get maximum comm range for a vessel
// works by checking the comm range of every part
//
// PARAMETER ves: the vessel to check
//
// RETURN the comm range in meters for the vessel
GLOBAL FUNCTION comm_range {
  PARAMETER ves.

  debug("determining max com range for " + ves).

  LOCAL max_range IS 0.

  FOR comm IN get_all_comms(ves) {
    LOCAL cr IS part_comm_range(comm).
    debug("com range for " + comm:NAME + ": " + cr) 
     .
    IF (cr > max_range) {
      SET range TO cr.
    }
  }

  RETURN range.
}
