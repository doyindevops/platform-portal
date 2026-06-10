FROM node:20-bookworm-slim

RUN apt-get update && apt-get install -y \
    python3 \
    g++ \
    build-essential \
    libsqlite3-dev \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare yarn@4.4.1 --activate

WORKDIR /app

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY packages ./packages
COPY plugins ./plugins

RUN yarn install 2>&1 | grep -v "YN0007" || true

COPY . .

RUN yarn tsc 2>/dev/null; exit 0
RUN yarn build:backend 2>&1 || yarn workspace backend build 2>&1 || true

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 backstage --ingroup nodejs

RUN chown -R backstage:nodejs /app

USER backstage

EXPOSE 7007

ENV NODE_ENV=production

CMD ["node", "packages/backend/dist/index.cjs.js", "--config", "app-config.yaml"]
