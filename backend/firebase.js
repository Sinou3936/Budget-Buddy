// firebase.js - Firebase Admin SDK 초기화
const admin = require('firebase-admin');

if (!admin.apps.length) {
  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // 운영 환경: 환경변수에서 JSON 파싱
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    credential = admin.credential.cert(serviceAccount);
  } else {
    // 로컬 개발: 파일 직접 참조
    const serviceAccount = require('./budget-buddy-5279a-firebase-adminsdk-fbsvc-c57f548cc1.json');
    credential = admin.credential.cert(serviceAccount);
  }

  admin.initializeApp({ credential });
}

const db = admin.firestore();
module.exports = { db, admin };
