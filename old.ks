function doStage {
    wait until stage:ready.
    stage.
}

function blastOff {
    lock throttle to 1.
    doStage().
}

function gravitySteer {
    lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
    set targetDirection to 90.

    lock steering to heading(targetDirection, targetPitch).
}

function manageThrusters {
    if not(defined prevShipThrust) {
        declare global prevShipThrust to ship:availablethrust.
    }
    if ship:availableThrust < (prevShipThrust - 10) {
        doStage(). wait 1.
        declare global prevShipThrust to ship:availablethrust.
    }
}

function coast {
    lock throttle to 0.
    lock steering to prograde.
    wait until false.
}

function launch {
    blastOff().

    gravitySteer().

    until apoapsis > 100000 {
        manageThrusters().
    }

    coast().
}

launch().
