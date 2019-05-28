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

// merge two LEXICONs of LISTs into single LEXICON of LISTs
//
// PARAMETER l1: first LEXICON
// PARAMETER l2: second LEXICON
//
// RETURN single LEXICON of LISTS
LOCAL FUNCTION merge_lexicons {
  PARAMETER l1.
  PARAMETER l2.

  LOCAL newlex IS LEXICON().

  FOR key IN l1:KEYS {
    IF (NOT newlex:HASKEY(key)) {
      newlex:ADD(key, LIST()).
    }

    FOR item IN l1[key] {
      newlex[key]:ADD(item).
    }
  }

  FOR key IN l2:KEYS {
    IF (NOT newlex:HASKEY(key)) {
      newlex:ADD(key, LIST()).
    }

    FOR item IN l2[key] {
      newlex[key]:ADD(item).
    }
  }

  RETURN newlex.
}

// recursivly build PART LEXICON
// given some PART, build a LEXICON of all children
// sorted by section
//
// PARAMETER rt: "root" PART to consider
// PARAMETER section: the section of the "root" PART
//
// RETURN a LEXICON of "root" PART and all children, sorted
//  by section
LOCAL FUNCTION part_lexicon {
  PARAMETER rt.
  PARAMETER section.

  debug("processing " + rt:NAME).
  debug("section: " + section).

  LOCAL ptlex IS LEXICON(section, LIST()).
  ptlex[section]:ADD(rt).

  FOR pt IN rt:CHILDREN {
    LOCAL sect IS section.
    // check if pt is a separator
    IF (pt:HASMODULE("ModuleDecouple")) {
      SET sect TO (section + 1).
    }

    SET ptlex TO 
      merge_lexicons(ptlex, part_lexicon(pt, sect)).
  }

  RETURN ptlex.
}

// get each part separated by *section*
// we think of a section as a *true* stage,
// since kOS determines stages... strangely
//
// RETURN a LEXICON with a list of parts per section
LOCAL FUNCTION parts_by_section {
  debug("sorting parts by section").
  RETURN part_lexicon(SHIP:ROOTPART, 0).
}

// get the wet and dry mass of each section
//
// PARAMETER ptlex: LEXICON of PARTs to find masses
//
// RETURN a LEXICON with the masses of each stage
//    wet_mass - wet mass for the stage
//    dry_mass - dry mass for the stage
LOCAL FUNCTION mass_by_section {
  PARAMETER ptlex.

  debug("getting the mass of each section").
  debug("ptlex: " + ptlex).

  LOCAL masslex IS LEXICON().
  LOCAL totalmass IS 0.

  FROM { LOCAL x IS 0. } 
  UNTIL (x = ptlex:LENGTH) 
  STEP { SET x TO (x + 1). } 
  DO {
    debug("calculating mass for stage " + x).
    LOCAL stage_wet_mass IS 0.
    LOCAL stage_dry_mass IS 0.
    FOR pt IN ptlex[x] {
      SET stage_wet_mass TO (stage_wet_mass + pt:MASS).
      SET stage_dry_mass TO (stage_dry_mass + pt:DRYMASS).
    }
    debug("stage wet mass: " + stage_wet_mass).
    debug("stage dry mass: " + stage_dry_mass).
    masslex:ADD(x, LEXICON()).
    masslex[x]:ADD("wet_mass", totalmass+stage_wet_mass).
    masslex[x]:ADD("dry_mass", totalmass+stage_dry_mass).
    SET totalmass TO (totalmass + stage_wet_mass).
  }

  RETURN masslex.
}

// get each engine sorted by section
//
// PARAMETER ptlex: LEXICON of PARTs to find ENGINEs from
//
// RETURN a LEXICON with a list of ENGINES per section
LOCAL FUNCTION engines_by_section {
  PARAMETER ptlex.

  debug("sorting engines by section").
  debug("ptlex: " + ptlex).

  LIST ENGINES IN englst.
  debug("englst: " + englst).

  LOCAL englex IS LEXICON().

  // examine each part and compare against list of engines
  FOR sctnum IN ptlex:KEYS {
    debug("sctnum: " + sctnum).
    FOR pt IN ptlex[sctnum] {
      debug("pt: " + pt:NAME).
      IF englst:CONTAINS(pt) {
        debug("----engine found").
        IF (NOT englex:HASKEY(sctnum)) {
          englex:ADD(sctnum, LIST()).
        }
        englex[sctnum]:ADD(pt).
      }
    }
  }

  RETURN englex.
}

