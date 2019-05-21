// library to help with maneuver nodes

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

// determine Vector for normal
//
// RETURN Vector structure pointing to current normal
LOCAL FUNCTION get_normal {
  RETURN 
    ((-1) * VCRS(SHIP:VELOCITY:ORBIT, BODY:POSITION)).
}

// calculate burn time to achieve a delta-v
// accepts individual ship values instead of the ship
// so that burn time can be calculated based on future state
//
// PARAMETER dv0: deltav in m/s for the node
// PARAMETER m0: initial mass of the vessel (kg)
// PARAMETER specific_impulse: Isp (seconds) of the engine
// PARAMETER thrust: maximum thrust of the engine (Newtons)
//
// RETURN burn time in seconds for node
LOCAL FUNCTION burn_time {
  PARAMETER dv0. 
  PARAMETER m0.
  PARAMETER specific_impulse.
  PARAMETER thrust.

  LOCAL ve IS (specific_impulse * CONSTANT:g0).
  debug("calculating burn time for delta-v").
  debug("dv0: " + dv0).
  debug("m0: " + m0).
  debug("Isp: " + specific_impulse).
  debug("thrust: " + thrust).
  debug("Ve: " + ve).

  RETURN (
    ((m0*ve)/(thrust)) * (1-(CONSTANT:E^(-1*(dv0/ve))))
  ).
}

// determine time to burn for given dv
// takes into consideration stage dv limits
//
// PARAMETER dv: deltaV in meters per second
// PARAMETER engstat: LEXICON with engine stats by stage
//
// RETURN time in seconds to burn to deltaV
LOCAL FUNCTION burn_time_by_stage {
  PARAMETER dv0.
  PARAMETER engstat.

  debug("calculating burn time with staging").
  debug("dv: " + dv0).
  debug("engstat: " + engstat).

  LOCAL total_time IS 0.
  LOCAL dv_counter IS 0.

  FROM { LOCAL x IS (engstat:LENGTH - 1). } 
  UNTIL ((dv_counter >= dv0) OR (x < 0)) 
  STEP { SET x TO (X - 1). } 
  DO {
    debug("calculating for stage " + x).
    LOCAL stage_dv IS 0.
    IF ((dv_counter + engstat[x]["delta_v"]) >= dv0) {
      // this is the last stage we'll need
      debug("final stage found").
      SET stage_dv TO (dv0 - dv_counter).
    } ELSE {
      // we need all the dv from this stage
      debug("full stage necessary").
      SET stage_dv TO engstat[x]["delta_v"].
    }

    debug("stage_dv: " + stage_dv).
    LOCAL stage_time IS burn_time(
      stage_dv, 
      engstat[x]["m0"], 
      engstat[x]["isp"], 
      engstat[x]["thrust"]
    ).
    debug("stage_time: " + stage_time).
    SET total_time TO (total_time + stage_time).
    debug("total_time: " + total_time).
    SET dv_counter TO (dv_counter + engstat[x]["delta_v"]).
    debug("dv_counter: " + dv_counter).
  }

  debug("").
  RETURN total_time.
}

// perform actions common to node executions
//
// steering lock must happen in calling function,
// since trying to lock it here would just result in
// some static value being used
//
// PARAMETER engstat: LEXICON with engine stats by stage
// PARAMETER nd: node for which to burn
// PARAMETER margin: time in seconds to prep before node
LOCAL FUNCTION node_execution {
  PARAMETER engstat.
  PARAMETER nd.
  PARAMETER margin.

  debug("preparing to execute node at " + TIME).
  debug("engstat: " + engstat).
  debug("nd: " + nd).
  debug("margin: " + margin).

  LOCAL dv0 IS nd:DELTAV.
  debug("dv0: " + dv0).
  LOCAL prenodedvtime IS 
    burn_time_by_stage((dv0:MAG / 2), engstat).
  debug("begin burn at node-" + prenodedvtime).

  PRINT("calculating burn for next node").
  PRINT("burn parameters").
  PRINT("  Δv: " + dv0:MAG + "m/s").
  PRINT("  burn at node-" + prenodedvtime + "s").

  PRINT("waiting until node...").
  debug("waiting until node").
  WAIT UNTIL (nd:ETA <= (prenodedvtime + margin)).
  KUNIVERSE:TIMEWARP:CANCELWARP.

  WAIT UNTIL (nd:ETA <= prenodedvtime).
  KUNIVERSE:TIMEWARP:CANCELWARP.
  PRINT("IGNITION").
  debug("beginning burn at " + TIME).
  LOCAL tset IS 0.
  LOCK THROTTLE TO tset.
  LOCAL done IS false.

  UNTIL done {
    LOCAL max_acc IS (SHIP:AVAILABLETHRUST / SHIP:MASS).
    LOCAL dvn IS nd:DELTAV:MAG.

    // if there's one second or more left on burn
    // set throttle to full, otherwise decrease linearly
    SET tset to MIN((dvn / max_acc), 1).

    // cut throttle if node direction reverses
    IF (VDOT(dv0, nd:DELTAV) < 0) {
      PRINT("vector reversal, terminating burn").
      PRINT("Δv remaining: " + nd:DELTAV:MAG + "m/s").
      LOCK THROTTLE TO 0.
      debug("vector reversal, terminating burn at " + TIME).
      debug("dv remaining: " + nd:DELTAV:MAG).
      SET done TO true.
    }

    // nearing end of burn
    IF (nd:DELTAV:MAG < 0.1) {
      PRINT("finalizing burn...").
      debug("finalizing burn at " + TIME).

      // burn slowly until vector begins to drift
      WAIT UNTIL (VDOT(dv0, nd:DELTAV) < 0.5).
      LOCK THROTTLE TO 0.
      SET done TO true.
      PRINT("CUTOFF").
      debug("burn cutoff at " + TIME).
    }
  }

  UNLOCK STEERING.
  UNLOCK THROTTLE.
  debug("steering and throttle unlocked at " + TIME).
  WAIT 1.

  REMOVE nd.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // just in case
}

