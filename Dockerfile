# Image de base légère
FROM node:20-alpine

# Exécuter en prod
ENV NODE_ENV=production

# Dossier de travail
WORKDIR /app

# Dépendances (utilise le lockfile s'il est présent)
COPY app/package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund

# Copie du code
COPY app/ ./

# Crée un user/groupe non-root avec UID/GID = 10001 et donne les droits
RUN addgroup -g 10001 app \
    && adduser -D -u 10001 -G app app \
    && chown -R 10001:10001 /app

# Basculer définitivement en non-root
USER 10001

# Port exposé par l'app
EXPOSE 8080

# Commande de démarrage
CMD ["node", "index.js"]
