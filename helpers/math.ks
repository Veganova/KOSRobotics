function nodeBurnDuration {
  parameter nd.
  local isp is 0.
  local e is constant():e.
  
  list engines in myEngines.
  for engine in myEngines {
    if engine:ignition and not engine:flameout {
      set isp to isp + (engine:isp * (engine:availableThrust / ship:availableThrust)).
    }
  }

  local mf is ship:mass / e^(nd:deltaV:mag / (isp * 9.80665)).
  local fuelFlow is ship:availableThrust / (isp * 9.80665).
  local burnTime is (ship:mass - mf) / fuelFlow.

  return burnTime.
}

function gravityTurn {
  return -1.035 * alt:radar^0.3998 + 90.05.
}


function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight - 4.7.
}

function stoppingDistance {
  local grav is constant():g.
  local gravForce is grav * (body:mass / body:radius^2).
  local maxDeceleration is (ship:availableThrust / ship:mass) - gravForce.
  return ship:verticalSpeed^2 / (2 * maxDeceleration).
}

function groundSlope {
  local east is vectorCrossProduct(north:vector, up:vector).

  local center is ship:position.

  // Get points (in a triangle) directly above the surface
  local p1 is body:geopositionOf(center + 5 * north:vector).
  local p2 is body:geopositionOf(center - 3 * north:vector + 4 * east).
  local p3 is body:geopositionOf(center - 3 * north:vector - 4 * east).

  // Map points onto the ground.
  // local centerPos is c:altitudePosition(c:terrainHeight).
  local p1_grnd is p1:altitudePosition(p1:terrainHeight).
  local p2_grnd is p2:altitudePosition(p2:terrainHeight).
  local p3_grnd is p3:altitudePosition(p2:terrainHeight).

  // Generate vectors from the triangle
  local v1 is p3_grnd - p1_grnd.
  local v2 is p2_grnd - p1_grnd.

  // local slope is vectorCrossProduct(v1, v2):normalized.
  // set slope_draw to vecDraw (
  //   centerPos,
  //   slope,
  //   green,
  //   "",
  //   10,
  //   true
  // ).

  return vectorCrossProduct(v1, v2):normalized.
}