import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadData().then((_) {
        _checkAiAlerts();
      });
    });
  }

  void _checkAiAlerts() {
    final provider = context.read<TransactionProvider>();
    final warnings = provider.insights.where((i) => i.type == 'warning').toList();
    if (warnings.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _showAiPopup(warnings.first);
      });
    }
  }

  void _showAiPopup(dynamic insight) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppTheme.warningOrange, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                insight.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                insight.message,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('확인했어요',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasTransactions = provider.currentMonthTransactions.isNotEmpty;

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              _buildSliverHeader(provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 빠른 통계 카드 ──────────────────────────────
                      _buildQuickStats(provider),
                      const SizedBox(height: 20),

                      // ── 데이터 없을 때 온보딩 카드 ─────────────────
                      if (!hasTransactions) ...[
                        _buildEmptyStateCard(),
                        const SizedBox(height: 20),
                      ],

                      // ── AI 인사이트 ────────────────────────────────
                      if (provider.insights.isNotEmpty) ...[
                        _buildAiInsightSection(provider),
                        const SizedBox(height: 20),
                      ],

                      // ── 카테고리 차트 (데이터 있을 때만) ───────────
                      if (provider.categoryExpenses.isNotEmpty) ...[
                        _buildCategoryChart(provider),
                        const SizedBox(height: 20),
                      ],

                      // ── 예산 현황 ──────────────────────────────────
                      if (provider.budgets.isNotEmpty) ...[
                        _buildBudgetSection(provider),
                        const SizedBox(height: 20),
                      ],

                      // ── 최근 거래 ──────────────────────────────────
                      if (hasTransactions) ...[
                        _buildRecentTransactions(provider),
                        const SizedBox(height: 20),
                      ],

                      // 하단 여백 (추가 버튼 + 네비게이션 바 공간)
                      const SizedBox(height: 100),
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

  // ── 빈 상태 카드 (첫 방문 / 거래 없음) ──────────────────────────────
  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.07),
            AppTheme.primaryTeal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppTheme.primaryBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Budget Buddy에 오신 걸 환영해요! 🎉',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            '첫 거래를 추가하면\nAI가 소비 패턴을 분석해 드려요.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // 빠른 시작 팁
          _buildTipRow(Icons.add_circle_outline, '오른쪽 아래 추가 버튼으로 거래를 기록하세요'),
          const SizedBox(height: 10),
          _buildTipRow(Icons.auto_awesome, 'AI가 카테고리를 자동으로 분류해 드려요'),
          const SizedBox(height: 10),
          _buildTipRow(Icons.bar_chart, '분석 탭에서 소비 패턴을 확인하세요'),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverHeader(TransactionProvider provider) {
    final now = DateTime.now();
    final months = ['1월', '2월', '3월', '4월', '5월', '6월',
                    '7월', '8월', '9월', '10월', '11월', '12월'];

    return SliverToBoxAdapter(
      child: GradientHeader(
        height: 200,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${now.year}년 ${months[now.month - 1]}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const Text(
                          'Budget Buddy',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('이번 달 잔액',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 3),
                Text(
                  _formatAmount(provider.totalBalance),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeaderStat(
                        '수입', provider.totalIncome, AppTheme.accentTeal),
                    const SizedBox(width: 20),
                    _buildHeaderStat(
                        '지출', provider.totalExpense, const Color(0xFFFF8A80)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, double amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(
              _formatAmount(amount),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(TransactionProvider provider) {
    final expenseRatio = provider.totalIncome > 0
        ? (provider.totalExpense / provider.totalIncome * 100).toStringAsFixed(0)
        : '0';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '거래 건수',
            '${provider.currentMonthTransactions.length}건',
            Icons.receipt_long,
            AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            '지출 비율',
            '$expenseRatio%',
            Icons.pie_chart,
            provider.totalExpense /
                        (provider.totalIncome > 0
                            ? provider.totalIncome
                            : 1) >
                    0.8
                ? AppTheme.dangerRed
                : AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'AI 인사이트',
            '${provider.insights.length}개',
            Icons.auto_awesome,
            AppTheme.warningOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightSection(TransactionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppTheme.primaryBlue, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI 소비 인사이트',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...provider.insights
            .take(2)
            .map((i) => AiInsightCard(insight: i)),
      ],
    );
  }

  Widget _buildCategoryChart(TransactionProvider provider) {
    final expenses = provider.categoryExpenses;

    final sections = <PieChartSectionData>[];
    int idx = 0;
    expenses.forEach((category, amount) {
      final color = AppTheme.categoryColors[category] ?? Colors.grey;
      final percentage =
          provider.totalExpense > 0 ? amount / provider.totalExpense * 100 : 0;
      sections.add(PieChartSectionData(
        value: amount,
        title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: color,
        radius: _touchedIndex == idx ? 65 : 55,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      idx++;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('카테고리별 지출',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 35,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                          } else {
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: expenses.entries.take(5).map((e) {
                    final color =
                        AppTheme.categoryColors[e.key] ?? Colors.grey;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(e.key,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary))),
                          Text(
                            _formatAmount(e.value),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('예산 현황',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          ...provider.budgets.map((budget) {
            final color =
                AppTheme.categoryColors[budget.category] ?? Colors.blue;
            final isOver = budget.isOverBudget;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          budget.category,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 3,
                        child: Text(
                          '${_formatAmount(budget.spent)} / ${_formatAmount(budget.limit)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isOver
                                  ? AppTheme.dangerRed
                                  : AppTheme.textSecondary,
                              fontWeight: isOver
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: budget.percentage,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isOver ? AppTheme.dangerRed : color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionProvider provider) {
    final transactions = provider.currentMonthTransactions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('최근 거래',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('전체 보기',
                    style: TextStyle(
                        color: AppTheme.primaryBlue, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...transactions.map((t) => TransactionListTile(
                transaction: t,
                onDelete: () =>
                    context.read<TransactionProvider>().deleteTransaction(t.id),
              )),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(1)}억원';
    } else if (amount >= 10000) {
      final man = (amount / 10000).floor();
      final rem = (amount % 10000).toInt();
      if (rem == 0) return '$man만원';
      return '$man만 ${rem}원'; // ignore: unnecessary_brace_in_string_interps
    }
    return '${amount.toInt()}원';
  }
}
