// functions for common orbital values

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

// find orbital velocity by vis-viva equation
//
// PARAMETER gm: gravitational parameter
// PARAMETER a: semi-major axis in meters
// PARAMETER radius: distance in meters to focus
//
// RETURN orbital velocity in m/s
LOCAL FUNCTION vis_viva {
  PARAMETER gm.
  PARAMETER a.
  PARAMETER radius.

  debug("calulating orbital velocity with vis viva") 
   .
  debug("gm: " + gm).
  debug("a: " + a).
  debug("radius: " + radius).

  RETURN ROUND(SQRT(gm * ((2/radius) - (1/a)))).
}

// get the eccentric anomaly from an orbit
//
// PARAMETER e: eccentricity
// PARAMETER ta: true anomaly
//
// RETURN the current eccentric anomaly in degrees
LOCAL FUNCTION eccentric_anomaly {
  PARAMETER e.
  PARAMETER ta.

  debug("calculating eccentric anomaly").
  debug("e: " + e).
  debug("ta: " + ta).

  LOCAL costheta IS COS(ta).
  debug("costheta: " + costheta).

  RETURN ARCCOS((e + costheta) / (1 + (e * costheta))).
}

// get the current mean anomaly of an orbit
// kOS provides suffixes on the Orbit structure only for
// MEANANOMALYATEPOCH and EPOCH, which along with current
// time and orbital period is enough to determine the REAL
// mean anomaly
//
// PARAMETER orbit: the orbit with everything
//
// RETURN the current mean anomaly in degrees
LOCAL FUNCTION mean_anomaly {
  PARAMETER orbit.

  debug("finding current mean anomaly").
  debug("orbit: " + orbit).

  LOCAL maae IS orbit:MEANANOMALYATEPOCH.
  debug("maae: " + maae).
  LOCAL ts IS TIME:SECONDS.
  debug("ts: " + ts).
  LOCAL epoch IS orbit:EPOCH.
  debug("epoch: " + epoch).
  LOCAL p IS orbit:PERIOD.
  debug("p: " + p).

  RETURN MOD((maae + (((ts - epoch) / p) * 360)), 360).
}

// get the mean anomaly from true anomaly
// if you want the current mean anomaly, use mean_anomaly()
//
// PARAMETER e: eccentricity
// PARAMETER ta: true anomly in degrees to convert
//
// RETURN the mean anomaly in degrees
LOCAL FUNCTION true_to_mean {
  PARAMETER e.
  PARAMETER ta.

  debug("converting true anomaly to mean anomaly").
  debug("e: " + e).
  debug("ta: " + ta).

  LOCAL ea IS eccentric_anomaly(e, ta).
  debug("ea: " + ea).
  LOCAL ma IS (ea - ((180 / CONSTANT:PI) * e * SIN(ea))).

  IF (ta < 180) {
    RETURN ma.
  } ELSE {
    RETURN (360 - ma).
  }
}

// calculate time to a given true anomaly
//
// PARAMETER orbit: the orbit to run calculation on
// PARAMETER ta: true anomaly in degrees we want time to
//
// RETURN time in seconds to the true anomaly
LOCAL FUNCTION time_to_true_anomaly {
  PARAMETER orbit.
  PARAMETER ta.

  debug("calculate time to true anomaly").
  debug("orbit: " + orbit).
  debug("ta: " + ta).

  LOCAL tma IS true_to_mean(orbit:ECCENTRICITY, ta).
  debug("tma: " + tma).
  LOCAL cma IS mean_anomaly(orbit).
  debug("cma: " + cma).
  LOCAL diff IS MOD(360 + tma - cma, 360).
  debug("diff: " + diff).
  LOCAL fraction IS (diff / 360).
  debug("fraction: " + fraction).

  RETURN (fraction * orbit:PERIOD).
}

// Calculate pericenter
//
// PARAMETER e: orbit eccentricity
// PARAMETER a: orbit semi-major axis in meters
//
// RETURN distance in meters from pericenter to focus
LOCAL FUNCTION find_pericenter {
  PARAMETER e.
  PARAMETER a.

  debug("finding pericenter").
  debug("e: " + e).
  debug("a: " + a).

  RETURN (a * (1 - e)).
}

// Calculate apocenter
//
// PARAMETER e: orbit eccentricity
// PARAMETER a: orbit semi-major axis in meters
//
// RETURN distance in meters from apocenter to center
GLOBAL FUNCTION find_apocenter {
  PARAMETER e.
  PARAMETER a.

  debug("finding apocenter").
  debug("e: " + e).
  debug("a: " + a).

  RETURN (a * (1 + e)).
}

