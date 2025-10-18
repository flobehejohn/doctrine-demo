@'
import http from "k6/http";
import { sleep } from "k6";

export const options = { vus: 30, duration: "45s" };

export default function () {
  http.get("http://localhost:8080/search?query=test");
  sleep(0.1);
}
'@ | Out-File -FilePath scripts\k6.js -Encoding ASCII -NoNewline
