// routes/analytics.js
const express = require('express');
const router  = express.Router();
const { db } = require('../firebase');

module.exports = () => {

  // POST /api/analytics/event
  router.post('/event', async (req, res) => {
    const { userId, eventName, eventData, platform = 'unknown', appVersion = '1.0.0' } = req.body;
    if (!eventName) return res.status(400).json({ success: false, error: 'eventName required' });
    try {
      await db.collection('app_events').add({
        user_id: userId || null, event_name: eventName,
        event_data: eventData ? JSON.stringify(eventData) : null,
        platform, app_version: appVersion,
        created_at: new Date().toISOString(),
      });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/analytics/ad
  router.post('/ad', async (req, res) => {
    const { userId, adType, adUnit, revenue = 0 } = req.body;
    try {
      await db.collection('ad_events').add({
        user_id: userId || null, ad_type: adType,
        ad_unit: adUnit || null, revenue,
        created_at: new Date().toISOString(),
      });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/analytics/dashboard
  router.get('/dashboard', async (req, res) => {
    try {
      const now = new Date();
      const todayStr = now.toISOString().split('T')[0];
      const sevenDaysAgo = new Date(now);
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
      const sevenDaysStr = sevenDaysAgo.toISOString();

      const [usersSnap, txSnap, adSnap, eventsSnap] = await Promise.all([
        db.collection('users').get(),
        db.collection('users').count().get(),  // placeholder
        db.collection('ad_events').get(),
        db.collection('app_events')
          .where('created_at', '>=', sevenDaysStr)
          .get(),
      ]);

      const users = usersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
      const totalUsers   = users.length;
      const premiumUsers = users.filter(u => u.is_premium).length;
      const todayUsers   = users.filter(u => u.last_seen_at?.startsWith(todayStr)).length;
      const newToday     = users.filter(u => u.created_at?.startsWith(todayStr)).length;
      const newWeek      = users.filter(u => u.created_at >= sevenDaysStr).length;

      const adEvents = adSnap.docs.map(d => d.data());
      const adToday  = adEvents.filter(a => a.created_at?.startsWith(todayStr));
      const adTodayRevenue = adToday.reduce((s, a) => s + (a.revenue || 0), 0);
      const adTotalRevenue = adEvents.reduce((s, a) => s + (a.revenue || 0), 0);

      // 최근 7일 이벤트 트렌드
      const events = eventsSnap.docs.map(d => d.data());
      const eventTrendMap = {};
      events.forEach(e => {
        const day = e.created_at?.split('T')[0];
        const key = `${day}_${e.event_name}`;
        if (!eventTrendMap[key]) eventTrendMap[key] = { day, event_name: e.event_name, count: 0 };
        eventTrendMap[key].count++;
      });

      res.json({
        success: true,
        data: {
          users: { total: totalUsers, premium: premiumUsers, dau: todayUsers, newToday, newWeek },
          ads: {
            today: { count: adToday.length, revenue: adTodayRevenue },
            total: { count: adEvents.length, revenue: adTotalRevenue },
          },
          trends: { events: Object.values(eventTrendMap) },
        }
      });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/analytics/events
  router.get('/events', async (req, res) => {
    const { limit = 50, eventName } = req.query;
    try {
      let query = db.collection('app_events').orderBy('created_at', 'desc').limit(Number(limit));
      if (eventName) query = db.collection('app_events')
        .where('event_name', '==', eventName)
        .orderBy('created_at', 'desc')
        .limit(Number(limit));
      const snap = await query.get();
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
};
