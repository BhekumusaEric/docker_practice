# Docker Practice - Echo Server

A simple TCP Echo Server built with Java and containerized with Docker.

## 🚀 What This Project Does

This is a learning project for Docker pipelines. The Echo Server:
- Listens on port 9000
- Accepts TCP connections
- Echoes back any messages it receives

## 📦 GitHub Actions CI/CD

This repository has a **simple automated workflow** that:

**Automatically builds the Docker image** whenever you push code to the `main` branch.

### How It Works:

1. You push code to GitHub
2. GitHub Actions automatically runs
3. It builds your Docker image using `Dockerfile.multistage`
4. You can see the build status in the "Actions" tab on GitHub

### View the Workflow:

- Go to your repository on GitHub
- Click the **"Actions"** tab
- You'll see the build running or completed

## 🛠️ Local Development

### Build and Run Locally

```bash
# Build the JAR
mvn clean package

# Build Docker image
docker build -t echo-server:latest .

# Run the container
docker run -d -p 9000:9000 --name my-echo-server echo-server:latest

# Test it
echo "Hello Docker!" | nc localhost 9000
```

### Using Docker Compose

```bash
# Start the server
docker-compose up -d

# Stop the server
docker-compose down
```

## 📚 Files in This Project

- `Dockerfile` - Simple Docker build (requires pre-built JAR)
- `Dockerfile.multistage` - Advanced multi-stage build (builds everything in Docker)
- `docker-compose.yml` - Easy container management
- `.github/workflows/docker-build.yml` - **GitHub Actions workflow for automated builds**
- `DOCKER_GUIDE.md` - Complete Docker commands reference

## 🎓 Learning Goals

- ✅ Build Java applications with Maven
- ✅ Create Docker images
- ✅ Run containers
- ✅ Set up automated CI/CD pipelines with GitHub Actions

---

**Next Steps:** Check the "Actions" tab on GitHub to see your automated builds! 🎉

