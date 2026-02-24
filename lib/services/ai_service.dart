import '../models/transaction.dart';

class AiService {
  // 서버에서 받아온 AI 키워드 (동적)
  static Map<String, List<String>> _keywordMap = {};

  /// 서버에서 받아온 키워드로 업데이트
  static void updateKeywords(Map<String, List<String>> keywords) {
    if (keywords.isNotEmpty) {
      _keywordMap = keywords;
    }
  }

  // AI 기반 거래 자동 분류
  static String classifyTransaction(String title) {
    final lower = title.toLowerCase();

    // 서버 키워드가 있으면 우선 사용
    if (_keywordMap.isNotEmpty) {
      for (final entry in _keywordMap.entries) {
        for (final kw in entry.value) {
          if (lower.contains(kw.toLowerCase())) return entry.key;
        }
      }
      return '기타';
    }

    // 폴백: 내장 키워드
    const foodKeywords = [
      '스타벅스', '카페', '맥도날드', '버거킹', '롯데리아', '파리바게뜨', '뚜레쥬르',
      '편의점', 'cu', 'gs25', '세븐일레븐', '미니스톱', '식당', '음식점', '배달',
      '배민', '요기요', '쿠팡이츠', '이마트', '홈플러스', '롯데마트', '마트',
      '치킨', '피자', '짜장', '짬뽕', '초밥', '삼겹살', '족발', '보쌈',
      '투썸', '이디야', '할리스', '엔제리너스', '던킨', '빵', '베이커리',
    ];
    const transportKeywords = [
      '교통카드', '지하철', '버스', '택시', '카카오택시', '우버',
      '주유', '주차', '고속도로', '톨게이트', 'ktx', '기차', '항공', '공항',
    ];
    const shoppingKeywords = [
      '쿠팡', '올리브영', '다이소', '유니클로', '자라', '무신사',
      '에이블리', '지그재그', '29cm', '위메프', '티몬', 'g마켓', '11번가',
      '아이파크', '이케아', '코스트코', '백화점', '쇼핑',
    ];
    const entertainmentKeywords = [
      '넷플릭스', '유튜브', '왓챠', '웨이브', '영화', 'cgv',
      '메가박스', '롯데시네마', '게임', '스팀', '노래방', '볼링',
      '헬스장', '헬스', '피트니스', '수영장',
    ];
    const medicalKeywords = [
      '병원', '약국', '의원', '한의원', '치과', '안과', '피부과', '내과',
      '약', '처방', '의료',
    ];
    const telecomKeywords = [
      '통신비', '인터넷요금', '핸드폰요금', '모바일요금',
    ];
    const housingKeywords = [
      '월세', '관리비', '전기요금', '가스요금', '수도요금', '렌트',
    ];
    const educationKeywords = [
      '학원', '교재', '강의', '수강', '과외', '교육비',
    ];

    for (final kw in foodKeywords) { if (lower.contains(kw)) return '식비'; }
    for (final kw in transportKeywords) { if (lower.contains(kw)) return '교통'; }
    for (final kw in shoppingKeywords) { if (lower.contains(kw)) return '쇼핑'; }
    for (final kw in entertainmentKeywords) { if (lower.contains(kw)) return '문화/여가'; }
    for (final kw in medicalKeywords) { if (lower.contains(kw)) return '의료'; }
    for (final kw in telecomKeywords) { if (lower.contains(kw)) return '통신'; }
    for (final kw in housingKeywords) { if (lower.contains(kw)) return '주거'; }
    for (final kw in educationKeywords) { if (lower.contains(kw)) return '교육'; }
    return '기타';
  }

  // AI 소비 분석 및 인사이트 생성 (임계값을 서버에서 받아 사용)
  static List<AiInsight> generateInsights({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required double totalExpense,
    required double totalIncome,
    Map<String, dynamic> thresholds = const {},
  }) {
    final insights = <AiInsight>[];
    final now = DateTime.now();

    // 임계값 (서버 설정값 사용, 없으면 기본값)
    final foodWarning     = (thresholds['food_warning']     as num?)?.toDouble()  ?? 300000;
    final shoppingWarning = (thresholds['shopping_warning'] as num?)?.toDouble()  ?? 200000;
    final cafeCount       = (thresholds['cafe_count']       as num?)?.toInt()     ?? 5;
    final expenseRatioWarn = (thresholds['expense_ratio_warning'] as num?)?.toDouble() ?? 0.8;
    final savingsPraise   = (thresholds['savings_praise_ratio'] as num?)?.toDouble()   ?? 0.4;

    final categoryExpenses = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      categoryExpenses[t.category] = (categoryExpenses[t.category] ?? 0) + t.amount;
    }

