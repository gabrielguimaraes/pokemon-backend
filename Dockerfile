# ---- Build Stage ----
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files and install all dependencies (including devDependencies for esbuild)
COPY package.json package-lock.json ./
RUN npm ci

# Copy source code and build the production bundle
COPY server.js ./
RUN npm run build

# ---- Production Stage ----
FROM node:20-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the bundled output from the build stage
COPY --from=builder /app/dist/server.js ./server.js

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Expose the API port
EXPOSE 3001

# Switch to non-root user
USER appuser

# Health check against the /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# Start the server
CMD ["node", "server.js"]
