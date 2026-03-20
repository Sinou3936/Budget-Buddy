import '../models/transaction.dart';
import 'api_client.dart';
import '../utils/app_config.dart';

/// 모든 API 호출을 담당하는 서비스
/// 하드코딩된 데이터를 모두 서버에서 가져옴
class BudgetApiService {
  BudgetApiService._();
  static final BudgetApiService instance = BudgetApiService._();
  final _client = ApiClient.instance;

  // ══════════════════════════════════════════════
  //  APP CONFIG  (은행목록, 구독플랜, AI키워드, 카테고리)
  // ══════════════════════════════════════════════

  /// 앱 전체 설정 (app_name, 광고 빈도, 기본예산, 샘플 데이터 등)
  Future<Map<String, dynamic>> fetchAppConfig() async {
    final r = await _client.get('/api/app/config');
    if (r['success'] == true) return r['data'] as Map<String, dynamic>;
    return {};
  }

  /// 은행 마스터 목록
  Future<List<Map<String, dynamic>>> fetchBanks() async {
    final r = await _client.get('/api/app/banks');
    if (r['success'] == true) {
      return (r['data'] as List).cast<Map<String, dynamic>>();
    }
    return _fallbackBanks;
  }

  /// 구독 플랜 목록
  Future<List<Map<String, dynamic>>> fetchPlans() async {
    final r = await _client.get('/api/app/plans');
    if (r['success'] == true) {
      return (r['data'] as List).cast<Map<String, dynamic>>();
    }
    return _fallbackPlans;
  }

