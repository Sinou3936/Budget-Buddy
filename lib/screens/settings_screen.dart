import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/ad_banner_widget.dart';
import '../utils/app_env.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GradientHeader(
                  height: 160,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('설정',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('반가워요! 👋',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      if (provider.isPremium)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700)
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.workspace_premium,
                                                  size: 12,
                                                  color: Color(0xFFFFD700)),
                                              SizedBox(width: 4),
                                              Text('Premium',
                                                  style: TextStyle(
                                                      color: Color(0xFFFFD700),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        )
                                      else
                                        Text('무료 플랜 사용 중',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.8),
                                                fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 프리미엄 업그레이드 카드
                      if (!provider.isPremium)
                        _buildPremiumCard(context, provider),
                      const SizedBox(height: 20),

                      // 설정 메뉴들
                      _buildSettingsGroup('계좌 관리', [
                        _SettingsItem(Icons.account_balance, '은행 연동', '연동된 계좌 관리'),
                        _SettingsItem(Icons.sync, '자동 동기화', '매일 자동 업데이트'),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('예산 관리', [
                        _SettingsItem(Icons.tune, '예산 설정', '카테고리별 예산 설정'),
                        _SettingsItem(Icons.notifications, '알림 설정', 'AI 소비 알림 관리'),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('보안', [
                        _SettingsItem(Icons.fingerprint, '생체인증', '지문/얼굴 인식으로 잠금'),
                        _SettingsItem(Icons.lock, '앱 잠금 설정', 'PIN 번호 설정'),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('앱 정보', [
                        _SettingsItem(Icons.info, '버전 정보', provider.appConfig['app_version']?.toString() ?? 'v1.0.0'),
                        _SettingsItem(Icons.privacy_tip, '개인정보처리방침', ''),
                        _SettingsItem(Icons.description, '이용약관', ''),
                      ]),
                      const SizedBox(height: 16),

                      // ── DEV 전용 개발자 패널 ──────────────────────────
                      if (AppEnv.isDev) _buildDevPanel(context, provider),

                      const SizedBox(height: 80),
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

  Widget _buildPremiumCard(BuildContext context, TransactionProvider provider) {
    return GestureDetector(
      onTap: () => _showPremiumDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Color(0xFFFFD700), size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget Buddy Premium',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('광고 없이 모든 기능 사용',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('업그레이드 →',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPremiumFeature('🤖 고급 AI 분석'),
                const SizedBox(width: 16),
                _buildPremiumFeature('📊 무제한 통계'),
                const SizedBox(width: 16),
                _buildPremiumFeature('🚫 광고 없음'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildSettingsGroup(
      String title, List<_SettingsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon,
                          color: AppTheme.primaryBlue, size: 18),
                    ),
                    title: Text(item.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary)),
                    subtitle: item.subtitle.isNotEmpty
                        ? Text(item.subtitle,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary))
                        : null,
                    trailing: const Icon(Icons.chevron_right,
                        color: AppTheme.textLight, size: 20),
                    onTap: () {},
                  ),
                  if (idx < items.length - 1)
                    const Divider(
                        height: 1,
                        indent: 60,
                        color: AppTheme.dividerColor),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showPremiumDialog(
      BuildContext context, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PremiumBottomSheet(provider: provider),
    );
  }

  // ── DEV 전용 개발자 패널 ─────────────────────────────────────
  Widget _buildDevPanel(BuildContext context, TransactionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '개발자 도구',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD600), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // 환경 정보 행
              _buildDevInfoTile(
                Icons.developer_mode,
                '현재 환경',
                AppEnv.fullLabel,
                const Color(0xFFFFD600),
              ),
              const Divider(height: 1, color: Color(0xFFFFD600)),
              _buildDevInfoTile(
                Icons.ad_units,
                '광고 모드',
                AppEnv.useMockAds ? 'Mock (DEV)' : '실제 AdMob (PROD)',
                AppEnv.useMockAds ? Colors.orange : AppTheme.successGreen,
              ),
              const Divider(height: 1, color: Color(0xFFFFD600)),
              _buildDevInfoTile(
                Icons.cloud_done,
                'API 서버',
                provider.appConfig.isNotEmpty ? '연결됨 ✅' : '연결 안됨 ❌',
                provider.appConfig.isNotEmpty ? AppTheme.successGreen : AppTheme.dangerRed,
              ),
              const Divider(height: 1, color: Color(0xFFFFD600)),
              _buildDevInfoTile(
                Icons.workspace_premium,
                '현재 플랜',
                provider.isPremium ? 'Premium ⭐' : '무료 플랜',
                provider.isPremium ? const Color(0xFFFFD700) : AppTheme.textSecondary,
              ),
              const Divider(height: 1, color: Color(0xFFFFD600)),
              // 프리미엄 토글 버튼
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.toggle_on, color: Color(0xFF5D4037), size: 18),
                ),
                title: const Text(
                  '[DEV] 프리미엄 토글',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
                ),
                subtitle: const Text(
                  '실제 결제 없이 프리미엄 테스트',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8D6E63)),
                ),
                trailing: Switch(
                  value: provider.isPremium,
                  onChanged: (val) => provider.setPremium(val),
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
              const Divider(height: 1, color: Color(0xFFFFD600)),
              // Mock 광고 테스트 버튼
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_outline, color: Color(0xFF5D4037), size: 18),
                ),
                title: const Text(
                  '[DEV] 전면광고 테스트',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
                ),
                subtitle: const Text(
                  'Mock 전면 광고 다이얼로그 확인',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8D6E63)),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF8D6E63), size: 20),
                onTap: () {
                  if (!provider.isPremium) {
                    AdInterstitialService.show(context, isPremium: false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('프리미엄 상태: 전면광고 표시 안됨'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1, color: Color(0xFFFFD600)),
              // API 설정값 보기
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings_ethernet, color: Color(0xFF5D4037), size: 18),
                ),
                title: const Text(
                  '[DEV] API 설정값',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
                ),
                subtitle: Text(
                  '로드된 설정: ${provider.appConfig.length}개',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8D6E63)),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF8D6E63), size: 20),
                onTap: () => _showApiConfigDialog(context, provider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevInfoTile(IconData icon, String label, String value, Color valueColor) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD600).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: const Color(0xFF5D4037), size: 16),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037), fontWeight: FontWeight.w500)),
      trailing: Text(
        value,
        style: TextStyle(fontSize: 12, color: valueColor, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showApiConfigDialog(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet, color: Color(0xFFFFD600)),
            SizedBox(width: 8),
            Text('API 설정값', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: provider.appConfig.isEmpty
              ? const Center(child: Text('API에서 설정을 불러오지 못했습니다.'))
              : ListView(
                  children: provider.appConfig.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              e.value?.toString() ?? 'null',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  _SettingsItem(this.icon, this.title, this.subtitle);
}

class _PremiumBottomSheet extends StatefulWidget {
  final TransactionProvider provider;
  const _PremiumBottomSheet({required this.provider});

  @override
  State<_PremiumBottomSheet> createState() => _PremiumBottomSheetState();
}

class _PremiumBottomSheetState extends State<_PremiumBottomSheet> {
  int _selectedPlan = 1; // 0: monthly, 1: yearly

  // API에서 가져온 플랜 (provider.plans 사용)
  List<Map<String, dynamic>> get _plans {
    final apiPlans = widget.provider.plans;
    if (apiPlans.isNotEmpty) {
      return apiPlans.map((p) => {
        'type': p['name'] ?? '',
        'price': '${(p['price'] as num?)?.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},') ?? '0'}원',
        'period': p['period'] ?? '',
        'badge': p['badge'] ?? '',
        'total': p['sub_text'] ?? '',
        'plan_type': p['plan_type'] ?? '',
      }).toList();
    }
    // 폴백 (API 미연결 시)
    return [
      {'type': '월간 구독', 'price': '4,900원', 'period': '/ 월', 'badge': '', 'total': '연 58,800원', 'plan_type': 'monthly'},
      {'type': '연간 구독', 'price': '39,900원', 'period': '/ 년', 'badge': '32% 할인', 'total': '월 3,325원', 'plan_type': 'yearly'},
    ];
  }

  final List<Map<String, dynamic>> _features = [
    {'icon': '🤖', 'title': '고급 AI 소비 분석', 'desc': '더 정밀한 소비 패턴 분석'},
    {'icon': '📊', 'title': '무제한 통계 및 리포트', 'desc': '월별/연간 상세 분석'},
    {'icon': '🏦', 'title': '무제한 은행 연동', 'desc': '모든 은행 계좌 동시 연동'},
    {'icon': '🔔', 'title': '스마트 맞춤 알림', 'desc': '개인 소비 패턴 기반 알림'},
    {'icon': '🚫', 'title': '광고 완전 제거', 'desc': '광고 없는 깔끔한 화면'},
    {'icon': '📤', 'title': '데이터 내보내기', 'desc': 'Excel/PDF 내보내기'},
    {'icon': '🎨', 'title': '프리미엄 테마', 'desc': '다양한 앱 테마 선택'},
  ];

  /// API 플랜 정보 기반으로 구독 시작 버튼 텍스트를 생성
  String _buildStartButtonText() {
    final plan = _plans[_selectedPlan.clamp(0, _plans.length - 1)];
    final price = plan['price'] ?? '';
    final period = plan['period'] ?? '';
    final badge = plan['badge'] ?? '';
    if (badge.isNotEmpty) {
      return '$price$period 시작 ($badge)';
    }
    return '$price$period 시작하기';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // 헤더
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryTeal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: Color(0xFFFFD700), size: 48),
                        const SizedBox(height: 12),
                        const Text('Budget Buddy Premium',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('더 스마트한 금융 관리를 시작하세요',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 플랜 선택
                  Row(
                    children: _plans.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final plan = entry.value;
                      final isSelected = _selectedPlan == idx;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPlan = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                                right: idx == 0 ? 8 : 0),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                      .withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (plan['badge']!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.dangerRed,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(plan['badge']!,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                Text(plan['type']!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(
                                  plan['price']!,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(plan['period']!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary)),
                                const SizedBox(height: 4),
                                Text(plan['total']!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textLight)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 기능 목록
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('프리미엄 혜택',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                  ),
                  const SizedBox(height: 12),
                  ..._features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text(f['icon']!,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(f['title']!,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary)),
                                  Text(f['desc']!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle,
                                color: AppTheme.successGreen, size: 20),
                          ],
                        ),
                      )),

                  const SizedBox(height: 24),

                  // 구독 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.provider.setPremium(true);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.workspace_premium,
                                      color: Color(0xFFFFD700), size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '프리미엄으로 업그레이드되었습니다! 🎉',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.primaryBlue,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _buildStartButtonText(),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    '언제든지 취소 가능 · 첫 7일 무료 체험',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
