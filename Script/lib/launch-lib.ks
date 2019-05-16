// launch trigger functions and basic launch profile

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

// perform calculations necessary for heading lock
//
// modified from function found in KSLib written by
//    space-is-hard and TDW89
//    https://github.com/KSP-KOS/KSLib/blob/master/library/lib_lazcalc.ks#L12-L57
//
// PARAMETER target_alt: altitude in meters to launch to
// PARAMETER target_inc: target inclination
//      use negative value to launch from descending node
//
// RETURN lexicon with parameters:
//    target_inc - target inclination
//    start_lat - latitude at launch
//    equatorial_vel - eastward delta-v due to rotation
//    target_orb_vel - target orbital velocity
//    launc_node - true for ascending, false for descending
LOCAL FUNCTION LAZcalc_init {
  PARAMETER target_alt.
  PARAMETER target_inc.

  PRINT("calculating launch details...").
  debug("calculating launch details").
  debug("target_alt: " + target_alt).
  debug("target_inc: " + target_inc).

  LOCAL data IS LEXICON(). // calculated params go here
  data:ADD("target_inc", ABS(target_inc)).
  data:ADD("start_lat", SHIP:LATITUDE).
  data:ADD("equatorial_vel", (
    (2 * CONSTANT:PI * KERBIN:RADIUS) /
    KERBIN:ROTATIONPERIOD
  )).
  data:ADD("target_orb_vel", SQRT(
    KERBIN:MU / (KERBIN:RADIUS + target_alt)
  )).
  data:ADD("launch_node", (target_inc >= 0)).

  debug("LAZcalc_init data: " + data).
  debug("").
  RETURN data.
}

// calculate target heading to get to desired inclination
// lock heading to output of this function to continuously
// correct steering during launch
//
// modified from function found in KSLib written by
//    space-is-hard and TDW89
//    https://github.com/KSP-KOS/KSLib/blob/master/library/lib_lazcalc.ks#L59-83
//
// PARAMETER data: output from LAZcalc_init
//
// RETURN target heading (0 - 360)
LOCAL FUNCTION LAZcalc {
  PARAMETER data.

  LOCAL inertialAzimuth IS ARCSIN(
    MAX(
      MIN(
        COS(data["target_inc"]) / COS(SHIP:LATITUDE), 1
      ), -1
    )
  ).
  LOCAL VXRot IS (
    (data["target_orb_vel"] * SIN(inertialAzimuth)) - 
    (data["equatorial_vel"] * COS(data["start_lat"]))
  ).
  LOCAL VYRot IS (
    data["target_orb_vel"] * COS(inertialAzimuth)
  ).
    
  // This clamps the result to values between 0 and 360.
  LOCAL Azimuth IS MOD(ARCTAN2(VXRot, VYRot) + 360, 360).
    
  IF data["launch_node"] {
    // Returns northerly azimuth
    // if launching from the ascending node
    RETURN Azimuth.
  } ELSE {
    // Returns southerly azimuth
    // if launching from the descending node
    IF (Azimuth <= 90) {
      RETURN (180 - Azimuth).        
    } ELSE IF (Azimuth >= 270) {
      RETURN (540 - Azimuth).
    }
  }
}

