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

// ─────────────────────── Cross-branch raters ───────────────────────

/// Raters who evaluate a branch other than the one they are employed at,
/// keyed by their own employee id. They rate that branch *instead of* their
/// own — the matrix page shows the target branch's employees and stations,
/// never their own.
///
/// Hardcoded on purpose: this is a two-person exception, so changing it needs
/// an app release. If the list starts churning, move the mapping behind the
/// API (an allowlist served with the identity) and keep
/// [matrixRatingBranchId] as the single place the app reads it from.
const Map<int, int> kMatrixRatingBranchByEmployee = {
  // <employee id>: 7, // <name> — employed at branch 2, rates Central Kitchen
  // <employee id>: 7, // <name> — employed at branch 2, rates Central Kitchen
  226: 7,
  220: 7,
  // 1748: 7, // testing
};

/// The branch a rater fills the matrix for: their override if they have one,
/// otherwise the branch they work at.
int? matrixRatingBranchId({int? employeeId, int? branchId}) =>
    kMatrixRatingBranchByEmployee[employeeId] ?? branchId;
