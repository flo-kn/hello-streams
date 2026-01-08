FROM node:12

WORKDIR /app

# Copy package files
COPY coffee-shop/package.json coffee-shop/yarn.lock ./

# Install dependencies
RUN yarn install

# Copy application source
COPY coffee-shop/src ./src
COPY coffee-shop/public ./public

# Set environment variables for React dev server in Docker
ENV SKIP_PREFLIGHT_CHECK=true
ENV WATCHPACK_POLLING=true
ENV BROWSERSLIST_IGNORE_OLD_DATA=true
ENV CI=true

# Expose port 3000 (default for create-react-app)
EXPOSE 3000

# Start the development server
CMD ["yarn", "start"]

