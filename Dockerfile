FROM node:20-bookworm-slim AS base
RUN apt-get update && apt-get install -y \
    python3 \
    g++ \
    build-essential \
    libsqlite3-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare yarn@4.4.1 --activate

FROM base AS build
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY packages ./packages
COPY plugins ./plugins
RUN yarn install --immutable --inline-builds 2>&1 | grep -v "YN0007" || true
COPY . .
RUN yarn tsc --skipLibCheck 2>/dev/null || true
RUN yarn build:backend --skip-integrity-check

FROM base AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 backstage
COPY --from=build /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz
COPY --from=build /app/app-config.yaml ./
USER backstage
EXPOSE 7007
ENV NODE_ENV=production
CMD ["node", "packages/backend", "--config", "app-config.yaml"]
