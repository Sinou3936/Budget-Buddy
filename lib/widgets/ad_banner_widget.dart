import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// AdMob 광고 배너 위젯 (수익화)
/// 실제 배포 시 google_mobile_ads 패키지와 연동
class AdBannerWidget extends StatelessWidget {
  final bool isPremium;

  const AdBannerWidget({super.key, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    // 프리미엄 사용자는 광고 비표시
    if (isPremium) return const SizedBox.shrink();

    // 웹 환경에서는 모의 광고 배너 표시
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '광고',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💰 재테크 시작하기 - 연 6% 적금 특판',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '신한은행 × Budget Buddy 특별 제휴',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                '보기',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 전면 광고 (Interstitial Ad) 시뮬레이터
class AdInterstitialService {
  static int _transactionCount = 0;

  /// 거래 추가 5회마다 전면 광고 표시
  static void onTransactionAdded(BuildContext context, bool isPremium) {
    if (isPremium) return;
    _transactionCount++;
    if (_transactionCount % 5 == 0) {
      _showInterstitialAd(context);
    }
  }

  static void _showInterstitialAd(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('광고',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance,
                          color: Colors.white, size: 48),
                      SizedBox(height: 12),
                      Text('토스뱅크 무이자 대출',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('연 3.9% ~ 최대 3천만원',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('광고 닫기'),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  '✨ 프리미엄으로 광고 없애기',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
