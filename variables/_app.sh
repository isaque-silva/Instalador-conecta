#!/bin/bash
#
# Variables to be used for application configuration.

# Generate random secrets if not set
jwt_secret="${jwt_secret:-$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)}"
postgres_password="${postgres_password:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"
deploy_password="${deploy_password:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"

# Default admin values
admin_email="${admin_email:-admin@conecta.local}"
admin_password="${admin_password:-Admin@123}"
admin_name="${admin_name:-Administrador}"

# Domain (can be empty for IP-only access)
domain="${domain:-}"

# Project paths
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
BACKEND_DIR="${PROJECT_ROOT}/backend"
FRONTEND_DIR="${PROJECT_ROOT}/frontend"
DEPLOY_USER="conecta"
DEPLOY_HOME="/home/${DEPLOY_USER}"
APP_DIR="${DEPLOY_HOME}/conecta"

# Ports
BACKEND_PORT="${BACKEND_PORT:-3001}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# Database
POSTGRES_USER="${POSTGRES_USER:-conecta}"
POSTGRES_DB="${POSTGRES_DB:-conecta}"

# For multi-instance support
instancia_add="${instancia_add:-}"
backend_port="${backend_port:-}"
frontend_port="${frontend_port:-}"
redis_port="${redis_port:-}"
backend_url="${backend_url:-}"
frontend_url="${frontend_url:-}"
max_user="${max_user:-}"
max_whats="${max_whats:-}"
