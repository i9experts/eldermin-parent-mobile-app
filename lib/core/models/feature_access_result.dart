/// Wraps a response from a parent-portal endpoint that may return a
/// suspended-feature placeholder (`{ suspended: true, feature, reason }`,
/// HTTP 200) instead of real data, when a school admin has paused that
/// premium feature for this parent + child. See eldermin-backend's
/// ParentAccessControlService for the server side.
class FeatureAccessResult<T> {
  final bool suspended;
  final String? reason;
  final T? data;

  const FeatureAccessResult.data(T this.data)
      : suspended = false,
        reason = null;

  const FeatureAccessResult.suspended({this.reason})
      : suspended = true,
        data = null;

  static bool isSuspendedShape(dynamic raw) => raw is Map && raw['suspended'] == true;

  static FeatureAccessResult<T> fromRaw<T>(dynamic raw, T Function(dynamic raw) parse) {
    if (isSuspendedShape(raw)) {
      return FeatureAccessResult<T>.suspended(reason: (raw as Map)['reason']?.toString());
    }
    return FeatureAccessResult<T>.data(parse(raw));
  }
}
