// wrapper around KOSDelegate to make life easier for ksconfig
@LAZYGLOBAL OFF.

GLOBAL FUNCTION TrenchDelegate {
  PARAMETER delegate.
  LOCAL self IS LEXICON().
  self:ADD("call", delegate:CALL@). // ignore type-missing-suffix
  self:ADD("bind", delegate:BIND@). // ignore type-missing-suffix
  self:ADD("isdead", delegate:ISDEAD@). // ignore type-missing-suffix
  RETURN self.
}
