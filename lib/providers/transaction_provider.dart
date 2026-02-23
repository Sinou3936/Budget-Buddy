import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/ai_service.dart';
import '../services/budget_api_service.dart';

class TransactionProvider extends ChangeNotifier {
  // ─── State ───────────────────────────────────────────────
  List<Transaction> _transactions = [];
  List<Budget>      _budgets      = [];
  List<AiInsight>   _insights     = [];
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic> _appConfig  = {};

  bool    _isPremium = false;
  bool    _isLoading = false;
  String  _userId    = '';
  int     _adCounter = 0;

  final _uuid = const Uuid();
  final _api  = BudgetApiService.instance;

  // ─── Getters ─────────────────────────────────────────────
  List<Transaction>          get transactions => _transactions;
  List<Budget>               get budgets      => _budgets;
  List<AiInsight>            get insights     => _insights;
  List<Map<String, dynamic>> get banks        => _banks;
  List<Map<String, dynamic>> get plans        => _plans;
  Map<String, dynamic>       get appConfig    => _appConfig;
  bool                       get isPremium    => _isPremium;
  bool                       get isLoading    => _isLoading;
  String                     get userId       => _userId;

  // 광고 노출 빈도 (서버 설정값)
  int get adInterstitialFreq {
    return int.tryParse(_appConfig['ad_interstitial_freq']?.toString() ?? '5') ?? 5;
  }

  // 배너 광고 활성화 여부 (서버 설정값)
  bool get adBannerEnabled {
    return _appConfig['ad_banner_enabled']?.toString() != 'false';
  }

  // 앱 이름 (서버 설정값)
  String get appName => _appConfig['app_name']?.toString() ?? 'Budget Buddy';

