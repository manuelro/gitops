import http from "k6/http";
import { check, sleep } from "k6";

const target = __ENV.TARGET_URL || "http://localhost/";
const users = Number(__ENV.SPIKE_USERS || 40000);
const rampSeconds = Number(__ENV.SPIKE_RAMP_SECONDS || 120);
const holdSeconds = Number(__ENV.SPIKE_HOLD_SECONDS || 600);
const refreshRate = Number(__ENV.REFRESH_RATE || 0.10);
const sessionSeconds = Number(__ENV.SESSION_SECONDS || 300);

export const options = {
  scenarios: {
    homepage_spike: {
      executor: "ramping-vus",
      stages: [
        { duration: `${rampSeconds}s`, target: users },
        { duration: `${holdSeconds}s`, target: users },
      ],
      gracefulRampDown: "10s",
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

  // Keep session open with lightweight refresh behavior.
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
