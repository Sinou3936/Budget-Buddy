// server.js - Budget Buddy API Server
require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const path    = require('path');
require('./firebase'); // Firebase 초기화

const app  = express();
const PORT = process.env.PORT || 3000;

// ──────────────────────────────────────────────
// 미들웨어
// ──────────────────────────────────────────────
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',');
app.use(cors({
  origin: (origin, callback) => {
    // 모바일 앱은 origin 헤더가 없으므로 허용, 브라우저는 목록으로 제한
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`CORS 차단: ${origin}`));
    }
  },
}));
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
const appRoutes            = require('./routes/app')();
const usersRoutes          = require('./routes/users')();
const transactionsRoutes   = require('./routes/transactions')();
const budgetsRoutes        = require('./routes/budgets')();
const analyticsRoutes      = require('./routes/analytics')();
const adminRoutes          = require('./routes/admin')();
const bankAccountsRoutes   = require('./routes/bank_accounts')();
const aiRoutes             = require('./routes/ai')();

app.use('/api/app',           appRoutes);
app.use('/api/users',         usersRoutes);
app.use('/api/transactions',  transactionsRoutes);
app.use('/api/budgets',       budgetsRoutes);
app.use('/api/analytics',     analyticsRoutes);
app.use('/api/admin',         adminRoutes);
app.use('/api/bank-accounts', bankAccountsRoutes);
app.use('/api/ai',            aiRoutes);

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
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Budget Buddy API Server running on port ${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}/dashboard`);
  console.log(`🔌 API Base:  http://localhost:${PORT}/api\n`);
});

module.exports = app;
