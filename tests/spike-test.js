import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // Warm-up
    { duration: '1m',  target: 200 },  // Spike กระตุ้น HPA (2 -> 8+ pods)
    { duration: '30s', target: 0 },    // Cool-down ดู Scale-in
  ],
  thresholds: {
    http_req_duration: ['p(95)<300'],  // SLA < 300ms
    http_req_failed: ['rate<0.01'],    // Error rate < 1%
  },
};

const TARGET_URL = __ENV.TARGET_URL || 'http://localhost:30080/healthz';

export default function () {
  const res = http.get(TARGET_URL);
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(0.05);
}
