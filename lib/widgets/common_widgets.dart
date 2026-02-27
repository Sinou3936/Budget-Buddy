import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../utils/app_env.dart';

// ══════════════════════════════════════════════════════════════
//  DEV 환경 배너 (화면 상단 고정 노란 리본)
// ══════════════════════════════════════════════════════════════
class DevEnvBanner extends StatelessWidget {
  final Widget child;
  const DevEnvBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppEnv.showDevBanner) return child;
    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: const Color(0xFFFFD600),
      textStyle: const TextStyle(
        color: Color(0xFF5D4037),
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AI 인사이트 카드
// ══════════════════════════════════════════════════════════════
class AiInsightCard extends StatelessWidget {
  final AiInsight insight;
  final VoidCallback? onDismiss;
  const AiInsightCard({super.key, required this.insight, this.onDismiss});

  Color get _cardColor {
    switch (insight.type) {
      case 'warning':     return const Color(0xFFFFF3E0);
      case 'achievement': return const Color(0xFFE8F5E9);
      default:            return const Color(0xFFE3F2FD);
    }
  }

  Color get _borderColor {
    switch (insight.type) {
      case 'warning':     return AppTheme.warningOrange;
      case 'achievement': return AppTheme.successGreen;
      default:            return AppTheme.accentBlue;
    }
  }

  IconData get _icon {
    switch (insight.type) {
      case 'warning':     return Icons.warning_amber_rounded;
      case 'achievement': return Icons.emoji_events_rounded;
      default:            return Icons.lightbulb_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _borderColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              margin: const EdgeInsets.only(right: 12, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _borderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon, color: _borderColor, size: 16),
            ),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    // ✅ 오버플로 방지
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    insight.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    // ✅ 오버플로 방지
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 16, color: AppTheme.textLight),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  거래 내역 리스트 타일 — 오버플로 전면 수정
// ══════════════════════════════════════════════════════════════
class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        AppTheme.categoryColors[transaction.category] ?? AppTheme.textLight;
    final icon =
        AppTheme.categoryIcons[transaction.category] ?? Icons.circle;
    final isIncome = transaction.type == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        // ─── 카테고리 아이콘 ───────────────────────────────
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        // ─── 타이틀: 거래명 + AI 태그 ─────────────────────
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                // ✅ 반드시 overflow 처리
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (transaction.isAiClassified) ...[
              const SizedBox(width: 6),
              _AiBadge(),
            ],
          ],
        ),
        // ─── 서브타이틀: 카테고리 + 은행 ─────────────────
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              // 카테고리 뱃지
              _CategoryBadge(label: transaction.category, color: color),
              // 은행명 — 공간이 있을 때만 표시
              if (transaction.bankName != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    transaction.bankName!,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLight),
                    // ✅ 오버플로 방지
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
        // ─── 트레일링: 금액 + 날짜 ────────────────────────
        trailing: IntrinsicWidth(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${_formatAmount(transaction.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      isIncome ? AppTheme.incomeGreen : AppTheme.textPrimary,
                ),
                // ✅ trailing 내에서도 overflow 처리
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(transaction.date),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
        onLongPress: onDelete != null ? () => _confirmDelete(context) : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('거래 삭제'),
        content: Text(
          '"${transaction.title}" 거래를 삭제할까요?',
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete!();
            },
            child: const Text('삭제',
                style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      final man = (amount / 10000).floor();
      final rem = (amount % 10000).toInt();
      if (rem == 0) return '$man만원';
      return '$man만 ${rem}원'; // ignore: unnecessary_brace_in_string_interps
    }
    return '${amount.toInt()}원';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1) return '방금 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    return '${date.month}/${date.day}';
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────
class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 9, color: AppTheme.primaryBlue),
          SizedBox(width: 2),
          Text('AI',
              style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
        // ✅ 뱃지도 overflow 방지
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  그라데이션 헤더
// ══════════════════════════════════════════════════════════════
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  const GradientHeader(
      {super.key, required this.child, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            Color(0xFF1976D2),
            AppTheme.primaryTeal,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: child,
    );
  }
}
