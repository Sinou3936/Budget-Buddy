// routes/admin.js
const express = require('express');
const router  = express.Router();
const { db } = require('../firebase');

module.exports = () => {

  // GET /api/admin/config
  router.get('/config', async (req, res) => {
    try {
      const snap = await db.collection('app_config').orderBy('__name__').get();
      const data = snap.docs.map(d => ({ key: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PATCH /api/admin/config/:key
  router.patch('/config/:key', async (req, res) => {
    const { value } = req.body;
    try {
      const val = typeof value === 'object' ? JSON.stringify(value) : String(value);
      await db.collection('app_config').doc(req.params.key).update({
        value: val,
        updated_at: new Date().toISOString(),
      });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/admin/plans
  router.get('/plans', async (req, res) => {
    try {
      const snap = await db.collection('subscription_plans').orderBy('sort_order').get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PATCH /api/admin/plans/:id
  router.patch('/plans/:id', async (req, res) => {
    const { name, price, badge, sub_text, is_active } = req.body;
    try {
      const updates = {};
      if (name      != null) updates.name      = name;
      if (price     != null) updates.price     = price;
      if (badge     != null) updates.badge     = badge;
      if (sub_text  != null) updates.sub_text  = sub_text;
      if (is_active != null) updates.is_active = !!is_active;
      if (Object.keys(updates).length === 0)
        return res.status(400).json({ success: false, error: 'No fields to update' });
      await db.collection('subscription_plans').doc(req.params.id).update(updates);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/admin/banks
  router.get('/banks', async (req, res) => {
    try {
      const snap = await db.collection('banks_master').orderBy('sort_order').get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PATCH /api/admin/banks/:id
  router.patch('/banks/:id', async (req, res) => {
    const { name, icon, color_hex, is_active, sort_order } = req.body;
    try {
      const updates = {};
      if (name       != null) updates.name       = name;
      if (icon       != null) updates.icon       = icon;
      if (color_hex  != null) updates.color_hex  = color_hex;
      if (is_active  != null) updates.is_active  = !!is_active;
      if (sort_order != null) updates.sort_order = sort_order;
      if (Object.keys(updates).length === 0)
        return res.status(400).json({ success: false, error: 'No fields' });
      await db.collection('banks_master').doc(req.params.id).update(updates);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/admin/users
  router.get('/users', async (req, res) => {
    const { limit = 100 } = req.query;
    try {
      const snap = await db.collection('users')
        .orderBy('created_at', 'desc')
        .limit(Number(limit))
        .get();
      const data  = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      const total = (await db.collection('users').count().get()).data().count;
      res.json({ success: true, data, total });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/admin/keywords
  router.get('/keywords', async (req, res) => {
    const { category } = req.query;
    try {
      let query = db.collection('ai_keywords').orderBy('category');
      if (category) query = db.collection('ai_keywords').where('category', '==', category);
      const snap = await query.get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/keywords
  router.post('/keywords', async (req, res) => {
    const { keyword, category } = req.body;
    if (!keyword || !category)
      return res.status(400).json({ success: false, error: 'Missing fields' });
    try {
      await db.collection('ai_keywords').add({ keyword, category, is_active: true });
      res.status(201).json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // DELETE /api/admin/keywords/:id
  router.delete('/keywords/:id', async (req, res) => {
    try {
      await db.collection('ai_keywords').doc(req.params.id).delete();
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
