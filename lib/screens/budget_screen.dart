import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/transaction.dart';

/// 예산 설정 화면 — API /api/budgets 완전 연동
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _isSaving = false;

  // 카테고리별 기본 예산 한도 (서버 default_budgets 기반 또는 API 응답)
  static const List<String> _categories = [
    '식비', '교통', '쇼핑', '문화/여가', '의료', '통신', '주거', '교육', '기타',
  ];

  // 임시 편집용 맵 (slider/textfield 로컬 상태)
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final cat in _categories) {
      _controllers[cat] = TextEditingController();
    }
    // 현재 예산 값 채우기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillCurrentValues();
    });
  }

  void _fillCurrentValues() {
    final provider = context.read<TransactionProvider>();
    for (final cat in _categories) {
      final budget = provider.budgets.firstWhere(
        (b) => b.category == cat,
        orElse: () => Budget(category: cat, limit: _defaultLimit(cat, provider)),
      );
      _controllers[cat]?.text = budget.limit.toInt().toString();
    }
    setState(() {});
  }

  double _defaultLimit(String category, TransactionProvider provider) {
    // API config의 default_budgets에서 기본값 가져오기
    final defaults = provider.appConfig['default_budgets'];
    if (defaults is List) {
      for (final d in defaults) {
        if (d['category'] == category) {
          return (d['limit'] as num).toDouble();
        }
      }
    }
    // 최종 폴백 기본값
    const fallback = {
      '식비': 400000.0, '교통': 100000.0, '쇼핑': 200000.0,
      '문화/여가': 100000.0, '의료': 50000.0, '통신': 60000.0,
      '주거': 500000.0, '교육': 100000.0, '기타': 50000.0,
    };
    return fallback[category] ?? 100000.0;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    final provider = context.read<TransactionProvider>();

    int saved = 0;
    for (final cat in _categories) {
      final text = _controllers[cat]?.text ?? '0';
      final limit = double.tryParse(text.replaceAll(',', '')) ?? 0;
      if (limit >= 0) {
        await provider.updateBudget(cat, limit);
        saved++;
      }
    }

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$saved개 카테고리 예산이 저장되었습니다'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              // ── 헤더 ──────────────────────────────────────────
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
                                '예산 설정',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '카테고리별 월간 예산을 설정하세요',
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
              // ── 전체 지출 요약 카드 ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildSummaryCard(provider),
                ),
              ),
              // ── 카테고리별 예산 입력 리스트 ───────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final cat = _categories[i];
                      return _buildBudgetItem(cat, provider);
                    },
                    childCount: _categories.length,
                  ),
                ),
              ),
              // ── 저장 버튼 ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('예산 저장',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 요약 카드 ────────────────────────────────────────────────
  Widget _buildSummaryCard(TransactionProvider provider) {
    final totalBudget = _categories.fold(0.0, (sum, cat) {
      final text = _controllers[cat]?.text ?? '0';
      return sum + (double.tryParse(text.replaceAll(',', '')) ?? 0);
    });
    final totalSpent = provider.categoryExpenses.values
        .fold(0.0, (s, v) => s + v);
    final ratio = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이번 달 전체 예산 현황',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryChip(
                    '총 예산', _fmt(totalBudget), AppTheme.primaryBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryChip(
                    '총 지출', _fmt(totalSpent),
                    ratio > 0.8 ? AppTheme.dangerRed : AppTheme.warningOrange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryChip(
                    '잔여', _fmt(totalBudget - totalSpent),
                    AppTheme.successGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                  ratio > 0.8 ? AppTheme.dangerRed : AppTheme.primaryBlue),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '전체 예산의 ${(ratio * 100).toStringAsFixed(0)}% 사용',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── 카테고리별 예산 아이템 ────────────────────────────────────
  Widget _buildBudgetItem(String category, TransactionProvider provider) {
    final color = AppTheme.categoryColors[category] ?? AppTheme.primaryBlue;
    final icon = AppTheme.categoryIcons[category] ?? Icons.circle;
    final spent = provider.categoryExpenses[category] ?? 0.0;
    final limitText = _controllers[category]?.text ?? '0';
    final limit = double.tryParse(limitText.replaceAll(',', '')) ?? 0;
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > limit && limit > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isOver ? Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.4), width: 1.5) : null,
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
          // ── 카테고리명 + 입력 ──────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(category,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        if (isOver) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text('초과',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '이번 달 지출: ${_fmt(spent)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isOver
                              ? AppTheme.dangerRed
                              : AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              // ── 금액 입력 필드 ─────────────────────────────
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _controllers[category],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isOver ? AppTheme.dangerRed : AppTheme.primaryBlue),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    suffixText: '원',
                    suffixStyle: TextStyle(
                        fontSize: 12,
                        color: isOver
                            ? AppTheme.dangerRed
                            : AppTheme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: isOver
                              ? AppTheme.dangerRed
                              : AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: isOver
                              ? AppTheme.dangerRed
                              : AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    filled: true,
                    fillColor: color.withValues(alpha: 0.04),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── 진행 바 ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? AppTheme.dangerRed : color),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(ratio * 100).toStringAsFixed(0)}% 사용',
                style: TextStyle(
                    fontSize: 10,
                    color: isOver ? AppTheme.dangerRed : AppTheme.textSecondary),
              ),
              if (limit > 0)
                Text(
                  '잔여 ${_fmt((limit - spent).clamp(0, double.infinity))}',
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) {
    if (amount >= 10000) {
      final man = (amount / 10000).floor();
      final rem = (amount % 10000).toInt();
      if (rem == 0) return '$man만원';
      return '$man만 $rem원';
    }
    return '${amount.toInt()}원';
  }
}
