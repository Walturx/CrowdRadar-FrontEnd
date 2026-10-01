/// Shared karma counter of the signed-in fake account: the report fake adds to
/// it and the profile fake reads it, so both agree like the real backend.
class KarmaFake {
  int total;

  KarmaFake([this.total = 100]);
}
