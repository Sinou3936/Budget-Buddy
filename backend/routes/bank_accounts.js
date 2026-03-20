// routes/bank_accounts.js
const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const { db } = require('../firebase');

module.exports = () => {

  // GET /api/bank-accounts?userId=
  router.get('/', async (req, res) => {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });
    try {
      const snap = await db.collection('users').doc(userId).collection('bank_accounts')
        .where('is_linked', '==', true)
        .orderBy('linked_at', 'desc')
        .get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/bank-accounts
  router.post('/', async (req, res) => {
    const { userId, bankName, accountNumber, balance = 0, accountType = 'checking' } = req.body;
    if (!userId || !bankName)
      return res.status(400).json({ success: false, error: 'userId, bankName required' });
    try {
      const now = new Date().toISOString();
      const snap = await db.collection('users').doc(userId).collection('bank_accounts')
        .where('bank_name', '==', bankName).limit(1).get();

      if (!snap.empty) {
        const doc = snap.docs[0];
        await doc.ref.update({ is_linked: true, linked_at: now, updated_at: now });
        return res.json({ success: true, data: { id: doc.id, ...doc.data(), is_linked: true } });
      }

      const id = uuidv4();
      const data = {
        bank_name: bankName, account_number: accountNumber || null,
        balance, account_type: accountType,
        is_linked: true, linked_at: now, updated_at: now,
      };
      await db.collection('users').doc(userId).collection('bank_accounts').doc(id).set(data);
      res.status(201).json({ success: true, data: { id, ...data } });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // DELETE /api/bank-accounts/:id
  router.delete('/:id', async (req, res) => {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });
    try {
      const ref = db.collection('users').doc(userId).collection('bank_accounts').doc(req.params.id);
      const doc = await ref.get();
      if (!doc.exists) return res.status(404).json({ success: false, error: 'Not found' });
      await ref.update({ is_linked: false, updated_at: new Date().toISOString() });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
