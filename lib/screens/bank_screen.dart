import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';


class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().trackPageView('bank_screen');
    });
  }

  // ── 헬퍼: bankName으로 연동 계좌 찾기 ─────────────────────
  Map<String, dynamic>? _findAccount(List<Map<String, dynamic>> accounts, String bankName) {
    try {
      return accounts.firstWhere((a) => a['bank_name'] == bankName);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        // 서버에서 받아온 데이터 사용
        final banks = provider.banks;
        final accounts = provider.bankAccounts;
        final linkedBanks = banks.where((b) => _findAccount(accounts, b['name'] as String) != null).toList();
        final totalBalance = accounts.fold(0.0, (s, a) => s + ((a['balance'] as num?)?.toDouble() ?? 0.0));

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 210,
                backgroundColor: AppTheme.primaryBlue,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: const Text(
                  '은행 연동',
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('총 자산', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(totalBalance),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.lock_outline, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('256-bit 암호화 보호', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ]),
                            ),
                          ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (linkedBanks.isNotEmpty) ...[
                        const Text('연동된 계좌',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        ...linkedBanks.map((bank) => _buildLinkedBankCard(bank, accounts)),
                        const SizedBox(height: 24),
                      ],
                      _buildSecurityInfo(),
                      const SizedBox(height: 24),
                      const Text('은행 연동하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Open API로 계좌를 안전하게 연동하세요',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      if (banks.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, childAspectRatio: 2.4,
                            crossAxisSpacing: 12, mainAxisSpacing: 12,
                          ),
                          itemCount: banks.length,
                          itemBuilder: (ctx, idx) => _buildBankCard(banks[idx], accounts),
                        ),
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

  Widget _buildLinkedBankCard(Map<String, dynamic> bank, List<Map<String, dynamic>> accounts) {
    final bankName = bank['name'] as String;
    final account  = _findAccount(accounts, bankName);
    final colorHex = bank['color_hex'] as String? ?? '#1565C0';
    final color    = _hexToColor(colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(bank['icon'] as String? ?? '🏦', style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(bankName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 10, color: AppTheme.successGreen),
                  SizedBox(width: 3),
                  Text('연동됨', style: TextStyle(fontSize: 10, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            const SizedBox(height: 2),
            Text(account?['account_number'] as String? ?? '',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(
            _formatAmount((account?['balance'] as num?)?.toDouble() ?? 0),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _unlinkBank(bank, account?['id'] as String?),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('연동 해제', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryBlue.withValues(alpha: 0.08),
          AppTheme.primaryTeal.withValues(alpha: 0.08),
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.security, color: AppTheme.primaryBlue, size: 20),
          SizedBox(width: 8),
          Text('보안 및 개인정보 보호',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ]),
        const SizedBox(height: 12),
        ...[
          '🔒 256-bit AES 암호화로 계좌 정보 보호',
          '🛡️ 읽기 전용 API - 송금/이체 불가',
          '🔐 OAuth 2.0 표준 인증 방식',
          '📱 생체인증으로 앱 접근 보호',
          '🚫 서버에 계좌번호 저장 안함',
        ].map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
            )),
      ]),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank, List<Map<String, dynamic>> accounts) {
    final bankName = bank['name'] as String;
    final isLinked = _findAccount(accounts, bankName) != null;
    final colorHex = bank['color_hex'] as String? ?? '#1565C0';
    final color    = _hexToColor(colorHex);

    return GestureDetector(
      onTap: () => isLinked ? null : _showLinkDialog(bank),
      child: Container(
        decoration: BoxDecoration(
          color: isLinked ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLinked ? color.withValues(alpha: 0.4) : AppTheme.dividerColor,
            width: isLinked ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(bank['icon'] as String? ?? '🏦', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Flexible(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  bank['name'] as String,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  isLinked ? '연동됨' : '연동하기',
                  style: TextStyle(fontSize: 10, color: isLinked ? AppTheme.successGreen : AppTheme.primaryBlue),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showLinkDialog(Map<String, dynamic> bank) {
    final bankId = bank['id'] as int;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Text(bank['icon'] as String? ?? '🏦', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Text('${bank['name']} 연동'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Open Banking API를 통해 계좌를 안전하게 연동합니다.',
              style: TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('✅ 잔액 조회만 가능', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('✅ 거래내역 자동 가져오기', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('❌ 송금/이체 절대 불가', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<TransactionProvider>();
              final ok = await provider.linkBankAccount(bank['name'] as String);
              if (!context.mounted) return;
              provider.trackPageView('bank_linked');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? '${bank['name']} 연동 완료!' : '연동에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: const Text('연동하기'),
          ),
        ],
      ),
    );
  }

  void _unlinkBank(Map<String, dynamic> bank, String? accountId) {
    if (accountId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('연동 해제'),
        content: Text('${bank['name']} 연동을 해제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionProvider>().unlinkBankAccount(accountId);
            },
            child: const Text('해제', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppTheme.primaryBlue;
    }
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
}
