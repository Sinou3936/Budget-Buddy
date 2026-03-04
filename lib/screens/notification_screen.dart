import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// 알림 설정 화면
/// - 예산 초과 알림, AI 인사이트 알림, 일일 소비 요약 알림
/// - 실제 푸시는 flutter_local_notifications 대신 인앱 알림으로 구현
///   (Play Store 심사 시 알림 권한 불필요 → 배포 리스크 최소화)
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 알림 설정 상태 (SharedPreferences로 저장)
  bool _budgetAlertEnabled   = true;   // 예산 초과 알림
  bool _aiInsightEnabled     = true;   // AI 인사이트 알림
  bool _dailySummaryEnabled  = false;  // 일일 소비 요약
  bool _weeklySummaryEnabled = true;   // 주간 소비 리포트
  bool _savingTipEnabled     = true;   // 절약 팁 알림
  String _summaryTime        = '21:00'; // 요약 알림 시간
  bool _isLoading            = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budgetAlertEnabled   = prefs.getBool('notif_budget')   ?? true;
      _aiInsightEnabled     = prefs.getBool('notif_ai')       ?? true;
      _dailySummaryEnabled  = prefs.getBool('notif_daily')    ?? false;
      _weeklySummaryEnabled = prefs.getBool('notif_weekly')   ?? true;
      _savingTipEnabled     = prefs.getBool('notif_tips')     ?? true;
      _summaryTime          = prefs.getString('notif_time')   ?? '21:00';
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    // 분석 이벤트 추적 (mounted 체크 후 context 사용)
    if (!mounted) return;
    context.read<TransactionProvider>()
        .trackPageView('notification_setting_changed');
  }

  Future<void> _pickTime() async {
    final timeParts = _summaryTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppTheme.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _summaryTime = newTime);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notif_time', newTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── 헤더 ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GradientHeader(
              height: 150,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '알림 설정',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'AI 소비 알림을 맞춤 설정하세요',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else ...[
            // ── AI 인사이트 섹션 ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSection(
                  'AI 스마트 알림',
                  Icons.auto_awesome,
                  AppTheme.primaryBlue,
                  [
                    _buildToggleTile(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppTheme.warningOrange,
                      title: '예산 초과 경고',
                      subtitle: '예산의 80% 도달 시 즉시 알림',
                      value: _budgetAlertEnabled,
                      onChanged: (v) {
                        setState(() => _budgetAlertEnabled = v);
                        _saveSetting('notif_budget', v);
                      },
                    ),
                    _buildToggleTile(
                      icon: Icons.lightbulb_outline_rounded,
                      iconColor: AppTheme.primaryBlue,
                      title: 'AI 인사이트 알림',
                      subtitle: '소비 패턴 분석 결과 알림',
                      value: _aiInsightEnabled,
                      onChanged: (v) {
                        setState(() => _aiInsightEnabled = v);
                        _saveSetting('notif_ai', v);
                      },
                    ),
                    _buildToggleTile(
                      icon: Icons.tips_and_updates_rounded,
                      iconColor: AppTheme.successGreen,
                      title: '절약 팁 알림',
                      subtitle: '카테고리별 절약 방법 제안',
                      value: _savingTipEnabled,
                      onChanged: (v) {
                        setState(() => _savingTipEnabled = v);
                        _saveSetting('notif_tips', v);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── 정기 리포트 섹션 ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSection(
                  '정기 소비 리포트',
                  Icons.bar_chart_rounded,
                  AppTheme.primaryTeal,
                  [
                    _buildToggleTile(
                      icon: Icons.today_rounded,
                      iconColor: AppTheme.accentBlue,
                      title: '일일 소비 요약',
                      subtitle: '매일 설정 시간에 오늘 지출 정리',
                      value: _dailySummaryEnabled,
                      onChanged: (v) {
                        setState(() => _dailySummaryEnabled = v);
                        _saveSetting('notif_daily', v);
                      },
                      trailing: _dailySummaryEnabled
                          ? GestureDetector(
                              onTap: _pickTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _summaryTime,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue),
                                ),
                              ),
                            )
                          : null,
                    ),
                    _buildToggleTile(
                      icon: Icons.calendar_view_week_rounded,
                      iconColor: AppTheme.accentTeal,
                      title: '주간 소비 리포트',
                      subtitle: '매주 월요일 지난 주 소비 분석',
                      value: _weeklySummaryEnabled,
                      onChanged: (v) {
                        setState(() => _weeklySummaryEnabled = v);
                        _saveSetting('notif_weekly', v);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── 알림 미리보기 섹션 ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSection(
                  '알림 미리보기',
                  Icons.notifications_active_rounded,
                  AppTheme.warningOrange,
                  [_buildPreviewTiles()],
                ),
              ),
            ),

            // ── 알림 테스트 버튼 ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: OutlinedButton.icon(
                  onPressed: () => _showTestNotification(context),
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('알림 테스트 보내기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 섹션 컨테이너 ─────────────────────────────────────────────
  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
            ],
          ),
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
          child: Column(children: children),
        ),
      ],
    );
  }

  // ── 토글 타일 ─────────────────────────────────────────────────
  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
          subtitle: Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
          trailing: trailing ??
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppTheme.primaryBlue,
              ),
          onTap: trailing != null ? null : () => onChanged(!value),
        ),
        const Divider(height: 1, indent: 60, color: AppTheme.dividerColor),
      ],
    );
  }

  // ── 알림 미리보기 타일 ────────────────────────────────────────
  Widget _buildPreviewTiles() {
    final examples = [
      if (_budgetAlertEnabled)
        {'icon': '⚠️', 'title': '식비 예산 80% 달성', 'body': '이번 달 식비가 32만원으로 목표의 80%에 도달했어요.'},
      if (_aiInsightEnabled)
        {'icon': '🤖', 'title': 'AI 소비 분석', 'body': '이번 주 카페 지출이 지난 주보다 35% 증가했어요.'},
      if (_savingTipEnabled)
        {'icon': '💡', 'title': '절약 팁', 'body': '구독 서비스 정기 결제가 3건 감지됐어요. 사용하지 않는 구독 정리해볼까요?'},
    ];
    if (examples.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('활성화된 알림이 없습니다',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
      );
    }
    return Column(
      children: examples.map((e) {
        return Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e['icon']!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['title']!,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(e['body']!,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── 테스트 알림 (인앱 스낵바) ─────────────────────────────────
  void _showTestNotification(BuildContext context) {
    final provider = context.read<TransactionProvider>();
    final insights = provider.insights;
    final msg = insights.isNotEmpty
        ? insights.first.message
        : 'AI가 분석한 이번 달 소비 패턴이 준비됐어요!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Budget Buddy 알림',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(
                    msg,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
