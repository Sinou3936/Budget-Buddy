import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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
                expandedHeight: 140,
                backgroundColor: AppTheme.primaryBlue,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: const Text(
                  '소비 분석',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryBlue, Color(0xFF1976D2), AppTheme.primaryTeal],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            'AI가 분석한 나의 소비 패턴',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                          ),
                        ),
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
                      _buildSummaryCards(provider),
                      const SizedBox(height: 20),
                      _buildBarChart(provider),
                      const SizedBox(height: 20),
                      _buildAiInsightsAll(provider),
                      const SizedBox(height: 20),
                      _buildTopSpending(provider),
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

  Widget _buildSummaryCards(TransactionProvider provider) {
    final savingRate = provider.totalIncome > 0
        ? ((provider.totalIncome - provider.totalExpense) /
                provider.totalIncome *
                100)
            .clamp(0.0, 100.0)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '총 수입',
            provider.totalIncome,
            AppTheme.incomeGreen,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '총 지출',
            provider.totalExpense,
            AppTheme.dangerRed,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSavingRateCard(savingRate),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatShort(amount),
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSavingRateCard(double rate) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.savings, color: AppTheme.primaryBlue, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${rate.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rate >= 20
                      ? AppTheme.successGreen
                      : AppTheme.warningOrange),
            ),
          ),
          const Text(
            '저축률',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(TransactionProvider provider) {
    final dailyData = provider.dailyExpenses;
    if (dailyData.isEmpty) return const SizedBox.shrink();

    final maxAmount = dailyData.fold(
        0.0,
        (max, d) =>
            (d['amount'] as double) > max ? (d['amount'] as double) : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('최근 7일 지출',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxAmount > 0 ? maxAmount * 1.2 : 100000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.primaryBlue,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        _formatShort(rod.toY),
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dailyData.length) {
                          return const Text('');
                        }
                        final date = dailyData[idx]['date'] as DateTime;
                        final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
                        return Text(
                          dayNames[date.weekday % 7],
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dailyData.length, (i) {
                  final amount = dailyData[i]['amount'] as double;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        color: amount > 100000
                            ? AppTheme.dangerRed
                            : AppTheme.primaryBlue,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxAmount > 0 ? maxAmount * 1.2 : 100000,
                          color:
                              AppTheme.primaryBlue.withValues(alpha: 0.07),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsAll(TransactionProvider provider) {
    if (provider.insights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
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
                '전체 AI 인사이트',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${provider.insights.length}개',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...provider.insights.map((i) => AiInsightCard(insight: i)),
        ],
      ),
    );
  }

  Widget _buildTopSpending(TransactionProvider provider) {
    final sorted = provider.currentMonthTransactions
        .where((t) => t.type == 'expense')
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (sorted.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이번 달 TOP 지출',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          ...sorted.take(5).map((t) {
            final idx = sorted.indexOf(t);
            final medals = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];
            final color =
                AppTheme.categoryColors[t.category] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(medals[idx], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        AppTheme.categoryIcons[t.category] ?? Icons.circle,
                        color: color,
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis),
                        Text(t.category,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    _formatShort(t.amount),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatShort(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    }
    return '${amount.toInt()}원';
  }
}
