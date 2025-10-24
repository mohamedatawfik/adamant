# Multi-stage build for Database UI
FROM node:16-alpine as build

# Set working directory
WORKDIR /app

# Copy package files
COPY db-ui/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY db-ui/src/ ./src/
COPY db-ui/public/ ./public/

# Build the application
RUN npm run build

# Production stage with Nginx
FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built app from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Create nginx configuration for DB UI
RUN echo 'server { \
    listen 3011; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
        add_header Cache-Control "no-cache, no-store, must-revalidate"; \
    } \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Create nginx user and set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3011/health || exit 1

# Expose port
EXPOSE 3011

# Start nginx
CMD ["nginx", "-g", "daemon off;"]


