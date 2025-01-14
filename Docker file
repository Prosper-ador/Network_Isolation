# Use the official Ubuntu image as the base image
FROM ubuntu:latest

# Install necessary networking utilities
RUN apt-get update && \
    apt-get install -y iputils-ping curl iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# Set environment variable for team name (Team A or Team B)
ARG TEAM_NAME
ENV TEAM_NAME=${TEAM_NAME}

# Default command to keep the container running
CMD echo "Container for ${TEAM_NAME}"; while true; do sleep 1000; done;
