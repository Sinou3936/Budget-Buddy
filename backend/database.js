// database.js - SQLite DB 초기화 및 스키마
const Database = require('better-sqlite3');
const path = require('path');

const DB_PATH = path.join(__dirname, 'budget_buddy.db');
const db = new Database(DB_PATH);

// WAL 모드로 성능 향상
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

function initDB() {
  // ────────────────────────────────────────────────────────
  // 1. 사용자 테이블
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      device_id TEXT UNIQUE NOT NULL,
      nickname TEXT DEFAULT '사용자',
      is_premium INTEGER DEFAULT 0,
      premium_expires_at TEXT,
      created_at TEXT DEFAULT (datetime('now','localtime')),
      last_seen_at TEXT DEFAULT (datetime('now','localtime'))
    )
  `);

  // ────────────────────────────────────────────────────────
  // 2. 거래 내역 테이블
  db.exec(`
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('income','expense')),
      date TEXT NOT NULL,
      memo TEXT,
      bank_name TEXT,
      is_ai_classified INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now','localtime')),
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // ────────────────────────────────────────────────────────
  // 3. 예산 설정 테이블
  db.exec(`
    CREATE TABLE IF NOT EXISTS budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      category TEXT NOT NULL,
      monthly_limit REAL NOT NULL DEFAULT 0,
      updated_at TEXT DEFAULT (datetime('now','localtime')),
      UNIQUE(user_id, category),
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // ────────────────────────────────────────────────────────
  // 4. 은행 연동 계좌 테이블
  db.exec(`
    CREATE TABLE IF NOT EXISTS bank_accounts (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      bank_name TEXT NOT NULL,
      account_number TEXT,
      balance REAL DEFAULT 0,
      account_type TEXT DEFAULT 'checking',
      is_linked INTEGER DEFAULT 0,
      linked_at TEXT,
      updated_at TEXT DEFAULT (datetime('now','localtime')),
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // ────────────────────────────────────────────────────────
  // 5. 은행 마스터 테이블 (관리자가 관리)
  db.exec(`
    CREATE TABLE IF NOT EXISTS banks_master (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      icon TEXT NOT NULL,
      color_hex TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      sort_order INTEGER DEFAULT 0
    )
  `);

  // ────────────────────────────────────────────────────────
  // 6. 구독 플랜 테이블 (관리자가 가격 관리)
  db.exec(`
    CREATE TABLE IF NOT EXISTS subscription_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      plan_type TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      price INTEGER NOT NULL,
      period TEXT NOT NULL,
      period_days INTEGER NOT NULL,
      badge TEXT DEFAULT '',
      sub_text TEXT DEFAULT '',
      is_active INTEGER DEFAULT 1,
      sort_order INTEGER DEFAULT 0
    )
  `);

  // ────────────────────────────────────────────────────────
  // 7. AI 분류 키워드 테이블 (관리자가 관리)
  db.exec(`
    CREATE TABLE IF NOT EXISTS ai_keywords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyword TEXT NOT NULL,
      category TEXT NOT NULL,
      is_active INTEGER DEFAULT 1
    )
  `);

  // ────────────────────────────────────────────────────────
  // 8. 앱 설정/메타 테이블 (관리자가 관리)
  db.exec(`
    CREATE TABLE IF NOT EXISTS app_config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      description TEXT,
      updated_at TEXT DEFAULT (datetime('now','localtime'))
    )
  `);

  // ────────────────────────────────────────────────────────
  // 9. 앱 이벤트 추적 테이블 (analytics)
  db.exec(`
    CREATE TABLE IF NOT EXISTS app_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      event_name TEXT NOT NULL,
      event_data TEXT,
      platform TEXT DEFAULT 'unknown',
      app_version TEXT DEFAULT '1.0.0',
      created_at TEXT DEFAULT (datetime('now','localtime'))
    )
  `);

  // ────────────────────────────────────────────────────────
  // 10. 광고 수익 추적 테이블
  db.exec(`
    CREATE TABLE IF NOT EXISTS ad_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      ad_type TEXT NOT NULL,
      ad_unit TEXT,
      revenue REAL DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now','localtime'))
    )
  `);

  // ────────────────────────────────────────────────────────
  // 11. 구독 결제 내역 테이블
  db.exec(`
    CREATE TABLE IF NOT EXISTS subscriptions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      plan_type TEXT NOT NULL,
      amount INTEGER NOT NULL,
      status TEXT DEFAULT 'active',
      started_at TEXT DEFAULT (datetime('now','localtime')),
      expires_at TEXT,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `);

  // ────────────────────────────────────────────────────────
  // 기본 데이터 시드 (마스터 데이터)
  _seedMasterData();

  console.log('✅ Database initialized successfully');
  return db;
}

function _seedMasterData() {
  // 은행 마스터 데이터
  const banks = [
    { name: '카카오뱅크', icon: '🟡', color_hex: '#FEE500', sort_order: 1 },
    { name: '신한은행',   icon: '🔵', color_hex: '#0046FF', sort_order: 2 },
    { name: '국민은행',   icon: '🟤', color_hex: '#FFB300', sort_order: 3 },
    { name: '우리은행',   icon: '🔵', color_hex: '#003087', sort_order: 4 },
    { name: '하나은행',   icon: '🟢', color_hex: '#00A650', sort_order: 5 },
    { name: 'IBK기업은행',icon: '🔴', color_hex: '#C41E3A', sort_order: 6 },
    { name: '토스뱅크',  icon: '⚪', color_hex: '#0064FF', sort_order: 7 },
    { name: '케이뱅크',  icon: '🔵', color_hex: '#00C8FF', sort_order: 8 },
  ];
  const insertBank = db.prepare(`
    INSERT OR IGNORE INTO banks_master (name, icon, color_hex, sort_order)
    VALUES (@name, @icon, @color_hex, @sort_order)
  `);
  banks.forEach(b => insertBank.run(b));

  // 구독 플랜 데이터
  const plans = [
    { plan_type: 'monthly', name: '월간 구독', price: 4900,  period: '/ 월', period_days: 30,  badge: '',       sub_text: '연 58,800원', sort_order: 1 },
    { plan_type: 'yearly',  name: '연간 구독', price: 39900, period: '/ 년', period_days: 365, badge: '32% 할인', sub_text: '월 3,325원', sort_order: 2 },
  ];
  const insertPlan = db.prepare(`
    INSERT OR IGNORE INTO subscription_plans
      (plan_type, name, price, period, period_days, badge, sub_text, sort_order)
    VALUES (@plan_type, @name, @price, @period, @period_days, @badge, @sub_text, @sort_order)
  `);
  plans.forEach(p => insertPlan.run(p));

  // AI 분류 키워드
  const keywords = [
    // 식비
    ...['스타벅스','카페','맥도날드','버거킹','롯데리아','파리바게뜨','뚜레쥬르',
        '편의점','cu','gs25','세븐일레븐','미니스톱','식당','음식점','배달',
        '배민','요기요','쿠팡이츠','이마트','홈플러스','롯데마트','마트',
        '치킨','피자','짜장','짬뽕','초밥','삼겹살','족발','보쌈',
        '투썸','이디야','할리스','엔제리너스','던킨','빵','베이커리']
      .map(k => ({ keyword: k, category: '식비' })),
    // 교통
    ...['교통카드','지하철','버스','택시','카카오택시','우버',
        '주유','주차','고속도로','톨게이트','ktx','기차','항공','공항']
      .map(k => ({ keyword: k, category: '교통' })),
    // 쇼핑
    ...['쿠팡','올리브영','다이소','유니클로','자라','무신사',
        '에이블리','지그재그','29cm','위메프','티몬','g마켓','11번가',
        '아이파크','이케아','코스트코','백화점','쇼핑몰']
      .map(k => ({ keyword: k, category: '쇼핑' })),
    // 문화/여가
    ...['넷플릭스','유튜브','왓챠','웨이브','영화','cgv',
        '메가박스','롯데시네마','게임','스팀','노래방','볼링','헬스장','피트니스']
      .map(k => ({ keyword: k, category: '문화/여가' })),
    // 의료
    ...['병원','약국','의원','한의원','치과','안과','피부과','내과','처방']
      .map(k => ({ keyword: k, category: '의료' })),
    // 통신
    ...['통신비','인터넷','핸드폰요금','모바일요금']
      .map(k => ({ keyword: k, category: '통신' })),
    // 주거
    ...['월세','관리비','전기요금','가스요금','수도요금','렌트']
      .map(k => ({ keyword: k, category: '주거' })),
    // 교육
    ...['학원','교재','강의','수강','과외','교육비']
      .map(k => ({ keyword: k, category: '교육' })),
  ];
  const insertKw = db.prepare(`
    INSERT OR IGNORE INTO ai_keywords (keyword, category) VALUES (@keyword, @category)
  `);
  keywords.forEach(k => insertKw.run(k));

  // 앱 설정 기본값
  const configs = [
    { key: 'app_name',             value: 'Budget Buddy',       description: '앱 이름' },
    { key: 'app_version',          value: '1.0.0',              description: '현재 앱 버전' },
    { key: 'min_app_version',      value: '1.0.0',              description: '최소 지원 버전' },
    { key: 'force_update',         value: 'false',              description: '강제 업데이트 여부' },
    { key: 'maintenance_mode',     value: 'false',              description: '점검 모드' },
    { key: 'maintenance_message',  value: '서버 점검 중입니다. 잠시 후 다시 시도해주세요.', description: '점검 안내 메시지' },
    { key: 'default_currency',     value: 'KRW',                description: '기본 통화' },
    { key: 'free_trial_days',      value: '7',                  description: '무료 체험 일수' },
    { key: 'ad_banner_enabled',    value: 'true',               description: '배너 광고 활성화' },
    { key: 'ad_interstitial_freq', value: '5',                  description: '전면광고 노출 빈도(거래 N회마다)' },
    { key: 'default_budgets',      value: JSON.stringify([
        { category: '식비',    limit: 400000 },
        { category: '교통',    limit: 100000 },
        { category: '쇼핑',    limit: 200000 },
        { category: '문화/여가', limit: 100000 },
        { category: '통신',    limit: 60000  },
      ]),                                                        description: '신규 사용자 기본 예산' },
    { key: 'sample_transactions',  value: JSON.stringify([
        { title: '스타벅스 아메리카노', amount: 5500,    category: '식비',    type: 'expense', daysAgo: 0,  bankName: '카카오뱅크' },
        { title: '편의점 CU',          amount: 3200,    category: '식비',    type: 'expense', daysAgo: 0,  bankName: '카카오뱅크' },
        { title: '지하철 교통카드',     amount: 1400,    category: '교통',    type: 'expense', daysAgo: 1 },
        { title: '올리브영',           amount: 35000,   category: '쇼핑',    type: 'expense', daysAgo: 1 },
        { title: '배달의민족',         amount: 18500,   category: '식비',    type: 'expense', daysAgo: 2,  bankName: '신한은행' },
        { title: '넷플릭스',           amount: 17000,   category: '문화/여가', type: 'expense', daysAgo: 3 },
        { title: 'GS25 편의점',        amount: 4800,    category: '식비',    type: 'expense', daysAgo: 3 },
        { title: '버스 교통카드',       amount: 1200,    category: '교통',    type: 'expense', daysAgo: 4 },
        { title: '쿠팡 주문',          amount: 42000,   category: '쇼핑',    type: 'expense', daysAgo: 5,  bankName: '국민은행' },
        { title: '카페 투썸플레이스',   amount: 6800,    category: '식비',    type: 'expense', daysAgo: 5 },
        { title: '월급',               amount: 2800000, category: '저축',    type: 'income',  daysAgo: 10, bankName: '신한은행' },
        { title: '부업 수입',          amount: 150000,  category: '기타',    type: 'income',  daysAgo: 7 },
        { title: '이마트 장보기',       amount: 67000,   category: '식비',    type: 'expense', daysAgo: 6,  bankName: '국민은행' },
        { title: 'KT 통신비',          amount: 55000,   category: '통신',    type: 'expense', daysAgo: 8 },
        { title: '영화 CGV',           amount: 14000,   category: '문화/여가', type: 'expense', daysAgo: 9 },
      ]),                                                        description: '신규 사용자 샘플 거래 데이터' },
    { key: 'ai_insight_thresholds', value: JSON.stringify({
        food_warning:     300000,
        shopping_warning: 200000,
        cafe_count:       5,
        expense_ratio_warning: 0.8,
        savings_praise_ratio:  0.4,
      }),                                                        description: 'AI 인사이트 임계값 설정' },
  ];
  const insertConfig = db.prepare(`
    INSERT OR IGNORE INTO app_config (key, value, description) VALUES (@key, @value, @description)
  `);
  configs.forEach(c => insertConfig.run(c));
}

module.exports = { db, initDB };
