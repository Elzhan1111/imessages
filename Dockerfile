# --- Stage 2: build the API bundle ---
    FROM node:22-bookworm-slim AS backend-build
    WORKDIR /app
    COPY backend/package.json backend/package-lock.json ./
    RUN npm install --no-audit --no-fund
    COPY backend/ ./
    # Здесь ничего не компилируем, просто проверяем шаги
    
    # --- Stage 3: runtime image (only prod deps + built assets) ---
    FROM node:22-bookworm-slim AS runner
    WORKDIR /app
    ENV NODE_ENV=production
    ENV PORT=10000
    
    COPY backend/package.json backend/package-lock.json ./
    RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force
    
    # ИСПРАВЛЕНО: Копируем напрямую папку src из бэкенда
    COPY --from=backend-build /app/backend/src ./src
    COPY --from=frontend-build /app/frontend/dist ./public
    
    EXPOSE 10000
    USER node
    
    # ИСПРАВЛЕНО: Запускаем файл напрямую из папки src!
    CMD ["node", "src/index.js"]
    