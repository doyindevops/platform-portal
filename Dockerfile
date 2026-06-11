FROM node:20-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 g++ build-essential libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare yarn@4.4.1 --activate

RUN mkdir -p /app && chown node:node /app
USER node
WORKDIR /app

COPY --chown=node:node yarn.lock package.json .yarnrc.yml ./
COPY --chown=node:node .yarn ./.yarn
COPY --chown=node:node packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

RUN yarn workspaces focus --all --production || (cat /tmp/xfs-*/build.log; exit 1)

COPY --chown=node:node packages/backend/dist/bundle.tar.gz app-config.yaml app-config.production.yaml ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

ENV NODE_ENV=production
EXPOSE 7007

CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
