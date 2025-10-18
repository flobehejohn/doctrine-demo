FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
# Optionnel: tests unitaires si présents, sinon ignorer
# RUN npm test || echo "no tests"

FROM node:20-alpine
WORKDIR /app
COPY --from=build /app /app
RUN addgroup -g 10001 app && adduser -D -u 10001 -G app app
USER 10001
ENV NODE_ENV=production
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
CMD ["node", "index.js"]
