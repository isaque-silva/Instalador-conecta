#!/bin/bash

source "${PROJECT_ROOT}"/utils/_banner.sh

# Utility functions

function print_info() {
  echo -e "\033[0;36m[INFO]\033[0m $1"
}

function print_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

function print_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}

function print_warning() {
  echo -e "\033[0;33m[WARNING]\033[0m $1"
}

function print_step() {
  echo -e "\n\033[1;34m========================================\033[0m"
  echo -e "\033[1;34m$1\033[0m"
  echo -e "\033[1;34m========================================\033[0m\n"
}

function check_command() {
  if command -v "$1" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

function wait_for_service() {
  local service=$1
  local max_attempts=30
  local attempt=0
  
  print_info "Aguardando serviço $service ficar disponível..."
  
  while [ $attempt -lt $max_attempts ]; do
    if systemctl is-active --quiet "$service"; then
      print_success "$service está rodando"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 2
  done
  
  print_error "$service não ficou disponível a tempo"
  return 1
}
