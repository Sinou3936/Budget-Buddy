// routes/budgets.js - 예산 CRUD
const express = require('express');
const router  = express.Router();

module.exports = (db) => {

  // GET /api/budgets?userId=
  router.get('/', (req, res) => {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });

    try {
      // 예산 + 이번달 실제 지출 JOIN
      const now = new Date();
      const ym = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}`;

      const budgets = db.prepare(`
        SELECT b.category, b.monthly_limit,
               COALESCE(t.spent, 0) as spent
        FROM budgets b
        LEFT JOIN (
          SELECT category, SUM(amount) as spent
          FROM transactions
          WHERE user_id=? AND type='expense' AND strftime('%Y-%m', date)=?
          GROUP BY category
        ) t ON b.category = t.category
        WHERE b.user_id=?
        ORDER BY b.category
      `).all(userId, ym, userId);

      res.json({ success: true, data: budgets });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/budgets  - 예산 설정 (upsert)
  // body: { userId, category, monthlyLimit }
  router.put('/', (req, res) => {
    const { userId, category, monthlyLimit } = req.body;
    if (!userId || !category || monthlyLimit == null) {
      return res.status(400).json({ success: false, error: 'Missing fields' });
    }
    try {
      db.prepare(`
        INSERT INTO budgets (user_id, category, monthly_limit)
        VALUES (?,?,?)
        ON CONFLICT(user_id, category) DO UPDATE SET monthly_limit=excluded.monthly_limit,
          updated_at=datetime('now','localtime')
      `).run(userId, category, monthlyLimit);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
