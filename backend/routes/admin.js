// routes/admin.js - 관리자 전용 API (설정값 수정)
const express = require('express');
const router  = express.Router();

module.exports = (db) => {

  // ──────────────────────────────────────────────
  // GET /api/admin/config  - 전체 설정 조회
  // ──────────────────────────────────────────────
  router.get('/config', (req, res) => {
    try {
      const rows = db.prepare('SELECT * FROM app_config ORDER BY key').all();
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // PATCH /api/admin/config/:key  - 설정값 수정
  // body: { value }
  // ──────────────────────────────────────────────
  router.patch('/config/:key', (req, res) => {
    const { value } = req.body;
    try {
      const val = typeof value === 'object' ? JSON.stringify(value) : String(value);
      db.prepare(`
        UPDATE app_config SET value=?, updated_at=datetime('now','localtime') WHERE key=?
      `).run(val, req.params.key);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/admin/plans  - 구독 플랜 관리
  // ──────────────────────────────────────────────
  router.get('/plans', (req, res) => {
    try {
      const plans = db.prepare('SELECT * FROM subscription_plans ORDER BY sort_order').all();
      res.json({ success: true, data: plans });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PATCH /api/admin/plans/:id  - 플랜 가격/이름 수정
  router.patch('/plans/:id', (req, res) => {
    const { name, price, badge, sub_text, is_active } = req.body;
    try {
      const updates = [];
      const params = [];
      if (name      != null) { updates.push('name=?');      params.push(name); }
      if (price     != null) { updates.push('price=?');     params.push(price); }
      if (badge     != null) { updates.push('badge=?');     params.push(badge); }
      if (sub_text  != null) { updates.push('sub_text=?');  params.push(sub_text); }
      if (is_active != null) { updates.push('is_active=?'); params.push(is_active ? 1 : 0); }
      if (updates.length === 0) return res.status(400).json({ success: false, error: 'No fields to update' });
      params.push(req.params.id);
      db.prepare(`UPDATE subscription_plans SET ${updates.join(',')} WHERE id=?`).run(...params);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/admin/banks  - 은행 마스터 관리
  // ──────────────────────────────────────────────
  router.get('/banks', (req, res) => {
    try {
      const banks = db.prepare('SELECT * FROM banks_master ORDER BY sort_order').all();
      res.json({ success: true, data: banks });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  router.patch('/banks/:id', (req, res) => {
    const { name, icon, color_hex, is_active, sort_order } = req.body;
    try {
      const updates = [];
      const params = [];
      if (name        != null) { updates.push('name=?');       params.push(name); }
      if (icon        != null) { updates.push('icon=?');       params.push(icon); }
      if (color_hex   != null) { updates.push('color_hex=?');  params.push(color_hex); }
      if (is_active   != null) { updates.push('is_active=?');  params.push(is_active ? 1 : 0); }
      if (sort_order  != null) { updates.push('sort_order=?'); params.push(sort_order); }
      if (updates.length === 0) return res.status(400).json({ success: false, error: 'No fields' });
      params.push(req.params.id);
      db.prepare(`UPDATE banks_master SET ${updates.join(',')} WHERE id=?`).run(...params);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/admin/users  - 전체 사용자 목록
  // ──────────────────────────────────────────────
  router.get('/users', (req, res) => {
    const { limit = 100, offset = 0 } = req.query;
    try {
      const users = db.prepare(
        'SELECT * FROM users ORDER BY created_at DESC LIMIT ? OFFSET ?'
      ).all(Number(limit), Number(offset));
      const total = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
      res.json({ success: true, data: users, total });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/admin/keywords  - AI 키워드 관리
  // ──────────────────────────────────────────────
  router.get('/keywords', (req, res) => {
    const { category } = req.query;
    try {
      let sql = 'SELECT * FROM ai_keywords';
      const params = [];
      if (category) { sql += ' WHERE category=?'; params.push(category); }
      sql += ' ORDER BY category, keyword';
      res.json({ success: true, data: db.prepare(sql).all(...params) });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  router.post('/keywords', (req, res) => {
    const { keyword, category } = req.body;
    if (!keyword || !category) return res.status(400).json({ success: false, error: 'Missing fields' });
    try {
      db.prepare('INSERT OR IGNORE INTO ai_keywords (keyword, category) VALUES (?,?)').run(keyword, category);
      res.status(201).json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  router.delete('/keywords/:id', (req, res) => {
    try {
      db.prepare('DELETE FROM ai_keywords WHERE id=?').run(req.params.id);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
