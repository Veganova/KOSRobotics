//ORBIT

//First, we'll clear the terminal screen to make it look nice
CLEARSCREEN.

//Next, we'll lock our throttle to 100%.
SET MYTHROTTLE TO 1.0.
LOCK THROTTLE TO MYTHROTTLE.   // 1.0 is the max, 0.0 is idle.

WHEN MAXTHRUST = 0 THEN {
    STAGE.
    PRESERVE.
}.

WHEN STAGE:SOLIDFUEL < 0.1 THEN {
	STAGE.
}.

SET MYSTEER TO HEADING(90,90).
set reached_apoapsis to false.
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
UNTIL SHIP:PERIAPSIS > 70000 AND SHIP:APOAPSIS <= (SHIP:PERIAPSIS * 1.09)   { 

	if reached_apoapsis {
		set MYTHROTTLE to 0.1.
		set MYSTEER to HEADING(90,-15).
	} else if SHIP:APOAPSIS < 90000 {	
		if SHIP:ALTITUDE < 500 {
			set MYSTEER to HEADING(90,90).
		} else if SHIP:ALTITUDE < 4000 {
			set MYSTEER to HEADING(90,80).
		} else if SHIP:ALTITUDE < 9000 {
			set MYSTEER to HEADING(90,65).
		} else if SHIP:ALTITUDE < 16000 {
			set MYSTEER to HEADING(90,55).
		} else if SHIP:ALTITUDE <  25000 {
			set MYSTEER to HEADING(90,45).
		} else if SHIP:ALTITUDE < 40000 {
			set MYSTEER to HEADING(90,30).
		} else if SHIP:ALTITUDE < 50000 {
			set MYSTEER to HEADING(90,15).
		} else if SHIP:ALTITUDE < 70000 {
			set MYSTEER to HEADING(90,5).
		} 
    } else {
    	set MYTHROTTLE to 0.0.
    	set MYSTEER to HEADING(90,-15).
    	if abs(SHIP:ALTITUDE - SHIP:APOAPSIS) <= 6000 {
    		PRINT "BURNING AT APOAPSIS".
    		set reached_apoapsis to true.
    	} 
    }
    
    PRINT ROUND(SHIP:APOAPSIS,0) AT (0,17).
    print ROUND(SHIP:ALTITUDE,0) AT (0,18).
    print SHIP:APOAPSIS at (0, 25).
    print SHIP:PERIAPSIS at (0, 26).
    print (SHIP:APOAPSIS - SHIP:PERIAPSIS) at (0, 27).
    
}.

PRINT "Reached Orbit".
LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