  /// AI 분류 키워드 { category: [keywords] }
  Future<Map<String, List<String>>> fetchAiKeywords() async {
    final r = await _client.get('/api/app/ai-keywords');
    if (r['success'] == true) {
      final data = r['data'] as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as List).cast<String>()));
    }
    return {};
  }

  /// 카테고리 목록
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final r = await _client.get('/api/app/categories');
    if (r['success'] == true) {
      return (r['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ══════════════════════════════════════════════
  //  USERS
  // ══════════════════════════════════════════════

  /// 기기 등록 또는 기존 사용자 반환
  Future<Map<String, dynamic>?> registerUser(String deviceId) async {
    final r = await _client.post('/api/users/register', {
      'device_id': deviceId,
      'nickname': '사용자',
    });
    if (r['success'] == true) return r['data'] as Map<String, dynamic>;
    return null;
  }

  /// 프리미엄 상태 업데이트
  Future<bool> setPremium(String userId, {required bool isPremium, String? expiresAt}) async {
    final r = await _client.post('/api/users/$userId/premium', {
      'is_premium': isPremium ? 1 : 0,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
    return r['success'] == true;
  }

  // ══════════════════════════════════════════════
  //  TRANSACTIONS
  // ══════════════════════════════════════════════

  /// 이번달 거래 목록
  Future<List<Transaction>> fetchTransactions({
    required String userId,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final r = await _client.get(
      '/api/transactions?userId=$userId&year=$y&month=$m',
    );
    if (r['success'] == true) {
      return (r['data'] as List).map((d) => Transaction.fromApiMap(d as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 거래 추가
  Future<Transaction?> addTransaction({
    required String userId,
    required Transaction transaction,
  }) async {
    final r = await _client.post('/api/transactions', {
      'userId': userId,
      'title': transaction.title,
      'amount': transaction.amount,
      'category': transaction.category,
      'type': transaction.type,
      'date': transaction.date.toIso8601String(),
      'memo': transaction.memo,
      'bankName': transaction.bankName,
      'isAiClassified': transaction.isAiClassified,
    });
    if (r['success'] == true) {
      return Transaction.fromApiMap(r['data'] as Map<String, dynamic>);
    }
    return null;
  }

  /// 거래 수정
  Future<Transaction?> updateTransaction(String userId, Transaction transaction) async {
    final r = await _client.put('/api/transactions/${transaction.id}', {
      'userId': userId,
      'title': transaction.title,
      'amount': transaction.amount,
      'category': transaction.category,
      'type': transaction.type,
      'date': transaction.date.toIso8601String(),
      'memo': transaction.memo,
      'bankName': transaction.bankName,
    });
    if (r['success'] == true) {
      return Transaction.fromApiMap(r['data'] as Map<String, dynamic>);
    }
    return null;
  }

  /// 거래 삭제
  Future<bool> deleteTransaction(String transactionId, {required String userId}) async {
    final r = await _client.delete('/api/transactions/$transactionId?userId=$userId');
    return r['success'] == true;
  }

  /// 월별 통계 요약
  Future<Map<String, dynamic>?> fetchSummary({
    required String userId,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final r = await _client.get(
      '/api/transactions/summary?userId=$userId&year=$y&month=$m',
    );
    if (r['success'] == true) return r['data'] as Map<String, dynamic>;
    return null;
  }

  // ══════════════════════════════════════════════
  //  BUDGETS
  // ══════════════════════════════════════════════

  /// 예산 목록 (실제 지출 포함)
  Future<List<Budget>> fetchBudgets(String userId) async {
    final r = await _client.get('/api/budgets?userId=$userId');
    if (r['success'] == true) {
      return (r['data'] as List).map((d) {
        final m = d as Map<String, dynamic>;
        return Budget(
          category: m['category'] as String,
          limit: (m['monthly_limit'] as num).toDouble(),
          spent: (m['spent'] as num).toDouble(),
        );
      }).toList();
    }
    return [];
  }

  /// 예산 설정 (upsert)
  Future<bool> upsertBudget({
    required String userId,
    required String category,
    required double monthlyLimit,
  }) async {
    final r = await _client.put('/api/budgets', {
      'userId': userId,
      'category': category,
      'monthlyLimit': monthlyLimit,
    });
    return r['success'] == true;
  }

  // ══════════════════════════════════════════════
  //  BANK ACCOUNTS (은행 연동)
  // ══════════════════════════════════════════════

  /// 연동된 은행 계좌 목록
  Future<List<Map<String, dynamic>>> fetchLinkedBankAccounts(String userId) async {
    final r = await _client.get('/api/bank-accounts?userId=$userId');
    if (r['success'] == true) {
      return (r['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// 은행 연동
  Future<Map<String, dynamic>?> linkBankAccount({
    required String userId,
    required String bankName,
  }) async {
    final r = await _client.post('/api/bank-accounts', {
      'userId': userId,
      'bankName': bankName,
    });
    if (r['success'] == true) return r['data'] as Map<String, dynamic>;
    return null;
  }

  /// 은행 연동 해제
  Future<bool> unlinkBankAccount(String accountId) async {
    final r = await _client.delete('/api/bank-accounts/$accountId');
    return r['success'] == true;
  }

  // ══════════════════════════════════════════════
  //  ANALYTICS (앱 이벤트 추적)
  // ══════════════════════════════════════════════

  /// 이벤트 기록 (fire and forget)
  void trackEvent({
    required String eventName,
    String? userId,
    Map<String, dynamic>? data,
  }) {
    _client.post('/api/analytics/event', {
      'eventName': eventName,
      'userId': userId,
      'eventData': data,
      'platform': AppConfig.platform,
      'appVersion': AppConfig.appVersion,
    });
  }

  /// 광고 노출 기록
  void trackAdEvent({String? userId, required String adType, String? adUnit, double revenue = 0}) {
    _client.post('/api/analytics/ad', {
      'userId': userId,
      'adType': adType,
      'adUnit': adUnit,
      'revenue': revenue,
    });
  }

  // ══════════════════════════════════════════════
  //  FALLBACK (네트워크 오류 시)
  // ══════════════════════════════════════════════
  static const _fallbackBanks = [
    {'id': 1, 'name': '카카오뱅크', 'icon': '🟡', 'color_hex': '#FEE500'},
    {'id': 2, 'name': '신한은행',   'icon': '🔵', 'color_hex': '#0046FF'},
    {'id': 3, 'name': '국민은행',   'icon': '🟤', 'color_hex': '#FFB300'},
    {'id': 4, 'name': '우리은행',   'icon': '🔵', 'color_hex': '#003087'},
    {'id': 5, 'name': '하나은행',   'icon': '🟢', 'color_hex': '#00A650'},
    {'id': 6, 'name': 'IBK기업은행','icon': '🔴', 'color_hex': '#C41E3A'},
  ];

  static const _fallbackPlans = [
    {'id': 1, 'plan_type': 'monthly', 'name': '월간 구독', 'price': 4900,  'period': '/ 월', 'badge': '',       'sub_text': '연 58,800원'},
    {'id': 2, 'plan_type': 'yearly',  'name': '연간 구독', 'price': 39900, 'period': '/ 년', 'badge': '32% 할인', 'sub_text': '월 3,325원'},
  ];
}
