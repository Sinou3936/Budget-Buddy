// Flutter가 웹으로 빌드될 때 같은 origin(port 5060)에서 실행되지만
// API 서버는 4949포트. GetServiceUrl을 통한 실제 URL이 필요합니다.
// 개발 편의를 위해 환경별 baseUrl을 설정합니다.

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // ─── API Base URL ───────────────────────────────────────────────────
  //
  //  📱 Android Emulator : http://10.0.2.2:4949
  //  📱 실기기(로컬 Wi-Fi) : http://192.168.x.x:4949  ← PC IP로 교체
  //  📱 실기기(ngrok)     : https://xxxx.ngrok-free.app
  //  🌐 Web 빌드         : 현재 호스트의 :4949 포트 자동 계산
  //
  // ─── 실기기 테스트 시 아래 값을 수정하세요 ──────────────────────────
  /// Wi-Fi 직접 연결: PC의 로컬 IP 입력 (ipconfig / ifconfig로 확인)
  // ignore: unused_field
  static const String _localIp = '192.168.45.188';  // ← 본인 PC IP로 교체

  /// ngrok 사용 시: ngrok URL 입력 (https://xxxx.ngrok-free.app)
  static const String _ngrokUrl = '';  // 비어 있으면 _localIp 사용

  static String get apiBaseUrl {
    if (kIsWeb) {
      // 브라우저 환경: window.location.origin의 포트를 4949으로 교체
      try {
        final origin = Uri.base;
        final apiOrigin = origin.replace(port: 4949);
        return apiOrigin.toString().replaceAll(RegExp(r'/$'), '');
      } catch (_) {
        return 'http://localhost:4949';
      }
    }
    // Android 에뮬레이터: 10.0.2.2 = host machine
    // Android 실기기: ngrok URL 또는 로컬 IP
    if (_ngrokUrl.isNotEmpty) return _ngrokUrl;
    return 'http://10.0.2.2:4949'; // 에뮬레이터 기본값
    // 실기기 사용 시 아래 줄 주석 해제:
    // return 'http://$_localIp:4949';
  }

  // ─── App Constants ──────────────────────────────────────────────────
  static const String appVersion = '1.0.0';
  static String get platform => kIsWeb ? 'web' : 'android';
}
