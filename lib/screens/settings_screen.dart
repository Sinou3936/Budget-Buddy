import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/ad_banner_widget.dart';
import '../utils/app_env.dart';
import '../services/notification_service.dart';
import 'budget_settings_screen.dart';

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
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.primaryBlue,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: const Text(
                  '설정',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),

                      // 설정 메뉴들
                      _buildSettingsGroup('예산 관리', [
                        _SettingsItem(Icons.tune, '예산 설정', '카테고리별 예산 설정',
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetSettingsScreen()))),
                        _SettingsItem(Icons.notifications, '알림 설정', 'AI 소비 알림 관리',
                          () => _showNotificationSettings(context)),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('데이터', [
                        _SettingsItem(Icons.table_chart, '거래 내역 내보내기', 'CSV 파일로 저장',
                          () => _exportCsv(context, provider)),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('지원', [
                        _SettingsItem(Icons.star_rounded, '앱 평가하기', 'Play Store에서 평가',
                          () => _launchUrl(context, 'https://play.google.com/store/apps/details?id=kr.budget.app')),
                        _SettingsItem(Icons.mail_outline, '문의/피드백', '개발자에게 이메일',
                          () => _launchUrl(context, 'mailto:support@budgetbuddy.kr?subject=Budget Buddy 문의')),
                        _SettingsItem(Icons.share, '앱 공유하기', '친구에게 추천',
                          () => Share.share(
                            'AI 스마트 가계부 Budget Buddy!\nhttps://play.google.com/store/apps/details?id=kr.budget.app',
                          )),
                      ]),
                      const SizedBox(height: 16),
                      _buildSettingsGroup('앱 정보', [
                        _SettingsItem(Icons.info, '버전 정보', provider.appConfig['app_version']?.toString() ?? 'v1.0.0'),
                        _SettingsItem(Icons.privacy_tip, '개인정보처리방침', '',
                          () => _showTextSheet(context, '개인정보처리방침', _privacyPolicy)),
                        _SettingsItem(Icons.description, '이용약관', '',
                          () => _showTextSheet(context, '이용약관', _termsOfService)),
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
                Expanded(child: _buildPremiumFeature('🤖 고급 AI 분석')),
                Expanded(child: _buildPremiumFeature('📊 무제한 통계')),
                Expanded(child: _buildPremiumFeature('🚫 광고 없음')),
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

  Future<void> _exportCsv(BuildContext context, TransactionProvider provider) async {
    try {
      final transactions = provider.transactions;
      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내보낼 거래 내역이 없습니다.'), behavior: SnackBarBehavior.floating),
        );
        return;
      }

      final buf = StringBuffer();
      buf.writeln('날짜,유형,카테고리,내용,금액');
      for (final t in transactions) {
        final date = t.date.toString().substring(0, 10);
        final type = t.type == 'income' ? '수입' : '지출';
        buf.writeln('$date,$type,${t.category},${t.title},${t.amount.toInt()}');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/budget_buddy_export.csv');
      await file.writeAsString(buf.toString());

      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Budget Buddy 거래 내역',
        );
      } catch (_) {
        // 에뮬레이터 등 공유 불가 환경: 파일 저장 위치 안내
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('파일 저장됨: ${file.path}'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showTextSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  const Divider(height: 24),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  Text(content,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _privacyPolicy = '''
제1조 (개인정보의 처리 목적)
Budget Buddy(이하 "앱")는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

• 서비스 제공: 가계부 기능, AI 소비 분석, 예산 관리 서비스 제공

제2조 (처리하는 개인정보 항목)
앱은 다음의 개인정보 항목을 처리합니다.

• 수집 항목: 거래 내역, 예산 설정 정보
• 수집 방법: 사용자 직접 입력

제3조 (개인정보의 보유 및 이용기간)
앱은 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의 받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.

• 보유 기간: 서비스 이용 기간 동안 / 앱 삭제 시 즉시 파기

제4조 (개인정보의 제3자 제공)
앱은 정보주체의 개인정보를 제1조(개인정보의 처리 목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의 없이는 개인정보를 제3자에게 제공하지 않습니다.

제5조 (정보주체의 권리·의무)
정보주체는 앱에 대해 언제든지 개인정보 열람·정정·삭제·처리정지 요구 등의 권리를 행사할 수 있습니다.

제6조 (문의)
개인정보 처리에 관한 문의사항은 앱 내 문의하기를 통해 연락하시기 바랍니다.

시행일: 2025년 1월 1일
''';

  static const String _termsOfService = '''
제1조 (목적)
이 약관은 Budget Buddy(이하 "앱")가 제공하는 가계부 및 AI 소비 분석 서비스의 이용 조건 및 절차, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (서비스의 제공)
앱은 다음과 같은 서비스를 제공합니다.

• 수입/지출 거래 내역 관리
• AI 기반 소비 분석 및 예산 추천
• 월말 소비 리포트 제공
• 영수증 OCR 인식

제3조 (서비스 이용)
① 서비스는 연중무휴, 1일 24시간 제공함을 원칙으로 합니다.
② 시스템 점검, 증설 및 교체, 고장 또는 운영상의 상당한 이유가 있는 경우 서비스 제공을 일시적으로 중단할 수 있습니다.

제4조 (이용자의 의무)
① 이용자는 서비스 이용 시 다음 행위를 하여서는 안 됩니다.
• 타인의 정보 도용
• 앱의 정상적인 운영을 방해하는 행위
• 기타 불법적이거나 부당한 행위

제5조 (면책 조항)
① 앱은 천재지변, 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.
② AI 분석 결과는 참고용이며, 실제 금융 결정에 대한 책임은 이용자에게 있습니다.

제6조 (약관의 변경)
앱은 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 앱 내 공지를 통해 안내합니다.

시행일: 2025년 1월 1일
''';

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _NotificationSettingsSheet(),
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
  final VoidCallback? onTap;
  _SettingsItem(this.icon, this.title, this.subtitle, [this.onTap]);
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
    {'icon': '🔔', 'title': '스마트 맞춤 알림', 'desc': '개인 소비 패턴 기반 알림'},
    {'icon': '🚫', 'title': '광고 완전 제거', 'desc': '광고 없는 깔끔한 화면'},
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
                      onPressed: () {
                        if (AppEnv.isProd) {
                          // PROD: 결제 미구현 - 준비 중 안내
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.construction, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '결제 기능을 준비 중입니다. 곧 출시됩니다!',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }
                        // DEV: 즉시 프리미엄 활성화 (테스트용)
                        widget.provider.setPremium(true).then((_) {
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
                                        '[DEV] 프리미엄으로 업그레이드되었습니다! 🎉',
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
                        });
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

class _NotificationSettingsSheet extends StatefulWidget {
  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  late bool _budget;
  late bool _anomaly;
  late bool _report;

  @override
  void initState() {
    super.initState();
    _budget  = NotificationService.budgetEnabled;
    _anomaly = NotificationService.anomalyEnabled;
    _report  = NotificationService.reportEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('알림 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('각 알림을 개별적으로 켜거나 끌 수 있습니다.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            _buildToggle(
              icon: Icons.warning_amber_rounded,
              color: AppTheme.warningOrange,
              title: '예산 초과 알림',
              subtitle: '카테고리 예산을 초과하면 알림',
              value: _budget,
              onChanged: (v) {
                setState(() => _budget = v);
                NotificationService.saveSetting('budget', v);
              },
            ),
            _buildToggle(
              icon: Icons.search_rounded,
              color: AppTheme.primaryBlue,
              title: '이상 지출 감지',
              subtitle: '평균보다 높은 지출 발생 시 알림',
              value: _anomaly,
              onChanged: (v) {
                setState(() => _anomaly = v);
                NotificationService.saveSetting('anomaly', v);
              },
            ),
            _buildToggle(
              icon: Icons.summarize_rounded,
              color: AppTheme.successGreen,
              title: 'AI 월말 리포트',
              subtitle: '매월 말 소비 분석 리포트 알림',
              value: _report,
              onChanged: (v) {
                setState(() => _report = v);
                NotificationService.saveSetting('report', v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }
}
