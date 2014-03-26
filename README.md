Elektrotickle
=============

Linear circuit simulation in Matlab

This program calculates the transfer functions and noise of linear circuits
composed of passive components and opamps.  It is essentially a 
re-implementation in MATLAB of the circuit simulation portions of LISO.  

Motivations:
 * Learn how LISO works
 * Simulate circuits in a 100% pure Matlab environment without the need to call an external executable
 * Embed the simulation in a higher-level numerical computing environment with scripting, plotting, and optimization routines.
 * Idea for future: Can we also use the symbolic computing toolbox to get symbolic transfer functions for simple circuits?

Features that currently work:
 * Parses LISO input file
 * Parses LISO opamp library
 * Currently understands resistors, capacitors, and opamps.
 * Produces resulting transfer functions and noises, agrees with LISO for test cases applied so far.
 
Not yet implemented:
 * Only does voltage-to-voltage transfer functions (no 'current' inputs or outputs)
 * None of LISO's other fancy features (fitting, etc)

