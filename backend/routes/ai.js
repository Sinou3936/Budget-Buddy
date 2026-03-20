// routes/ai.js - Gemini AI 프록시 라우터
const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');

module.exports = function () {
  const router = express.Router();

  const CATEGORIES = ['식비', '교통', '쇼핑', '문화/여가', '의료', '통신', '주거', '교육', '기타'];

  function getModels() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new Error('GEMINI_API_KEY가 설정되지 않았습니다.');
    const genAI = new GoogleGenerativeAI(apiKey);
    return {
      flash: genAI.getGenerativeModel({
        model: 'gemini-2.0-flash',
        systemInstruction:
          '당신은 Budget Buddy AI 재무 상담사입니다. ' +
          '사용자의 소비 데이터를 분석하고 실용적인 조언을 제공합니다. ' +
          '항상 한국어로 친근하고 간결하게 답변하세요.',
      }),
      pro: genAI.getGenerativeModel({ model: 'gemini-2.0-flash' }),
    };
  }

  // ── POST /api/ai/classify ──────────────────────────────────────────
  router.post('/classify', async (req, res) => {
    try {
      const { title } = req.body;
      if (!title) return res.status(400).json({ error: 'title 필드가 필요합니다.' });

      const { flash } = getModels();
      const prompt =
        `거래 제목: "${title}"\n\n` +
        '위 거래를 아래 카테고리 중 하나로만 분류해. 카테고리 이름만 출력해:\n' +
        '식비, 교통, 쇼핑, 문화/여가, 의료, 통신, 주거, 교육, 기타';

      const result = await flash.generateContent(prompt);
      const category = result.response.text().trim();
      res.json({ category: CATEGORIES.includes(category) ? category : '기타' });
    } catch (e) {
      console.error('[AI] classify 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  });

  // ── POST /api/ai/chat ──────────────────────────────────────────────
  // body: { message, context: { income, expense, catSummary, budgetSummary, recentTxs } }
  router.post('/chat', async (req, res) => {
    try {
      const { message, context } = req.body;
      if (!message) return res.status(400).json({ error: 'message 필드가 필요합니다.' });

      const { flash } = getModels();
      const ctx = context
        ? `월 수입: ${context.income}원 / 월 지출: ${context.expense}원\n` +
          `카테고리별 지출: ${context.catSummary}\n` +
          `예산 현황: ${context.budgetSummary}\n` +
          `최근 거래: ${context.recentTxs}`
        : '';

      const fullMsg =
        (ctx ? `[현재 재무 데이터]\n${ctx}\n\n` : '') +
        `[질문] ${message}\n\n위 데이터 기반으로 150자 이내로 답변해줘.`;

      const result = await flash.generateContent(fullMsg);
      res.json({ reply: result.response.text().trim() });
    } catch (e) {
      console.error('[AI] chat 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  });

  // ── POST /api/ai/report ────────────────────────────────────────────
  // body: { year, month, context, totalIncome, totalExpense }
  router.post('/report', async (req, res) => {
    try {
      const { year, month, context, totalIncome, totalExpense } = req.body;
      const { pro } = getModels();

      const prompt =
        '당신은 개인 재무 분석 전문가입니다.\n' +
        `${year}년 ${month}월 소비 데이터를 분석해서 한국어로 월말 리포트를 작성해주세요.\n\n` +
        `월 수입: ${totalIncome}원 / 월 지출: ${totalExpense}원\n` +
        `${context}\n\n` +
        '다음 형식으로 친근하고 실용적으로 작성해주세요:\n' +
        '## 이번 달 총평\n(2-3줄)\n\n' +
        '## 카테고리별 분석\n(각 카테고리 1-2줄)\n\n' +
        '## 절약 포인트 TOP 3\n(구체적인 금액 포함)\n\n' +
        '## 다음 달 목표\n(1-2줄)';

      const result = await pro.generateContent(prompt);
      res.json({ report: result.response.text().trim() });
    } catch (e) {
      console.error('[AI] report 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  });

  // ── POST /api/ai/suggest-budgets ───────────────────────────────────
  // body: { monthlyIncome, catExpenses: {카테고리: 금액}, currentBudgets: {카테고리: 금액} }
  router.post('/suggest-budgets', async (req, res) => {
    try {
      const { monthlyIncome, catExpenses, currentBudgets } = req.body;
      const { pro } = getModels();

      const summary = Object.entries(catExpenses || {})
        .map(([k, v]) => `${k}: ${v}원`)
        .join(', ');
      const current = Object.entries(currentBudgets || {})
        .map(([k, v]) => `${k}: ${v}원`)
        .join(', ');

      const prompt =
        `월 소득: ${monthlyIncome}원\n` +
        `최근 지출: ${summary}\n` +
        `현재 예산: ${current}\n\n` +
        '위 데이터를 기반으로 적정 월별 예산을 추천해줘.\n' +
        '반드시 아래 JSON 형식으로만 응답해 (다른 텍스트 없이):\n' +
        '{"식비": 숫자, "교통": 숫자, "쇼핑": 숫자, "문화/여가": 숫자, ' +
        '"의료": 숫자, "통신": 숫자, "주거": 숫자, "교육": 숫자}\n' +
        '숫자는 원 단위 정수.';

      const result = await pro.generateContent(prompt);
      const text = result.response.text().trim()
        .replace(/```json/g, '').replace(/```/g, '').trim();
      const budgets = JSON.parse(text);
      res.json({ budgets });
    } catch (e) {
      console.error('[AI] suggest-budgets 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  });

  // ── POST /api/ai/anomaly ───────────────────────────────────────────
  // body: { title, amount, category, categoryAverage }
  router.post('/anomaly', async (req, res) => {
    try {
      const { title, amount, category, categoryAverage } = req.body;
      const { flash } = getModels();

      const prompt =
        `거래: "${title}" ${amount}원 (${category})\n` +
        `이 카테고리 평균: ${categoryAverage}원\n\n` +
        '평균보다 많이 지출된 이유를 한 문장으로 분석하고, 절약 팁 한 가지를 추가해줘. 총 60자 이내.';

      const result = await flash.generateContent(prompt);
      res.json({ explanation: result.response.text().trim() });
    } catch (e) {
      console.error('[AI] anomaly 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  });

  // ── POST /api/ai/ocr ───────────────────────────────────────────────
  // body: { imageBase64: string (base64 jpeg) }
  router.post('/ocr', async (req, res) => {
    try {
      const { imageBase64 } = req.body;
      if (!imageBase64) return res.status(400).json({ error: 'imageBase64 필드가 필요합니다.' });

      const { flash } = getModels();
      const prompt =
        '이 영수증 이미지에서 정보를 추출해. JSON만 응답해 (다른 텍스트 없이):\n' +
        '{"merchant": "가게명", "amount": 숫자, "category": "카테고리"}\n' +
        '카테고리는 식비/교통/쇼핑/문화여가/의료/통신/주거/교육/기타 중 하나. amount는 정수.';

      const result = await flash.generateContent([
        prompt,
        { inlineData: { mimeType: 'image/jpeg', data: imageBase64 } },
      ]);
      const text = result.response.text().trim()
        .replace(/```json/g, '').replace(/```/g, '').trim();
      const ocr = JSON.parse(text);
      res.json(ocr);
    } catch (e) {
      console.error('[AI] ocr 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  });

  return router;
};
