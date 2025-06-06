// wrapper around KACAddon to make life easier for ksconfig
@LAZYGLOBAL OFF.

GLOBAL kac_available IS FALSE.

IF ADDONS:AVAILABLE("KAC") {
  SET kac_available TO ADDONS:KAC:AVAILABLE(). // ignore type-missing-suffix
}

GLOBAL FUNCTION kac_alarms {
  LOCAL alarms IS LIST().
  IF kac_available {
    SET alarms TO ADDONS:KAC:ALARMS(). // ignore type-missing-suffix
  }
  RETURN alarms.
}

GLOBAL FUNCTION TrenchKACAlarm {
  PARAMETER alarm.
  LOCAL self IS LEXICON().
  self:ADD("id", "").
  self:ADD("name", {return "".}).
  self:ADD("action", {return "".}).
  self:ADD("type", "").
  self:ADD("notes", {return "".}).
  self:ADD("remaining", {return -1.}).
  self:ADD("repeat", {return FALSE.}).
  self:ADD("repeat_period", {return -1.}).
  self:ADD("origin_body", {return "".}).
  self:ADD("target_body", {return "".}).
  
  IF kac_available AND alarm:ISTYPE("KACAlarm") {
    SET self["id"] TO alarm:ID(). // ignore type-missing-suffix
    SET self["name"] TO alarm:NAME@. // ignore type-missing-suffix
    SET self["action"] TO alarm:ACTION@. // ignore type-missing-suffix
    SET self["type"] TO alarm:TYPE(). // ignore type-missing-suffix
    SET self["notes"] TO alarm:NOTES@. // ignore type-missing-suffix
    SET self["remaining"] TO alarm:REMAINING@. // ignore type-missing-suffix
    SET self["repeat"] TO alarm:REPEAT@. // ignore type-missing-suffix
    SET self["repeat_period"] TO alarm:REPEATPERIOD@. // ignore type-missing-suffix
    SET self["origin_body"] TO alarm:ORIGINBODY@. // ignore type-missing-suffix
    SET self["target_body"] TO alarm:TARGETBODY@. // ignore type-missing-suffix
  }

  RETURN self.
}
