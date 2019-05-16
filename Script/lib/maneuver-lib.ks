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
// PARAMETER dv: deltav in m/s for the node
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

// execute the next node
//
// for now MUST be the next node only, because executing
// a burn other than the next one is slightly more difficult
//
// also it's assumed that the vessel has only one engine,
// which simplifies determining Isp
//
// changing the node between calling this function and
// node execution is not recommended
//
// locks steering to node vector, which isn't awesome
// for changing inclination
//
// includes WAIT statements, so this will essentially take
// control from calling process
//
// PARAMETER preburn: time in seconds to burn before node
GLOBAL FUNCTION execute_node {
  PARAMETER preburn IS 60. // default to 60 seconds

  debug("preparing to execute node at " + TIME).
  debug("preburn: " + preburn).

  LIST ENGINES IN eng.
  debug("eng: " + eng).
  LOCAL nd IS NEXTNODE.
  debug("nd: " + nd).
  LOCAL dv0 IS nd:DELTAV.
  debug("dv0: " + dv0).
  LOCAL duration IS burn_time(dv0:MAG,
  														SHIP:MASS,
  														eng[0]:ISP,
  														SHIP:AVAILABLETHRUST).
  debug("duration: " + duration).

  PRINT("calculating burn for next node").
  PRINT("burn parameters").
  PRINT("  Δv: " + dv0:MAG + "m/s").
  PRINT("  Δt: " + duration + "s").

  PRINT("preparing for burn...").
  debug("preparing for burn at " + TIME).
  LOCK STEERING TO nd:DELTAV.
  debug("steering locked at " + TIME).

  // wait until ship is pointing towards node
  debug("waiting for ship alignment").
  WAIT UNTIL (VANG(nd:DELTAV, SHIP:FACING:VECTOR) < 0.25).
  PRINT("ready for burn").
  debug("ready for burn at " + TIME).

  PRINT("waiting until node...").
  debug("waiting until node").
  WAIT UNTIL (nd:ETA <= ((duration / 2) + preburn)).
  KUNIVERSE:TIMEWARP:CANCELWARP.

  WAIT UNTIL (nd:ETA <= (duration / 2)).
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
      debug("vector reversal, terminating burn at " + TIME) 
       .
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
  debug("steering and throttle unlocked at " + TIME) 
   .
  WAIT 1.

  REMOVE nd.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // just in case
}

// execute the next node using normal/antinormal only
//
// for now MUST be the next node only, because executing
// a burn other than the next one is slightly more difficult
//
// also it's assumed that the vessel has only one engine,
// which simplifies determining Isp
//
// changing the node between calling this function and
// node execution is not recommended
//
// locks steering to either normal or antinormal
// in order to prevent orbital velocity from changing
// can ONLY be used for inclination change and NOTHING else
//
// includes WAIT statements, so this will essentially take
// control from calling process
//
// PARAMETER preburn: time in seconds to burn before node
GLOBAL FUNCTION execute_normal_node {
  PARAMETER preburn IS 60. // default to 60 seconds

  debug("preparing to execute normal only node at " + TIME) 
   .
  debug("preburn: " + preburn).

  LIST ENGINES IN eng.
  debug("eng: " + eng).
  LOCAL nd IS NEXTNODE.
  debug("nd: " + nd).
  LOCAL dv0 IS nd:DELTAV.
  debug("dv0: " + dv0).
  LOCAL duration IS burn_time(dv0:MAG,
                              SHIP:MASS,
                              eng[0]:ISP,
                              SHIP:AVAILABLETHRUST).
  debug("duration: " + duration).

  PRINT("calculating burn for next node").
  PRINT("burn parameters").
  PRINT("  Δv: " + dv0:MAG + "m/s").
  PRINT("  Δt: " + duration + "s").

  PRINT("preparing for burn...").
  debug("preparing for burn at " + TIME).
  debug("nd:NORMAL: " + nd:NORMAL).
  IF (nd:NORMAL > 0) {
    LOCK STEERING TO get_normal().
    debug("steering locked to normal hopefully").
  } ELSE {
    LOCK STEERING TO (-1) * get_normal().
    debug("steering locked to antinormal hopefully").
  }
  debug("steering locked at " + TIME).

  // wait until ship is pointing towards node
  debug("waiting for ship alignment").
  WAIT UNTIL (VANG(nd:DELTAV, SHIP:FACING:VECTOR) < 0.25).
  PRINT("ready for burn").
  debug("ready for burn at " + TIME).

  PRINT("waiting until node...").
  debug("waiting until node").
  WAIT UNTIL (nd:ETA <= ((duration / 2) + preburn)).
  KUNIVERSE:TIMEWARP:CANCELWARP.

  WAIT UNTIL (nd:ETA <= (duration / 2)).
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
      debug("vector reversal, terminating burn at " + TIME) 
       .
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
  debug("steering and throttle unlocked at " + TIME) 
   .
  WAIT 1.

  REMOVE nd.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // just in case
}
