// routes/transactions.js
const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const { db } = require('../firebase');

module.exports = () => {

  // GET /api/transactions?userId=&year=&month=&category=&type=
  router.get('/', async (req, res) => {
    const { userId, year, month, category, type } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });

    try {
      let query = db.collection('users').doc(userId).collection('transactions');

      if (year && month) {
        const pad = String(month).padStart(2, '0');
        const ym = `${year}-${pad}`;
        query = query
          .where('date', '>=', `${ym}-01`)
          .where('date', '<=', `${ym}-31`);
      }
      if (category) query = query.where('category', '==', category);
      if (type)     query = query.where('type', '==', type);

      const snap = await query.orderBy('date', 'desc').get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/transactions/summary?userId=&year=&month=
  router.get('/summary', async (req, res) => {
    const { userId, year, month } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });

    try {
      const now = new Date();
      const y  = year  || now.getFullYear();
      const m  = month || String(now.getMonth() + 1).padStart(2, '0');
      const ym = `${y}-${String(m).padStart(2, '0')}`;

      const snap = await db.collection('users').doc(userId).collection('transactions')
        .where('date', '>=', `${ym}-01`)
        .where('date', '<=', `${ym}-31`)
        .get();

      const txs = snap.docs.map(d => d.data());

      let totalIncome = 0, totalExpense = 0, txCount = 0;
      const byCategory = {};

      txs.forEach(t => {
        txCount++;
        if (t.type === 'income')  totalIncome  += t.amount;
        if (t.type === 'expense') {
          totalExpense += t.amount;
          byCategory[t.category] = (byCategory[t.category] || 0) + t.amount;
        }
      });

      // 최근 7일 일별 지출
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
      const daily7Snap = await db.collection('users').doc(userId).collection('transactions')
        .where('type', '==', 'expense')
        .where('date', '>=', sevenDaysAgo.toISOString().split('T')[0])
        .get();

      const daily7Map = {};
      daily7Snap.docs.forEach(d => {
        const t = d.data();
        daily7Map[t.date] = (daily7Map[t.date] || 0) + t.amount;
      });
      const daily7 = Object.entries(daily7Map)
        .map(([day, total]) => ({ day, total }))
        .sort((a, b) => a.day.localeCompare(b.day));

      res.json({
        success: true,
        data: {
          year: Number(y), month: Number(m),
          totalIncome, totalExpense,
          balance: totalIncome - totalExpense,
          transactionCount: txCount,
          byCategory: Object.entries(byCategory)
            .map(([category, total]) => ({ category, total }))
            .sort((a, b) => b.total - a.total),
          daily7,
        }
      });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/transactions
  router.post('/', async (req, res) => {
    const { userId, title, amount, category, type, date, memo, bankName, isAiClassified } = req.body;
    if (!userId || !title || !amount || !category || !type || !date) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }
    try {
      const id  = uuidv4();
      const now = new Date().toISOString();
      const data = {
        title, amount, category, type, date,
        memo: memo || null,
        bank_name: bankName || null,
        is_ai_classified: !!isAiClassified,
        created_at: now,
      };
      await db.collection('users').doc(userId).collection('transactions').doc(id).set(data);
      res.status(201).json({ success: true, data: { id, ...data } });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/transactions/:id
  router.put('/:id', async (req, res) => {
    const { userId, title, amount, category, type, date, memo, bankName } = req.body;
    if (!userId || !title || !amount || !category || !type || !date) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }
    try {
      const ref = db.collection('users').doc(userId).collection('transactions').doc(req.params.id);
      const doc = await ref.get();
      if (!doc.exists) return res.status(404).json({ success: false, error: 'Not found' });

      const updated = { title, amount, category, type, date, memo: memo || null, bank_name: bankName || null };
      await ref.update(updated);
      res.json({ success: true, data: { id: req.params.id, ...doc.data(), ...updated } });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // DELETE /api/transactions/:id
  router.delete('/:id', async (req, res) => {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });
    try {
      const ref = db.collection('users').doc(userId).collection('transactions').doc(req.params.id);
      const doc = await ref.get();
      if (!doc.exists) return res.status(404).json({ success: false, error: 'Not found' });
      await ref.delete();
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