// get the average specific impulse from a list of ENGINEs
//
// PARAMETER eng: LIST of ENGINEs to average
//
// RETURN the average specific impulse in seconds
LOCAL FUNCTION average_isp {
  PARAMETER eng.

  debug("determining average Isp for engines: " + eng).

  LOCAL sum IS 0.
  FOR engine IN eng {
    debug("engine: " + engine).
    SET sum TO (sum + engine:ISP).
  }

  RETURN (sum / eng:LENGTH).
}

// get the total thrust from a list of ENGINEs
//
// PARAMETER eng: LIST of ENGINEs to total
//
// RETURN the total available thrust in kilonewtons
LOCAL FUNCTION total_thrust {
  PARAMETER eng.

  debug("determining total thrust for engines: " + eng).

  LOCAL sum IS 0.
  FOR engine IN eng {
    SET sum TO (sum + engine:POSSIBLETHRUST).
  }

  RETURN sum.
}

// calculate available deltaV
//
// PARAMETER isp: specific impulse in seconds
// PARAMETER m0: initial mass in kilograms
// PARAMETER mf: final mass in kilograms
//
// RETURN deltaV in meters per second
LOCAL FUNCTION get_delta_v {
  PARAMETER isp.
  PARAMETER m0.
  PARAMETER mf.

  debug("getting deltaV").
  debug("isp: " + isp).
  debug("m0: " + m0).
  debug("mf: " + mf).

  RETURN (isp * CONSTANT:G0 * LN(m0 / mf)).
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

// get a LEXICON with engine data seperated by section
//
// RETURN a LEXICON with engine data per section:
//    delta_v - total deltaV available for the section
//    isp - specific impulse for the section
//    thrust - total thrust for the section
//    m0 - start mass for the vessel during this section
LOCAL FUNCTION engine_breakdown {
  debug("determining engine values per stage").

  LOCAL breakdown IS LEXICON().
  LOCAL ptlex IS parts_by_section().
  debug("ptlex: " + ptlex).
  LOCAL englex IS engines_by_section(ptlex).
  debug("englex: " + englex).
  LOCAL masslex IS mass_by_section(ptlex).
  debug("masslex: " + masslex).

  FROM { LOCAL x IS 0. } 
  UNTIL (x = englex:LENGTH) 
  STEP { SET x TO (x + 1). } 
  DO {
    debug("determining parameters for stage: " + x).
    breakdown:ADD(x, LEXICON()).

    LOCAL stage_isp IS average_isp(englex[x]).
    debug("stage_isp: " + stage_isp).
    LOCAL stage_thrust IS total_thrust(englex[x]).
    debug("stage_thrust: " + stage_thrust).
    LOCAL stage_wet_mass IS masslex[x]["wet_mass"].
    debug("stage_wet_mass: " + stage_wet_mass).
    LOCAL stage_dry_mass IS masslex[x]["dry_mass"].
    debug("stage_dry_mass: " + stage_dry_mass).
    LOCAL stage_delta_v IS get_delta_v(
      stage_isp, 
      stage_wet_mass, 
      stage_dry_mass
    ).
    debug("stage_delta_v: " + stage_delta_v).

    breakdown[x]:ADD("delta_v", stage_delta_v).
    breakdown[x]:ADD("isp", stage_isp).
    breakdown[x]:ADD("thrust", stage_thrust).
    breakdown[x]:ADD("m0", stage_wet_mass).
  }

  RETURN breakdown.
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
// PARAMETER margin: time in seconds to prep before node
GLOBAL FUNCTION execute_node {
  PARAMETER margin IS 60.

  debug("execute node by locking to node vector").
  debug("margin: " + margin).

  LOCAL engstat IS engine_breakdown().
  debug("engstat: " + engstat).

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
// PARAMETER margin: time in seconds to prep before node
GLOBAL FUNCTION execute_grade_node {
  PARAMETER margin IS 60.

  debug("execute node by locking to prograde/retrograde").
  debug("margin: " + margin).

  LOCAL engstat IS engine_breakdown().
  debug("engstat: " + engstat).

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
// PARAMETER margin: time in seconds to prep before node
GLOBAL FUNCTION execute_normal_node {
  PARAMETER margin IS 60.

  debug("execute node by locking to normal/anti-normal").
  debug("margin: " + margin).

  LOCAL engstat IS engine_breakdown().
  debug("engstat: " + engstat).

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
