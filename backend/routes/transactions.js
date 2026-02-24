// routes/transactions.js - 거래 내역 CRUD + 월별 통계
const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');

module.exports = (db) => {

  // ──────────────────────────────────────────────
  // GET /api/transactions?userId=&year=&month=&category=&type=
  // ──────────────────────────────────────────────
  router.get('/', (req, res) => {
    const { userId, year, month, category, type } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });

    try {
      let sql = 'SELECT * FROM transactions WHERE user_id=?';
      const params = [userId];

      if (year && month) {
        const pad = String(month).padStart(2, '0');
        sql += ` AND strftime('%Y-%m', date)=?`;
        params.push(`${year}-${pad}`);
      }
      if (category) { sql += ' AND category=?'; params.push(category); }
      if (type)     { sql += ' AND type=?';     params.push(type); }

      sql += ' ORDER BY date DESC, created_at DESC';
      const rows = db.prepare(sql).all(...params);
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // POST /api/transactions  - 거래 추가
  // body: { userId, title, amount, category, type, date, memo?, bankName? }
  // ──────────────────────────────────────────────
  router.post('/', (req, res) => {
    const { userId, title, amount, category, type, date, memo, bankName, isAiClassified } = req.body;
    if (!userId || !title || !amount || !category || !type || !date) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }
    try {
      const id = uuidv4();
      db.prepare(`
        INSERT INTO transactions
          (id, user_id, title, amount, category, type, date, memo, bank_name, is_ai_classified)
        VALUES (?,?,?,?,?,?,?,?,?,?)
      `).run(id, userId, title, amount, category, type, date, memo || null, bankName || null, isAiClassified ? 1 : 0);

      const tx = db.prepare('SELECT * FROM transactions WHERE id=?').get(id);
      res.status(201).json({ success: true, data: tx });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // DELETE /api/transactions/:id
  // ──────────────────────────────────────────────
  router.delete('/:id', (req, res) => {
    try {
      const info = db.prepare('DELETE FROM transactions WHERE id=?').run(req.params.id);
      if (info.changes === 0) return res.status(404).json({ success: false, error: 'Not found' });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/transactions/summary?userId=&year=&month=
  // 월별 수입/지출/카테고리별 집계
  // ──────────────────────────────────────────────
  router.get('/summary', (req, res) => {
    const { userId, year, month } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });

    try {
      const now = new Date();
      const y = year  || now.getFullYear();
      const m = month || String(now.getMonth() + 1).padStart(2, '0');
      const ym = `${y}-${String(m).padStart(2, '0')}`;

      const totals = db.prepare(`
        SELECT type, SUM(amount) as total, COUNT(*) as count
        FROM transactions
        WHERE user_id=? AND strftime('%Y-%m', date)=?
        GROUP BY type
      `).all(userId, ym);

      const byCategory = db.prepare(`
        SELECT category, SUM(amount) as total
        FROM transactions
        WHERE user_id=? AND strftime('%Y-%m', date)=? AND type='expense'
        GROUP BY category
        ORDER BY total DESC
      `).all(userId, ym);

      // 최근 7일 일별 지출
      const daily7 = db.prepare(`
        SELECT strftime('%Y-%m-%d', date) as day, SUM(amount) as total
        FROM transactions
        WHERE user_id=? AND type='expense'
          AND date >= datetime('now','-6 days','start of day')
        GROUP BY day
        ORDER BY day
      `).all(userId);

      const income  = totals.find(t => t.type === 'income')?.total  || 0;
      const expense = totals.find(t => t.type === 'expense')?.total || 0;
      const count   = totals.reduce((s, t) => s + t.count, 0);

      res.json({
        success: true,
        data: {
          year: Number(y), month: Number(m),
          totalIncome: income,
          totalExpense: expense,
          balance: income - expense,
          transactionCount: count,
          byCategory,
          daily7,
        }
      });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
