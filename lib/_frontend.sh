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

  # Base da URL da API: backend_domain (HTTPS) ou domain (legacy) ou localhost
  local api_url
  if [[ -n "${backend_domain}" ]]; then
    api_url="https://${backend_domain}"
  elif [[ -n "$domain" ]] && [[ "$domain" != "_" ]]; then
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

  # Preparar variáveis de ambiente para autenticação Git
  local env_prefix=""
  if [[ -n "${GIT_ASKPASS:-}" ]] && [[ -f "${GIT_ASKPASS:-}" ]]; then
    env_prefix="GIT_ASKPASS=${GIT_ASKPASS} GIT_TERMINAL_PROMPT=0"
  fi

  # 1) Atualizar código via git pull (pode já ter sido feito no backend_update)
  # git stash para garantir que alterações locais (package-lock.json) não bloqueiem o pull
  echo ">>> [1/5] Executando: git stash + git pull (frontend)"
  sudo -u "${DEPLOY_USER}" bash -c "cd ${app_instance_dir} && git stash 2>/dev/null || true"
  sudo -u "${DEPLOY_USER}" bash -c "cd ${app_instance_dir} && ${env_prefix} git pull" 2>/dev/null || true
  sudo -u "${DEPLOY_USER}" bash -c "cd ${app_instance_dir} && git stash drop 2>/dev/null || true"

  # 2) Instalar dependências
  echo ">>> [2/5] Executando: npm install (frontend)"
  sudo -u "${DEPLOY_USER}" bash -c "cd ${app_instance_dir}/frontend && npm install"

  # 3) Compilar o frontend
  echo ">>> [3/5] Executando: npm run build (frontend)"
  sudo -u "${DEPLOY_USER}" bash -c "cd ${app_instance_dir}/frontend && rm -rf dist && npm run build"
  if [[ $? -ne 0 ]]; then
    printf "${RED} ERRO: build do frontend falhou!${GRAY_LIGHT}\n"
    return 1
  fi

  # 4) Ajustar permissões para o Nginx (www-data) ler os novos arquivos
  echo ">>> [4/5] Ajustando permissões para Nginx"
  sudo chmod o+x /home/${DEPLOY_USER} 2>/dev/null || true
  sudo chmod o+x ${app_instance_dir} 2>/dev/null || true
  sudo chmod o+x ${app_instance_dir}/frontend 2>/dev/null || true
  sudo chmod o+x ${app_instance_dir}/frontend/dist 2>/dev/null || true
  sudo chmod -R o+rX ${app_instance_dir}/frontend/dist 2>/dev/null || true
  sudo chmod o+x ${app_instance_dir}/backend 2>/dev/null || true
  sudo chmod o+x ${app_instance_dir}/backend/media 2>/dev/null || true
  sudo chmod -R o+rX ${app_instance_dir}/backend/media 2>/dev/null || true

  # 5) Reiniciar Nginx para servir os novos arquivos
  echo ">>> [5/5] Reiniciando Nginx"
  sudo systemctl restart nginx

  printf "\n${GREEN} ✅ Frontend atualizado com sucesso!${GRAY_LIGHT}\n\n"
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

  local empresa="conecta"
  # Normaliza domínio do frontend (remove protocolo e barra final)
  local frontend_hostname
  frontend_hostname=$(echo "${alter_frontend_url}" | sed -e 's|^https\?://||' -e 's|/.*||' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ -z "${frontend_hostname}" ]]; then
    printf "${RED}Erro: domínio do frontend não informado.${GRAY_LIGHT}\n\n"
    return 1
  fi
  # Backend: usar alter_backend_domain se informado, senão derivar api.<domínio base>
  local backend_hostname
  local backend_domain_norm
  backend_domain_norm=$(echo "${alter_backend_domain:-}" | sed -e 's|^https\?://||' -e 's|/.*||' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ -n "${backend_domain_norm}" ]]; then
    backend_hostname="${backend_domain_norm}"
  else
    local base_domain
    if [[ "${frontend_hostname}" == *.*.* ]]; then
      base_domain="${frontend_hostname#*.}"
    else
      base_domain="${frontend_hostname}"
    fi
    backend_hostname="api.${base_domain}"
  fi
  local alter_backend_url="https://${backend_hostname}"
  local alter_backend_port="${BACKEND_PORT:-3001}"
  local alter_frontend_port="${FRONTEND_PORT:-3000}"
  local app_instance_dir="/home/${DEPLOY_USER}/${empresa}"

  # Remove ALL old Conecta nginx configs (single-block "conecta", two-block "conecta-frontend/backend", and any Certbot SSL variants)
  # so only the new domains are served (old domains stop working)
  sudo bash <<EOF
  sudo rm -f /etc/nginx/sites-enabled/conecta*
  sudo rm -f /etc/nginx/sites-available/conecta*
EOF

  sleep 2

  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/frontend"
  sed -i "1c\VITE_API_URL=${alter_backend_url}" .env 2>/dev/null || true
EOF

  sleep 2

  # Rebuild frontend so the new backend URL is baked into the JS (Vite embeds VITE_API_URL at build time)
  # Otherwise login/API/WebSocket keep using the old domain and cause ERR_CERT_COMMON_NAME_INVALID
  printf "${WHITE} 💻 Recompilando o frontend com o novo domínio da API...${GRAY_LIGHT}\n\n"
  sudo -u "${DEPLOY_USER}" bash <<EOF
  cd "${app_instance_dir}/frontend"
  npm run build
EOF

  sleep 2

  sudo bash <<EOF
  cat > /etc/nginx/sites-available/${empresa}-backend << 'NGINXEND'
server {
  server_name ${backend_hostname};
  client_max_body_size 100M;
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
  location /socket.io {
    proxy_pass http://127.0.0.1:${alter_backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
  location /api/media {
    alias ${app_instance_dir}/backend/media;
    expires 30d;
    add_header Cache-Control "public, immutable";
  }
}
NGINXEND
ln -sf /etc/nginx/sites-available/${empresa}-backend /etc/nginx/sites-enabled
EOF

  sleep 2

  sudo bash << EOF
cat > /etc/nginx/sites-available/${empresa}-frontend << 'NGINXEND'
server {
  server_name ${frontend_hostname};
  location / {
    root ${app_instance_dir}/frontend/dist;
    try_files \$uri \$uri/ /index.html;
    index index.html;
  }
}
NGINXEND
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

