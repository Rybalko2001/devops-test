# ===== Base =====
FROM node:20-alpine AS base
WORKDIR /app


# ===== Dependencies (prod) =====
FROM base AS deps
# Встановлюємо лише залежності згідно lock-файлу
COPY package*.json ./
RUN npm ci --only=production && \
npm cache clean --force


# ===== Builder (dev deps + build) =====
FROM base AS builder
COPY package*.json ./
RUN npm ci && npm cache clean --force
COPY tsconfig.json ./
COPY src ./src
# Якщо Nest використовується – встановіть глобально CLI за потреби або додайте скрипт build у package.json
# RUN npm i -g @nestjs/cli
RUN npm run build


# ===== Runner (final) =====
FROM node:20-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app


# Додаємо системного користувача без root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup


# Копіюємо лише prod-залежності та зібраний код
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./


# Best practices: не запускати як root
USER appuser


# Порт вашого NestJS (типово 3000)
EXPOSE 3000


# Healthcheck (опційно, продублюємо у K8s)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD node -e "fetch('http://localhost:3000/redis').then(r=>r.ok?process.exit(0):process.exit(1)).catch(()=>process.exit(1))" || exit 1


CMD ["npm", "run", "start:prod"]