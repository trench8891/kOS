// functions for storing and retrieving data
// all functions here depend on the archive being accessible

RUNONCEPATH("/lib/io-lib").
debug("loading " + SCRIPTPATH()).

LOCAL store_location IS 
	PATH("0:/data/" + namespace() + "/store.json").
debug("store location: " + store_location).

// Retrieve the store
//
// Return the deserialized lexicon from store
LOCAL FUNCTION load_store {
	debug("loading store").
	IF NOT EXISTS(store_location) {
		debug("initializing store").
		replace_store(lexicon()).
	}
	RETURN READJSON(store_location).
}

// Completely replace whatever is in the store with a new lexicon
//
// PARAMETER lex: the lexicon to serialize
LOCAL FUNCTION replace_store {
	PARAMETER lex.

	debug("replacing store").
	debug("lex: " + lex).

	WRITEJSON(lex, store_location).
}

// Retrieve a single value from the store
//
// PARAMETER key: the key to retrieve from the store
// PARAMETER fallback: value to return if the key does not exist, default boolean false
//
// RETURN the value from the store
GLOBAL FUNCTION value_from_store {
	PARAMETER key.
	PARAMETER fallback IS false.

	debug("fetching value from store").
	debug("key: " + key).
	debug("fallback: " + fallback).

	LOCAL store IS load_store().
	debug("store: " + store).

	IF NOT store:HASKEY(key) {
		debug("key not found, returning fallback").
		SET store[key] TO fallback.
		replace_store(store).
	}

	RETURN store[key].
}

// Write a value to the store
//
// PARAMETER key: key of the entry to write
// PARAMETER value: value of the entry to write
//
// RETURN the deserialized store after the addition
GLOBAL FUNCTION add_to_store {
	PARAMETER key.
	PARAMETER value.

	debug("adding value to store").
	debug("key: " + key).
	debug("value: " + value).

	LOCAL store IS load_store().
	debug("store: " + store).
	SET store[key] TO value.

	replace_store(store).
	RETURN store.
}
