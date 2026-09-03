import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp-up 20 VUs
    { duration: '1m',  target: 60 },  // Spike 60 VUs เพื่อดัน CPU ให้เกิน 50%
    { duration: '30s', target: 0 },   // Scale down
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],    // ยอมรับ error rate ไม่เกิน 5%
    http_req_duration: ['p(95)<1000'], // 95% ของ request ตอบกลับภายใน 1s
  },
};

export default function () {
  const url = 'http://localhost:8000/cpu-burn?duration=0.03';
  const res = http.get(url);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(0.05);
}
