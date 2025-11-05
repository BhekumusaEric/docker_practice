# Docker Guide for Echo Server

## Prerequisites

### Install Docker
```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install docker.io -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Apply group changes (or log out and back in)
newgrp docker
```

## Option 1: Simple Dockerfile (Pre-built JAR)

### Build the application first
```bash
mvn clean package
```

### Build Docker image
```bash
docker build -t echo-server:latest .
```

### Run the container
```bash
docker run -d -p 9000:9000 --name my-echo-server echo-server:latest
```

### Test the server
```bash
echo "Hello from Docker!" | nc localhost 9000
```

## Option 2: Multi-stage Dockerfile (Builds inside Docker)

### Build Docker image (no need to build with Maven first)
```bash
docker build -f Dockerfile.multistage -t echo-server:latest .
```

### Run the container
```bash
docker run -d -p 9000:9000 --name my-echo-server echo-server:latest
```

## Useful Docker Commands

### Container Management
```bash
# List running containers
docker ps

# List all containers
docker ps -a

# View container logs
docker logs my-echo-server

# Follow logs in real-time
docker logs -f my-echo-server

# Stop the container
docker stop my-echo-server

# Start the container
docker start my-echo-server

# Restart the container
docker restart my-echo-server

# Remove the container (must be stopped first)
docker rm my-echo-server

# Force remove running container
docker rm -f my-echo-server
```

### Image Management
```bash
# List images
docker images

# Remove an image
docker rmi echo-server:latest

# Remove all unused images
docker image prune
```

### Interactive Mode
```bash
# Run container in interactive mode (see output directly)
docker run -p 9000:9000 --name my-echo-server echo-server:latest

# Execute a command inside running container
docker exec -it my-echo-server /bin/bash

# View container details
docker inspect my-echo-server
```

### Testing the Server
```bash
# Using netcat
echo "Test message" | nc localhost 9000

# Interactive netcat
nc localhost 9000

# Using telnet
telnet localhost 9000
```

## Docker Compose (Optional)

Create a `docker-compose.yml` file for easier management:

```yaml
version: '3.8'

services:
  echo-server:
    build: .
    ports:
      - "9000:9000"
    container_name: my-echo-server
    restart: unless-stopped
```

Then use:
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f
```

## Troubleshooting

### Port already in use
```bash
# Find process using port 9000
sudo lsof -i :9000

# Kill the process
sudo kill -9 <PID>

# Or kill all processes on port 9000
sudo lsof -ti:9000 | xargs kill -9
```

### Container won't start
```bash
# Check logs
docker logs my-echo-server

# Run in foreground to see errors
docker run -p 9000:9000 echo-server:latest
```

### Clean up everything
```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Remove all unused resources
docker system prune -a
```

