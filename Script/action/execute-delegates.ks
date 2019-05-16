// execute each delegate in a list
// useful for when you want to do a lot of calculations
// but want to keep the data on a volume low

PARAMETER delegates.

RUNONCEPATH("/lib/io-lib").

PRINT("executing " + delegates:LENGTH + " delegates").
debug("executing " + delegates:LENGTH + " delegates") 
 .
FOR delegate IN delegates {
  debug("executing " + delegate).
  delegate().
  debug("").
}

PRINT("delegate execution complete").
debug("delegate execution complete").
debug("").
