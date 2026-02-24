// routes/users.js - 사용자 등록 / 조회 / 샘플 데이터 초기화
const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');

module.exports = (db) => {

  // ──────────────────────────────────────────────
  // POST /api/users/register  - 기기 등록 또는 기존 사용자 반환
  // body: { device_id, nickname? }
  // ──────────────────────────────────────────────
  router.post('/register', (req, res) => {
    const { device_id, nickname = '사용자' } = req.body;
    if (!device_id) return res.status(400).json({ success: false, error: 'device_id required' });

    try {
      let user = db.prepare('SELECT * FROM users WHERE device_id=?').get(device_id);

      if (!user) {
        // 신규 사용자
        const id = uuidv4();
        db.prepare(`
          INSERT INTO users (id, device_id, nickname) VALUES (?,?,?)
        `).run(id, device_id, nickname);

        // 기본 예산 설정
        const defaultBudgetsCfg = db.prepare("SELECT value FROM app_config WHERE key='default_budgets'").get();
        if (defaultBudgetsCfg) {
          const budgets = JSON.parse(defaultBudgetsCfg.value);
          const insertBudget = db.prepare(
            'INSERT OR IGNORE INTO budgets (user_id, category, monthly_limit) VALUES (?,?,?)'
          );
          budgets.forEach(b => insertBudget.run(id, b.category, b.limit));
        }

        // 샘플 거래 데이터 삽입
        const sampleCfg = db.prepare("SELECT value FROM app_config WHERE key='sample_transactions'").get();
        if (sampleCfg) {
          const samples = JSON.parse(sampleCfg.value);
          const now = new Date();
          const insertTx = db.prepare(`
            INSERT INTO transactions
              (id, user_id, title, amount, category, type, date, bank_name, is_ai_classified)
            VALUES (?,?,?,?,?,?,?,?,1)
          `);
          samples.forEach(s => {
            const d = new Date(now);
            d.setDate(d.getDate() - (s.daysAgo || 0));
            insertTx.run(
              uuidv4(), id, s.title, s.amount, s.category, s.type,
              d.toISOString(), s.bankName || null
            );
          });
        }

        user = db.prepare('SELECT * FROM users WHERE id=?').get(id);
        return res.json({ success: true, data: user, isNew: true });
      }

      // 기존 사용자 - last_seen 업데이트
      db.prepare("UPDATE users SET last_seen_at=datetime('now','localtime') WHERE id=?").run(user.id);
      res.json({ success: true, data: user, isNew: false });

    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // GET /api/users/:userId  - 사용자 정보 조회
  // ──────────────────────────────────────────────
  router.get('/:userId', (req, res) => {
    try {
      const user = db.prepare('SELECT * FROM users WHERE id=?').get(req.params.userId);
      if (!user) return res.status(404).json({ success: false, error: 'User not found' });
      res.json({ success: true, data: user });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ──────────────────────────────────────────────
  // PATCH /api/users/:userId/premium  - 프리미엄 설정
  // body: { is_premium, expires_at? }
  // ──────────────────────────────────────────────
  router.patch('/:userId/premium', (req, res) => {
    const { is_premium, expires_at } = req.body;
    try {
      db.prepare(`
        UPDATE users SET is_premium=?, premium_expires_at=? WHERE id=?
      `).run(is_premium ? 1 : 0, expires_at || null, req.params.userId);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
