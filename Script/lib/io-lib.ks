// helpful I/O functions

// fetch a list of the names of every vessel
//
// RETURN a LIST with the names of every vessel
LOCAL FUNCTION shipnames {
  LOCAL nameslist IS LIST().

  LIST TARGETS IN tars.
  FOR ves IN tars {
    nameslist:ADD(ves:NAME).
  }

  RETURN nameslist.
}

// fetch the namespace for the save
//
// RETURN a namespace string
GLOBAL FUNCTION namespace {
  LOCAL ns IS "default".
  FOR n IN shipnames() {
    IF n:STARTSWITH("namespace_") {
      SET ns TO n:SPLIT("_")[1].
      BREAK.
    }
  }

  RETURN ns.
}

// some startup stuff
LOCAL logfile IS (
  "0:/data/" + 
  namespace() + 
  "/logs/" + 
  SHIP:NAME:REPLACE(" ", "_") + 
  ".txt"
).
PRINT("logfile: " + logfile).
LOCAL shiplog IS "1:/log.txt".
DELETEPATH(logfile). // remove duplicate logfile

// move contents of log on ship to archive
// should only be called when archive is accessible
LOCAL FUNCTION movelog {
  IF EXISTS(shiplog) {
    OPEN(logfile):WRITE(OPEN(shiplog):READALL).
    DELETEPATH(shiplog).
  }
}

ON ADDONS:RT:HASKSCCONNECTION(SHIP) {
  IF ADDONS:RT:HASKSCCONNECTION(SHIP) {
    movelog().
  }
  RETURN true.
}

// wrapper around LOG to make logging easy
//
// PARAMETER msg: the message to log
GLOBAL FUNCTION debug {
  PARAMETER msg.

  LOCAL logmsg IS msg.
  IF (msg:LENGTH > 0) {
    SET logmsg TO (FLOOR(TIME:SECONDS) + ": " + msg).
  }

  IF ADDONS:RT:HASKSCCONNECTION(SHIP) {
    LOG(logmsg) TO logfile.
  } ELSE {
    LOG(logmsg) TO shiplog.
  }
}

debug("loading " + SCRIPTPATH()).

// terminate the running script by forcing an exception
//
// PARAMETER msg: message to print before terminating
GLOBAL FUNCTION terminate {
	PARAMETER msg.

	PRINT("terminating: " + msg).
  debug("terminating: " + msg).
	LOCAL segfault IS lexicon()["terminate"].
}
