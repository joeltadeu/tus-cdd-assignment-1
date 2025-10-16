#!/bin/bash

LOG_FILE="/var/log/ec2-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# --- Start ---
log "=== Starting Simplified EC2 Setup ==="
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    error_exit "Please run as root or use sudo"
fi

log "Running as root - proceeding"

yum update -y || error_exit "Failed to update packages"

# Install AWS CLI if missing
if ! command -v aws &> /dev/null; then
    log "Installing AWS CLI..."
    yum install -y awscli || error_exit "Failed to install AWS CLI"
fi

# Install Java 21
if ! command -v java &> /dev/null; then
    log "Installing Amazon Corretto Java 21..."
    yum install -y java-21-amazon-corretto-devel || error_exit "Failed to install Java 21"
fi

JAVA_PATH=$(readlink -f "$(command -v java)")
JAVA_HOME=$(dirname "$(dirname "$JAVA_PATH")")
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

cat > /etc/profile.d/java21.sh <<EOF
export JAVA_HOME=$JAVA_HOME
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

log "JAVA_HOME set to $JAVA_HOME"

# --- FIXED FUNCTION ---
get_secret() {
    local secret_id="$1"
    # log to stderr only
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Retrieving secret: $secret_id" >&2
    aws secretsmanager get-secret-value \
        --secret-id "$secret_id" \
        --query SecretString \
        --output text 2>/dev/null || error_exit "Failed to get secret: $secret_id"
}
# ----------------------

# Retrieve secrets
log "Retrieving database credentials..."
DB_HOST=$(get_secret "tusca1-secret-db-host")
DB_USERNAME=$(get_secret "tusca1-secret-db-username")
DB_PASSWORD=$(get_secret "tusca1-secret-db-password")

log "Secrets retrieved successfully"

# Setup application
APP_USER="doctorapp"
APP_DIR="/opt/doctor-app"
SERVICE_NAME="doctor-microservice"
JAR_URL="https://github.com/joeltadeu/tus-cdd-assignment-1/releases/download/v.0.0.1/doctor-0.0.1-SNAPSHOT.jar"
JAR_NAME="doctor-0.0.1-SNAPSHOT.jar"
ENV_FILE="$APP_DIR/.env"

if ! id "$APP_USER" &>/dev/null; then
    log "Creating app user: $APP_USER"
    useradd -r -s /bin/false -d "$APP_DIR" "$APP_USER"
fi

mkdir -p "$APP_DIR"
chown "$APP_USER:$APP_USER" "$APP_DIR"

log "Downloading JAR..."
curl -L -o "$APP_DIR/$JAR_NAME" "$JAR_URL" || error_exit "Failed to download JAR"
chown "$APP_USER:$APP_USER" "$APP_DIR/$JAR_NAME"

# --- FIXED ENV CREATION ---
cat > "$ENV_FILE" <<EOF
DB_HOST=$DB_HOST
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
SPRING_PROFILES_ACTIVE=aws
JAVA_HOME=$JAVA_HOME
EOF
# ---------------------------

chown "$APP_USER:$APP_USER" "$ENV_FILE"
chmod 600 "$ENV_FILE"
log "Environment file created successfully"

# Create systemd service
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Doctor Microservice
After=network.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$JAVA_HOME/bin/java -jar $APP_DIR/$JAR_NAME --spring.profiles.active=aws
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

sleep 5
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log "✅ $SERVICE_NAME started successfully"
else
    error_exit "$SERVICE_NAME failed to start"
fi

log "=== EC2 Setup Completed Successfully ==="