// perform the actual launch
// does not perform orbital insertion
// includes the STAGE command
//
// set GLOBAL launch_complete when done
//
// heavily adapted from launch script by Devon Connor
// https://pastebin.com/ECFM14Df
//
// PARAMETER data: the output from LAZcalc_init
// PARAMETER target_alt: altitude in meters to launch to
//
// RETURN true when launch is complete
LOCAL FUNCTION perform_launch {
  PARAMETER data.
  PARAMETER target_alt.

  PRINT("assuming control").
  debug("performing launch at " + TIME).
  debug("data: " + data).
  debug("target_alt: " + target_alt).

  // prevent any interferance
  SAS OFF.
  debug("SAS OFF.").
  RCS OFF.
  debug("RCS OFF.").
  LIGHTS OFF.
  debug("LIGHTS OFF.").
  GEAR OFF.
  debug("GEAR OFF.").

  // guide vars, adjust these to steer
  LOCK throt TO 1.
  LOCK pitch TO 90.

  // control locks
  LOCK THROTTLE TO throt.
  LOCK STEERING TO HEADING(LAZcalc(data), pitch).
  debug("throttle and steering locked at " + TIME).

  PRINT("***STAGE***").
  STAGE. // ignition
  debug("STAGE at " + TIME).

  // set trigger for stage
  debug("setting stage trigger").
  WHEN ((SHIP:MAXTHRUST = 0) AND (STAGE:NUMBER > 0)) THEN {
    PRINT("***STAGE***").
    STAGE.
    debug("STAGE at " + TIME).
    RETURN true.
  }

  // vertical ascent until speed is 100 m/s
  debug("ascending UP to v > 100m/s").
  WAIT UNTIL (SHIP:AIRSPEED > 100).
  PRINT("beginning gravity turn").
  debug("airspeed: " + SHIP:AIRSPEED).
  debug("beginning gravity turn at " + TIME).

  // gravity turn
  LOCK pitch TO MAX(
    8,
    (90 * (1 - (SHIP:ALTITUDE / KERBIN:ATM:HEIGHT)))
  ).

  // calculate burn time remaining
  LOCK max_acc TO MAX(
    0.1, 
    (SHIP:AVAILABLETHRUST / SHIP:MASS)
  ).
  LOCK dpos TO MAX(0, (target_alt - SHIP:ORBIT:APOAPSIS)).
  LOCK gacc TO
    (KERBIN:MU / (SHIP:ALTITUDE + KERBIN:RADIUS)^2).
  LOCK dv TO (2 * gacc * dpos).
  LOCK maxtimeleft TO (dv / max_acc).

  // throttle based on proximity to target apoaps
  LOCK throt TO MIN(1, maxtimeleft).

  // go until above atmosphere and target apoaps
  debug("waiting until launch completion").
  WAIT UNTIL (
    (SHIP:ALTITUDE > KERBIN:ATM:HEIGHT) AND 
    (maxtimeleft < 0.1)
  ).
  debug("launch complete at " + TIME).

  // launch complete, release control
  PRINT("releasing control").
  LOCK throt to 0.
  UNLOCK THROTTLE.
  UNLOCK STEERING.
  debug("throttle and steering unlocked at " + TIME) 
   .

  // alert any listener that launch is complete
  RETURN true.
}

// create gui with single button to trigger launch delgate
//
// PARAMETER target_alt: altitude in meters to launch to
// PARAMETER target_inc: target inclination
//      use negative value to launch from descending node
GLOBAL FUNCTION launch_button {
  PARAMETER target_alt.
  PARAMETER target_inc IS 0.

  debug("building launch button").
  debug("target_alt: " + target_alt).
  debug("target_inc: " + target_inc).

  LOCAL data IS LAZcalc_init(target_alt, target_inc).

  LOCAL gui IS GUI(200).
  LOCAL button IS gui:ADDBUTTON("LAUNCH").
  gui:SHOW().
  debug("waiting on button press").
  UNTIL button:TAKEPRESS WAIT(0).
  gui:HIDE().
  debug("button pressed at " + TIME).
  debug("performing launch").
  perform_launch(data, target_alt).
  debug("launch from button complete").
  debug("").
}

// trigger launch delegate at a specific time
//
// PARAMETER ut: universal time (in seconds) to launch
// PARAMETER target_alt: altitude in meters to launch to
// PARAMETER target_inc: target inclination
//      use negative value to launch from descending node
GLOBAL FUNCTION launch_at_time {
  PARAMETER ut.
  PARAMETER target_alt.
  PARAMETER target_inc IS 0.

  debug("slaving launch to time").
  debug("ut: " + ut).
  debug("target_alt: " + target_alt).
  debug("target_inc: " + target_inc).

  LOCAL data IS LAZcalc_init(target_alt, target_inc).

  debug("waiting until ut-60").
  WAIT UNTIL (TIME:SECONDS > (ut-60)).
  KUNIVERSE:TIMEWARP:CANCELWARP.
  debug("cancelling time warp").
  WAIT UNTIL (TIME:SECONDS >= ut).
  KUNIVERSE:TIMEWARP:CANCELWARP.
  debug("performing launch at " + TIME).
  perform_launch(data, target_alt).
  debug("launch at time complete").
  debug("").
}
