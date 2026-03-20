import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_env.dart';
import '../widgets/common_widgets.dart';
import 'ai_chat_screen.dart';
import 'ai_report_screen.dart';
import 'budget_suggest_screen.dart';
import 'receipt_ocr_screen.dart';
import 'add_transaction_screen.dart';
import '../models/transaction.dart';
import '../models/ocr_result.dart';

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppTheme.primaryBlue,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                SizedBox(width: 8),
                Text(
                  'AI 재무 어시스턴트',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini AI가 소비 패턴을 분석하고\n맞춤형 재무 인사이트를 제공합니다.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
                        ),
                        if (!AppEnv.geminiEnabled) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange, size: 14),
                                SizedBox(width: 6),
                                Text('Gemini API 키 미설정', style: TextStyle(color: Colors.orange, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 이번 달 요약 카드
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _MonthSummaryCard(tx: tx),
            ),
          ),

          // AI 기능 메뉴
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: const Text(
                'AI 기능',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _AiFeatureCard(
                  icon: Icons.chat_bubble_rounded,
                  color: AppTheme.primaryBlue,
                  title: 'AI 소비 상담',
                  subtitle: '재무 관련 무엇이든 물어보세요',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
                ),
                _AiFeatureCard(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF7C3AED),
                  title: '영수증 스캔',
                  subtitle: '사진으로 자동 지출 등록',
                  onTap: () => _openReceiptOcr(context, tx),
                ),
                _AiFeatureCard(
                  icon: Icons.summarize_rounded,
                  color: const Color(0xFF059669),
                  title: 'AI 월말 리포트',
                  subtitle: '이번 달 소비 종합 분석',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiReportScreen())),
                ),
                _AiFeatureCard(
                  icon: Icons.tune_rounded,
                  color: const Color(0xFFD97706),
                  title: 'AI 예산 추천',
                  subtitle: '패턴 기반 최적 예산 설정',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetSuggestScreen())),
                ),
              ]),
            ),
          ),

          // 하단 여백
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Future<void> _openReceiptOcr(BuildContext context, TransactionProvider tx) async {
    final result = await Navigator.push<OcrResult>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptOcrScreen()),
    );
    if (result != null && context.mounted) {
      final transaction = Transaction(
        id: tx.generateNewId(),
        title: result.title,
        amount: result.amount ?? 0,
        category: result.category.isNotEmpty ? result.category : '기타',
        type: 'expense',
        date: DateTime.now(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddTransactionScreen(editTransaction: transaction),
        ),
      );
    }
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final TransactionProvider tx;
  const _MonthSummaryCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expense = tx.totalExpense;
    final income = tx.totalIncome;
    final balance = tx.totalBalance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 16),
              const SizedBox(width: 6),
              Text(
                '${now.year}년 ${now.month}월 현황',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryItem(label: '수입', amount: income, color: AppTheme.successGreen),
              const SizedBox(width: 16),
              _SummaryItem(label: '지출', amount: expense, color: AppTheme.dangerRed),
              const SizedBox(width: 16),
              _SummaryItem(
                label: '잔액',
                amount: balance,
                color: balance >= 0 ? AppTheme.primaryBlue : AppTheme.dangerRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryItem({required this.label, required this.amount, required this.color});

  String _fmt(double v) {
    final abs = v.abs();
    if (abs >= 10000) return '${(abs / 10000).floor()}만원';
    return '${abs.toInt()}원';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(
            _fmt(amount),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AiFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AiFeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
