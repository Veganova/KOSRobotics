function nodeBurnDuration {
  parameter nd.
  local isp is 0.
  local e is constant():e.
  local deltaV is nd:deltaV:mag.
  local grav is 9.80665.
  
  list engines in myEngines.
  for engine in myEngines {
    if engine:ignition and not engine:flameout {
      set isp to isp + (engine:isp * (engine:availableThrust / ship:availableThrust)).
    }
  }

  local mf is ship:mass / e^(deltaV / (isp * grav)).
  local fuelFlow is ship:availableThrust / (isp * grav).
  local burnTime is (ship:mass - mf) / fuelFlow.

  return burnTime.
}

function gravityTurn {
    return -1.035 * alt:radar^0.3998 + 90.05.
}