#!/bin/bash
# 
# Functions for setting up app frontend

#######################################
# Sets frontend environment variables
# Arguments:
#   None
#######################################
function frontend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_dir="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  # Base da URL (sem /api): o frontend já usa paths como /api/auth/login
  local api_url
  if [[ -n "$domain" ]]; then
    api_url="https://${domain}"
  else
    local backend_port_used="${backend_port:-${BACKEND_PORT}}"
    api_url="http://localhost:${backend_port_used}"
  fi

  sudo -u "${DEPLOY_USER}" bash << EOF
  cat <<[-]EOF > "${app_instance_dir}/frontend/.env"
VITE_API_URL=${api_url}
[-]EOF
  chmod 600 "${app_instance_dir}/frontend/.env"
EOF

  sleep 2
}

#######################################
# Installed node packages
# Arguments:
#   None
#######################################
function frontend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_dir="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/frontend"
  echo ""
  echo ">>> Executando: npm install (frontend)"
  npm install
  echo ""
EOF

  sleep 2
}

#######################################
# Compiles frontend code
# Arguments:
#   None
#######################################
function frontend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_dir="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/frontend"
  echo ""
  echo ">>> Executando: npm run build (frontend)"
  npm run build
  echo ""
EOF

  sleep 2
}

#######################################
# Starts pm2 for frontend
# Arguments:
#   None
#######################################
function frontend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Frontend será servido pelo nginx, não precisa PM2
  print_info "Frontend será servido pelo Nginx"

  sleep 2
}

#######################################
# Sets up nginx for frontend
# Arguments:
#   None
#######################################
function frontend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local instance_name="${instancia_add:-conecta}"
  local app_instance_dir="${APP_DIR}"
  if [[ -n "${instancia_add}" ]] && [[ "${instancia_add}" != "conecta" ]]; then
    app_instance_dir="/home/${DEPLOY_USER}/${instancia_add}"
  fi
  local frontend_hostname="${domain:-_}"

  # Gerar config com domínio real para o Certbot encontrar o server_name
  sudo tee /etc/nginx/sites-available/${instance_name}-frontend > /dev/null << NGINXEOF
server {
  listen 80;
  server_name ${frontend_hostname};
  location / {
    root ${app_instance_dir}/frontend/dist;
    try_files \$uri \$uri/ /index.html;
    index index.html;
  }
  location /api/media {
    alias ${app_instance_dir}/backend/media;
    expires 30d;
    add_header Cache-Control "public, immutable";
  }
}
NGINXEOF
  sudo ln -sf /etc/nginx/sites-available/${instance_name}-frontend /etc/nginx/sites-enabled
  sudo rm -f /etc/nginx/sites-enabled/default

  # Testar configuração
  if sudo nginx -t; then
    print_success "Configuração do Nginx válida"
  else
    print_error "Erro na configuração do Nginx"
    exit 1
  fi

  sleep 2
}

#######################################
# Updates frontend code
# Arguments:
#   None
#######################################
function frontend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local empresa="${empresa_atualizar:-conecta}"
  local app_instance_dir="/home/${DEPLOY_USER}/${empresa}"

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}"
  pm2 stop ${empresa}-frontend 2>/dev/null || true
  git pull || true
  cd "${app_instance_dir}/frontend"
  npm install
  rm -rf build dist
  npm run build
  pm2 start ${empresa}-frontend 2>/dev/null || true
  pm2 save
EOF

  sleep 2
}

#######################################
# Configure domain change
# Arguments:
#   None
#######################################
function configurar_dominio() {
  print_banner
  printf "${WHITE} 💻 Vamos Alterar os Dominios do Conecta...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local empresa="${empresa_dominio:-conecta}"

  sudo bash <<EOF
  cd && rm -rf /etc/nginx/sites-enabled/${empresa}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa}-backend
EOF

  sleep 2

  local app_instance_dir="/home/${DEPLOY_USER}/${empresa}"
  local alter_backend_port="${alter_backend_port:-${BACKEND_PORT}}"
  local alter_frontend_port="${alter_frontend_port:-${FRONTEND_PORT}}"

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/frontend"
  sed -i "1c\VITE_API_URL=https://${alter_backend_url}" .env 2>/dev/null || true
EOF

  sleep 2

  local backend_hostname=$(echo "${alter_backend_url/https:\/\/}")

  sudo bash <<EOF
  cat > /etc/nginx/sites-available/${empresa}-backend << 'END'
server {
  server_name ${backend_hostname};
  location /api {
    proxy_pass http://127.0.0.1:${alter_backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -sf /etc/nginx/sites-available/${empresa}-backend /etc/nginx/sites-enabled
EOF

  sleep 2

  local frontend_hostname=$(echo "${alter_frontend_url/https:\/\/}")

  sudo bash << EOF
cat > /etc/nginx/sites-available/${empresa}-frontend << 'END'
server {
  server_name ${frontend_hostname};
  location / {
    root ${app_instance_dir}/frontend/dist;
    try_files \$uri \$uri/ /index.html;
    index index.html;
  }
}
END
ln -sf /etc/nginx/sites-available/${empresa}-frontend /etc/nginx/sites-enabled
EOF

  sleep 2

  sudo bash <<EOF
  service nginx restart
EOF

  sleep 2

  sudo bash <<EOF
  certbot -m ${admin_email} \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains ${backend_hostname},${frontend_hostname} \
          --redirect
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Alteração de dominio da Instancia/Empresa ${empresa} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

