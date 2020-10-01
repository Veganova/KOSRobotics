set STEP_SIZES to list(80, 8, 1).

// Apply Hillclimbing at different step sizes 
function iterativeOptimize {
  parameter inp, evaluationFunc.
  for delta in STEP_SIZES {
    until false {
      local oldCost is evaluationFunc(inp).
      set inp to optimize(inp, delta, evaluationFunc).
      if oldCost <= evaluationFunc(inp) {
        break.
      }
    }
  }
  return inp.
}

// Run discrete hill climbing on an input array of any size
// Input will usually be some or all of the maneuver node components.
function optimize {
  parameter inp, delta, evaluationFunc.
  local costToBeat is evaluationFunc(inp).
  local best is inp.
  local i is 0.

  // Try all combinations of inc/dec to see which yields the best cost
  until i >= inp:length {
    local incremented is inp:copy().
    set incremented[i] to incremented[i] + delta.
    local decremented is inp:copy().
    set decremented[i] to decremented[i] - delta.
    
    local candidateCost is evaluationFunc(incremented).
    if candidateCost < costToBeat {
      set costToBeat to candidateCost.
      set best to incremented.
    }
    set candidateCost to evaluationFunc(decremented).
    if candidateCost < costToBeat {
      set costToBeat to candidateCost.
      set best to decremented.
    }
    set i to i + 1.
  }
  return best.
}

// ------------- COST FUNCTIONS -------------

// Add maneuver node with the provided prograde value and return how circular the orbit appears 
function circularCost {
  parameter inp.
  local nd is node(time:seconds + eta:apoapsis, 0, 0, inp[0]).
  add nd.
  local cost is nd:orbit:eccentricity.
  remove nd.
  return cost.
}

function costToMun {
  parameter inp.
  return costToTarget(inp, MUN).
}

// Returns the time at which the angle to the target is maximized during an orbit
// This will give us a point this is colinear to the target.
// Example if target=Mun, body=Kerbin, we want the line to be: [spaceship], [Kerbin], [Mun]
function maximizeAngleToTargetInOrbit {
  parameter target.
  local lowerTimeBound is time:seconds + 30.
  local upperTimeBound is time:seconds + 30 + orbit:period.
  return ternarySearch(angleToTargetFunc(target), lowerTimeBound, upperTimeBound, 2).
}

// ------------- end of Cost functions -------------


// ------------- cost function helpers -------------

function angleToTargetFunc {
  parameter target.

  return {
    parameter t.
    local vecToShip is Kerbin:position - positionAt(ship, t).
    local vecToTarget is Kerbin:position - positionAt(target, t).
    return vectorAngle(vecToShip, vecToTarget).
  }.
}

function costToTarget {
  parameter inp, target.
  local nd is node(inp[0], inp[1], inp[2], inp[3]).
  if inp[0] < time:seconds + 15 {
    return 100000000. // large value to heavily dis-incentify 
  }
  add nd.
  local result is 0.
  if nd:orbit:hasNextPatch {
    // In the target orbit
    set result to nd:orbit:nextPatch:periapsis.
  } else {
    set result to distanceFromApoapsisToTarget(nd, target).
  }
  remove nd.
  return result.
}

function distanceFromApoapsisToTarget {
  parameter nd, target.

  local lowerTimeBound is time:seconds + nd:eta.
  local upperTimeBound is time:seconds + nd:eta + (nd:orbit:period / 2).
  local timeToApoapsis is ternarySearch(getAltitude@, lowerTimeBound, upperTimeBound, 2).
  return (positionAt(ship, timeToApoapsis) - positionAt(target, timeToApoapsis)):mag.
}

function getAltitude {
  parameter time.
  local pos to positionAt(ship, time).
  // Convert to a standard altitude (works when out of Kerbin orbit)
  return Kerbin:altitudeOf(pos). 
}

// Finds max of a unimodal function.
// https://en.wikipedia.org/wiki/Ternary_search
function ternarySearch {
  parameter evalFunc, l, r, delta.
  until false {
    if abs(r - l) < delta {
      return (l + r) / 2.
    }
    local leftThird is l + (r - l) / 3.
    local rightThird is r - (r - l) / 3.
    if evalFunc(leftThird) < evalFunc(rightThird) {
      set l to leftThird.
    } else {
      set r to rightThird.
    }
  }
}
