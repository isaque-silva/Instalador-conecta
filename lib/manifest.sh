#!/bin/bash

source "${PROJECT_ROOT}"/lib/_backend.sh
source "${PROJECT_ROOT}"/lib/_frontend.sh
source "${PROJECT_ROOT}"/lib/_system.sh
source "${PROJECT_ROOT}"/lib/_inquiry.sh
  print_step "Configuração Interativa"
  
  # Usar valores padrão se não existirem no config
  domain="${domain:-}"
  admin_email="${admin_email:-admin@conecta.local}"
  admin_password="${admin_password:-Admin@123}"
  admin_name="${admin_name:-Administrador}"
  
  read -p "Digite o domínio (ex: conecta.exemplo.com) ou pressione Enter para pular SSL: " domain_input
  domain="${domain_input:-}"
  
  read -p "E-mail do administrador padrão [${admin_email}]: " admin_email_input
  admin_email="${admin_email_input:-${admin_email}}"
  
  read -sp "Senha do administrador padrão [${admin_password}]: " admin_password_input
  echo
  admin_password="${admin_password_input:-${admin_password}}"
  
  read -sp "Senha do PostgreSQL [gerar automaticamente]: " postgres_password_input
  echo
  if [[ -n "$postgres_password_input" ]]; then
    postgres_password="${postgres_password_input}"
  else
    postgres_password="${postgres_password:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"
  fi
  
  read -sp "JWT Secret [gerar automaticamente]: " jwt_secret_input
  echo
  if [[ -n "$jwt_secret_input" ]]; then
    jwt_secret="${jwt_secret_input}"
  else
    jwt_secret="${jwt_secret:-$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)}"
  fi
  
  # Salvar no config
  cat > "${PROJECT_ROOT}"/config <<EOF
deploy_password=${deploy_password}
postgres_password=${postgres_password}
jwt_secret=${jwt_secret}
domain=${domain}
admin_email=${admin_email}
admin_password=${admin_password}
admin_name=${admin_name}
EOF
  
  sudo chown root:root "${PROJECT_ROOT}"/config
  sudo chmod 700 "${PROJECT_ROOT}"/config
  source "${PROJECT_ROOT}"/config
}

function system_update() {
  print_step "Atualizando Sistema"
  sudo apt update -y
  sudo apt upgrade -y
  print_success "Sistema atualizado"
}

function system_node_install() {
  print_step "Instalando Node.js"
  
  if check_command node; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ $NODE_VERSION -ge 18 ]]; then
      print_info "Node.js já instalado (versão $(node -v))"
      return 0
    fi
  fi
  
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  
  print_success "Node.js instalado: $(node -v)"
  print_success "npm instalado: $(npm -v)"
}

function system_pm2_install() {
  print_step "Instalando PM2"
  
  if check_command pm2; then
    print_info "PM2 já instalado"
    return 0
  fi
  
  sudo npm install -g pm2
  sudo pm2 startup systemd -u "${DEPLOY_USER}" --hp "${DEPLOY_HOME}"
  
  print_success "PM2 instalado"
}

function system_postgresql_install() {
  print_step "Instalando PostgreSQL"
  
  if check_command psql; then
    print_info "PostgreSQL já instalado"
    return 0
  fi
  
  sudo apt install -y postgresql postgresql-contrib
  
  wait_for_service postgresql
  
  print_success "PostgreSQL instalado"
}

function system_nginx_install() {
  print_step "Instalando Nginx"
  
  if check_command nginx; then
    print_info "Nginx já instalado"
    return 0
  fi
  
  sudo apt install -y nginx
  
  wait_for_service nginx
  
  print_success "Nginx instalado"
}

function system_certbot_install() {
  print_step "Instalando Certbot"
  
  if check_command certbot; then
    print_info "Certbot já instalado"
    return 0
  fi
  
  sudo apt install -y certbot python3-certbot-nginx
  
  print_success "Certbot instalado"
}

function system_create_user() {
  print_step "Criando usuário de deploy"
  
  if id "${DEPLOY_USER}" &>/dev/null; then
    print_info "Usuário ${DEPLOY_USER} já existe"
  else
    sudo useradd -m -s /bin/bash "${DEPLOY_USER}"
    print_success "Usuário ${DEPLOY_USER} criado"
  fi
  
  # Criar diretório da aplicação
  sudo mkdir -p "${APP_DIR}"
  sudo chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_DIR}"
}

