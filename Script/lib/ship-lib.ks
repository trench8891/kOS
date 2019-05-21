// library of functions to help with calculations about
// the current ship

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

// get each engine part seperated by stage
//
// RETURN a lexicon with a list of engines per stage
LOCAL FUNCTION engines_by_stage {
  debug("arranging engines by stage").

  LOCAL engine_lex IS LEXICON().
  LIST ENGINES IN eng.
  debug("eng: " + eng).
  FOR engine IN eng {
    debug("----engine: " + engine).
    LOCAL stage_num IS engine:STAGE.
    debug("    stage_num: " + stage_num).
    IF (NOT engine_lex:HASKEY(stage_num)) {
      engine_lex:ADD(stage_num, LIST()).
    }
    engine_lex[stage_num]:ADD(engine).
  }

  debug("").
  RETURN engine_lex.
}

// get each part seperated by stage
//
// RETURN a lexicon with a list of parts per stage
LOCAL FUNCTION parts_by_stage {
  debug("arranging parts by stage").

  LOCAL part_lex IS LEXICON().
  LIST PARTS IN pts.
  debug("pts: " + pts).
  FOR pt IN pts {
    debug("----part: " + pt).
    LOCAL stage_num IS pt:STAGE.
    IF (stage_num < 0) {
      SET stage_num TO 0.
    }
    debug("    stage_num: " + stage_num).
    IF (NOT part_lex:HASKEY(stage_num)) {
      part_lex:ADD(stage_num, LIST()).
    }
    part_lex[stage_num]:ADD(pt).
  }

  debug("").
  RETURN part_lex.
}

// get the mass for each stage
//
// RETURN a lexicon with the mass of each stage
//    wet_mass - wet mass for the stage
//    dry_mass - dry mass for the stage
LOCAL FUNCTION mass_by_stage {
  debug("determining mass by stage").

  LOCAL mass_lex IS LEXICON().
  LOCAL part_lex IS parts_by_stage().
  LOCAL total_mass IS 0.
  
  FROM { LOCAL x IS 0. } 
  UNTIL (x = part_lex:LENGTH) 
  STEP { SET x TO (x + 1). } 
  DO {
    debug("calculating mass for stage " + x).
    LOCAL stage_wet_mass IS 0.
    LOCAL stage_dry_mass IS 0.
    FOR pt IN part_lex[x] {
      SET stage_wet_mass TO (stage_wet_mass + pt:MASS).
      SET stage_dry_mass TO (stage_dry_mass + pt:DRYMASS).
    }
    debug("stage wet mass: " + stage_wet_mass).
    debug("stage dry mass: " + stage_dry_mass).
    mass_lex:ADD(x, LEXICON()).
    mass_lex[x]:ADD("wet_mass", total_mass+stage_wet_mass).
    mass_lex[x]:ADD("dry_mass", total_mass+stage_dry_mass).
  }

  RETURN mass_lex.
}

// get the average specific impulse from a list of engines
//
// PARAMETER eng: LIST of engines to average
//
// RETURN the average specific impulse in seconds
LOCAL FUNCTION average_isp {
  PARAMETER eng.

  debug("determining average Isp for: " + eng).

  LOCAL sum IS 0.
  FOR engine IN eng {
    debug("engine: " + engine).
    SET sum TO (sum + engine:ISP).
  }

  RETURN (sum / eng:LENGTH).
}

// get the total thrust from a list of engines
//
// PARAMETER eng: LIST of engines to total
//
// RETURN the total available thrust in kilonewtons
LOCAL FUNCTION total_thrust {
  PARAMETER eng.

  debug("determining total thrust for: " + eng).

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

// get a lexicon with engine data seperated by stage
//
// RETURN a lexicon with engine data per stage:
//    delta_v - total deltaV available for the stage
//    isp - specific impulse for the stage
//    thrust - total thrust for the stage
//    m0 - start mass for the vessel during this stage
GLOBAL FUNCTION engine_breakdown {
  debug("determining engine values per stage").

  LOCAL breakdown IS LEXICON().
  LOCAL engine_lex IS engines_by_stage().
  debug("engine_lex: " + engine_lex).
  LOCAL mass_lex IS mass_by_stage().
  debug("mass_lex: " + mass_lex).

  FROM { LOCAL x IS 0. } 
  UNTIL (x = engine_lex:LENGTH) 
  STEP { SET x TO (x + 1). } 
  DO {
    debug("determining parameters for stage: " + x).
    breakdown:ADD(x, LEXICON()).

    LOCAL stage_isp IS average_isp(engine_lex[x]).
    debug("stage_isp: " + stage_isp).
    LOCAL stage_thrust IS total_thrust(engine_lex[x]).
    debug("stage_thrust: " + stage_thrust).
    LOCAL stage_wet_mass IS mass_lex[x]["wet_mass"].
    debug("stage_wet_mass: " + stage_wet_mass).
    LOCAL stage_dry_mass IS mass_lex[x]["dry_mass"].
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
