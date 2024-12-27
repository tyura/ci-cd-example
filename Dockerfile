# Package installation stage
FROM node:20-alpine AS dependencies
WORKDIR /app

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini

COPY package*.json ./
RUN npm ci --omit=dev

# Build stage
FROM node:20-bookworm-slim as builder

WORKDIR /app
COPY . /app/

RUN npm ci && npm run build

# Runtime stage
FROM gcr.io/distroless/nodejs22-debian12

ENV \
  LANG="C.UTF-8" \
  TZ="UTC" \
  NODE_ENV="production" \
  NODE_OPTIONS="--enable-source-maps"

WORKDIR /app

COPY --from=dependencies --chown=nonroot:nonroot /tini /tini
COPY --from=dependencies --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --from=builder --chown=nonroot:nonroot /app/dist .

USER nonroot

EXPOSE 3000

# Prevent Node.js from executing as PID1
ENTRYPOINT [ "/tini", "--", "/nodejs/bin/node" ]
CMD ["index.js"]