function system_git_clone() {
  print_step "Preparando projeto"
  
  if [[ -d "${APP_DIR}/backend" ]] && [[ -d "${APP_DIR}/frontend" ]]; then
    print_info "Projeto já existe em ${APP_DIR}, pulando cópia"
    return 0
  fi
  
  # Se já estamos no diretório do projeto (tem backend/ e frontend/), copiar para APP_DIR
  if [[ -d "${PROJECT_ROOT}/backend" ]] && [[ -d "${PROJECT_ROOT}/frontend" ]]; then
    print_info "Copiando projeto atual para ${APP_DIR}"
    sudo mkdir -p "${APP_DIR}"
    
    # Copiar estrutura do projeto
    sudo cp -r "${PROJECT_ROOT}/backend" "${APP_DIR}/" 2>/dev/null || true
    sudo cp -r "${PROJECT_ROOT}/frontend" "${APP_DIR}/" 2>/dev/null || true
    
    # Copiar arquivos importantes se existirem
    [[ -d "${PROJECT_ROOT}/prisma" ]] && sudo cp -r "${PROJECT_ROOT}/prisma" "${APP_DIR}/" 2>/dev/null || true
    [[ -f "${PROJECT_ROOT}/package.json" ]] && sudo cp "${PROJECT_ROOT}/package.json" "${APP_DIR}/" 2>/dev/null || true
    [[ -f "${PROJECT_ROOT}/README.md" ]] && sudo cp "${PROJECT_ROOT}/README.md" "${APP_DIR}/" 2>/dev/null || true
    [[ -f "${PROJECT_ROOT}/.gitignore" ]] && sudo cp "${PROJECT_ROOT}/.gitignore" "${APP_DIR}/" 2>/dev/null || true
    
    # Ajustar permissões
    sudo chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_DIR}"
  else
    print_error "Não foi possível encontrar o projeto (backend/ e frontend/)."
    print_error "Certifique-se de estar executando o script do diretório raiz do projeto."
    exit 1
  fi
  
  print_success "Projeto preparado em ${APP_DIR}"
}

function backend_set_env() {
  print_step "Configurando variáveis de ambiente do backend"
  
  local env_file="${APP_DIR}/backend/.env"
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cat > "${env_file}" <<ENVEOF
# Database
DATABASE_URL=postgresql://${POSTGRES_USER}:${postgres_password}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}?schema=public

# JWT
JWT_SECRET=${jwt_secret}

# Server
PORT=${BACKEND_PORT}
CORS_ORIGIN=*

# Admin padrão
DEFAULT_ADMIN_EMAIL=${admin_email}
DEFAULT_ADMIN_PASSWORD=${admin_password}
DEFAULT_ADMIN_NAME=${admin_name}

# Media
MEDIA_PATH=${APP_DIR}/backend/media
AUTH_SESSIONS_PATH=${APP_DIR}/backend/auth_sessions
ENVEOF
chmod 600 "${env_file}"
ENVEOF
  
  print_success "Variáveis de ambiente do backend configuradas"
}

function backend_db_create() {
  print_step "Criando banco de dados PostgreSQL"
  
  sudo -u postgres bash <<EOF
psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${postgres_password}';" 2>/dev/null || echo "Usuário já existe"
psql -c "ALTER USER ${POSTGRES_USER} CREATEDB;" 2>/dev/null || true
psql -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" 2>/dev/null || echo "Banco já existe"
EOF
  
  print_success "Banco de dados configurado"
}

function backend_node_dependencies() {
  print_step "Instalando dependências do backend"
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cd "${APP_DIR}/backend"
npm install
EOF
  
  print_success "Dependências do backend instaladas"
}

function backend_node_build() {
  print_step "Compilando backend"
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cd "${APP_DIR}/backend"
npm run build
EOF
  
  print_success "Backend compilado"
}

function backend_db_migrate() {
  print_step "Executando migrations do banco de dados"
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cd "${APP_DIR}/backend"
export DATABASE_URL="postgresql://${POSTGRES_USER}:${postgres_password}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}?schema=public"
npx prisma migrate deploy || npx prisma db push
EOF
  
  print_success "Migrations executadas"
}

