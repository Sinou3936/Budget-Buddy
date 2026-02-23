import '../models/transaction.dart';

class AiService {
  // AI 기반 거래 자동 분류
  static String classifyTransaction(String title) {
    final lower = title.toLowerCase();

    // 식비
    final foodKeywords = [
      '스타벅스', '카페', '맥도날드', '버거킹', '롯데리아', '파리바게뜨', '뚜레쥬르',
      '편의점', 'cu', 'gs25', '세븐일레븐', '미니스톱', '식당', '음식점', '배달',
      '배민', '요기요', '쿠팡이츠', '이마트', '홈플러스', '롯데마트', '마트',
      '치킨', '피자', '짜장', '짬뽕', '초밥', '삼겹살', '족발', '보쌈',
      '투썸', '이디야', '할리스', '엔제리너스', '던킨', '빵', '베이커리',
    ];

    // 교통
    final transportKeywords = [
      '교통카드', '지하철', '버스', '택시', 'kt', '카카오택시', '우버',
      '주유', '주차', '고속도로', '톨게이트', 'ktx', '기차', '항공', '공항',
    ];

    // 쇼핑
    final shoppingKeywords = [
      '쿠팡', '올리브영', '다이소', '유니클로', 'h&m', '자라', '무신사',
      '에이블리', '지그재그', '29cm', '위메프', '티몬', 'g마켓', '11번가',
      '아이파크', '이케아', '코스트코', '백화점', '쇼핑',
    ];

    // 문화/여가
    final entertainmentKeywords = [
      '넷플릭스', '유튜브', '왓챠', '웨이브', '시즌', '영화', 'cgv',
      '메가박스', '롯데시네마', '게임', '스팀', '노래방', '볼링', '당구',
      '헬스장', '헬스', '피트니스', '수영장', 'pc방',
    ];

    // 의료
    final medicalKeywords = [
      '병원', '약국', '의원', '한의원', '치과', '안과', '피부과', '내과',
      '약', '처방', '의료',
    ];

    // 통신
    final telecomKeywords = [
      'kt', 'sk', 'lg', '통신', '인터넷', '모바일', '핸드폰', '요금',
    ];

    // 주거
    final housingKeywords = [
      '월세', '관리비', '전기', '가스', '수도', '인터넷', '렌트', '부동산',
    ];

    // 교육
    final educationKeywords = [
      '학원', '학교', '교재', '책', '교육', '강의', '수강', '과외',
    ];

    for (final kw in foodKeywords) {
      if (lower.contains(kw)) return '식비';
    }
    for (final kw in transportKeywords) {
      if (lower.contains(kw)) return '교통';
    }
    for (final kw in shoppingKeywords) {
      if (lower.contains(kw)) return '쇼핑';
    }
    for (final kw in entertainmentKeywords) {
      if (lower.contains(kw)) return '문화/여가';
    }
    for (final kw in medicalKeywords) {
      if (lower.contains(kw)) return '의료';
    }
    for (final kw in telecomKeywords) {
      if (lower.contains(kw)) return '통신';
    }
    for (final kw in housingKeywords) {
      if (lower.contains(kw)) return '주거';
    }
    for (final kw in educationKeywords) {
      if (lower.contains(kw)) return '교육';
    }

    return '기타';
  }

  // AI 소비 분석 및 인사이트 생성
  static List<AiInsight> generateInsights({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required double totalExpense,
    required double totalIncome,
  }) {
    final insights = <AiInsight>[];
    final now = DateTime.now();

    // 카테고리별 지출 집계
    final categoryExpenses = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      categoryExpenses[t.category] =
          (categoryExpenses[t.category] ?? 0) + t.amount;
    }

