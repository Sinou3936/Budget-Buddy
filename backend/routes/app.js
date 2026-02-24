// routes/app.js - 앱 설정, 은행, 플랜, AI 키워드 API
const express = require('express');
const router = express.Router();

module.exports = (db) => {

  // ──────────────────────────────────────────────
  // GET /api/app/config  - 앱 전체 설정 조회
  // ──────────────────────────────────────────────
  router.get('/config', (req, res) => {
    try {
      const rows = db.prepare('SELECT key, value FROM app_config').all();
      const config = {};
      rows.forEach(r => {
        try { config[r.key] = JSON.parse(r.value); }
        catch { config[r.key] = r.value; }
      });
      res.json({ success: true, data: config });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/app/banks  - 은행 마스터 목록
  // ──────────────────────────────────────────────
  router.get('/banks', (req, res) => {
    try {
      const banks = db.prepare(
        'SELECT * FROM banks_master WHERE is_active=1 ORDER BY sort_order'
      ).all();
      res.json({ success: true, data: banks });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/app/plans  - 구독 플랜 목록
  // ──────────────────────────────────────────────
  router.get('/plans', (req, res) => {
    try {
      const plans = db.prepare(
        'SELECT * FROM subscription_plans WHERE is_active=1 ORDER BY sort_order'
      ).all();
      res.json({ success: true, data: plans });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/app/ai-keywords  - AI 분류 키워드 목록
  // ──────────────────────────────────────────────
  router.get('/ai-keywords', (req, res) => {
    try {
      const keywords = db.prepare(
        'SELECT keyword, category FROM ai_keywords WHERE is_active=1'
      ).all();
      // { category: [keywords...] } 형태로 그룹핑
      const grouped = {};
      keywords.forEach(({ keyword, category }) => {
        if (!grouped[category]) grouped[category] = [];
        grouped[category].push(keyword);
      });
      res.json({ success: true, data: grouped });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/app/categories  - 지출 카테고리 목록
  // ──────────────────────────────────────────────
  router.get('/categories', (req, res) => {
    try {
      const cfg = db.prepare("SELECT value FROM app_config WHERE key='ai_insight_thresholds'").get();
      const categories = [
        { name: '식비',    icon: 'restaurant',      color: '#FF6B6B' },
        { name: '교통',    icon: 'directions_transit', color: '#4ECDC4' },
        { name: '쇼핑',    icon: 'shopping_bag',    color: '#FFE66D' },
        { name: '문화/여가', icon: 'movie',           color: '#A78BFA' },
        { name: '의료',    icon: 'local_hospital',  color: '#F472B6' },
        { name: '통신',    icon: 'phone_android',   color: '#60A5FA' },
        { name: '주거',    icon: 'home',            color: '#34D399' },
        { name: '교육',    icon: 'school',          color: '#FBBF24' },
        { name: '저축',    icon: 'savings',         color: '#818CF8' },
        { name: '기타',    icon: 'more_horiz',      color: '#9CA3AF' },
      ];
      res.json({ success: true, data: categories });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
