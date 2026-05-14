FROM node:20-alpine

WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

COPY server.js ./

RUN addgroup -g 10001 app && adduser -D -u 10001 -G app app
USER 10001

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/healthz || exit 1

CMD ["node", "server.js"]
