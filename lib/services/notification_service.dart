import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // ─── 알림 설정 (SharedPreferences 기반) ─────────────────
  static bool _budgetEnabled  = true;
  static bool _anomalyEnabled = true;
  static bool _reportEnabled  = true;

  static bool get budgetEnabled  => _budgetEnabled;
  static bool get anomalyEnabled => _anomalyEnabled;
  static bool get reportEnabled  => _reportEnabled;

  static Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetEnabled  = prefs.getBool('notif_budget')  ?? true;
    _anomalyEnabled = prefs.getBool('notif_anomaly') ?? true;
    _reportEnabled  = prefs.getBool('notif_report')  ?? true;
  }

  static Future<void> saveSetting(String key, bool value) async {
    switch (key) {
      case 'budget':  _budgetEnabled  = value; break;
      case 'anomaly': _anomalyEnabled = value; break;
      case 'report':  _reportEnabled  = value; break;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$key', value);
  }

  static final _budgetChannel = AndroidNotificationDetails(
    'budget_alerts',
    '예산 알림',
    channelDescription: '카테고리별 예산 초과 시 알림을 보냅니다',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static final _anomalyChannel = AndroidNotificationDetails(
    'anomaly_alerts',
    '이상 지출 감지',
    channelDescription: '평균보다 높은 지출이 감지되면 알림을 보냅니다',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  static final _reportChannel = AndroidNotificationDetails(
    'ai_report',
    'AI 월말 리포트',
    channelDescription: 'AI가 작성한 월말 소비 분석 리포트 알림',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  // ─── 초기화 ─────────────────────────────────────────────
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Android 13+ 알림 권한 요청
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _loadSettings();
  }

  // ─── 예산 초과 알림 ──────────────────────────────────────
  static Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double limit,
  }) async {
    if (!_budgetEnabled) return;
    final percent = ((spent / limit) * 100).toInt();
    final spentStr = _fmt(spent);
    final limitStr = _fmt(limit);
    await _plugin.show(
      category.hashCode.abs() % 10000,
      '⚠️ $category 예산 초과',
      '$category 예산의 $percent% 사용 중 ($spentStr원 / $limitStr원)',
      NotificationDetails(android: _budgetChannel),
    );
  }

  // ─── 이상 지출 감지 알림 ─────────────────────────────────
  static Future<void> showAnomalyAlert({
    required String category,
    required double amount,
    required String explanation,
  }) async {
    if (!_anomalyEnabled) return;
    await _plugin.show(
      9001,
      '🔍 $category 이상 지출 감지',
      explanation,
      NotificationDetails(android: _anomalyChannel),
    );
  }

  // ─── AI 월말 리포트 준비 알림 ────────────────────────────
  static Future<void> showMonthlyReportReady() async {
    if (!_reportEnabled) return;
    await _plugin.show(
      9002,
      '📊 AI 월말 리포트 준비 완료',
      '이번 달 소비 분석 리포트가 작성됐습니다. 확인해보세요!',
      NotificationDetails(android: _reportChannel),
    );
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────
  static String _fmt(double amount) {
    if (amount >= 10000) {
      final man = (amount / 10000).floor();
      final rem = (amount % 10000).toInt();
      return rem == 0 ? '$man만' : '$man만 ${rem}';
    }
    return amount.toInt().toString();
  }
}