  // ─── 월별 필터 ────────────────────────────────────────────
  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalIncome => currentMonthTransactions
      .where((t) => t.type == 'income')
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense => currentMonthTransactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (s, t) => s + t.amount);

  double get totalBalance => totalIncome - totalExpense;

  Map<String, double> get categoryExpenses {
    final map = <String, double>{};
    for (final t in currentMonthTransactions.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<Map<String, dynamic>> get dailyExpenses {
    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayTotal = _transactions
          .where((t) =>
              t.type == 'expense' &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      result.add({'date': day, 'amount': dayTotal});
    }
    return result;
  }

  // ─── 초기화 ───────────────────────────────────────────────
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // 1. 기기 ID 가져오기 (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString('device_id', deviceId);
    }

    // 2. 앱 설정 & 은행 & 플랜 병렬 로드
    final results = await Future.wait([
      _api.fetchAppConfig(),
      _api.fetchBanks(),
      _api.fetchPlans(),
      _api.fetchAiKeywords(),
    ]);

    _appConfig = results[0] as Map<String, dynamic>;
    _banks     = results[1] as List<Map<String, dynamic>>;
    _plans     = results[2] as List<Map<String, dynamic>>;

    // AI 키워드 서비스 업데이트
    AiService.updateKeywords(results[3] as Map<String, List<String>>);

    // 3. 사용자 등록/로드
    final user = await _api.registerUser(deviceId);
    if (user != null) {
      _userId    = user['id'] as String;
      _isPremium = (user['is_premium'] as int? ?? 0) == 1;

      // SharedPreferences에도 캐시
      await prefs.setString('user_id', _userId);
      await prefs.setBool('is_premium', _isPremium);
    } else {
      // 오프라인 폴백: 캐시 사용
      _userId    = prefs.getString('user_id') ?? '';
      _isPremium = prefs.getBool('is_premium') ?? false;
    }

    // 4. 거래 & 예산 병렬 로드
    if (_userId.isNotEmpty) {
      final txBudget = await Future.wait([
        _api.fetchTransactions(userId: _userId),
        _api.fetchBudgets(_userId),
      ]);
      _transactions = txBudget[0] as List<Transaction>;
      _budgets      = txBudget[1] as List<Budget>;
    }

    // 앱 오픈 이벤트 추적
    _api.trackEvent(eventName: 'app_open', userId: _userId.isNotEmpty ? _userId : null);

    _isLoading = false;
    notifyListeners();

    // 5. AI 인사이트 생성
    await _generateAiInsights();
  }

  // ─── 거래 추가 ────────────────────────────────────────────
  Future<void> addTransaction(Transaction transaction) async {
    // AI 자동 분류
    String category = transaction.category;
    if (transaction.type == 'expense' && category == '기타') {
      category = AiService.classifyTransaction(transaction.title);
    }

    final newTx = transaction.copyWith(category: category, isAiClassified: true);

    // 낙관적 업데이트 (UI 즉시 반영)
    _transactions.insert(0, newTx);
    _updateBudgetSpent();
    notifyListeners();

    // API 저장
    if (_userId.isNotEmpty) {
      final saved = await _api.addTransaction(userId: _userId, transaction: newTx);
      if (saved != null) {
        // 서버 저장 성공 - 서버 ID로 교체
        final idx = _transactions.indexWhere((t) => t.id == newTx.id);
        if (idx >= 0) _transactions[idx] = saved;
      }

      // 이벤트 추적
      _api.trackEvent(
        eventName: 'transaction_added',
        userId: _userId,
        data: {'category': category, 'type': transaction.type, 'amount': transaction.amount},
      );

      // 광고 카운터 증가
      _adCounter++;
    }

    _updateBudgetSpent();
    notifyListeners();
    await _generateAiInsights();
  }

  /// 광고 노출 여부 체크 (거래 추가 후 호출)
  bool shouldShowInterstitialAd() {
    if (_isPremium) return false;
    return _adCounter % adInterstitialFreq == 0 && _adCounter > 0;
  }

  // ─── 거래 삭제 ────────────────────────────────────────────
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    _updateBudgetSpent();
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.deleteTransaction(id);
    }
    await _generateAiInsights();
  }

  // ─── 예산 업데이트 ────────────────────────────────────────
  Future<void> updateBudget(String category, double limit) async {
    final idx = _budgets.indexWhere((b) => b.category == category);
    if (idx >= 0) {
      _budgets[idx].limit = limit;
    } else {
      _budgets.add(Budget(category: category, limit: limit));
    }
    _updateBudgetSpent();
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.upsertBudget(userId: _userId, category: category, monthlyLimit: limit);
    }
  }

  // ─── 프리미엄 설정 ────────────────────────────────────────
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    notifyListeners();

    if (_userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', value);
      await _api.setPremium(_userId, isPremium: value);
      _api.trackEvent(
        eventName: value ? 'premium_purchased' : 'premium_cancelled',
        userId: _userId,
      );
    }
  }

  // ─── 이벤트 추적 (화면 방문 등) ──────────────────────────
  void trackPageView(String pageName) {
    _api.trackEvent(
      eventName: 'page_view',
      userId: _userId.isNotEmpty ? _userId : null,
      data: {'page': pageName},
    );
  }

  void trackAdShown(String adType) {
    _api.trackAdEvent(
      userId: _userId.isNotEmpty ? _userId : null,
      adType: adType,
    );
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────
  void _updateBudgetSpent() {
    final expenses = categoryExpenses;
    for (final budget in _budgets) {
      budget.spent = expenses[budget.category] ?? 0;
    }
  }

  Future<void> _generateAiInsights() async {
    // AI 임계값도 서버에서 가져온 값 사용
    Map<String, dynamic> thresholds = {};
    try {
      final raw = _appConfig['ai_insight_thresholds'];
      if (raw is Map<String, dynamic>) thresholds = raw;
    } catch (_) {}

    _insights = AiService.generateInsights(
      transactions: currentMonthTransactions,
      budgets: _budgets,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      thresholds: thresholds,
    );
    notifyListeners();
  }

  String generateNewId() => _uuid.v4();
}
