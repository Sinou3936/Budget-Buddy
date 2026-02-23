import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final List<Map<String, dynamic>> _banks = [
    {'name': '카카오뱅크', 'icon': '🟡', 'color': const Color(0xFFFEE500), 'linked': true, 'balance': 1250000.0, 'account': '333-0000-1234'},
    {'name': '신한은행', 'icon': '🔵', 'color': const Color(0xFF0046FF), 'linked': true, 'balance': 850000.0, 'account': '110-456-789012'},
    {'name': '국민은행', 'icon': '🟤', 'color': const Color(0xFFFFB300), 'linked': false, 'balance': 0.0, 'account': ''},
    {'name': '우리은행', 'icon': '🔵', 'color': const Color(0xFF003087), 'linked': false, 'balance': 0.0, 'account': ''},
    {'name': '하나은행', 'icon': '🟢', 'color': const Color(0xFF00A650), 'linked': false, 'balance': 0.0, 'account': ''},
    {'name': 'IBK기업은행', 'icon': '🔴', 'color': const Color(0xFFC41E3A), 'linked': false, 'balance': 0.0, 'account': ''},
  ];

  @override
  Widget build(BuildContext context) {
    final linkedBanks = _banks.where((b) => b['linked'] as bool).toList();
    final totalBalance = linkedBanks.fold(0.0, (sum, b) => sum + (b['balance'] as double));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              height: 180,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('은행 연동',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('총 자산',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(totalBalance),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                const Text('256-bit 암호화 보호',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  // 연동된 계좌
                  if (linkedBanks.isNotEmpty) ...[
                    const Text('연동된 계좌',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    ...linkedBanks.map((bank) => _buildLinkedBankCard(bank)),
                    const SizedBox(height: 24),
                  ],

                  // 보안 안내
                  _buildSecurityInfo(),
                  const SizedBox(height: 24),

                  // 연동 가능 은행
                  const Text('은행 연동하기',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Open API로 계좌를 안전하게 연동하세요',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _banks.length,
                    itemBuilder: (ctx, idx) => _buildBankCard(_banks[idx], idx),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedBankCard(Map<String, dynamic> bank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (bank['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(bank['icon'] as String,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bank['name'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 10, color: AppTheme.successGreen),
                          SizedBox(width: 3),
                          Text('연동됨',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(bank['account'] as String,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(bank['balance'] as double),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _showUnlinkDialog(bank),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('연동 해제',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.primaryTeal.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('보안 및 개인정보 보호',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            '🔒 256-bit AES 암호화로 계좌 정보 보호',
            '🛡️ 읽기 전용 API - 송금/이체 불가',
            '🔐 OAuth 2.0 표준 인증 방식',
            '📱 생체인증으로 앱 접근 보호',
            '🚫 서버에 계좌번호 저장 안함',
          ].map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4)),
              )),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank, int index) {
    final isLinked = bank['linked'] as bool;
    final color = bank['color'] as Color;

    return GestureDetector(
      onTap: () => isLinked ? null : _showLinkDialog(bank, index),
      child: Container(
        decoration: BoxDecoration(
          color: isLinked ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLinked ? color.withValues(alpha: 0.4) : AppTheme.dividerColor,
            width: isLinked ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(bank['icon'] as String,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank['name'] as String,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(
                  isLinked ? '연동됨' : '연동하기',
                  style: TextStyle(
                    fontSize: 11,
                    color: isLinked ? AppTheme.successGreen : AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog(Map<String, dynamic> bank, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(bank['icon'] as String, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text('${bank['name']} 연동'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Open Banking API를 통해 계좌를 안전하게 연동합니다.',
                style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ 잔액 조회만 가능',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('✅ 거래내역 자동 가져오기',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('❌ 송금/이체 절대 불가',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _banks[index]['linked'] = true;
                _banks[index]['balance'] = 500000.0;
                _banks[index]['account'] = '123-456-789';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${bank['name']} 연동 완료!'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('연동하기'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkDialog(Map<String, dynamic> bank) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('연동 해제'),
        content: Text('${bank['name']} 연동을 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final idx = _banks.indexOf(bank);
                _banks[idx]['linked'] = false;
                _banks[idx]['balance'] = 0.0;
                _banks[idx]['account'] = '';
              });
            },
            child: const Text('해제',
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
      return '$man만 ${rem}원';
    }
    return '${amount.toInt()}원';
  }
}
