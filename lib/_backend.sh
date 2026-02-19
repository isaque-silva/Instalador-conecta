#!/bin/bash
# 
# Functions for setting up app backend

#######################################
# Creates PostgreSQL database
# Arguments:
#   None
#######################################
function backend_db_create() {
  print_banner
  printf "${WHITE} 💻 Criando Banco Postgres...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local db_user="${instancia_add:-${POSTGRES_USER}}"
  local db_name="${instancia_add:-${POSTGRES_DB}}"
  local db_pass="${mysql_root_password:-${postgres_password}}"
  # Escapar aspas simples para uso em SQL
  local db_pass_sql="${db_pass//\'/\'\'}"

  echo "[PostgreSQL] Criando usuário e banco..."
  sudo -u postgres psql -c "CREATE USER ${db_user} WITH PASSWORD '${db_pass_sql}';" 2>/dev/null || true
  sudo -u postgres psql -c "ALTER USER ${db_user} WITH PASSWORD '${db_pass_sql}';"
  sudo -u postgres psql -c "ALTER USER ${db_user} CREATEDB;" 2>/dev/null || true
  sudo -u postgres psql -c "CREATE DATABASE ${db_name} OWNER ${db_user};" 2>/dev/null || true
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};" 2>/dev/null || true
  echo "[PostgreSQL] Usuário ${db_user} e banco ${db_name} configurados."

  sleep 2
}

