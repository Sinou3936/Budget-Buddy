import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';
import '../services/budget_api_service.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final _api = BudgetApiService.instance;

  String _userId = '';
  bool _isPremium = false;
  bool _isOffline = false;
  bool _isLoading = true;
  Map<String, dynamic> _appConfig = {};
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _banks = [];

  String get userId => _userId;
  bool get isPremium => _isPremium;
  bool get isOffline => _isOffline;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get appConfig => _appConfig;
  List<Map<String, dynamic>> get plans => _plans;
  List<Map<String, dynamic>> get banks => _banks;

  int get adInterstitialFreq =>
      int.tryParse(_appConfig['ad_interstitial_freq']?.toString() ?? '5') ?? 5;
  bool get adBannerEnabled =>
      _appConfig['ad_banner_enabled']?.toString() != 'false';
  String get appName => _appConfig['app_name']?.toString() ?? 'Budget Buddy';

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    _isPremium = prefs.getBool('is_premium') ?? false;
    _isLoading = true;
    notifyListeners();

    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString('device_id', deviceId);
    }

    try {
      final results = await Future.wait([
        _api.fetchAppConfig(),
        _api.fetchPlans(),
        _api.fetchAiKeywords(),
        _api.fetchBanks(),
      ]);

      _appConfig = results[0] as Map<String, dynamic>;
      _plans = results[1] as List<Map<String, dynamic>>;
      _isOffline = _appConfig.isEmpty;
      AiService.updateKeywords(results[2] as Map<String, List<String>>);
      _banks = results[3] as List<Map<String, dynamic>>;

      final user = await _api.registerUser(deviceId);
      if (user != null) {
        _userId = user['id'] as String;
        _isPremium = user['is_premium'] == true;
        await prefs.setString('user_id', _userId);
        await prefs.setBool('is_premium', _isPremium);
      }

      _api.trackEvent(
        eventName: 'app_open',
        userId: _userId.isNotEmpty ? _userId : null,
      );
    } catch (_) {
      _isOffline = true;
    }

    _isLoading = false;
    notifyListeners();
  }

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
}
