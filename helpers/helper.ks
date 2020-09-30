
runpath("0:/helpers/math.ks").

runpath("0:/helpers/exec.ks").

set STEP_SIZES to list(80, 8, 1).

function blastOff {
  lock throttle to 1.
  stageOnReady().
}

function engageThrusters {
  if not(defined prevThrust) {
    global prevThrust is ship:availablethrust.
  }
  if prevThrust - 12 > ship:availablethrust {
    until false {
      stageOnReady(). wait 1.
      if ship:availableThrust > 0 { 
        break.
      }
    }
    global prevThrust is ship:availablethrust.
  }
}

function escapeAtmosphere {
  lock targetAngle to gravityTurn().
  lock steering to heading(90, targetAngle).

  until apoapsis > 100000 {
    engageThrusters().
  }

  lock throttle to 0.
  lock steering to prograde.
}

function stageOnReady {
  wait until stage:ready.
  stage.
}

function makeOrbitCircular {
  local prograde is 0.
  set prograde to iterativeOptimize(list(prograde), circularCost@)[0].
  wait until altitude > 72000.
  // local mList is list(time:seconds + eta:apoapsis, 0, 0, prograde).
  // local nd is node(mList[0], mList[1], mList[2], mList[3]).
  // add nd.
  // local startTime is calculateStartTime(nd).
  // warpto(startTime - 15).
  // executeNode(nd).
  executeManeuver(list(time:seconds + eta:apoapsis, 0, 0, prograde)).
}

function protectFromPast {
  parameter originalFunction.
  local replacementFunction is {
    parameter inp.
    if inp[0] < time:seconds + 15 {
      return 2^64.
    } else {
      return originalFunction(inp).
    }
  }.
  return replacementFunction@.
}

function doTransfer {
  local startSearchTime is ternarySearch(
    angleToMun@,
    time:seconds + 30, 
    time:seconds + 30 + orbit:period,
    1
  ).
  local transfer is list(startSearchTime, 0, 0, 0).
  set transfer to iterativeOptimize(transfer, protectFromPast(munTransferCost@)).
  executeManeuver(transfer).
  wait 1.
  warpto(time:seconds + obt:nextPatchEta - 5).
  wait until body = Mun.
  wait 1.
}

function angleToMun {
  parameter t.
  return vectorAngle(
    Kerbin:position - positionAt(ship, t),
    Kerbin:position - positionAt(Mun, t)
  ).
}

function munTransferCost {
  parameter inp.
  local nd is node(inp[0], inp[1], inp[2], inp[3]).
  add nd.
  local result is 0.
  if nd:orbit:hasNextPatch {
    set result to nd:orbit:nextPatch:periapsis.
  } else {
    set result to distanceToMunAtApoapsis(nd).
  }
  remove nd.
  return result.
}

function distanceToMunAtApoapsis {
  parameter nd.
  local apoapsisTime is ternarySearch(
    altitudeAt@, 
    time:seconds + nd:eta, 
    time:seconds + nd:eta + (nd:orbit:period / 2),
    1
  ).
  return (positionAt(ship, apoapsisTime) - positionAt(Mun, apoapsisTime)):mag.
}

function altitudeAt {
  parameter t.
  return Kerbin:altitudeOf(positionAt(ship, t)).
}

function ternarySearch {
  parameter f, left, right, absolutePrecision.
  until false {
    if abs(right - left) < absolutePrecision {
      return (left + right) / 2.
    }
    local leftThird is left + (right - left) / 3.
    local rightThird is right - (right - left) / 3.
    if f(leftThird) < f(rightThird) {
      set left to leftThird.
    } else {
      set right to rightThird.
    }
  }
}


// ----- COST FUNCTIONS -----

// Add maneuver node and check 
function circularCost {
  parameter inp.
  local nd is node(time:seconds + eta:apoapsis, 0, 0, inp[0]).
  add nd.
  local cost is nd:orbit:eccentricity.
  remove nd.
  return cost.
}

// Apply Hillclimbing at different step sizes 
function iterativeOptimize {
  parameter inp, evaluationFunc.
  for stepSize in STEP_SIZES {
    until false {
      local oldCost is evaluationFunc(inp).
      set inp to improve(inp, stepSize, evaluationFunc).
      if oldCost <= evaluationFunc(inp) {
        break.
      }
    }
  }
  return inp.
}

function improve {
  parameter inp, stepSize, evaluationFunc.
  local costToBeat is evaluationFunc(inp).
  local bestCandidate is inp.
  local candidates is list().
  local index is 0.
  until index >= inp:length {
    local incCandidate is inp:copy().
    local decCandidate is inp:copy().
    set incCandidate[index] to incCandidate[index] + stepSize.
    set decCandidate[index] to decCandidate[index] - stepSize.
    candidates:add(incCandidate).
    candidates:add(decCandidate).
    set index to index + 1.
  }
  for candidate in candidates {
    local candidateCost is evaluationFunc(candidate).
    if candidateCost < costToBeat {
      set costToBeat to candidateCost.
      set bestCandidate to candidate.
    }
  }
  return bestCandidate.
}

function executeManeuver {
  parameter mList.
  local nd is node(mList[0], mList[1], mList[2], mList[3]).
  add nd.
  local startTime is calculateStartTime(nd).
  warpto(startTime - 15).
  wait until time:seconds > startTime - 10.
  executeNode(nd).
  // lockSteeringAtManeuverTarget(nd).
  // wait until time:seconds > startTime.
  // lock throttle to 1.
  // until isManeuverComplete(nd) {
  //   engageThrusters().
  // }
  // lock throttle to 0.
  // unlock steering.
  // remove nd.
}

function addManeuverToFlightPlan {
  parameter nd.
  add nd.
}

function calculateStartTime {
  parameter nd.
  return time:seconds + nd:eta - nodeBurnDuration(nd) / 2.
}

function lockSteeringAtManeuverTarget {
  parameter nd.
  lock steering to nd:burnvector.
}

function isManeuverComplete {
  parameter nd.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to nd:burnvector.
  }
  if vang(originalVector, nd:burnvector) > 90 {
    declare global originalVector to -1.
    return true.
  }
  return false.
}

function doHoverslam {
  lock steering to srfRetrograde.
  lock pct to stoppingDistance() / distanceToGround().
  set warp to 4.
  wait until pct > 0.1.
  set warp to 3.
  wait until pct > 0.4.
  set warp to 0.
  wait until pct > 1.
  lock throttle to pct.
  when distanceToGround() < 500 then { gear on. }
  wait until ship:verticalSpeed > 0.
  lock throttle to 0.
  lock steering to groundSlope().
  wait 30.
  unlock steering.
}

function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight - 4.7.
}

function stoppingDistance {
  local grav is constant():g * (body:mass / body:radius^2).
  local maxDeceleration is (ship:availableThrust / ship:mass) - grav.
  return ship:verticalSpeed^2 / (2 * maxDeceleration).
}

function groundSlope {
  local east is vectorCrossProduct(north:vector, up:vector).

  local center is ship:position.

  local a is body:geopositionOf(center + 5 * north:vector).
  local b is body:geopositionOf(center - 3 * north:vector + 4 * east).
  local c is body:geopositionOf(center - 3 * north:vector - 4 * east).

  local a_vec is a:altitudePosition(a:terrainHeight).
  local b_vec is b:altitudePosition(b:terrainHeight).
  local c_vec is c:altitudePosition(c:terrainHeight).

  return vectorCrossProduct(c_vec - a_vec, b_vec - a_vec):normalized.
}