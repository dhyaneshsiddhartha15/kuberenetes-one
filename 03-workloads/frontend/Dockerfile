# Frontend container - nginx serving static HTML
FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy nginx configuration
COPY app/nginx.conf /etc/nginx/nginx.conf

# Copy static files
COPY app/index.html /usr/share/nginx/html/index.html

# Create non-root user for nginx (nginx:alpine already has nginx user)
RUN chown -R nginx:nginx /usr/share/nginx/html /var/log/nginx /var/lib/nginx /etc/nginx && \
    chmod -R 755 /usr/share/nginx/html && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
