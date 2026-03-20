// firebase_seed.js - Firestore 마스터 데이터 초기화 (최초 1회 실행)
require('dotenv').config();
const { db } = require('./firebase');

async function seed() {
  console.log('🌱 Firestore 시드 데이터 초기화 시작...');
  const batch = db.batch();

  // ── 은행 마스터 ────────────────────────────────────────────
  const banks = [
    { name: '카카오뱅크', icon: '🟡', color_hex: '#FEE500', is_active: true, sort_order: 1 },
    { name: '신한은행',   icon: '🔵', color_hex: '#0046FF', is_active: true, sort_order: 2 },
    { name: '국민은행',   icon: '🟤', color_hex: '#FFB300', is_active: true, sort_order: 3 },
    { name: '우리은행',   icon: '🔵', color_hex: '#003087', is_active: true, sort_order: 4 },
    { name: '하나은행',   icon: '🟢', color_hex: '#00A650', is_active: true, sort_order: 5 },
    { name: 'IBK기업은행',icon: '🔴', color_hex: '#C41E3A', is_active: true, sort_order: 6 },
    { name: '토스뱅크',  icon: '⚪', color_hex: '#0064FF', is_active: true, sort_order: 7 },
    { name: '케이뱅크',  icon: '🔵', color_hex: '#00C8FF', is_active: true, sort_order: 8 },
  ];
  banks.forEach(b => {
    batch.set(db.collection('banks_master').doc(b.name), b);
  });

  // ── 구독 플랜 ──────────────────────────────────────────────
  const plans = [
    { plan_type: 'monthly', name: '월간 구독', price: 4900,  period: '/ 월', period_days: 30,  badge: '',        sub_text: '연 58,800원', is_active: true, sort_order: 1 },
    { plan_type: 'yearly',  name: '연간 구독', price: 39900, period: '/ 년', period_days: 365, badge: '32% 할인', sub_text: '월 3,325원',  is_active: true, sort_order: 2 },
  ];
  plans.forEach(p => {
    batch.set(db.collection('subscription_plans').doc(p.plan_type), p);
  });

  // ── 앱 설정 ────────────────────────────────────────────────
  const configs = {
    app_name:            { value: 'Budget Buddy',       description: '앱 이름' },
    app_version:         { value: '1.0.0',              description: '현재 앱 버전' },
    min_app_version:     { value: '1.0.0',              description: '최소 지원 버전' },
    force_update:        { value: 'false',              description: '강제 업데이트 여부' },
    maintenance_mode:    { value: 'false',              description: '점검 모드' },
    maintenance_message: { value: '서버 점검 중입니다. 잠시 후 다시 시도해주세요.', description: '점검 안내' },
    default_currency:    { value: 'KRW',                description: '기본 통화' },
    free_trial_days:     { value: '7',                  description: '무료 체험 일수' },
    ad_banner_enabled:   { value: 'true',               description: '배너 광고 활성화' },
    ad_interstitial_freq:{ value: '5',                  description: '전면광고 빈도(N회 거래마다)' },
    default_budgets: { value: JSON.stringify([
      { category: '식비',     limit: 400000 },
      { category: '교통',     limit: 100000 },
      { category: '쇼핑',     limit: 200000 },
      { category: '문화/여가', limit: 100000 },
      { category: '통신',     limit: 60000  },
    ]), description: '신규 사용자 기본 예산' },
    sample_transactions: { value: JSON.stringify([
      { title: '스타벅스 아메리카노', amount: 5500,    category: '식비',     type: 'expense', daysAgo: 0,  bankName: '카카오뱅크' },
      { title: '편의점 CU',          amount: 3200,    category: '식비',     type: 'expense', daysAgo: 0 },
      { title: '지하철 교통카드',     amount: 1400,    category: '교통',     type: 'expense', daysAgo: 1 },
      { title: '올리브영',           amount: 35000,   category: '쇼핑',     type: 'expense', daysAgo: 1 },
      { title: '배달의민족',         amount: 18500,   category: '식비',     type: 'expense', daysAgo: 2,  bankName: '신한은행' },
      { title: '넷플릭스',           amount: 17000,   category: '문화/여가', type: 'expense', daysAgo: 3 },
      { title: '쿠팡 주문',          amount: 42000,   category: '쇼핑',     type: 'expense', daysAgo: 5,  bankName: '국민은행' },
      { title: '월급',               amount: 2800000, category: '저축',     type: 'income',  daysAgo: 10, bankName: '신한은행' },
      { title: 'KT 통신비',          amount: 55000,   category: '통신',     type: 'expense', daysAgo: 8 },
      { title: '영화 CGV',           amount: 14000,   category: '문화/여가', type: 'expense', daysAgo: 9 },
    ]), description: '신규 사용자 샘플 데이터' },
  };
  Object.entries(configs).forEach(([key, val]) => {
    batch.set(db.collection('app_config').doc(key), {
      ...val,
      updated_at: new Date().toISOString(),
    });
  });

  await batch.commit();
  console.log('✅ 기본 데이터 완료');

  // ── AI 키워드 (배치 500개 제한으로 분리) ────────────────────
  const keywords = [
    ...['스타벅스','카페','맥도날드','버거킹','롯데리아','파리바게뜨','뚜레쥬르','편의점','cu','gs25','세븐일레븐','식당','음식점','배달','배민','요기요','쿠팡이츠','이마트','홈플러스','롯데마트','마트','치킨','피자','투썸','이디야','할리스','던킨','빵','베이커리'].map(k=>({keyword:k,category:'식비'})),
    ...['교통카드','지하철','버스','택시','카카오택시','주유','주차','고속도로','톨게이트','ktx','기차','항공'].map(k=>({keyword:k,category:'교통'})),
    ...['쿠팡','올리브영','다이소','유니클로','자라','무신사','에이블리','위메프','티몬','g마켓','11번가','백화점','쇼핑몰'].map(k=>({keyword:k,category:'쇼핑'})),
    ...['넷플릭스','유튜브','왓챠','웨이브','영화','cgv','메가박스','롯데시네마','게임','스팀','노래방','볼링','헬스장'].map(k=>({keyword:k,category:'문화/여가'})),
    ...['병원','약국','의원','한의원','치과','안과','피부과','내과','처방'].map(k=>({keyword:k,category:'의료'})),
    ...['통신비','인터넷','핸드폰요금','모바일요금'].map(k=>({keyword:k,category:'통신'})),
    ...['월세','관리비','전기요금','가스요금','수도요금'].map(k=>({keyword:k,category:'주거'})),
    ...['학원','교재','강의','수강','과외','교육비'].map(k=>({keyword:k,category:'교육'})),
  ];

  const kwBatch = db.batch();
  keywords.forEach(k => {
    kwBatch.set(db.collection('ai_keywords').doc(), { ...k, is_active: true });
  });
  await kwBatch.commit();
  console.log(`✅ AI 키워드 ${keywords.length}개 완료`);
  console.log('🎉 Firestore 시드 완료!');
  process.exit(0);
}

seed().catch(err => { console.error('❌ 시드 오류:', err); process.exit(1); });
