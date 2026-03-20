import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class BudgetSuggestScreen extends StatefulWidget {
  const BudgetSuggestScreen({super.key});

  @override
  State<BudgetSuggestScreen> createState() => _BudgetSuggestScreenState();
}

class _BudgetSuggestScreenState extends State<BudgetSuggestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gemini = context.read<GeminiProvider>();
      if (gemini.suggestedBudgets.isEmpty && !gemini.isBudgetLoading) {
        gemini.fetchBudgetSuggestions(context.read<TransactionProvider>());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GeminiProvider, TransactionProvider>(
      builder: (context, gemini, tx, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 150,
                backgroundColor: AppTheme.primaryBlue,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('AI 예산 추천', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            '소비 패턴 기반 맞춤 예산',
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
                  child: gemini.isBudgetLoading
                      ? _buildLoading()
                      : gemini.suggestedBudgets.isEmpty
                          ? _buildEmpty(gemini, tx)
                          : _buildSuggestions(gemini, tx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('AI가 소비 패턴을 분석하고 있습니다...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmpty(GeminiProvider gemini, TransactionProvider tx) {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tune, color: AppTheme.textLight, size: 64),
          const SizedBox(height: 16),
          Text(gemini.error ?? '예산 추천을 받아보세요', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => gemini.fetchBudgetSuggestions(tx),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('예산 추천 받기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(GeminiProvider gemini, TransactionProvider tx) {
    final suggestions = gemini.suggestedBudgets;
    final currentBudgets = {for (final b in tx.budgets) b.category: b.limit};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '소비 데이터를 분석해서 최적의 예산을 추천했습니다.\n원하는 항목만 선택해서 적용하세요.',
                  style: TextStyle(fontSize: 13, color: AppTheme.primaryBlue, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...suggestions.entries.map((entry) {
          final current = currentBudgets[entry.key] ?? 0;
          final suggested = entry.value;
          final diff = suggested - current;
          return _buildSuggestionCard(
            category: entry.key,
            current: current,
            suggested: suggested,
            diff: diff,
            onApply: () => tx.updateBudget(entry.key, suggested),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              for (final entry in suggestions.entries) {
                await tx.updateBudget(entry.key, entry.value);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('모든 추천 예산이 적용되었습니다!'),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('전체 적용', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => gemini.fetchBudgetSuggestions(tx),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 추천받기'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required String category,
    required double current,
    required double suggested,
    required double diff,
    required VoidCallback onApply,
  }) {
    final color = AppTheme.categoryColors[category] ?? AppTheme.primaryBlue;
    final icon  = AppTheme.categoryIcons[category] ?? Icons.circle;
    final isUp  = diff > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(child: Text('현재 ${_fmt(current)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                    const Text(' → ', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    Flexible(child: Text('추천 ${_fmt(suggested)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis)),
                    if (diff != 0) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '(${isUp ? '+' : ''}${_fmt(diff)})',
                          style: TextStyle(fontSize: 11, color: isUp ? AppTheme.warningOrange : AppTheme.successGreen),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: const Text('적용', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) {
    if (amount >= 10000) return '${(amount / 10000).floor()}만원';
    return '${amount.toInt()}원';
  }
}
