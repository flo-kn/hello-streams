FROM node:12

WORKDIR /app

# Copy package files
COPY coffee-shop-service/package.json coffee-shop-service/yarn.lock ./

# Install dependencies
RUN yarn install

# Copy application source
COPY coffee-shop-service/.babelrc ./
COPY coffee-shop-service/src ./src

# Expose port 4000 (typical for GraphQL services)
EXPOSE 4000

# Start the service (builds and runs)
CMD ["yarn", "start"]

