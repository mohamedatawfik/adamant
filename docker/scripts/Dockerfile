# Scripts container for data processing and synchronization
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install required tools
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    rsync \
    openssh-client \
    inotify-tools \
    mysql-client \
    python3 \
    python3-pip \
    && pip3 install pymysql \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy scripts
COPY *.sh ./
COPY requirements.txt ./

# Install Python dependencies
RUN pip3 install -r requirements.txt

# Make scripts executable
RUN chmod +x *.sh

# Create data directories
RUN mkdir -p /data/raw /data/sorted /data/processed

# Create non-root user
RUN adduser -D -s /bin/bash app && \
    chown -R app:app /app /data
USER app

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
    CMD ps aux | grep -v grep | grep -q "data_preprocessing.sh\|syncscript.sh\|insert_data2db.sh" || exit 1

# Default command (will be overridden by docker-compose)
CMD ["tail", "-f", "/dev/null"]


