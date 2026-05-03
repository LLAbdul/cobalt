FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app
COPY --from=build --chown=node:node /app/package.json /app/package.json

# Create minimal .git so version-info module doesn't crash
RUN mkdir -p /app/.git/logs && \
    echo "ref: refs/heads/main" > /app/.git/HEAD && \
    echo "0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 deploy $(date +%s) +0000	init" > /app/.git/logs/HEAD && \
    printf "[remote \"origin\"]\n\turl = https://github.com/imputnet/cobalt.git\n" > /app/.git/config && \
    chown -R node:node /app/.git

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
