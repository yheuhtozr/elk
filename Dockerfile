FROM docker.io/library/node:lts-alpine AS base

# Prepare work directory
WORKDIR /elk

FROM base AS builder

# Prepare pnpm ( refer to https://pnpm.io/installation#on-alpine-linux )
RUN wget -qO /bin/pnpm "https://github.com/pnpm/pnpm/releases/latest/download/pnpm-linuxstatic-x64" && chmod +x /bin/pnpm

# Prepare deps
RUN apk update
RUN apk add git --no-cache

# Prepare build deps ( ignore postinstall scripts for now )
COPY package.json ./
COPY pnpm-lock.yaml ./
COPY patches ./patches
RUN pnpm i --frozen-lockfile --ignore-scripts

# Copy all source files
COPY . ./

# Run full install with every postinstall script ( This needs project file )
RUN pnpm i --frozen-lockfile

# Build
RUN pnpm build

FROM base AS runner

ENV NODE_ENV=production

COPY --from=builder /elk/.output ./.output

EXPOSE 5314/tcp

ENV PORT=5314

# Specify container only environment variables ( can be overwritten by runtime env )
ENV NUXT_STORAGE_FS_BASE='/elk/data'

# Persistent storage data
VOLUME [ "/elk/data" ]

CMD ["node", ".output/server/index.mjs"]