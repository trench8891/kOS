# kOS
kOS scripts for Kerbal Operating System mod

See the [kOS documentation](https://ksp-kos.github.io/KOS/) for more details

## Sublime editing
KSP-KOS provides [kOS syntax highlighting for Sublime Text 3](https://github.com/KSP-KOS/EditorTools/tree/develop/SublimeText3)

## How to Use
Copy the contents of the `Script` folder to the `Ships/Script` folder inside the KSP game directory, or create a link

### kOS Settings
Start on archive so boot files run there instead of ship volume

### General Strategy
Perform as much calculation as possible on archive and compile a very simple script to ship volume that just runs a list of delegates.

## Logging
Getting readable logs is apparently nontrivial. Files written on ship volumes are not easy to read, and the archive (where we don't have to worry about space anyway) isn't always available. For now we just have a function defined in `io-lib` to wrap around the log function. By default it's effectively a no-op, but that's easy to change.

Ideally we'd like all lib files to have no dependencies, but since the logging wrapper is defined in `io-lib` we make an exception and have that as a dependency for _everything_.

## Required Mods
- [Remote Tech](http://remotetechnologiesgroup.github.io/RemoteTech/) is assumed for checking comms
- [Kerbal Alarm Clock](https://forum.kerbalspaceprogram.com/index.php?/topic/22809-14x-kerbal-alarm-clock-v3900-mar-17/) is required for setting alarms

## Anatomy
Scrips directly beneath the `Script/` directory are intended to be run directly from the terminal, typically on the archive.

### action
This directory holds files meant to be compiled onto ship volumes and run from there.
Ideally they should have no dependencies and should be as lightweight as possible.

#### execute-delegates
Accepts a list of delegates and runs then one at a time.

### boot
See the kOS docs on [special handling of files in the "boot" directory](https://ksp-kos.github.io/KOS/general/volumes.html#special-handling-of-files-in-the-boot-directory) for details on how the boot directory works.

#### ks4
Automates launch for a tetrahedral constellation of comm satellites around Kerbin.
Handles all the calculations for the launch and defines delegates to be run on the ship volume by the `execute-delegates` script.

##### What it does
1. Define static values
2. Calculate derived values
3. Verify all values are acceptable (check against Kerbin-defined minimums)
4. Define delegates and add them to a list
    1. Define a delegate to control the actual launch
    2. Define a delegate to control orbital insertion
    3. Define a delegate to correct inclination
    4. Define a delegate to raise apoapsis at correct argument
    5. Define a delegate to verify orbit
5. Set a trigger to set the next alarm after launch
6. Compile simple action script to ship volume
7. Change to ship volume and run compiled script with list of delegates
8. Unset boot script

### lib
This directory contains scripts that define various helper functions.
Ideally none of these should have dependencies on any other files.
The one exception (for now) is `io-lib`.

#### comms-lib
Helpful functions for comms.
Inclusion of [RemoteTech](http://remotetechnologiesgroup.github.io/RemoteTech/) mod is assumed.

#### io-lib
Helpful I/O functions.
At this point just provides a handy function for terminating execution.

#### kac-lib
Helpful functions for alarms.
Inclusion of [Kerbal Alarm Clock](https://forum.kerbalspaceprogram.com/index.php?/topic/22809-16x-kerbal-alarm-clock-v31000-dec-31/) mod is assumed.

#### launch-lib
Launch trigger functions and basic launch profile

#### maneuver-lib
Library to help with maneuver nodes

#### orbit-lib
Functions for common orbital values

#### sat4-lib
Functions for SAT-4 constellations

#### store-lib
Functions for storing and retrieving data.
All functions here depend on the archive being accessible.
Reads and writes serialized lexicon on the archive to store information.
