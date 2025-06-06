// wrapper around KOSDelegate to make life easier for ksconfig
@LAZYGLOBAL OFF.

GLOBAL FUNCTION TrenchDelegate {
  PARAMETER delegate.
  LOCAL self IS LEXICON().
  self:ADD("CALL", delegate:CALL@). // ignore type-missing-suffix
  self:ADD("BIND", delegate:BIND@). // ignore type-missing-suffix
  self:ADD("ISDEAD", delegate:ISDEAD@). // ignore type-missing-suffix
  RETURN self.
}
