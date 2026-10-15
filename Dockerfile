# Monolith: Vite frontend + Express API. Build from repo root.

# --- Stage 1: build the SPA (Vite) ---
    FROM node:22-bookworm-slim AS frontend-build
    WORKDIR /app/frontend
    COPY frontend/package.json frontend/package-lock.json ./
    RUN npm install --no-audit --no-fund --legacy-peer-deps
    COPY frontend/ ./
    ENV VITE_API_URL=
    ARG VITE_CLERK_PUBLISHABLE_KEY
    ENV VITE_CLERK_PUBLISHABLE_KEY=$VITE_CLERK_PUBLISHABLE_KEY
    RUN npm run build
    
    # --- Stage 2: build the API bundle ---
    FROM node:22-bookworm-slim AS backend-build
    # Исправлено: переносим рабочую директорию в /app/backend
    WORKDIR /app/backend
    COPY backend/package.json backend/package-lock.json ./
    RUN npm install --no-audit --no-fund
    COPY backend/ ./
    RUN npm run build
    
    # --- Stage 3: runtime image (only prod deps + built assets) ---
    FROM node:22-bookworm-slim AS runner
    # Финальное приложение будет запускаться из /app/backend
    WORKDIR /app/backend
    ENV NODE_ENV=production
    ENV PORT=10000
    
    # Исправлено: копируем файлы зависимостей в текущий WORKDIR (/app/backend)
    COPY backend/package.json backend/package-lock.json ./
    RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force
    
    # Исправлено: забираем собранный дистрибутив из правильного пути (/app/backend/dist)
    COPY --from=backend-build /app/backend/dist ./dist
    # Фронтенд копируем в папку public внутри бэкенда (чтобы Express мог его раздавать)
    COPY --from=frontend-build /app/frontend/dist ./public
    
    EXPOSE 10000
    USER node
    
    # Запуск теперь происходит локально из /app/backend
    CMD ["node", "dist/index.js"]
    