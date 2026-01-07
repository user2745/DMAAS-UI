# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build argument for API base URL
ARG API_BASE_URL=

# Build the web application with the API_BASE_URL compile-time constant
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Production stage - serve with nginx
FROM nginx:alpine

# Copy built web app to nginx html directory
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
