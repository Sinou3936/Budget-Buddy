// Flutter가 웹으로 빌드될 때 같은 origin(port 5060)에서 실행되지만
// API 서버는 3000포트. GetServiceUrl을 통한 실제 URL이 필요합니다.
// 개발 편의를 위해 환경별 baseUrl을 설정합니다.

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // ─── API Base URL ───────────────────────────────────────────────────
  // 웹 빌드 시 같은 호스트의 3000 포트로 라우팅
  // kIsWeb이면 현재 페이지 origin의 포트만 3000으로 변경
  static String get apiBaseUrl {
    if (kIsWeb) {
      // 브라우저 환경: window.location.origin의 포트를 3000으로 교체
      // e.g. https://5060-xxx.sandbox.novita.ai → https://3000-xxx.sandbox.novita.ai
      // dart:html을 직접 import하면 non-web에서 에러나므로 Uri 사용
      try {
        // ignore: undefined_identifier
        final origin = Uri.base;
        final apiOrigin = origin.replace(port: 3000);
        return apiOrigin.toString().replaceAll(RegExp(r'/$'), '');
      } catch (_) {
        return 'http://localhost:3000';
      }
    }
    return 'http://10.0.2.2:3000'; // Android Emulator → host 3000
  }

  // ─── App Constants ──────────────────────────────────────────────────
  static const String appVersion = '1.0.0';
  static String get platform => kIsWeb ? 'web' : 'android';
}