#######################################
# Sets environment variable for backend.
# Arguments:
#   None
#######################################
function backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_dir="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  # ensure idempotency
  if [[ -n "${backend_url}" ]]; then
    backend_url=$(echo "${backend_url/https:\/\/}")
    backend_url=${backend_url%%/*}
    backend_url="https://$backend_url"
  fi

  # ensure idempotency
  if [[ -n "${frontend_url}" ]]; then
    frontend_url=$(echo "${frontend_url/https:\/\/}")
    frontend_url=${frontend_url%%/*}
    frontend_url="https://$frontend_url"
  fi

  local backend_port_used="${backend_port:-${BACKEND_PORT}}"
  local db_user="${instancia_add:-${POSTGRES_USER}}"
  local db_name="${instancia_add:-${POSTGRES_DB}}"
  local db_pass="${mysql_root_password:-${postgres_password}}"

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cat <<[-]EOF > "${app_instance_dir}/backend/.env"
# Database
DATABASE_URL=postgresql://${db_user}:${db_pass}@localhost:${POSTGRES_PORT}/${db_name}?schema=public

# JWT
JWT_SECRET=${jwt_secret}

# Server
PORT=${backend_port_used}
CORS_ORIGIN=*

# Admin padrão
DEFAULT_ADMIN_EMAIL=${admin_email}
DEFAULT_ADMIN_PASSWORD=${admin_password}
DEFAULT_ADMIN_NAME=${admin_name}

# Media
MEDIA_PATH=${app_instance_dir}/backend/media
AUTH_SESSIONS_PATH=${app_instance_dir}/backend/auth_sessions
[-]EOF
  chmod 600 "${app_instance_dir}/backend/.env"
EOF

  sleep 2
}

#######################################
# Installs node.js dependencies
# Arguments:
#   None
#######################################
function backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_dir="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/backend"
  echo ""
  echo ">>> Executando: npm install"
  npm install
  echo ""
  echo ">>> Executando: npx prisma generate"
  npx prisma generate || echo "Prisma generate falhou, mas continuando..."
  echo ""
EOF

  sleep 2
}

#######################################
# Compiles backend code
# Arguments:
#   None
#######################################
function backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_dir="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/backend"
  echo ""
  echo ">>> Executando: npm run build"
  npm run build || {
    echo "Build completou com erros TypeScript, mas continuando..."
    npx prisma generate || true
  }
  echo ""
EOF

  sleep 2
}

#######################################
# Runs db migrate
# Arguments:
#   None
#######################################
function backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_dir="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  # Usar o .env já escrito pelo backend_set_env (mesma fonte de credenciais)
  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/backend"
  
  if [[ ! -f .env ]]; then
    echo "ERRO: Arquivo .env não encontrado. Execute backend_set_env antes."
    exit 1
  fi
  
  echo ""
  echo ">>> Executando: npx prisma generate"
  npx prisma generate || true
  
  echo ""
  echo ">>> Executando: npx prisma db push"
  if ! npx prisma db push --accept-data-loss; then
    echo ">>> db push falhou, tentando: npx prisma migrate deploy"
    if ! npx prisma migrate deploy; then
      echo "ERRO: migrate deploy falhou. Verifique as credenciais em .env e se o usuário conecta existe no PostgreSQL."
      exit 1
    fi
  fi
  
  echo ""
  echo ">>> Executando: npx prisma generate (atualizar client)"
  npx prisma generate || true
  echo ""
EOF

  sleep 2
}

#######################################
# Runs db seed
# Arguments:
#   None
#######################################
function backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Executando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # O seedAdmin já é executado automaticamente no index.ts
  print_info "Seed será executado na primeira inicialização do backend"

  sleep 2
}

#######################################
# Starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
function backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_name="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  local db_user="${instancia_add:-${POSTGRES_USER}}"
  local db_name="${instancia_add:-${POSTGRES_DB}}"
  local db_pass="${mysql_root_password:-${postgres_password}}"

  sudo -u "${DEPLOY_USER}" mkdir -p "${app_instance_dir}/backend/media"
  sudo -u "${DEPLOY_USER}" mkdir -p "${app_instance_dir}/backend/auth_sessions"

  echo ">>> Iniciando backend com PM2: ${instance_name}-backend"
  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/backend"
  export DATABASE_URL="postgresql://${db_user}:${db_pass}@localhost:${POSTGRES_PORT}/${db_name}?schema=public"
  pm2 delete ${instance_name}-backend 2>/dev/null || true
  pm2 start dist/index.js --name ${instance_name}-backend --update-env
  pm2 save
  echo ""
  pm2 list
EOF

  sleep 2
}

#######################################
# Sets up nginx for backend
# Arguments:
#   None
#######################################
function backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_name="${instancia_add:-conecta}"
  local backend_port_used="${backend_port:-${BACKEND_PORT}}"
  local backend_hostname="${domain:-_}"

  # Gerar config com domínio real para o Certbot encontrar o server_name
  sudo tee /etc/nginx/sites-available/${instance_name}-backend > /dev/null << NGINXEOF
server {
  listen 80;
  server_name ${backend_hostname};
  location /api {
    proxy_pass http://127.0.0.1:${backend_port_used};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
  location /socket.io {
    proxy_pass http://127.0.0.1:${backend_port_used};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
NGINXEOF
  sudo ln -sf /etc/nginx/sites-available/${instance_name}-backend /etc/nginx/sites-enabled

  sleep 2
}

#######################################
# Updates backend code
# Arguments:
#   None
#######################################
function backend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local empresa="${empresa_atualizar:-conecta}"
  local app_instance_dir="/home/${DEPLOY_USER}/${empresa}"
  local sudo_env=""
  [[ -n "${GIT_ASKPASS:-}" ]] && [[ -f "${GIT_ASKPASS:-}" ]] && sudo_env="GIT_ASKPASS=${GIT_ASKPASS} GIT_TERMINAL_PROMPT=0"

  sudo -u "${DEPLOY_USER}" $sudo_env bash <<EOF
  cd "${app_instance_dir}"
  pm2 stop ${empresa}-backend
  git pull || true
  cd "${app_instance_dir}/backend"
  npm install
  npm update -f
  rm -rf dist 
  npm run build
  npx prisma migrate deploy || npx prisma db push
  pm2 start ${empresa}-backend
  pm2 save
EOF

  sleep 2
}

