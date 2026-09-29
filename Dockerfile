# Official Node 16 base (same major version as the CI agent), alpine for a smaller image
FROM node:16-alpine

WORKDIR /app

# Copy manifests first so the dependency layer is cached between builds
COPY package*.json ./

# Reproducible install from the lockfile, production deps only (no mocha/supertest)
RUN npm ci --omit=dev

# Copy only the application code
COPY app.js ./

# Run as the built-in unprivileged "node" user instead of root
USER node

EXPOSE 8080
CMD ["node", "app.js"]
