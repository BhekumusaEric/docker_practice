# Makefile for Echo Server Docker Project
# This makes it easy to run common commands locally
# GitHub Actions can also use these same commands!

.PHONY: help build build-simple run stop logs clean test deploy-local all

# Default target - show help
help:
	@echo "📦 Echo Server Docker Commands"
	@echo ""
	@echo "Local Development:"
	@echo "  make build        - Build Docker image (multi-stage)"
	@echo "  make build-simple - Build Docker image (simple)"
	@echo "  make run          - Run the container"
	@echo "  make stop         - Stop the container"
	@echo "  make logs         - View container logs"
	@echo "  make test         - Test the server"
	@echo "  make clean        - Stop and remove container"
	@echo ""
	@echo "Maven:"
	@echo "  make maven-build  - Build JAR with Maven"
	@echo "  make maven-test   - Run Maven tests"
	@echo ""
	@echo "Docker Compose:"
	@echo "  make up           - Start with docker-compose"
	@echo "  make down         - Stop docker-compose"
	@echo ""
	@echo "Deployment:"
	@echo "  make push         - Push image to Docker Hub"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean-all    - Remove everything (containers, images)"

# Build the Docker image using multi-stage Dockerfile
build:
	@echo "🔨 Building Docker image (multi-stage)..."
	docker build -f Dockerfile.multistage -t echo-server:latest .
	@echo "✅ Build complete!"

# Build using simple Dockerfile (requires Maven build first)
build-simple:
	@echo "🔨 Building JAR with Maven..."
	mvn clean package
	@echo "🔨 Building Docker image (simple)..."
	docker build -t echo-server:latest .
	@echo "✅ Build complete!"

# Build JAR with Maven
maven-build:
	@echo "🔨 Building JAR with Maven..."
	mvn clean package
	@echo "✅ Maven build complete!"

# Run Maven tests
maven-test:
	@echo "🧪 Running Maven tests..."
	mvn test

# Run the container
run:
	@echo "🚀 Starting Echo Server container..."
	docker run -d -p 9000:9000 --name my-echo-server --restart=unless-stopped echo-server:latest
	@echo "✅ Container started!"
	@echo "📡 Server running on port 9000"
	@echo "🧪 Test with: make test"

# Stop the container
stop:
	@echo "🛑 Stopping container..."
	docker stop my-echo-server || true
	@echo "✅ Container stopped!"

# View container logs
logs:
	@echo "📋 Container logs:"
	docker logs -f my-echo-server

# Test the server
test:
	@echo "🧪 Testing Echo Server..."
	@echo "Sending test message..."
	@echo "Hello from Makefile!" | nc localhost 9000 || echo "❌ Server not responding. Is it running? (make run)"

# Clean up - stop and remove container
clean:
	@echo "🧹 Cleaning up..."
	docker stop my-echo-server || true
	docker rm my-echo-server || true
	@echo "✅ Cleanup complete!"

# Clean everything - containers and images
clean-all: clean
	@echo "🧹 Removing Docker images..."
	docker rmi echo-server:latest || true
	@echo "🧹 Removing dangling images..."
	docker image prune -f
	@echo "✅ Full cleanup complete!"

# Docker Compose commands
up:
	@echo "🚀 Starting services with docker-compose..."
	docker-compose up -d
	@echo "✅ Services started!"

down:
	@echo "🛑 Stopping services with docker-compose..."
	docker-compose down
	@echo "✅ Services stopped!"

# Push to Docker Hub (requires login first)
push:
	@echo "📤 Pushing to Docker Hub..."
	@echo "⚠️  Make sure you've run: docker login"
	@echo "⚠️  And tagged image: docker tag echo-server:latest yourusername/echo-server:latest"
	@read -p "Enter your Docker Hub username: " username; \
	docker tag echo-server:latest $$username/echo-server:latest; \
	docker push $$username/echo-server:latest
	@echo "✅ Push complete!"

# Complete workflow - build and run
all: build run
	@echo "✅ Build and run complete!"
	@echo "🧪 Test with: make test"
	@echo "📋 View logs with: make logs"

