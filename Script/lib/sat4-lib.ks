// functions for SAT-4 constellations

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

// get the eccentric anomaly from mean anomaly using
// fixed point iteration
//
// we use this instead of Newton's method because it is
// guaranteed to work and ideally if this calculation is
// done prior to launch the extra expense is manageable
//
// although logically this would make sense in orbit-lib,
// this file is currently the only place it's used and by
// placing it here we avoid an uneccessary dependency
//
// PARAMETER ma: mean anomaly in degrees
// PARAMETER e: eccentricity
// PARAMETER guess: the initial guess in degrees
// PARAMETER depth: number of prior iterations
//
// RETURN lexicon with eccentric anomaly in degrees 
//   and iteration count
//    eccentric_anomaly - true anomaly in degrees
//    count - number of iterations required
LOCAL FUNCTION eccentric_fixed_point_iteration {
  PARAMETER ma.
  PARAMETER e.
  PARAMETER guess IS ma.
  PARAMETER depth IS 0.

  debug("iterating on eccentric anomaly").
  debug("ma: " + ma).
  debug("e: " + e).
  debug("guess: " + guess).
  debug("depth: " + depth).

  LOCAL next_guess IS (
    ma + ((e * 180 / CONSTANT:PI) * SIN(guess))
  ).
  debug("next_guess: " + next_guess).

  IF (ABS(guess - next_guess) < 0.1) {
    // answer is close enough
    debug("returning result").
    RETURN LEX(
      "eccentric_anomaly",
      next_guess,
      "count",
      depth + 1
    ).
  } ELSE {
    // iterate again
    debug("continue fixed point iteration").
    RETURN eccentric_fixed_point_iteration(
      ma, 
      e, 
      next_guess, 
      depth + 1
    ).
  }
}

// get the true anomaly from the mean anomaly
// under the hood this uses fixed point iteration, since
// there is no closed-form solution
//
// fixed point iteration is simpler and easier than
// Newton's method, but is more expensive
// ideally this should be run from archive before launch
//
// although logically this would make sense in orbit-lib,
// this file is currently the only place it's used and by
// placing it here we avoid an uneccessary dependency
//
// PARAMETER e: eccentricity
// PARAMETER ma: mean anomaly in degrees to convert
//
// RETURN the true anomaly in degrees
LOCAL FUNCTION mean_to_true {
  PARAMETER e.
  PARAMETER ma.

  debug("converting mean anomaly to true anomaly").
  debug("e: " + e).
  debug("ma: " + ma).

  LOCAL eal IS eccentric_fixed_point_iteration(ma, e).
  LOCAL ea IS eal["eccentric_anomaly"].
  debug("eccentric anomaly: " + ea).
  debug("iterations required: " + eal["count"]).

  RETURN (2 * ARCTAN((SQRT((1+e) / (1-e))) * (TAN(ea/2)))).
}

// Determine minimum semi-major axis of SAT-4 constellation
// Atmospheric height is included in the calculation
//
// PARAMETER body: parent body
//
// RETURN minimum semi-major axis in meters
GLOBAL FUNCTION sat4_min_a {
	PARAMETER body.

  debug("calculating sat4_min_a").
  debug("body: " + body).

	RETURN FLOOR((body:RADIUS + body:ATM:HEIGHT) * 7.2).
}

// Determine maximum distance between SAT-4 nodes
// Currently this returns a value higher than true max
//
// PARAMETER ra: apocenter in meters
// PARAMETER a: semi-major axis in meters
//
// RETURN max distance in meters between nodes
GLOBAL FUNCTION sat4_max_distance {
	PARAMETER ra.
  PARAMETER a.

  debug("calculating sat4_max_distance").
  debug("ra: " + ra).

  LOCAL e IS 0.28.
  debug("e: " + e).
  LOCAL ma IS 270.
  debug("ma: " + ma).
  LOCAL ta IS mean_to_true(e, ma).
  debug("ta: " + ta).
  LOCAL theta IS (ta - 90).
  debug("theta: " + theta).
  LOCAL rta IS ((a * (1 - (e^2))) / (1 + (e * COS(ta)))).
  debug("rta: " + rta).

	RETURN CEILING(
    SQRT((ra^2) + (rta^2) - (2 * ra * rta * COS(theta)))
  ).
}
