runpath("0:/helper.ks").
print "blastoff!".

doLaunch().

escapeAtmosphere().

manageThrusters().

doShutdown().

set mapview to true.

doCircularization().

doTransfer().

set mapview to false.

doHoverslam().

wait until false.