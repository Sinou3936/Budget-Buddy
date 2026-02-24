// server.js - Budget Buddy API Server
require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const path    = require('path');
const { db, initDB } = require('./database');

const app  = express();
const PORT = process.env.PORT || 3000;

// ──────────────────────────────────────────────
// 미들웨어
// ──────────────────────────────────────────────
app.use(cors({ origin: '*' }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'dashboard')));

// 요청 로깅
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const ms = Date.now() - start;
    if (req.path !== '/api/health') {
      console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.path} ${res.statusCode} (${ms}ms)`);
    }
  });
  next();
});

// ──────────────────────────────────────────────
// 라우터 등록
// ──────────────────────────────────────────────
const appRoutes          = require('./routes/app')(db);
const usersRoutes        = require('./routes/users')(db);
const transactionsRoutes = require('./routes/transactions')(db);
const budgetsRoutes      = require('./routes/budgets')(db);
const analyticsRoutes    = require('./routes/analytics')(db);
const adminRoutes        = require('./routes/admin')(db);

app.use('/api/app',          appRoutes);
app.use('/api/users',        usersRoutes);
app.use('/api/transactions', transactionsRoutes);
app.use('/api/budgets',      budgetsRoutes);
app.use('/api/analytics',    analyticsRoutes);
app.use('/api/admin',        adminRoutes);

// ──────────────────────────────────────────────
// 헬스체크
// ──────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

// 대시보드 SPA 폴백
app.get(['/dashboard', '/dashboard/'], (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard', 'index.html'));
});

// ──────────────────────────────────────────────
// 서버 시작
// ──────────────────────────────────────────────
initDB();
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Budget Buddy API Server running on port ${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}/dashboard`);
  console.log(`🔌 API Base:  http://localhost:${PORT}/api\n`);
});

module.exports = app;
