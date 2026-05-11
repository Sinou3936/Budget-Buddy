# Budget Buddy

AI 기반 스마트 가계부 앱 — Flutter + Node.js + Firebase Firestore

## 주요 기능

- **거래 내역 관리** — 지출/수입 추가, 수정, 삭제
- **예산 관리** — 카테고리별 월간 예산 설정 및 초과 알림
- **AI 소비 분석** — Gemini AI 기반 자동 카테고리 분류 및 인사이트
- **AI 소비 상담** — 재무 데이터 기반 AI 채팅 상담
- **AI 월말 리포트** — 이번 달 소비 종합 분석
- **AI 예산 추천** — 소비 패턴 기반 최적 예산 제안
- **영수증 OCR** — 사진으로 자동 지출 등록
- **알림** — 예산 초과 / 이상 지출 감지 / 월말 리포트 알림
- **광고** — AdMob 배너 / 전면 광고 (무료 플랜)

## 아키텍처

```
Flutter (Android)
    │
    │  HTTPS
    ▼
Vercel (Node.js/Express)
    ├── /api/transactions
    ├── /api/budgets
    ├── /api/users
    ├── /api/bank-accounts
    ├── /api/analytics
    └── /api/ai/*  ──────────► Gemini API
            │
            ▼
    Firebase Firestore
    users/{deviceId}/transactions
    users/{deviceId}/budgets
    users/{deviceId}/bank_accounts
```

**사용자 식별**: 로그인 없이 device_id(UUID) 기반으로 기기별 데이터 분리

## 기술 스택

| 분류 | 기술 |
|------|------|
| 앱 | Flutter (Android) |
| 상태관리 | Provider (MVVM 패턴) |
| 백엔드 | Node.js / Express |
| 배포 | Vercel |
| DB | Firebase Firestore |
| AI | Google Gemini API |
| 광고 | Google AdMob |

## 프로젝트 구조

```
lib/
├── main.dart
├── models/          # 데이터 모델
├── providers/       # ViewModel (MVVM)
│   ├── app_provider.dart        # 앱 초기화, 사용자, 설정
│   ├── transaction_provider.dart # 거래 CRUD
│   ├── budget_provider.dart     # 예산 + AI 인사이트
│   ├── bank_provider.dart       # 은행 계좌
│   └── ai_provider.dart        # AI 채팅/리포트/예산추천
├── screens/         # UI 화면
├── services/        # API 클라이언트, AI 서비스
├── widgets/         # 공통 위젯
├── theme/           # 앱 테마
└── utils/           # 환경 설정

backend/
├── server.js
├── firebase.js
├── routes/
│   ├── transactions.js
│   ├── budgets.js
│   ├── users.js
│   ├── bank_accounts.js
│   ├── analytics.js
│   ├── admin.js
│   ├── app.js
│   └── ai.js       # Gemini AI 프록시
└── vercel.json
```

## 로컬 실행

### 백엔드

```bash
cd backend
cp .env.example .env  # 환경변수 설정
node server.js        # http://localhost:4949
```

### Flutter

```bash
flutter pub get
flutter run
```

> 에뮬레이터 기본 API URL: `http://10.0.2.2:4949`  
> 운영 서버 URL: `https://budget-buddy-chi-green.vercel.app`  
> ([lib/utils/app_config.dart](lib/utils/app_config.dart)에서 설정)

## 환경변수 (backend/.env)

```env
GEMINI_API_KEY=your_gemini_api_key
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
ALLOWED_ORIGINS=http://localhost:3000
```

## 주요 설정값

| 항목 | 값 |
|------|-----|
| Vercel URL | https://budget-buddy-chi-green.vercel.app |
| Firebase 프로젝트 | budget-buddy-5279a |
| 패키지명 | kr.budget.app |
| 백엔드 포트 (로컬) | 4949 |
