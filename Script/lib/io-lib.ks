// helpful I/O functions

// wrapper around debug to make logging easy
//
// PARAMETER msg: the message to log
GLOBAL FUNCTION debug {
  PARAMETER msg.

  LOCAL logfile IS "0:/logfile.txt".
  LOCAL tolog IS false.

  IF tolog {
    LOG(msg) TO logfile.
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
