# Stage 1: Build React frontend
FROM node:16 as frontend

WORKDIR /app/frontend

# Copy the React app source code
COPY package.json package-lock.json ./
RUN npm install

COPY . .

# Build the React app
RUN npm run build