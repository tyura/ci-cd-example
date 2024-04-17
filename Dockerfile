# Package installation stage
FROM node:20-alpine AS dependencies
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install --production

# Build stage
FROM node:20-alpine AS builder

WORKDIR /work
COPY . /work/

RUN npm install
RUN npm run build

# Runtime stage
FROM node:20-alpine AS runtime

ENV \
  LANG="C.UTF-8" \
  TZ="UTC" \
  NODE_ENV="production" \
  NODE_OPTIONS="--enable-source-maps"

WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=builder /work/dist ./dist

# Prevent Node.js from executing as PID1
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]

USER node

EXPOSE 3000

CMD ["node", "dist/src/main.js"]
