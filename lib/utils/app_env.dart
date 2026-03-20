import 'package:flutter/foundation.dart';

/// DEV / PROD 환경 분리
/// --dart-define=APP_ENV=production 으로 PROD 전환
/// 기본값은 개발 환경(DEV)
class AppEnv {
  AppEnv._();

  // ─── 환경 감지 ─────────────────────────────────────────────
  static const String _env =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static bool get isDev  => _env == 'development';
  static bool get isProd => _env == 'production';

  // ─── 플래그 ────────────────────────────────────────────────
  /// DEV 환경 표시 배너 (화면 상단 노란 리본)
  static bool get showDevBanner => isDev && !kReleaseMode;

  /// 광고 Mock 표시 여부  (DEV=true → Mock UI, PROD=false → 실제 AdMob)
  static bool get useMockAds => isDev;

  /// 서버 로그 콘솔 출력
  static bool get enableLogs => isDev;

  // ─── AdMob Unit IDs ────────────────────────────────────────
  /// 배너 광고 Unit ID
  static String get bannerAdUnitId {
    if (useMockAds) return 'ca-app-pub-3940256099942544/6300978111'; // Google 테스트 ID (DEV)
    return 'ca-app-pub-4743333137314535/8384748554'; // 실제 배너 광고 ID
  }

  /// 전면(Interstitial) 광고 Unit ID
  static String get interstitialAdUnitId {
    if (useMockAds) return 'ca-app-pub-3940256099942544/1033173712'; // Google 테스트 ID (DEV)
    return 'ca-app-pub-4743333137314535/8384748554'; // TODO: 전면 광고 단위 별도 생성 필요
  }

  // ─── Gemini AI ────────────────────────────────────────────
  /// AI 기능은 백엔드를 통해 제공 (항상 활성화)
  static const bool geminiEnabled = true;

  // ─── 환경 레이블 ───────────────────────────────────────────
  static String get label => isDev ? 'DEV' : 'PROD';
  static String get fullLabel => isDev ? '개발(DEV)' : '운영(PROD)';
}
