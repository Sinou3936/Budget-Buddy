import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'notification_screen.dart';
import '../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTransactions;
  const DashboardScreen({super.key, this.onNavigateToTransactions});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedIndex = -1;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadData().then((_) {
        _checkAiAlerts();
      });
    });
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  void _checkAiAlerts() {
    final provider = context.read<BudgetProvider>();
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
      builder: (context, tx, _) {
        final app = context.watch<AppProvider>();
        final budget = context.watch<BudgetProvider>();

        if (app.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              if (app.isOffline)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '서버에 연결할 수 없습니다. 저장된 데이터를 표시합니다.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildSliverHeader(tx),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(tx, budget),
                      const SizedBox(height: 20),
                      _buildAiInsightSection(budget),
                      const SizedBox(height: 20),
                      _buildCategoryChart(tx),
                      const SizedBox(height: 20),
                      _buildBudgetSection(budget),
                      const SizedBox(height: 20),
                      _buildRecentTransactions(tx),
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

  Widget _buildSliverHeader(TransactionProvider tx) {
    final now = DateTime.now();
    final months = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: AppTheme.primaryBlue,
      elevation: 0,
      title: const Text(
        'Budget Buddy',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
              _loadUnreadCount();
            },
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.dangerRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _unreadCount > 9 ? '9+' : '$_unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${now.year}년 ${months[now.month - 1]}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Spacer(),
                  const Text('이번 달 잔액',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(tx.totalBalance),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(child: _buildHeaderStat('수입', tx.totalIncome, AppTheme.accentTeal)),
                      const SizedBox(width: 20),
                      Flexible(child: _buildHeaderStat('지출', tx.totalExpense, const Color(0xFFFF8A80))),
                    ],
                  ),
                ],
              ),
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

  Widget _buildQuickStats(TransactionProvider tx, BudgetProvider budget) {
    final expenseRatio = tx.totalIncome > 0
        ? (tx.totalExpense / tx.totalIncome * 100).toStringAsFixed(0)
        : '0';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '거래 건수',
            '${tx.currentMonthTransactions.length}건',
            Icons.receipt_long,
            AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '지출 비율',
            '$expenseRatio%',
            Icons.pie_chart,
            tx.totalExpense / (tx.totalIncome > 0 ? tx.totalIncome : 1) > 0.8
                ? AppTheme.dangerRed
                : AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'AI 인사이트',
            '${budget.insights.length}개',
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
          const SizedBox(height: 2),
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

  Widget _buildAiInsightSection(BudgetProvider budget) {
    if (budget.insights.isEmpty) return const SizedBox.shrink();

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
        ...budget.insights
            .take(2)
            .map((i) => AiInsightCard(insight: i)),
      ],
    );
  }

  Widget _buildCategoryChart(TransactionProvider tx) {
    final expenses = tx.categoryExpenses;
    if (expenses.isEmpty) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    int idx = 0;
    expenses.forEach((category, amount) {
      final color = AppTheme.categoryColors[category] ?? Colors.grey;
      final percentage =
          tx.totalExpense > 0 ? amount / tx.totalExpense * 100 : 0;
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

  Widget _buildBudgetSection(BudgetProvider budget) {
    if (budget.budgets.isEmpty) return const SizedBox.shrink();

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
          ...budget.budgets.map((b) {
            final color = AppTheme.categoryColors[b.category] ?? Colors.blue;
            final isOver = b.isOverBudget;
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
                          b.category,
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
                          '${_formatAmount(b.spent)} / ${_formatAmount(b.limit)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isOver
                                  ? AppTheme.dangerRed
                                  : AppTheme.textSecondary,
                              fontWeight:
                                  isOver ? FontWeight.bold : FontWeight.normal),
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
                      value: b.percentage,
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

  Widget _buildRecentTransactions(TransactionProvider tx) {
    final transactions = tx.currentMonthTransactions.take(5).toList();

    return Column(
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
              onPressed: widget.onNavigateToTransactions,
              child: const Text('전체 보기',
                  style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...transactions.map((t) => TransactionListTile(
              transaction: t,
              onDelete: () =>
                  context.read<TransactionProvider>().deleteTransaction(t.id),
            )),
      ],
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
