# Monolith: Vite frontend + Express API. Build from repo root.

# --- Stage 1: Build Frontend (Vite) ---
    FROM node:22-bookworm-slim AS frontend-build
    WORKDIR /app/frontend
    COPY frontend/package*.json ./
    RUN npm install --no-audit --no-fund --legacy-peer-deps
    COPY frontend/ ./
    ENV VITE_API_URL=
    ARG VITE_CLERK_PUBLISHABLE_KEY
    ENV VITE_CLERK_PUBLISHABLE_KEY=$VITE_CLERK_PUBLISHABLE_KEY
    RUN npm run build
    
    # --- Stage 2: Build Backend ---
    FROM node:22-bookworm-slim AS backend-build
    WORKDIR /app/backend
    COPY backend/package*.json ./
    # Здесь устанавливаем ВСЕ зависимости (включая devDependencies для сборки: cpx, rimraf)
    RUN npm install --no-audit --no-fund
    COPY backend/ ./
    RUN npm run build
    
    # --- Stage 3: Runner (Production Image) ---
    FROM node:22-bookworm-slim AS runner
    WORKDIR /app/backend
    ENV NODE_ENV=production
    ENV PORT=10000
    
    # Устанавливаем только production-зависимости бэкенда (без devDependencies)
    COPY backend/package*.json ./
    RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force
    
    # Копируем скомпилированный бэкенд (папку dist)
    COPY --from=backend-build /app/backend/dist ./dist
    
    # Копируем собранный фронтенд в папку public бэкенда (как прописано в index.js)
    COPY --from=frontend-build /app/frontend/dist ./public
    
    EXPOSE 10000
    USER node
    
    # Запускаем собранный файл из папки dist
    CMD ["node", "dist/index.js"]
    