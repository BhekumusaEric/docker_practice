# Use an official Eclipse Temurin runtime as a parent image
FROM eclipse-temurin:11-jre

# Set the working directory in the container
WORKDIR /app

# Copy the JAR file from the target directory to the container
COPY target/echo-server-0.0.0-SNAPSHOT-jar-with-dependencies.jar /app/echo-server.jar

# Expose port 9000 for the Echo Server
EXPOSE 9000

# Run the JAR file
CMD ["java", "-jar", "echo-server.jar"]

