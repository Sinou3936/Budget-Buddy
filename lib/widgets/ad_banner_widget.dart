import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_env.dart';

// ══════════════════════════════════════════════════════════════
//  배너 광고 위젯
//  DEV  → Mock UI (노란 [DEV] 라벨 + 샘플 문구)
//  PROD → 실제 AdMob BannerAd 위젯 (google_mobile_ads 연동 시 교체)
// ══════════════════════════════════════════════════════════════
class AdBannerWidget extends StatelessWidget {
  final bool isPremium;
  const AdBannerWidget({super.key, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    if (isPremium) return const SizedBox.shrink();

    return AppEnv.useMockAds
        ? _MockBannerAd()
        : _ProdBannerAd(unitId: AppEnv.bannerAdUnitId);
  }
}

// ──────────────────────────────────────────────────────────────
//  DEV: Mock 배너 광고
// ──────────────────────────────────────────────────────────────
class _MockBannerAd extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // 노란 배경 → DEV임을 직관적으로 표시
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD600), width: 1.5),
      ),
      child: Row(
        children: [
          // [DEV] 라벨
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD600),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'DEV\n광고',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 광고 문구
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💰 [Mock] 재테크 시작하기 - 연 6% 적금 특판',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D4037),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '실제 배포 시 AdMob 광고로 자동 전환됩니다',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8D6E63),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          // 보기 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                '보기',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  PROD: 실제 AdMob 배너 자리 (배포 전 google_mobile_ads 교체)
// ──────────────────────────────────────────────────────────────
class _ProdBannerAd extends StatelessWidget {
  final String unitId;
  const _ProdBannerAd({required this.unitId});

  @override
  Widget build(BuildContext context) {
    // ── TODO: google_mobile_ads 활성화 후 아래 주석을 해제하세요 ──
    // return SizedBox(
    //   height: 50,
    //   child: AdWidget(ad: BannerAd(
    //     adUnitId: unitId,
    //     size: AdSize.banner,
    //     request: const AdRequest(),
    //     listener: BannerAdListener(),
    //   )..load()),
    // );

    // 임시: PROD 빌드에서도 UI 깨지지 않도록 빈 박스 유지
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: const Center(
        child: Text(
          '광고 로딩 중...',
          style: TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  전면 광고 서비스
//  DEV  → Mock Dialog (노란 테두리 + [DEV] 뱃지)
//  PROD → 실제 AdMob Interstitial (배포 전 교체)
// ══════════════════════════════════════════════════════════════
class AdInterstitialService {
  AdInterstitialService._();

  static void show(BuildContext context, {bool isPremium = false}) {
    if (isPremium) return;

    if (AppEnv.useMockAds) {
      _showMockInterstitial(context);
    } else {
      _showProdInterstitial(context);
    }
  }

  // ── DEV Mock ──────────────────────────────────────────────
  static void _showMockInterstitial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD600), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더: DEV 뱃지 + 닫기
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'DEV 전면광고',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Mock 광고 본문
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD600), width: 1.5),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance,
                          color: Color(0xFF8D6E63), size: 44),
                      SizedBox(height: 10),
                      Text(
                        '[Mock] 토스뱅크 무이자 대출',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037)),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '연 3.9% ~ 최대 3천만원',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF8D6E63)),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '실제 배포 시 AdMob 광고로 교체됩니다',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF8D6E63)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('광고 닫기',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '✨ 프리미엄으로 광고 없애기',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PROD (배포 전 AdMob SDK 교체) ────────────────────────
  static void _showProdInterstitial(BuildContext context) {
    // TODO: AdMob InterstitialAd.load() → .show() 구현
    // 지금은 아무것도 표시하지 않음 (광고 로드 실패 시 앱 크래시 방지)
  }
}
