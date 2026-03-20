// routes/users.js
const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const { db } = require('../firebase');

module.exports = () => {

  // POST /api/users/register
  router.post('/register', async (req, res) => {
    const { device_id, nickname = '사용자' } = req.body;
    if (!device_id) return res.status(400).json({ success: false, error: 'device_id required' });

    try {
      const usersRef = db.collection('users');
      const snap = await usersRef.where('device_id', '==', device_id).limit(1).get();

      if (!snap.empty) {
        const doc = snap.docs[0];
        await doc.ref.update({ last_seen_at: new Date().toISOString() });
        return res.json({ success: true, data: { id: doc.id, ...doc.data() }, isNew: false });
      }

      // 신규 사용자
      const id = uuidv4();
      const now = new Date().toISOString();
      const userData = {
        device_id, nickname,
        is_premium: false,
        premium_expires_at: null,
        created_at: now,
        last_seen_at: now,
      };
      await usersRef.doc(id).set(userData);

      // 기본 예산 설정
      const cfgDoc = await db.collection('app_config').doc('default_budgets').get();
      if (cfgDoc.exists) {
        const budgets = JSON.parse(cfgDoc.data().value);
        const batch = db.batch();
        budgets.forEach(b => {
          const docId = b.category.replace(/\//g, '_');
          batch.set(usersRef.doc(id).collection('budgets').doc(docId), {
            category: b.category,
            monthly_limit: b.limit,
            updated_at: now,
          });
        });
        await batch.commit();
      }

      // 샘플 거래 데이터
      const sampleDoc = await db.collection('app_config').doc('sample_transactions').get();
      if (sampleDoc.exists) {
        const samples = JSON.parse(sampleDoc.data().value);
        const batch = db.batch();
        const nowDate = new Date();
        samples.forEach(s => {
          const d = new Date(nowDate);
          d.setDate(d.getDate() - (s.daysAgo || 0));
          batch.set(usersRef.doc(id).collection('transactions').doc(uuidv4()), {
            title: s.title, amount: s.amount, category: s.category,
            type: s.type, date: d.toISOString().split('T')[0],
            bank_name: s.bankName || null, memo: null,
            is_ai_classified: true,
            created_at: now,
          });
        });
        await batch.commit();
      }

      res.json({ success: true, data: { id, ...userData }, isNew: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/users/:userId
  router.get('/:userId', async (req, res) => {
    try {
      const doc = await db.collection('users').doc(req.params.userId).get();
      if (!doc.exists) return res.status(404).json({ success: false, error: 'User not found' });
      res.json({ success: true, data: { id: doc.id, ...doc.data() } });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PATCH /api/users/:userId/premium
  router.patch('/:userId/premium', async (req, res) => {
    const { is_premium, expires_at } = req.body;
    try {
      await db.collection('users').doc(req.params.userId).update({
        is_premium: !!is_premium,
        premium_expires_at: expires_at || null,
      });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