function backend_db_seed() {
  print_step "Criando usuário admin padrão"
  
  # O seedAdmin já é executado automaticamente no index.ts
  print_info "Seed será executado na primeira inicialização do backend"
  print_success "Seed configurado"
}

function backend_start_pm2() {
  print_step "Iniciando backend com PM2"
  
  # Criar diretórios necessários
  sudo -u "${DEPLOY_USER}" mkdir -p "${APP_DIR}/backend/media"
  sudo -u "${DEPLOY_USER}" mkdir -p "${APP_DIR}/backend/auth_sessions"
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cd "${APP_DIR}/backend"
export DATABASE_URL="postgresql://${POSTGRES_USER}:${postgres_password}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}?schema=public"
pm2 delete conecta-backend 2>/dev/null || true
pm2 start dist/index.js --name conecta-backend --update-env
pm2 save
EOF
  
  print_success "Backend iniciado com PM2"
}

function frontend_set_env() {
  print_step "Configurando variáveis de ambiente do frontend"
  
  local env_file="${APP_DIR}/frontend/.env"
  local api_url
  
  if [[ -n "$domain" ]]; then
    api_url="https://${domain}/api"
  else
    api_url="http://localhost:${BACKEND_PORT}"
  fi
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cat > "${env_file}" <<ENVEOF
VITE_API_URL=${api_url}
ENVEOF
chmod 600 "${env_file}"
ENVEOF
  
  print_success "Variáveis de ambiente do frontend configuradas"
}

function frontend_node_dependencies() {
  print_step "Instalando dependências do frontend"
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cd "${APP_DIR}/frontend"
npm install
EOF
  
  print_success "Dependências do frontend instaladas"
}

function frontend_node_build() {
  print_step "Compilando frontend"
  
  sudo -u "${DEPLOY_USER}" bash <<EOF
cd "${APP_DIR}/frontend"
npm run build
EOF
  
  print_success "Frontend compilado"
}

function frontend_start_pm2() {
  print_step "Iniciando frontend com PM2"
  
  # Frontend será servido pelo nginx, não precisa PM2
  print_info "Frontend será servido pelo Nginx"
  print_success "Frontend configurado"
}

function system_nginx_conf() {
  print_step "Configurando Nginx"
  
  local nginx_conf="/etc/nginx/sites-available/conecta"
  local api_url
  
  if [[ -n "$domain" ]]; then
    api_url="https://${domain}"
  else
    api_url="http://localhost"
  fi
  
  sudo bash <<EOF
cat > "${nginx_conf}" <<NGINXEOF
server {
    listen 80;
    server_name ${domain:-_};
    
    # Frontend
    location / {
        root ${APP_DIR}/frontend/dist;
        try_files \$uri \$uri/ /index.html;
        index index.html;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Socket.IO
    location /socket.io {
        proxy_pass http://localhost:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Media files
    location /api/media {
        alias ${APP_DIR}/backend/media;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
NGINXEOF

# Habilitar site
ln -sf "${nginx_conf}" /etc/nginx/sites-enabled/conecta
rm -f /etc/nginx/sites-enabled/default
NGINXEOF
  
  # Testar configuração
  if sudo nginx -t; then
    print_success "Configuração do Nginx válida"
  else
    print_error "Erro na configuração do Nginx"
    exit 1
  fi
}

function system_nginx_restart() {
  print_step "Reiniciando Nginx"
  
  sudo systemctl restart nginx
  wait_for_service nginx
  
  print_success "Nginx reiniciado"
}

function system_certbot_setup() {
  if [[ -z "$domain" ]] || [[ "$domain" == "_" ]]; then
    print_warning "Domínio não configurado, pulando configuração SSL"
    return 0
  fi
  
  print_step "Configurando SSL com Certbot"
  
  sudo certbot --nginx -d "${domain}" --non-interactive --agree-tos --email "${admin_email}" --redirect
  
  # Configurar renovação automática
  sudo systemctl enable certbot.timer
  sudo systemctl start certbot.timer
  
  print_success "SSL configurado para ${domain}"
}