    // 1. 예산 초과 경고
    for (final budget in budgets) {
      if (budget.isOverBudget) {
        insights.add(AiInsight(
          title: '⚠️ 예산 초과 경고',
          message: '${budget.category} 예산이 ${_fmt(budget.spent - budget.limit)} 초과되었어요!',
          type: 'warning', category: budget.category, createdAt: now,
        ));
      } else if (budget.percentage > 0.8) {
        insights.add(AiInsight(
          title: '🔔 예산 80% 도달',
          message: '${budget.category} 예산의 ${(budget.percentage * 100).toStringAsFixed(0)}%를 사용했어요. 남은 예산: ${_fmt(budget.remaining)}',
          type: 'warning', category: budget.category, createdAt: now,
        ));
      }
    }

    // 2. 지출 비율 분석
    if (totalIncome > 0 && totalExpense / totalIncome > expenseRatioWarn) {
      insights.add(AiInsight(
        title: '💸 지출 비율이 높아요',
        message: '이번 달 수입의 ${(totalExpense / totalIncome * 100).toStringAsFixed(0)}%를 지출했어요. 수입의 20%는 저축하는 게 좋아요!',
        type: 'warning', category: '전체', createdAt: now,
      ));
    }

    // 3. 식비 과다
    final foodExpense = categoryExpenses['식비'] ?? 0;
    if (foodExpense > foodWarning) {
      insights.add(AiInsight(
        title: '🍽️ 식비 지출 패턴 분석',
        message: '이번 달 식비가 ${_fmt(foodExpense)}이에요. 직접 요리하면 월 10~15만원 절약 가능!',
        type: 'tip', category: '식비', createdAt: now,
      ));
    }

    // 4. 카페 지출
    final cafeTxs = transactions.where((t) =>
      t.type == 'expense' &&
      (t.title.contains('스타벅스') || t.title.contains('카페') ||
       t.title.contains('투썸')   || t.title.contains('이디야')));
    if (cafeTxs.length >= cafeCount) {
      final cafeTotal = cafeTxs.fold(0.0, (s, t) => s + t.amount);
      insights.add(AiInsight(
        title: '☕ 카페 지출 패턴 감지',
        message: '이번 달 카페 ${cafeTxs.length}번 방문, 총 ${_fmt(cafeTotal)}. 텀블러 챌린지로 30% 절약!',
        type: 'tip', category: '식비', createdAt: now,
      ));
    }

    // 5. 저축 칭찬
    if (totalIncome > 0 && totalExpense / totalIncome < savingsPraise) {
      insights.add(AiInsight(
        title: '🏆 훌륭한 절약 습관!',
        message: '이번 달 수입의 ${(100 - totalExpense / totalIncome * 100).toStringAsFixed(0)}% 절약! 연간 ${_fmt((totalIncome - totalExpense) * 12)} 저축 가능!',
        type: 'achievement', category: '전체', createdAt: now,
      ));
    }

    // 6. 쇼핑 분석
    final shoppingExpense = categoryExpenses['쇼핑'] ?? 0;
    if (shoppingExpense > shoppingWarning) {
      insights.add(AiInsight(
        title: '🛍️ 쇼핑 지출 알림',
        message: '이번 달 쇼핑 ${_fmt(shoppingExpense)}. 24시간 장바구니 대기 규칙을 시도해보세요!',
        type: 'tip', category: '쇼핑', createdAt: now,
      ));
    }

    if (insights.isEmpty) {
      insights.add(AiInsight(
        title: '✨ AI 분석 완료',
        message: '더 많은 거래 내역을 추가하면 맞춤 인사이트를 제공해드릴게요!',
        type: 'tip', category: '전체', createdAt: now,
      ));
    }

    return insights;
  }

  static String _fmt(double amount) {
    if (amount >= 10000) return '${(amount / 10000).toStringAsFixed(1)}만원';
    return '${amount.toInt()}원';
  }
}
