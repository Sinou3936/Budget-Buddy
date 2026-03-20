import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme/app_theme.dart';
import 'providers/transaction_provider.dart';
import 'providers/gemini_provider.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ai_hub_screen.dart';
import 'widgets/ad_banner_widget.dart';
import 'widgets/common_widgets.dart';
import 'utils/app_env.dart';
import 'services/notification_service.dart';
import 'services/gemini_service.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  // AdMob 초기화 (DEV에서는 테스트 ID 사용, PROD에서는 실제 ID)
  // Web 환경에서는 AdMob 미지원이므로 Android에서만 초기화
  if (!AppEnv.useMockAds) {
    await MobileAds.instance.initialize();
  }
  await NotificationService.init();
  GeminiService.instance.initialize();
  FlutterNativeSplash.remove();
  runApp(const BudgetBuddyApp());
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => GeminiProvider()),
      ],
      child: DevEnvBanner(
        child: MaterialApp(
          title: 'Budget Buddy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigateToTransactions: () => setState(() => _currentIndex = 1)),
      const TransactionListScreen(),
      const StatsScreen(),
      const AiHubScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen()),
                  ),
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: const StadiumBorder(),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    '지출 추가',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 광고 배너 (수익화 - 무료 플랜)
              AdBannerWidget(isPremium: provider.isPremium),
              // 하단 네비게이션
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (idx) => setState(() => _currentIndex = idx),
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppTheme.primaryBlue,
                    unselectedItemColor: AppTheme.textLight,
                    selectedFontSize: 11,
                    unselectedFontSize: 11,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    items: [
                      _buildNavItem(Icons.home_rounded, Icons.home_outlined, '홈', 0),
                      _buildNavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, '내역', 1),
                      _buildNavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, '분석', 2),
                      _buildNavItem(Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'AI', 3),
                      _buildNavItem(Icons.settings_rounded, Icons.settings_outlined, '설정', 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isActive ? activeIcon : inactiveIcon),
      ),
      label: label,
    );
  }
}