// Calculate periapsis
//
// PARAMETER radius: radius of parent body in meters
// PARAMETER e: orbit eccentricity
// PARAMETER a: orbit semi-major axis in meters
//
// RETURN altitude of periapsis in meters
GLOBAL FUNCTION find_periapsis {
  PARAMETER radius.
  PARAMETER e.
  PARAMETER a.

  debug("find periapsis").
  debug("radius: " + radius).
  debug("e: " + e).
  debug("a: " + a).

  RETURN ROUND(find_pericenter(e, a) - radius).
}

// Calculate apoapsis
//
// PARAMETER radius: radius of parent body in meters
// PARAMETER e: orbit eccentricity
// PARAMETER a: orbit semi-major axis in meters
//
// RETURN altitude of apoapsis in meters
GLOBAL FUNCTION find_apoapsis {
  PARAMETER radius.
  PARAMETER e.
  PARAMETER a.

  debug("find apoapsis").
  debug("radius: " + radius).
  debug("e: " + e).
  debug("a: " + a).

  RETURN ROUND(find_apocenter(e, a) - radius).
}

// Calculate semi-major axis for a given period
//
// PARAMETER gm: gravitational parameter
// PARAMETER T: orbital period in seconds
//
// RETURN target semi-major axis in meters
GLOBAL FUNCTION find_semimajor_axis {
  PARAMETER gm.
  PARAMETER T.

  debug("finding semi-major axis").
  debug("gm: " + gm).
  debug("T: " + T).

  RETURN ROUND((((T^2) * gm)/(4 * (CONSTANT:PI)^2))^(1/3)).
}

// calculate delta-v required to change semi-major axis
//
// PARAMETER start_orbit: initial orbit
// PARAMETER target_a: semi-major axis to shift to
//
// RETURN delta-v in m/s required to change semi-major axis
//    negative value indicates retrograde burn required
GLOBAL FUNCTION semimajor_axis_change {
  PARAMETER current_orbit.
  PARAMETER target_a.

  debug("calulating dv for sma change").
  debug("current_orbit: " + current_orbit).
  debug("target_a: " + target_a).

  // can use either pericenter or apocenter,
  // the result should be the same
  // ...but apparently is not
  LOCAL radius IS find_apocenter(
    current_orbit:ECCENTRICITY, 
    current_orbit:SEMIMAJORAXIS
  ).
  debug("radius: " + radius).
  LOCAL startv IS vis_viva(
    current_orbit:BODY:MU, 
    current_orbit:SEMIMAJORAXIS, 
    radius
  ).
  debug("startv: " + startv).
  LOCAL endv IS vis_viva(
    current_orbit:BODY:MU, 
    target_a, 
    radius
  ).
  debug("endv: " + endv).

  RETURN (endv - startv).
}

// calculate delta-v required to change inclination
//
// PARAMETER v: orbital velocity in m/s
// PARAMETER theta: angle change in degrees
//
// RETURN delta-v in m/s required to change inclination
GLOBAL FUNCTION inclination_change {
  PARAMETER v.
  PARAMETER theta.

  debug("calulating dv for inclination change").
  debug("v: " + v).
  debug("theta: " + theta).

  RETURN (2 * v * SIN(theta / 2)).
}

// calculate the time to a specified angle from
// the equatorial plane
//
// PARAMETER orbit: the orbit to run calculation on
// PARAMETER arg: target angle in degrees
//
// RETURN time in seconds to the target angle
GLOBAL FUNCTION time_to_argument {
  PARAMETER orbit.
  PARAMETER arg.

  debug("calculate time to argument").
  debug("orbit: " + orbit).
  debug("arg: " + arg).

  LOCAL tta IS 
    MOD(360 + arg - orbit:ARGUMENTOFPERIAPSIS, 360).
  debug("tta: " + tta).

  RETURN time_to_true_anomaly(orbit, tta).
}

// calculate the time to ascending node
//
// PARAMETER orbit: the orbit to run calculation on
//
// RETURN time in seconds to ascending node
GLOBAL FUNCTION time_to_an {
  PARAMETER orbit.

  debug("calculate time to ascending node").
  debug("orbit: " + orbit).

  LOCAL taan IS (360 - orbit:ARGUMENTOFPERIAPSIS).
  debug("taan: " + taan).

  RETURN time_to_true_anomaly(orbit, taan).
}

// calculate the time to descending node
//
// PARAMETER orbit: the orbit to run calculation on
//
// RETURN time in seconds to descending node
GLOBAL FUNCTION time_to_dn {
  PARAMETER orbit.

  debug("calculate time to descending node").
  debug("orbit: " + orbit).

  LOCAL tadn IS MOD(540 - orbit:ARGUMENTOFPERIAPSIS, 360).
  debug("tadn: " + tadn).

  RETURN time_to_true_anomaly(orbit, tadn).
}