// execute the next node
//
// for now MUST be the next node only, because executing
// a burn other than the next one is slightly more difficult
//
// changing the node between calling this function and
// node execution is not recommended
//
// locks steering to node vector, which isn't awesome
// for changing inclination
//
// takes control from calling process
//
// PARAMETER engstat: LEXICON with engine stats by stage
// PARAMETER margin: time in seconds to prep before node
GLOBAL FUNCTION execute_node {
  PARAMETER engstat.
  PARAMETER margin IS 60.

  debug("execute node by locking to node vector").
  debug("margin: " + margin).

  LOCAL nd IS NEXTNODE.
  debug("nd: " + nd).

  PRINT("preparing for burn...").
  debug("preparing for burn at " + TIME).
  LOCK STEERING TO nd:DELTAV.
  debug("steering locked at " + TIME).

  // wait until ship is pointing towards node
  debug("waiting for ship alignment").
  WAIT UNTIL (VANG(nd:DELTAV, SHIP:FACING:VECTOR) < 0.25).
  PRINT("ready for burn").
  debug("ready for burn at " + TIME).

  node_execution(engstat, nd, margin).
}

// execute the next node using prograde/retrograde only
//
// for now MUST be the next node only, because executing
// a burn other than the next one is slightly more difficult
//
// changing the node between calling this function and
// node execution is not recommended
//
// locks steering to either prograde or retrograde
// in order to minimize interferance
//
// takes control from calling process
//
// PARAMETER engstat: LEXICON with engine stats by stage
// PARAMETER margin: time in seconds to prep before node
GLOBAL FUNCTION execute_grade_node {
  PARAMETER engstat.
  PARAMETER margin IS 60.

  debug("execute node by locking to prograde/retrograde").
  debug("margin: " + margin).

  LOCAL nd IS NEXTNODE.
  debug("nd: " + nd).

  PRINT("preparing for burn...").
  debug("preparing for burn at " + TIME).

  IF (nd:PROGRADE > 0) {
    debug("locking to prograde").
    LOCK STEERING TO PROGRADE.
    debug("steering locked at " + TIME).
    // wait until ship is pointing towards prograde
    debug("waiting for ship alignment").
    WAIT UNTIL (
      VANG(PROGRADE:FOREVECTOR, SHIP:FACING:VECTOR) < 0.25
    ).
  } ELSE {
    debug("locking to retrograde").
    LOCK STEERING TO RETROGRADE.
    debug("steering locked at " + TIME).
    // wait until ship is pointing towards retrograde
    debug("waiting for ship alignment").
    WAIT UNTIL (
      VANG(RETROGRADE:FOREVECTOR, SHIP:FACING:VECTOR) < 0.25
    ).
  }

  PRINT("ready for burn").
  debug("ready for burn at " + TIME).

  node_execution(engstat, nd, margin).
}

// execute the next node using normal/antinormal only
//
// for now MUST be the next node only, because executing
// a burn other than the next one is slightly more difficult
//
// changing the node between calling this function and
// node execution is not recommended
//
// locks steering to either normal or antinormal
// in order to prevent orbital velocity from changing
// can ONLY be used for inclination change and NOTHING else
//
// takes control from calling process
//
// PARAMETER engstat: LEXICON with engine stats by stage
// PARAMETER margin: time in seconds to prep before node
GLOBAL FUNCTION execute_normal_node {
  PARAMETER engstat.
  PARAMETER margin IS 60.

  debug("execute node by locking to normal/anti-normal").
  debug("margin: " + margin).

  LOCAL nd IS NEXTNODE.
  debug("nd: " + nd).

  PRINT("preparing for burn...").
  debug("preparing for burn at " + TIME).

  IF (nd:NORMAL > 0) {
    debug("locking to normal").
    LOCK STEERING TO get_normal().
  } ELSE {
    debug("locking to antinormal").
    LOCK STEERING TO ((-1) * get_normal()).
  }

  // wait until ship is pointing towards node
  debug("waiting for ship alignment").
  WAIT UNTIL (VANG(nd:DELTAV, SHIP:FACING:VECTOR) < 0.25).
  PRINT("ready for burn").
  debug("ready for burn at " + TIME).

  node_execution(engstat, nd, margin).
}