    // 1. 예산 초과 경고
    for (final budget in budgets) {
      if (budget.isOverBudget) {
        insights.add(AiInsight(
          title: '⚠️ 예산 초과 경고',
          message:
              '${budget.category} 예산이 ${_formatAmount(budget.spent - budget.limit)} 초과되었어요! '
              '이번 달 남은 기간 동안 지출을 줄여보세요.',
          type: 'warning',
          category: budget.category,
          createdAt: now,
        ));
      } else if (budget.percentage > 0.8) {
        insights.add(AiInsight(
          title: '🔔 예산 80% 도달',
          message:
              '${budget.category} 예산의 ${(budget.percentage * 100).toStringAsFixed(0)}%를 사용했어요. '
              '남은 예산은 ${_formatAmount(budget.remaining)}입니다.',
          type: 'warning',
          category: budget.category,
          createdAt: now,
        ));
      }
    }

    // 2. 지출 비율 분석
    if (totalIncome > 0) {
      final expenseRatio = totalExpense / totalIncome;
      if (expenseRatio > 0.8) {
        insights.add(AiInsight(
          title: '💸 지출 비율이 높아요',
          message:
              '이번 달 수입의 ${(expenseRatio * 100).toStringAsFixed(0)}%를 지출했어요. '
              '저축 습관을 만들어 보는 건 어떨까요? 수입의 20%는 저축하는 게 좋아요!',
          type: 'warning',
          category: '전체',
          createdAt: now,
        ));
      }
    }

    // 3. 식비 과다 지출
    final foodExpense = categoryExpenses['식비'] ?? 0;
    if (foodExpense > 300000) {
      insights.add(AiInsight(
        title: '🍽️ 식비 지출 패턴 분석',
        message:
            '이번 달 식비가 ${_formatAmount(foodExpense)}이에요. 배달 앱 대신 '
            '직접 요리하면 월 10~15만원을 절약할 수 있어요!',
        type: 'tip',
        category: '식비',
        createdAt: now,
      ));
    }

    // 4. 카페 지출 감지
    final cafeTransactions = transactions.where((t) =>
        t.type == 'expense' &&
        (t.title.contains('스타벅스') ||
            t.title.contains('카페') ||
            t.title.contains('투썸') ||
            t.title.contains('이디야')));
    if (cafeTransactions.length >= 5) {
      final cafeTotal =
          cafeTransactions.fold(0.0, (sum, t) => sum + t.amount);
      insights.add(AiInsight(
        title: '☕ 카페 지출 패턴 감지',
        message:
            '이번 달 카페를 ${cafeTransactions.length}번 방문해서 총 ${_formatAmount(cafeTotal)}을 썼어요. '
            '텀블러 챌린지로 최대 30% 절약해보세요!',
        type: 'tip',
        category: '식비',
        createdAt: now,
      ));
    }

    // 5. 저축 달성 칭찬
    if (totalIncome > 0 && totalExpense / totalIncome < 0.6) {
      insights.add(AiInsight(
        title: '🏆 훌륭한 절약 습관!',
        message:
            '이번 달 수입의 ${(100 - totalExpense / totalIncome * 100).toStringAsFixed(0)}%를 절약했어요! '
            '이 속도면 연간 ${_formatAmount((totalIncome - totalExpense) * 12)} 저축이 가능해요.',
        type: 'achievement',
        category: '전체',
        createdAt: now,
      ));
    }

    // 6. 쇼핑 분석
    final shoppingExpense = categoryExpenses['쇼핑'] ?? 0;
    if (shoppingExpense > 200000) {
      insights.add(AiInsight(
        title: '🛍️ 쇼핑 지출 알림',
        message:
            '이번 달 쇼핑에 ${_formatAmount(shoppingExpense)}을 지출했어요. '
            '충동구매를 줄이려면 24시간 장바구니 대기 규칙을 시도해보세요!',
        type: 'tip',
        category: '쇼핑',
        createdAt: now,
      ));
    }

    if (insights.isEmpty) {
      insights.add(AiInsight(
        title: '✨ AI 분석 완료',
        message: '지출 패턴을 분석 중이에요. 더 많은 거래 내역을 추가하면 맞춤 인사이트를 제공해드릴게요!',
        type: 'tip',
        category: '전체',
        createdAt: now,
      ));
    }

    return insights;
  }

  static String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만원';
    }
    return '${amount.toInt()}원';
  }
}
