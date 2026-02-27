import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/transaction_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/bank_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/ad_banner_widget.dart';
import 'widgets/common_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BudgetBuddyApp());
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
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

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionListScreen(),
    const StatsScreen(),
    const BankScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
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
                      _buildNavItem(Icons.account_balance_rounded, Icons.account_balance_outlined, '은행', 3),
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
