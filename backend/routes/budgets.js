// routes/budgets.js
const express = require('express');
const router  = express.Router();
const { db } = require('../firebase');

module.exports = () => {

  // GET /api/budgets?userId=
  router.get('/', async (req, res) => {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });

    try {
      const now = new Date();
      const ym  = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

      const [budgetSnap, txSnap] = await Promise.all([
        db.collection('users').doc(userId).collection('budgets').get(),
        db.collection('users').doc(userId).collection('transactions')
          .where('type', '==', 'expense')
          .where('date', '>=', `${ym}-01`)
          .where('date', '<=', `${ym}-31`)
          .get(),
      ]);

      // 카테고리별 지출 합산
      const spentMap = {};
      txSnap.docs.forEach(d => {
        const t = d.data();
        spentMap[t.category] = (spentMap[t.category] || 0) + t.amount;
      });

      const data = budgetSnap.docs.map(d => {
        const category = d.data().category || d.id.replace(/_/g, '/');
        return {
          category,
          monthly_limit: d.data().monthly_limit,
          spent: spentMap[category] || 0,
        };
      }).sort((a, b) => a.category.localeCompare(b.category));

      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/budgets
  router.put('/', async (req, res) => {
    const { userId, category, monthlyLimit } = req.body;
    if (!userId || !category || monthlyLimit == null) {
      return res.status(400).json({ success: false, error: 'Missing fields' });
    }
    try {
      const docId = category.replace(/\//g, '_');
      await db.collection('users').doc(userId).collection('budgets').doc(docId).set({
        category,
        monthly_limit: monthlyLimit,
        updated_at: new Date().toISOString(),
      }, { merge: true });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
