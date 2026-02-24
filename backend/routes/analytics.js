// routes/analytics.js - 앱 이벤트 추적 및 운영 통계
const express = require('express');
const router  = express.Router();

module.exports = (db) => {

  // ──────────────────────────────────────────────
  // POST /api/analytics/event  - 이벤트 기록
  // body: { userId, eventName, eventData?, platform?, appVersion? }
  // ──────────────────────────────────────────────
  router.post('/event', (req, res) => {
    const { userId, eventName, eventData, platform = 'unknown', appVersion = '1.0.0' } = req.body;
    if (!eventName) return res.status(400).json({ success: false, error: 'eventName required' });

    try {
      db.prepare(`
        INSERT INTO app_events (user_id, event_name, event_data, platform, app_version)
        VALUES (?,?,?,?,?)
      `).run(userId || null, eventName, eventData ? JSON.stringify(eventData) : null, platform, appVersion);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // POST /api/analytics/ad  - 광고 수익 기록
  // body: { userId, adType, adUnit, revenue? }
  // ──────────────────────────────────────────────
  router.post('/ad', (req, res) => {
    const { userId, adType, adUnit, revenue = 0 } = req.body;
    try {
      db.prepare(`
        INSERT INTO ad_events (user_id, ad_type, ad_unit, revenue)
        VALUES (?,?,?,?)
      `).run(userId || null, adType, adUnit || null, revenue);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/analytics/dashboard  - 운영 대시보드 통계
  // ──────────────────────────────────────────────
  router.get('/dashboard', (req, res) => {
    try {
      // 전체 사용자
      const totalUsers = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
      const premiumUsers = db.prepare('SELECT COUNT(*) as count FROM users WHERE is_premium=1').get().count;
      const todayUsers = db.prepare(
        "SELECT COUNT(*) as count FROM users WHERE date(last_seen_at)=date('now','localtime')"
      ).get().count;
      const newUsersToday = db.prepare(
        "SELECT COUNT(*) as count FROM users WHERE date(created_at)=date('now','localtime')"
      ).get().count;
      const newUsersWeek = db.prepare(
        "SELECT COUNT(*) as count FROM users WHERE created_at >= datetime('now','-7 days','localtime')"
      ).get().count;

      // 거래 통계
      const totalTx = db.prepare('SELECT COUNT(*) as count FROM transactions').get().count;
      const todayTx = db.prepare(
        "SELECT COUNT(*) as count FROM transactions WHERE date(created_at)=date('now','localtime')"
      ).get().count;

      // 광고 통계
      const adToday = db.prepare(
        "SELECT COUNT(*) as count, COALESCE(SUM(revenue),0) as revenue FROM ad_events WHERE date(created_at)=date('now','localtime')"
      ).get();
      const adTotal = db.prepare(
        "SELECT COUNT(*) as count, COALESCE(SUM(revenue),0) as revenue FROM ad_events"
      ).get();

      // 구독 통계
      const subscriptions = db.prepare(
        "SELECT plan_type, COUNT(*) as count, SUM(amount) as revenue FROM subscriptions GROUP BY plan_type"
      ).all();

      // 최근 7일 신규 가입자 추이
      const signupTrend = db.prepare(`
        SELECT date(created_at,'localtime') as day, COUNT(*) as count
        FROM users
        WHERE created_at >= datetime('now','-6 days','localtime')
        GROUP BY day ORDER BY day
      `).all();

      // 최근 7일 이벤트 추이
      const eventTrend = db.prepare(`
        SELECT date(created_at,'localtime') as day, event_name, COUNT(*) as count
        FROM app_events
        WHERE created_at >= datetime('now','-6 days','localtime')
        GROUP BY day, event_name ORDER BY day
      `).all();

      // 플랫폼 분포
      const platforms = db.prepare(`
        SELECT platform, COUNT(DISTINCT user_id) as count
        FROM app_events WHERE user_id IS NOT NULL
        GROUP BY platform
      `).all();

      // 카테고리별 총 지출 (전체 사용자)
      const topCategories = db.prepare(`
        SELECT category, SUM(amount) as total, COUNT(*) as count
        FROM transactions WHERE type='expense'
        GROUP BY category ORDER BY total DESC LIMIT 10
      `).all();

      // 이번 달 구독 수익
      const now = new Date();
      const ym = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}`;
      const monthlyRevenue = db.prepare(`
        SELECT COALESCE(SUM(amount),0) as total FROM subscriptions
        WHERE strftime('%Y-%m', started_at)=?
      `).get(ym)?.total || 0;

      res.json({
        success: true,
        data: {
          users: { total: totalUsers, premium: premiumUsers, dau: todayUsers, newToday: newUsersToday, newWeek: newUsersWeek },
          transactions: { total: totalTx, today: todayTx },
          ads: { today: adToday, total: adTotal },
          subscriptions: { plans: subscriptions, monthlyRevenue },
          trends: { signups: signupTrend, events: eventTrend },
          platforms,
          topCategories,
        }
      });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/analytics/events?limit=&eventName=
  // ──────────────────────────────────────────────
  router.get('/events', (req, res) => {
    const { limit = 50, eventName } = req.query;
    try {
      let sql = 'SELECT * FROM app_events';
      const params = [];
      if (eventName) { sql += ' WHERE event_name=?'; params.push(eventName); }
      sql += ' ORDER BY created_at DESC LIMIT ?';
      params.push(Number(limit));
      const events = db.prepare(sql).all(...params);
      res.json({ success: true, data: events });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
