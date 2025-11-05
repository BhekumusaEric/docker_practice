# 🐳 Complete Docker Guide: From Zero to Deployment

## Table of Contents
1. [What is Docker?](#what-is-docker)
2. [Docker Concepts](#docker-concepts)
3. [Creating a Dockerfile](#creating-a-dockerfile)
4. [Building Docker Images](#building-docker-images)
5. [Running Containers](#running-containers)
6. [Docker Compose](#docker-compose)
7. [GitHub Actions CI/CD](#github-actions-cicd)
8. [Deploying to Production](#deploying-to-production)

---

## What is Docker?

### The Problem Docker Solves

Imagine you build an application on your computer. It works perfectly! But when you try to run it on:
- Your friend's computer → ❌ Doesn't work
- A server → ❌ Different errors
- Production → ❌ "But it works on my machine!"

**Why?** Different:
- Operating systems
- Java/Python/Node versions
- Dependencies
- Environment variables
- System libraries

### The Docker Solution

Docker packages your application with **everything it needs** into a **container**:
- Your code
- Runtime (Java, Python, etc.)
- System libraries
- Dependencies
- Configuration

**Result:** If it works in a Docker container on your machine, it will work **anywhere** Docker runs!

---

## Docker Concepts

### 1. **Image** (The Blueprint)
- A **template** or **snapshot** of your application
- Contains everything needed to run your app
- **Immutable** (doesn't change)
- Like a **class** in programming

**Example:** `echo-server:latest` is an image

### 2. **Container** (The Running Instance)
- A **running instance** of an image
- Like an **object** created from a class
- Can have multiple containers from one image
- **Isolated** from other containers

**Example:** When you run `docker run echo-server:latest`, you create a container

### 3. **Dockerfile** (The Recipe)
- A **text file** with instructions to build an image
- Tells Docker how to create your image step-by-step

### 4. **Registry** (The Storage)
- A place to store and share images
- **Docker Hub** is the public registry (like GitHub for Docker images)
- You can also have private registries

### Visual Analogy:
```
Dockerfile (Recipe)  →  Image (Blueprint)  →  Container (Running App)
     📝                      📦                      🏃
```

---

## Creating a Dockerfile

### Anatomy of a Dockerfile

Let's break down our `Dockerfile` line by line:

```dockerfile
# Use an official Eclipse Temurin runtime as a parent image
FROM eclipse-temurin:11-jre

# Set working directory
WORKDIR /app

# Copy the JAR file
COPY target/echo-server-0.0.0-SNAPSHOT-jar-with-dependencies.jar /app/echo-server.jar

# Expose port 9000
EXPOSE 9000

# Run the application
CMD ["java", "-jar", "echo-server.jar"]
```

### Line-by-Line Explanation:

#### 1. `FROM eclipse-temurin:11-jre`
- **What it does:** Starts with a base image that has Java 11 installed
- **Why:** You don't build from scratch; you build on top of existing images
- **Analogy:** Like inheriting from a parent class

**Base Image Layers:**
```
┌─────────────────────────┐
│  Your Application       │  ← You add this
├─────────────────────────┤
│  Java 11 Runtime (JRE)  │  ← FROM provides this
├─────────────────────────┤
│  Operating System       │  ← FROM provides this
└─────────────────────────┘
```

#### 2. `WORKDIR /app`
- **What it does:** Sets the working directory inside the container to `/app`
- **Why:** All subsequent commands run from this directory
- **Analogy:** Like `cd /app` in terminal

**Without WORKDIR:**
```dockerfile
COPY file.jar /some/long/path/file.jar
RUN cd /some/long/path && java -jar file.jar
```

**With WORKDIR:**
```dockerfile
WORKDIR /app
COPY file.jar file.jar
RUN java -jar file.jar
```

#### 3. `COPY target/echo-server-0.0.0-SNAPSHOT-jar-with-dependencies.jar /app/echo-server.jar`
- **What it does:** Copies the JAR file from your computer into the container
- **Source:** `target/echo-server-0.0.0-SNAPSHOT-jar-with-dependencies.jar` (on your machine)
- **Destination:** `/app/echo-server.jar` (inside container)

**Important:** The source path is relative to the **build context** (usually the directory where you run `docker build`)

#### 4. `EXPOSE 9000`
- **What it does:** Documents that the container listens on port 9000
- **Why:** It's **documentation only** - doesn't actually open the port
- **Actual port mapping:** Done with `-p` flag when running: `docker run -p 9000:9000`

#### 5. `CMD ["java", "-jar", "echo-server.jar"]`
- **What it does:** Specifies the command to run when the container starts
- **Format:** JSON array format `["executable", "param1", "param2"]`
- **Alternative format:** Shell form `CMD java -jar echo-server.jar`

**CMD vs RUN:**
- `RUN`: Executes during **build time** (creates layers in the image)
- `CMD`: Executes at **runtime** (when container starts)

---

## Multi-Stage Dockerfile (Advanced)

Our `Dockerfile.multistage` is more sophisticated:

```dockerfile
# Stage 1: Build the application
FROM maven:3.9-eclipse-temurin-11 AS builder

WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Create the runtime image
FROM eclipse-temurin:11-jre

WORKDIR /app
COPY --from=builder /build/target/echo-server-0.0.0-SNAPSHOT-jar-with-dependencies.jar /app/echo-server.jar
EXPOSE 9000
CMD ["java", "-jar", "echo-server.jar"]
```

### Why Multi-Stage?

**Problem with single-stage:**
- Includes Maven (build tool) in final image
- Includes source code in final image
- Final image is **huge** (500MB+)

**Multi-stage solution:**
- **Stage 1 (builder):** Has Maven, builds the JAR
- **Stage 2 (runtime):** Only has Java runtime and the JAR
- Final image is **small** (200MB)

### How It Works:

```
Stage 1: Builder                    Stage 2: Runtime
┌──────────────────┐               ┌──────────────────┐
│ Maven + Java     │               │ Java Runtime     │
│ Source Code      │               │                  │
│ Dependencies     │  Copy JAR →   │ JAR file only    │
│ Build Tools      │               │                  │
│                  │               │                  │
│ Size: 500MB      │               │ Size: 200MB      │
└──────────────────┘               └──────────────────┘
     (Discarded)                      (Final Image)
```

### Key Line:
```dockerfile
COPY --from=builder /build/target/echo-server-0.0.0-SNAPSHOT-jar-with-dependencies.jar /app/echo-server.jar
```
- `--from=builder`: Copies from the **builder stage**, not from your local machine
- Only the JAR file is copied to the final image
- Everything else from Stage 1 is discarded

---

## Building Docker Images

### Basic Build Command

```bash
docker build -t echo-server:latest .
```

**Breaking it down:**
- `docker build`: The build command
- `-t echo-server:latest`: Tag the image with name `echo-server` and tag `latest`
- `.`: Build context (current directory)

### What Happens During Build?

1. **Docker reads the Dockerfile**
2. **Executes each instruction** (FROM, WORKDIR, COPY, etc.)
3. **Creates layers** for each instruction
4. **Caches layers** for faster rebuilds
5. **Tags the final image**

### Build Process Visualization:

```
Step 1/5 : FROM eclipse-temurin:11-jre
 ---> c31dde28bee7                    ← Layer 1 (Base image)

Step 2/5 : WORKDIR /app
 ---> 725e6f3df1d7                    ← Layer 2 (Set working dir)

Step 3/5 : COPY target/...jar /app/echo-server.jar
 ---> d2f9aecd7387                    ← Layer 3 (Copy JAR)

Step 4/5 : EXPOSE 9000
 ---> 78156fd34bfd                    ← Layer 4 (Document port)

Step 5/5 : CMD ["java", "-jar", "echo-server.jar"]
 ---> b5371584bdfc                    ← Layer 5 (Set startup command)

Successfully built b5371584bdfc        ← Final image ID
Successfully tagged echo-server:0.0.0-snapshot
```

### Layer Caching

Docker caches each layer. If nothing changes, it reuses the cache:

```
Step 1/5 : FROM eclipse-temurin:11-jre
 ---> Using cache                     ← Reused!
 ---> c31dde28bee7

Step 2/5 : WORKDIR /app
 ---> Using cache                     ← Reused!
 ---> 725e6f3df1d7
```

**Pro Tip:** Put things that change frequently (like your code) **later** in the Dockerfile

### Build with Multi-Stage:

```bash
docker build -f Dockerfile.multistage -t echo-server:latest .
```

- `-f Dockerfile.multistage`: Specify which Dockerfile to use
- Default is `Dockerfile`

### Useful Build Commands:

```bash
# Build with a specific tag
docker build -t echo-server:v1.0.0 .

# Build without cache (fresh build)
docker build --no-cache -t echo-server:latest .

# Build and see all output
docker build --progress=plain -t echo-server:latest .

# Build for a different platform (e.g., ARM)
docker build --platform linux/arm64 -t echo-server:latest .
```

---

## GitHub Actions CI/CD

### What is CI/CD?

**CI (Continuous Integration):**
- Automatically build and test code when you push changes
- Catch bugs early
- Ensure code always builds

**CD (Continuous Deployment):**
- Automatically deploy code to servers
- Fast releases
- Less manual work

### Our GitHub Actions Workflow

File: `.github/workflows/docker-build.yml`

```yaml
name: Build Docker Image

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -f Dockerfile.multistage -t echo-server:latest .
```

### Breaking It Down:

#### `name: Build Docker Image`
- Name of the workflow
- Shows up in GitHub Actions tab

#### `on:`
- **Trigger** - when should this workflow run?
- `push:` - runs when you push code
- `branches: [main]` - only on the `main` branch

**Other triggers:**
```yaml
on:
  pull_request:        # When PR is created
  schedule:            # On a schedule (cron)
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:   # Manual trigger
```

#### `jobs:`
- A workflow can have multiple jobs
- Jobs run in parallel by default

#### `build:`
- Name of the job
- You can have multiple jobs: `build:`, `test:`, `deploy:`

#### `runs-on: ubuntu-latest`
- Which operating system to use
- GitHub provides: `ubuntu-latest`, `windows-latest`, `macos-latest`

#### `steps:`
- Sequential tasks within a job
- Each step runs one after another

#### `- name: Checkout code`
- Human-readable name for the step

#### `uses: actions/checkout@v4`
- Uses a pre-built action from GitHub Marketplace
- `actions/checkout` clones your repository
- `@v4` is the version

#### `run: docker build ...`
- Runs a shell command
- Like typing in terminal

### How It Works:

```
1. You push code to GitHub
         ↓
2. GitHub detects push to 'main' branch
         ↓
3. GitHub Actions starts a virtual machine (Ubuntu)
         ↓
4. Checks out your code
         ↓
5. Runs: docker build -f Dockerfile.multistage -t echo-server:latest .
         ↓
6. ✅ Success or ❌ Failure
         ↓
7. You see results in "Actions" tab
```

### Advanced Workflow: Build and Push to Docker Hub

```yaml
name: Build and Push to Docker Hub

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile.multistage
          push: true
          tags: yourusername/echo-server:latest
```

**What's new:**
- `secrets.DOCKER_USERNAME` - Stored securely in GitHub Settings
- `docker/login-action` - Logs into Docker Hub
- `docker/build-push-action` - Builds AND pushes image

**Setting up secrets:**
1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add `DOCKER_USERNAME` and `DOCKER_PASSWORD`

### Workflow with Tests:

```yaml
name: Build, Test, and Deploy

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          java-version: '11'
          distribution: 'temurin'
      - name: Run tests
        run: mvn test

  build:
    needs: test  # Only runs if 'test' job succeeds
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: docker build -f Dockerfile.multistage -t echo-server:latest .
```

**Key concept:**
- `needs: test` - This job waits for `test` job to complete
- If tests fail, build doesn't run

---

## Deploying to Production

### Deployment Options

1. **Cloud Platforms (Easiest)**
   - AWS (ECS, Fargate, App Runner)
   - Google Cloud (Cloud Run, GKE)
   - Azure (Container Instances, AKS)
   - DigitalOcean (App Platform)
   - Heroku (Container Registry)

2. **Your Own Server (VPS)**
   - DigitalOcean Droplet
   - AWS EC2
   - Linode
   - Vultr

3. **Kubernetes (Advanced)**
   - For large-scale applications
   - Multiple containers
   - Auto-scaling

### Option 1: Deploy to DigitalOcean App Platform (Easiest)

**Steps:**

1. **Push your code to GitHub** ✅ (Already done!)

2. **Create DigitalOcean account**
   - Go to digitalocean.com
   - Sign up (free $200 credit for new users)

3. **Create a new App**
   - Click "Create" → "Apps"
   - Connect your GitHub repository
   - Select `docker_practice` repository

4. **Configure the app**
   - DigitalOcean detects your Dockerfile automatically
   - Set HTTP port: `9000`
   - Choose plan: $5/month (Basic)

5. **Deploy!**
   - Click "Create Resources"
   - Wait 5-10 minutes
   - Your app is live! 🎉

6. **Auto-deployment**
   - Every time you push to `main`, it auto-deploys
   - No extra configuration needed!

**Cost:** ~$5/month

### Option 2: Deploy to Your Own Server (VPS)

**Prerequisites:**
- A server (DigitalOcean Droplet, AWS EC2, etc.)
- SSH access to the server

#### Step 1: Set up the server

```bash
# SSH into your server
ssh root@your-server-ip

# Update system
apt update && apt upgrade -y

# Install Docker
apt install docker.io -y

# Start Docker
systemctl start docker
systemctl enable docker
```

#### Step 2: Clone your repository

```bash
# Install git
apt install git -y

# Clone your repo
git clone https://github.com/BhekumusaEric/docker_practice.git
cd docker_practice
```

#### Step 3: Build and run

```bash
# Build the image
docker build -f Dockerfile.multistage -t echo-server:latest .

# Run the container
docker run -d -p 9000:9000 --name echo-server --restart=always echo-server:latest

# Check if it's running
docker ps
```

#### Step 4: Configure firewall

```bash
# Allow port 9000
ufw allow 9000/tcp
ufw enable
```

#### Step 5: Access your app

```
http://your-server-ip:9000
```

#### Step 6: Set up auto-deployment with GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Server

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_IP }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /root/docker_practice
            git pull
            docker build -f Dockerfile.multistage -t echo-server:latest .
            docker stop echo-server || true
            docker rm echo-server || true
            docker run -d -p 9000:9000 --name echo-server --restart=always echo-server:latest
```

**What this does:**
1. Connects to your server via SSH
2. Pulls latest code
3. Builds new Docker image
4. Stops old container
5. Starts new container

**Setup secrets in GitHub:**
- `SERVER_IP`: Your server's IP address
- `SERVER_USER`: SSH username (usually `root`)
- `SSH_PRIVATE_KEY`: Your SSH private key

### Option 3: Deploy to Docker Hub + Pull on Server

This is a better approach for production.

#### Step 1: Push image to Docker Hub

**GitHub Actions workflow:**

```yaml
name: Build and Deploy

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile.multistage
          push: true
          tags: yourusername/echo-server:latest

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest

    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_IP }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            docker pull yourusername/echo-server:latest
            docker stop echo-server || true
            docker rm echo-server || true
            docker run -d -p 9000:9000 --name echo-server --restart=always yourusername/echo-server:latest
```

**Benefits:**
- Don't need to build on server (faster)
- Server just pulls pre-built image
- Can deploy to multiple servers easily

#### Step 2: On your server

```bash
# Login to Docker Hub (one time)
docker login

# Pull and run
docker pull yourusername/echo-server:latest
docker run -d -p 9000:9000 --name echo-server --restart=always yourusername/echo-server:latest
```

### Option 4: Deploy with Docker Compose on Server

**On your server:**

```bash
# Clone repo
git clone https://github.com/BhekumusaEric/docker_practice.git
cd docker_practice

# Install Docker Compose
apt install docker-compose -y

# Start services
docker-compose up -d

# View logs
docker-compose logs -f
```

**Update deployment:**

```bash
cd docker_practice
git pull
docker-compose up -d --build
```

### Production Best Practices

#### 1. Use Environment Variables

```yaml
# docker-compose.yml
services:
  echo-server:
    build: .
    ports:
      - "9000:9000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    env_file:
      - .env
```

```bash
# .env file (don't commit to git!)
DATABASE_URL=postgres://user:pass@db:5432/mydb
API_KEY=secret123
```

#### 2. Use Health Checks

```dockerfile
# In Dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:9000/health || exit 1
```

```yaml
# In docker-compose.yml
services:
  echo-server:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

#### 3. Use Logging

```yaml
services:
  echo-server:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

#### 4. Use Reverse Proxy (Nginx)

```yaml
version: '3.8'

services:
  echo-server:
    build: .
    expose:
      - "9000"

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - echo-server
```

**Benefits:**
- SSL/TLS termination
- Load balancing
- Caching
- Security

#### 5. Use Docker Secrets (for sensitive data)

```yaml
services:
  echo-server:
    secrets:
      - db_password

secrets:
  db_password:
    file: ./db_password.txt
```

---

## Complete Deployment Workflow

### The Full Picture:

```
1. Developer writes code
         ↓
2. Push to GitHub (main branch)
         ↓
3. GitHub Actions triggered
         ↓
4. Run tests
         ↓
5. Build Docker image
         ↓
6. Push image to Docker Hub
         ↓
7. SSH into production server
         ↓
8. Pull new image
         ↓
9. Stop old container
         ↓
10. Start new container
         ↓
11. ✅ Deployed!
```

### Monitoring Your Deployment

```bash
# View running containers
docker ps

# View logs
docker logs -f echo-server

# View resource usage
docker stats echo-server

# View container details
docker inspect echo-server

# Execute commands in container
docker exec -it echo-server /bin/bash
```

### Rollback Strategy

If something goes wrong:

```bash
# Tag images with versions
docker build -t echo-server:v1.0.0 .
docker build -t echo-server:v1.0.1 .

# Run specific version
docker run -d -p 9000:9000 echo-server:v1.0.0

# If v1.0.1 has issues, rollback:
docker stop echo-server
docker rm echo-server
docker run -d -p 9000:9000 echo-server:v1.0.0
```

---

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs echo-server

# Run in foreground to see errors
docker run -p 9000:9000 echo-server:latest

# Check if port is already in use
sudo lsof -i :9000
```

### Can't connect to container

```bash
# Check if container is running
docker ps

# Check port mapping
docker port echo-server

# Check firewall
sudo ufw status

# Test from inside container
docker exec echo-server curl localhost:9000
```

### Image too large

```bash
# Check image size
docker images

# Use multi-stage builds
# Use alpine base images
# Remove unnecessary files
```

### Build fails

```bash
# Build without cache
docker build --no-cache -t echo-server:latest .

# Check Dockerfile syntax
# Verify files exist in build context
# Check .dockerignore
```

---

## Summary: Your Docker Journey

### What You've Learned:

1. ✅ **Docker Basics**
   - Images, containers, Dockerfile
   - How Docker solves deployment problems

2. ✅ **Creating Dockerfiles**
   - Single-stage and multi-stage builds
   - Best practices for efficient images

3. ✅ **Building Images**
   - Build commands
   - Layer caching
   - Tagging strategies

4. ✅ **Running Containers**
   - Port mapping
   - Environment variables
   - Volume mounting
   - Container management

5. ✅ **Docker Compose**
   - Multi-container applications
   - Service orchestration
   - Easy deployment

6. ✅ **CI/CD with GitHub Actions**
   - Automated builds
   - Automated testing
   - Automated deployment

7. ✅ **Production Deployment**
   - Cloud platforms
   - VPS deployment
   - Docker Hub registry
   - Best practices

### Next Steps:

1. **Practice** - Build more applications with Docker
2. **Learn Kubernetes** - For large-scale deployments
3. **Explore Docker Networking** - Connect multiple containers
4. **Study Security** - Secure your containers
5. **Monitor & Log** - Use tools like Prometheus, Grafana, ELK stack

### Resources:

- **Official Docker Docs:** https://docs.docker.com
- **Docker Hub:** https://hub.docker.com
- **Play with Docker:** https://labs.play-with-docker.com (free online playground)
- **GitHub Actions Docs:** https://docs.github.com/en/actions

---

## Quick Reference Commands

### Docker Build
```bash
docker build -t name:tag .
docker build -f Dockerfile.multistage -t name:tag .
docker build --no-cache -t name:tag .
```

### Docker Run
```bash
docker run -d -p 8080:80 --name myapp image:tag
docker run -it image:tag /bin/bash
docker run --rm image:tag
docker run -e VAR=value image:tag
docker run -v /host:/container image:tag
```

### Docker Management
```bash
docker ps                    # List running containers
docker ps -a                 # List all containers
docker images                # List images
docker logs container        # View logs
docker exec -it container bash  # Enter container
docker stop container        # Stop container
docker rm container          # Remove container
docker rmi image            # Remove image
```

### Docker Compose
```bash
docker-compose up -d         # Start services
docker-compose down          # Stop services
docker-compose logs -f       # View logs
docker-compose ps            # List services
docker-compose restart       # Restart services
```

### Cleanup
```bash
docker system prune          # Remove unused data
docker container prune       # Remove stopped containers
docker image prune          # Remove unused images
docker volume prune         # Remove unused volumes
```

---

**Congratulations!** 🎉 You now have a comprehensive understanding of Docker from development to deployment!

## Running Containers

### Basic Run Command

```bash
docker run -d -p 9000:9000 --name my-echo-server echo-server:latest
```

**Breaking it down:**
- `docker run`: Run a container
- `-d`: Detached mode (runs in background)
- `-p 9000:9000`: Port mapping (host:container)
- `--name my-echo-server`: Give the container a name
- `echo-server:latest`: The image to use

### Port Mapping Explained

```
Your Computer                Container
┌─────────────┐             ┌─────────────┐
│             │             │             │
│  Port 9000  │ ←────────→  │  Port 9000  │
│             │             │             │
└─────────────┘             └─────────────┘
     Host                      Container

Command: -p 9000:9000
         ↑    ↑
         │    └─ Container port
         └────── Host port
```

**Different port mapping:**
```bash
docker run -p 8080:9000 echo-server:latest
```
- Access on your computer: `localhost:8080`
- App listens inside container: `port 9000`

### Run Modes

#### 1. Detached Mode (Background)
```bash
docker run -d -p 9000:9000 --name my-echo-server echo-server:latest
```
- Returns immediately
- Container runs in background
- View logs with `docker logs my-echo-server`

#### 2. Interactive Mode (Foreground)
```bash
docker run -p 9000:9000 --name my-echo-server echo-server:latest
```
- See output directly in terminal
- Press `Ctrl+C` to stop
- Good for debugging

#### 3. Interactive with Terminal
```bash
docker run -it ubuntu /bin/bash
```
- `-it`: Interactive + TTY (terminal)
- Opens a shell inside the container
- Good for exploring containers

### Environment Variables

```bash
docker run -e DATABASE_URL=postgres://db:5432 -e API_KEY=secret123 echo-server:latest
```
- `-e KEY=VALUE`: Set environment variable
- Your app can read these variables

### Volume Mounting (Persist Data)

```bash
docker run -v /host/path:/container/path echo-server:latest
```
- Maps a directory from your computer into the container
- Data persists even if container is deleted

**Example:**
```bash
docker run -v $(pwd)/logs:/app/logs echo-server:latest
```
- Logs written to `/app/logs` in container appear in `./logs` on your computer

### Useful Run Commands:

```bash
# Run and remove container when it stops
docker run --rm -p 9000:9000 echo-server:latest

# Run with resource limits
docker run --memory="512m" --cpus="1.0" echo-server:latest

# Run with restart policy
docker run --restart=always -p 9000:9000 echo-server:latest

# Run and execute a command inside
docker run echo-server:latest ls -la /app
```

---

## Container Management

### View Containers

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List with custom format
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```

### Container Logs

```bash
# View logs
docker logs my-echo-server

# Follow logs (like tail -f)
docker logs -f my-echo-server

# Last 100 lines
docker logs --tail 100 my-echo-server

# Logs with timestamps
docker logs -t my-echo-server
```

### Start/Stop/Restart

```bash
# Stop a running container
docker stop my-echo-server

# Start a stopped container
docker start my-echo-server

# Restart a container
docker restart my-echo-server

# Pause a container (freeze it)
docker pause my-echo-server

# Unpause
docker unpause my-echo-server
```

### Execute Commands in Running Container

```bash
# Run a command in running container
docker exec my-echo-server ls -la /app

# Open a shell in running container
docker exec -it my-echo-server /bin/bash

# Run as root user
docker exec -u root -it my-echo-server /bin/bash
```

### Remove Containers

```bash
# Remove a stopped container
docker rm my-echo-server

# Force remove a running container
docker rm -f my-echo-server

# Remove all stopped containers
docker container prune
```

### Inspect Container

```bash
# View detailed container info
docker inspect my-echo-server

# Get specific info (IP address)
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-echo-server
```

---

## Docker Compose

### What is Docker Compose?

**Problem:** Running containers with long commands:
```bash
docker run -d -p 9000:9000 --name my-echo-server --restart=always -e ENV=prod echo-server:latest
```

**Solution:** Define everything in a YAML file!

### Our docker-compose.yml

```yaml
version: '3.8'

services:
  echo-server:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "9000:9000"
    container_name: my-echo-server
    restart: unless-stopped
```

### Breaking It Down:

#### `version: '3.8'`
- Docker Compose file format version
- Different versions support different features

#### `services:`
- Defines the containers to run
- Each service is a container

#### `echo-server:`
- Name of the service
- You can have multiple services (e.g., `database:`, `redis:`, etc.)

#### `build:`
- Tells Docker Compose to build an image
- Alternative: `image: echo-server:latest` (use existing image)

#### `context: .`
- Build context (current directory)
- Where to find the Dockerfile and files to copy

#### `dockerfile: Dockerfile`
- Which Dockerfile to use
- Default is `Dockerfile`

#### `ports:`
- Port mapping
- `"9000:9000"` = host:container

#### `container_name:`
- Name for the container
- Without this, Docker Compose generates a name

#### `restart: unless-stopped`
- Restart policy
- Options: `no`, `always`, `on-failure`, `unless-stopped`

### Docker Compose Commands:

```bash
# Start all services (build if needed)
docker-compose up

# Start in background
docker-compose up -d

# Build and start
docker-compose up --build

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# View running services
docker-compose ps

# Restart services
docker-compose restart

# Execute command in service
docker-compose exec echo-server /bin/bash
```

### Multi-Service Example:

```yaml
version: '3.8'

services:
  echo-server:
    build: .
    ports:
      - "9000:9000"
    depends_on:
      - database
    environment:
      - DB_HOST=database
      - DB_PORT=5432

  database:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

**What this does:**
- Runs two containers: `echo-server` and `database`
- `echo-server` waits for `database` to start (`depends_on`)
- They can communicate using service names (`database:5432`)
- Database data persists in a volume

---


