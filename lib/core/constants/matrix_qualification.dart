// Position fields of the qualification matrix.
//
// The matrix is a flat 2-level tree with no branch column of its own, so a
// branch's stations are expressed as a top-level field whose sub-fields are
// the stations. Which of those fields a rater sees is decided here, mirroring
// the same split in the web app's matrix-qualification.constants.ts.

/// "Pozitsiyada ishlash ko'nikmalari" — the restaurant stations (Kassa,
/// Burger, Fri, Pitsa, ...). The default for every branch not listed below.
const String kRestaurantPositionSkillsUuid =
    '57d49168-3847-4041-81d9-2b1f86686ed9';

/// "Central Kitchen pozitsiyalari" — the production lines (Pizza bo'limi,
/// Kotlet bo'limi, Go'sht bo'limi — Qassob, ...).
const String kCentralKitchenPositionSkillsUuid =
    'e423680d-af87-4879-9c74-b8b434551e0d';

/// Branches whose stations are not the restaurant ones.
const Map<int, String> kPositionSkillsUuidByBranch = {
  7: kCentralKitchenPositionSkillsUuid,
};

/// Every position field, whichever branch it belongs to.
const Set<String> kPositionSkillsUuids = {
  kRestaurantPositionSkillsUuid,
  kCentralKitchenPositionSkillsUuid,
};

/// The position field a branch rates on. Falls back to the restaurant set, so
/// a branch only needs an entry above when it differs.
String positionSkillsUuidForBranch(int? branchId) =>
    kPositionSkillsUuidByBranch[branchId] ?? kRestaurantPositionSkillsUuid;

/// Whether a top-level matrix field should be shown to a rater from [branchId].
///
/// Position fields are branch-specific — Central Kitchen rates its production
/// lines and nobody else sees them, every other branch rates the restaurant
/// stations. Fields that are not position fields (Soft Skills, HACCP, ...)
/// apply company-wide and stay visible to everyone.
bool isQualificationFieldVisibleForBranch(String? uuid, int? branchId) {
  if (uuid == null || !kPositionSkillsUuids.contains(uuid)) return true;
  return uuid == positionSkillsUuidForBranch(branchId);
}
