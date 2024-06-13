# Stage 1: Build React frontend
FROM node:16 as frontend

WORKDIR /app/frontend

# Copy the React app source code
COPY frontend/package.json frontend/package-lock.json ./
RUN npm install

COPY frontend/. .

# Build the React app
RUN npm run build

# Stage 2: Build Django backend
FROM python:3.12.1 as backend

# Set the working directory for backend
WORKDIR /app/backend

# Install dependencies
COPY . .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]