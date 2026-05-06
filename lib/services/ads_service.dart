/// Resolves which AdMob ad-unit IDs to use at build time.
///
/// The real production ad-unit IDs are kept out of git via `--dart-define`.
/// Default values are Google's published TEST ad-unit IDs, which serve a
/// "Test Ad" filler in development without spending real ad inventory or
/// triggering AdMob's invalid-traffic detection.
///
/// To bake in the real banner ID for a release build:
///
///   flutter build appbundle --release \
///     --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
class AdsService {
  // Google's documented test banner unit ID. Safe to ship to test builds.
  // https://developers.google.com/admob/flutter/test-ads
  static const String _testBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String bannerUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: _testBannerUnitId,
  );

  /// True when the build is using the test ID (no override passed at build time).
  /// Useful for log messages or debug overlays.
  static bool get isUsingTestIds => bannerUnitId == _testBannerUnitId;
}
