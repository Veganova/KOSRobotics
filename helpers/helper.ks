
runpath("0:/helpers/math.ks").
runpath("0:/helpers/ml_util.ks").
runpath("0:/helpers/exec.ks").


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
  local initialManeuverNodeParams is list(prograde).
  set prograde to iterativeOptimize(initialManeuverNodeParams, circularCost@).
  wait until altitude > 72000.
  createAndExecuteNode(list(time:seconds + eta:apoapsis, 0, 0, prograde[0])).
}

function createAndExecuteNode {
  parameter nodeVals.
  local nd is node(nodeVals[0], nodeVals[1], nodeVals[2], nodeVals[3]).
  add nd.

  executeNode(nd).
}

function transferToMun {
  local timeToMaxMunAngle is maximizeAngleToTargetInOrbit(MUN).

  // Look at mvn paths near the "timeToMaxMunAngle" colinear point.
  local initalManeuverNodeParams is list(timeToMaxMunAngle, 0, 0, 0).
  local transfer to iterativeOptimize(initalManeuverNodeParams, costToMun@).
  createAndExecuteNode(transfer).
  warpToTarget(MUN).
}


function hoverslam {
  lock steering to srfRetrograde.
  lock throttlePercentage to stoppingDistance() / distanceToGround().
  // set warp to 4.
  // wait until throttlePercentage > 0.5.
  // set warp to 0.
  wait until throttlePercentage > 1.
  lock throttle to throttlePercentage.

  groundSlope().
  when distanceToGround() < 500 then { gear on. }
  wait until ship:verticalSpeed > 0.
  lock throttle to 0.
  lock steering to groundSlope().
  wait 30.
  unlock steering.
}

function warpToTarget {
  parameter target.
  wait 1.
  warpto(time:seconds + obt:nextPatchEta - 4).
  wait until body = target.
  wait 1.
}