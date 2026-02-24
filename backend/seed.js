// API 서버를 먼저 구동하여 테스트 데이터 생성
const { db, initDB } = require('./database');
initDB();

const { v4: uuidv4 } = require('uuid');

// 테스트 사용자 생성
const deviceId = 'test-device-001';
let user = db.prepare('SELECT * FROM users WHERE device_id=?').get(deviceId);
if (!user) {
  const id = uuidv4();
  db.prepare('INSERT INTO users (id, device_id, nickname) VALUES (?,?,?)').run(id, deviceId, '테스트유저');
  user = db.prepare('SELECT * FROM users WHERE id=?').get(id);
  console.log('✅ Test user created:', user.id);
} else {
  console.log('✅ Test user exists:', user.id);
}

// 샘플 이벤트 기록
const events = ['app_open','page_view','transaction_added','bank_linked','ad_shown'];
events.forEach(name => {
  db.prepare('INSERT INTO app_events (user_id, event_name, platform, app_version) VALUES (?,?,?,?)')
    .run(user.id, name, 'android', '1.0.0');
});
console.log('✅ Sample events created');
console.log('✅ Seed completed');
process.exit(0);
