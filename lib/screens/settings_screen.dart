import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/ad_banner_widget.dart';
import '../utils/app_env.dart';
import 'budget_screen.dart';
import 'notification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // ── 공통 미구현 기능 안내 다이얼로그
  void _showComingSoon(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.construction, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(message,
            style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ── 버전 정보 다이얼로그
  void _showVersionDialog(TransactionProvider provider) {
    final version = provider.appConfig['app_version']?.toString() ?? 'v1.0.0';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('버전 정보', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  const Text('Budget Buddy',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(version,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildVersionRow('앱 버전', version),
            _buildVersionRow('빌드 환경', AppEnv.fullLabel),
            _buildVersionRow('지원 플랫폼', 'Android / Web'),
            _buildVersionRow('개발사', 'Budget Buddy Team'),
          ],
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

  Widget _buildVersionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── 개인정보처리방침 다이얼로그
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('개인정보처리방침', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicySection('1. 수집하는 개인정보',
                    'Budget Buddy는 앱 사용을 위해 최소한의 정보만 수집합니다.\n\n'
                    '• 기기 고유 ID (익명 식별용)\n'
                    '• 거래 내역 (사용자가 직접 입력한 데이터)\n'
                    '• 앱 사용 분석 데이터 (광고 최적화용)'),
                _buildPolicySection('2. 개인정보 이용 목적',
                    '• AI 소비 패턴 분석 및 인사이트 제공\n'
                    '• 맞춤형 광고 제공 (무료 플랜)\n'
                    '• 서비스 개선 및 통계 분석'),
                _buildPolicySection('3. 보관 기간',
                    '사용자가 앱을 삭제하거나 데이터 삭제를 요청할 때까지 보관합니다.'),
                _buildPolicySection('4. 제3자 제공',
                    'Google AdMob (광고 서비스) 외에는 개인정보를 제3자에게 제공하지 않습니다.'),
                _buildPolicySection('5. 문의',
                    '개인정보 관련 문의: support@budgetbuddy.app'),
              ],
            ),
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

  // ── 이용약관 다이얼로그
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.description, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('이용약관', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicySection('제1조 (목적)',
                    'Budget Buddy 서비스의 이용 조건 및 절차, 회사와 이용자 간의 권리·의무를 규정합니다.'),
                _buildPolicySection('제2조 (서비스 내용)',
                    '• 가계부 기록 및 관리\n'
                    '• AI 기반 소비 패턴 분석\n'
                    '• 예산 설정 및 알림\n'
                    '• 은행 계좌 연동 (추후 제공)'),
                _buildPolicySection('제3조 (무료 서비스)',
                    '기본 서비스는 무료로 제공되며, 광고가 표시됩니다.\n'
                    '프리미엄 구독 시 광고 없이 모든 기능을 이용할 수 있습니다.'),
                _buildPolicySection('제4조 (금지사항)',
                    '• 타인의 개인정보 무단 수집\n'
                    '• 서비스의 역설계 또는 해킹 시도\n'
                    '• 허위 정보 등록'),
                _buildPolicySection('제5조 (면책사항)',
                    'Budget Buddy는 사용자가 입력한 재정 데이터의 정확성에 대한 책임을 지지 않습니다.'),
              ],
            ),
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

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.6)),
        ],
      ),
    );
  }

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
                        _SettingsItem(
                          icon: Icons.account_balance,
                          iconColor: AppTheme.primaryBlue,
                          title: '은행 연동',
                          subtitle: '연동된 계좌 관리',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const _BankRedirectPage()),
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.sync,
                          iconColor: AppTheme.primaryTeal,
                          title: '자동 동기화',
                          subtitle: '매일 자동 업데이트',
                          onTap: () => _showComingSoon(
                            '자동 동기화',
                            '연결된 은행 계좌의 거래 내역을 매일 자동으로 업데이트하는 기능입니다.\n\n실제 은행 Open API 연동 후 제공될 예정입니다.',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('예산 관리', [
                        _SettingsItem(
                          icon: Icons.tune,
                          iconColor: AppTheme.warningOrange,
                          title: '예산 설정',
                          subtitle: '카테고리별 예산 설정',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BudgetScreen()),
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.notifications,
                          iconColor: AppTheme.accentBlue,
                          title: '알림 설정',
                          subtitle: 'AI 소비 알림 관리',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('보안', [
                        _SettingsItem(
                          icon: Icons.fingerprint,
                          iconColor: AppTheme.successGreen,
                          title: '생체인증',
                          subtitle: '지문/얼굴 인식으로 잠금',
                          onTap: () => _showComingSoon(
                            '생체인증',
                            '지문 또는 얼굴 인식으로 앱을 잠글 수 있습니다.\n\n기기의 생체인증 센서가 필요하며, 다음 업데이트에서 제공될 예정입니다.',
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.lock,
                          iconColor: AppTheme.dangerRed,
                          title: 'PIN 설정',
                          subtitle: '4자리 PIN 번호로 앱 잠금',
                          onTap: () => _showPinDialog(context),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('앱 정보', [
                        _SettingsItem(
                          icon: Icons.info,
                          iconColor: AppTheme.primaryBlue,
                          title: '버전 정보',
                          subtitle: provider.appConfig['app_version']?.toString() ?? 'v1.0.0',
                          onTap: () => _showVersionDialog(provider),
                        ),
                        _SettingsItem(
                          icon: Icons.privacy_tip,
                          iconColor: AppTheme.primaryTeal,
                          title: '개인정보처리방침',
                          subtitle: '',
                          onTap: _showPrivacyPolicy,
                        ),
                        _SettingsItem(
                          icon: Icons.description,
                          iconColor: AppTheme.textSecondary,
                          title: '이용약관',
                          subtitle: '',
                          onTap: _showTermsOfService,
                        ),
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
                        color: item.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon,
                          color: item.iconColor, size: 18),
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
                                color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: const Icon(Icons.chevron_right,
                        color: AppTheme.textLight, size: 20),
                    onTap: item.onTap,
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

  // ── PIN 설정 다이얼로그 (간단 UI)
  void _showPinDialog(BuildContext context) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('PIN 설정', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '4자리 PIN 번호를 설정하면 앱 실행 시 잠금 화면이 표시됩니다.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'PIN 번호 (4자리)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.dialpad),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.construction, color: AppTheme.primaryBlue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PIN 잠금은 다음 업데이트에서 완전히 활성화될 예정입니다.',
                      style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN이 저장되었습니다 (다음 업데이트에서 활성화)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
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

// ── 은행 화면 리다이렉트 (MainNavigation의 BankScreen을 별도 push로 보여주는 래퍼)
class _BankRedirectPage extends StatelessWidget {
  const _BankRedirectPage();

  @override
  Widget build(BuildContext context) {
    // BankScreen을 직접 임포트해서 보여줌
    return const _BankScreenProxy();
  }
}

class _BankScreenProxy extends StatelessWidget {
  const _BankScreenProxy();

  @override
  Widget build(BuildContext context) {
    // bank_screen.dart를 inline으로 가져올 수 없으므로
    // 하단 네비게이션에서 탭 인덱스를 전환하도록 안내
    return Scaffold(
      appBar: AppBar(
        title: const Text('은행 연동', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance,
                    color: AppTheme.primaryBlue, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                '은행 연동',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                '하단 네비게이션의 [은행] 탭에서\n계좌를 연동하고 관리할 수 있습니다.',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('돌아가기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor = AppTheme.primaryBlue,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
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
