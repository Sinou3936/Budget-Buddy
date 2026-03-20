// routes/app.js
const express = require('express');
const router  = express.Router();
const { db } = require('../firebase');

module.exports = () => {

  // GET /api/app/config
  router.get('/config', async (req, res) => {
    try {
      const snap = await db.collection('app_config').get();
      const config = {};
      snap.docs.forEach(d => {
        try { config[d.id] = JSON.parse(d.data().value); }
        catch { config[d.id] = d.data().value; }
      });
      res.json({ success: true, data: config });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/app/banks
  router.get('/banks', async (req, res) => {
    try {
      const snap = await db.collection('banks_master')
        .where('is_active', '==', true)
        .orderBy('sort_order')
        .get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/app/plans
  router.get('/plans', async (req, res) => {
    try {
      const snap = await db.collection('subscription_plans')
        .where('is_active', '==', true)
        .orderBy('sort_order')
        .get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/app/ai-keywords
  router.get('/ai-keywords', async (req, res) => {
    try {
      const snap = await db.collection('ai_keywords')
        .where('is_active', '==', true)
        .get();
      const grouped = {};
      snap.docs.forEach(d => {
        const { keyword, category } = d.data();
        if (!grouped[category]) grouped[category] = [];
        grouped[category].push(keyword);
      });
      res.json({ success: true, data: grouped });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/app/categories
  router.get('/categories', async (req, res) => {
    try {
      const categories = [
        { name: '식비',     icon: 'restaurant',        color: '#FF6B6B' },
        { name: '교통',     icon: 'directions_transit', color: '#4ECDC4' },
        { name: '쇼핑',     icon: 'shopping_bag',       color: '#FFE66D' },
        { name: '문화/여가', icon: 'movie',              color: '#A78BFA' },
        { name: '의료',     icon: 'local_hospital',     color: '#F472B6' },
        { name: '통신',     icon: 'phone_android',      color: '#60A5FA' },
        { name: '주거',     icon: 'home',               color: '#34D399' },
        { name: '교육',     icon: 'school',             color: '#FBBF24' },
        { name: '저축',     icon: 'savings',            color: '#818CF8' },
        { name: '기타',     icon: 'more_horiz',         color: '#9CA3AF' },
      ];
      res.json({ success: true, data: categories });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
