import http from "k6/http";
import { check, sleep } from "k6";

const target = __ENV.TARGET_URL || "http://localhost/";
const users = Number(__ENV.RAMP_USERS || 40000);
const rampSeconds = Number(__ENV.RAMP_SECONDS || 1800);
const holdSeconds = Number(__ENV.HOLD_SECONDS || 1800);
const rampdownSeconds = Number(__ENV.RAMPDOWN_SECONDS || 900);
const refreshRate = Number(__ENV.REFRESH_RATE || 0.10);
const sessionSeconds = Number(__ENV.SESSION_SECONDS || 300);

export const options = {
  scenarios: {
    homepage_ramp_hold: {
      executor: "ramping-vus",
      stages: [
        { duration: `${rampSeconds}s`, target: users },
        { duration: `${holdSeconds}s`, target: users },
        { duration: `${rampdownSeconds}s`, target: 0 },
      ],
      gracefulRampDown: "30s",
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<300"],
  },
};

export default function () {
  const response = http.get(target);
  check(response, {
    "status is 200": (r) => r.status === 200,
  });

  if (Math.random() < refreshRate) {
    sleep(Math.max(1, sessionSeconds));
    const refreshResponse = http.get(target);
    check(refreshResponse, {
      "refresh status is 200": (r) => r.status === 200,
    });
    return;
  }

  sleep(Math.max(1, sessionSeconds));
}
