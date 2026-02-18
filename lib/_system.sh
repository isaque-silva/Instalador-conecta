#!/bin/bash
# 
# System management functions

#######################################
# Creates user
# Arguments:
#   None
#######################################
function system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para a instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if id "${DEPLOY_USER}" &>/dev/null; then
    print_info "Usuário ${DEPLOY_USER} já existe"
  else
    # Obter senha para o usuário
    local user_password="${mysql_root_password:-${postgres_password}}"
    
    # Criar usuário sem senha primeiro
    sudo useradd -m -s /bin/bash "${DEPLOY_USER}" || {
      print_error "Falha ao criar usuário ${DEPLOY_USER}"
      exit 1
    }
    
    # Adicionar ao grupo sudo
    sudo usermod -aG sudo "${DEPLOY_USER}" || {
      print_error "Falha ao adicionar usuário ao grupo sudo"
      exit 1
    }
    
    # Definir senha usando chpasswd (método mais confiável)
    echo "${DEPLOY_USER}:${user_password}" | sudo chpasswd || {
      print_error "Falha ao definir senha do usuário"
      exit 1
    }
    
    print_success "Usuário ${DEPLOY_USER} criado com sucesso"
  fi

  # Verificar se o usuário existe antes de criar diretório
  if ! id "${DEPLOY_USER}" &>/dev/null; then
    print_error "Usuário ${DEPLOY_USER} não existe após tentativa de criação"
    exit 1
  fi

  # Criar diretório da aplicação
  sudo mkdir -p "${APP_DIR}"
  sudo chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_DIR}"

  sleep 2
}

#######################################
# Clones repositories using git
# Arguments:
#   None
#######################################
function system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código Conecta...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

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
  elif [[ -n "${link_git}" ]]; then
    print_info "Clonando projeto do repositório: ${link_git}"
    echo ">>> Executando: git clone ${link_git} ${APP_DIR}"
    sudo -u "${DEPLOY_USER}" bash <<EOF
    git clone ${link_git} "${APP_DIR}"
EOF
  else
    print_info "Clonando projeto Conecta do repositório padrão: ${CONECTA_REPO}"
    echo ">>> Executando: git clone ${CONECTA_REPO} ${APP_DIR}"
    sudo -u "${DEPLOY_USER}" bash <<EOF
    git clone ${CONECTA_REPO} "${APP_DIR}"
EOF
    if [[ ! -d "${APP_DIR}/backend" ]] || [[ ! -d "${APP_DIR}/frontend" ]]; then
      print_error "Não foi possível encontrar o projeto (backend/ e frontend/)."
      print_error "Por favor, forneça o link do repositório quando solicitado."
      exit 1
    fi
  fi

  sleep 2
}

#######################################
# Updates system
# Arguments:
#   None
#######################################
function system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos atualizar o sistema Conecta...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  echo ">>> Executando: apt update"
  sudo apt -y update
  echo ">>> Executando: apt install (dependências do sistema)"
  sudo apt-get install -y git libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
  echo ""

  # Configurar locale pt_BR.UTF-8
  echo ">>> Configurando locale pt_BR.UTF-8"
  sudo locale-gen pt_BR.UTF-8 2>/dev/null || true
  sudo update-locale LANG=pt_BR.UTF-8 2>/dev/null || true
  echo ""

  sleep 2
}

#######################################
# Installs node
# Arguments:
#   None
#######################################
function system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if check_command node; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ $NODE_VERSION -ge 18 ]]; then
      print_info "Node.js já instalado (versão $(node -v))"
      return 0
    fi
  fi

  echo ">>> Executando: setup NodeSource (Node.js 20.x)"
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  echo ">>> Executando: apt install nodejs"
  sudo apt-get install -y nodejs
  sleep 2
  echo ">>> Executando: npm install -g npm@latest"
  sudo npm install -g npm@latest
  sleep 2
  echo ">>> Configurando timezone America/Sao_Paulo"
  sudo timedatectl set-timezone America/Sao_Paulo
  echo ""

  sleep 2
}

#######################################
# Installs pm2
# Arguments:
#   None
#######################################
function system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando pm2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if check_command pm2; then
    print_info "PM2 já instalado"
  else
    echo ">>> Executando: npm install -g pm2"
    sudo npm install -g pm2
    echo ""
  fi

  # Configurar PM2 para iniciar no boot
  echo ">>> Configurando PM2 para iniciar no boot do sistema"
  sudo -u "${DEPLOY_USER}" pm2 startup systemd -u "${DEPLOY_USER}" --hp "/home/${DEPLOY_USER}" 2>/dev/null || {
    # Se falhar, tentar sem especificar usuário
    sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u "${DEPLOY_USER}" --hp "/home/${DEPLOY_USER}" || true
  }
  echo ""

  sleep 2
}

#######################################
# Installs PostgreSQL
# Arguments:
#   None
#######################################
function system_postgresql_install() {
  print_banner
  printf "${WHITE} 💻 Instalando PostgreSQL...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if check_command psql; then
    print_info "PostgreSQL já instalado"
    return 0
  fi

  echo ">>> Adicionando repositório PostgreSQL"
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  echo ">>> Executando: apt install postgresql"
  sudo apt-get update -y && sudo apt-get -y install postgresql
  echo ">>> Aguardando serviço PostgreSQL"
  wait_for_service postgresql
  echo ""

  sleep 2
}

#######################################
# Installs nginx
# Arguments:
#   None
#######################################
function system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if check_command nginx; then
    print_info "Nginx já instalado"
    return 0
  fi

  echo ">>> Executando: apt install nginx"
  sudo apt install -y nginx
  sudo rm -f /etc/nginx/sites-enabled/default
  echo ">>> Aguardando serviço Nginx"
  wait_for_service nginx
  echo ""

  sleep 2
}

#######################################
# Installs certbot
# Arguments:
#   None
#######################################
function system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if check_command certbot; then
    print_info "Certbot já instalado"
    return 0
  fi

  echo ">>> Executando: apt install certbot python3-certbot-nginx"
  sudo apt install -y certbot python3-certbot-nginx
  echo ""

  sleep 2
}

#######################################
# Restarts nginx
# Arguments:
#   None
#######################################
function system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  echo ">>> Executando: systemctl restart nginx"
  sudo systemctl restart nginx
  echo ">>> Aguardando serviço Nginx"
  wait_for_service nginx
  echo ""

  sleep 2
}

#######################################
# Cria um único server block para instalação primária (um domínio).
# Necessário para o Certbot encontrar server_name e para / e /api funcionarem.
#######################################
function system_nginx_primary_sites() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend + frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local server_name="${domain:-_}"
  local backend_port_used="${BACKEND_PORT:-3001}"
  local app_dir="${APP_DIR:-/home/conecta/conecta}"

  echo ">>> Gerando /etc/nginx/sites-available/conecta (server_name=${server_name})"
  sudo tee /etc/nginx/sites-available/conecta > /dev/null << NGINXEOF
server {
  listen 80;
  server_name ${server_name};
  client_max_body_size 100M;

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
  location /api/media {
    alias ${app_dir}/backend/media;
    expires 30d;
    add_header Cache-Control "public, immutable";
  }
  location / {
    root ${app_dir}/frontend/dist;
    try_files \$uri \$uri/ /index.html;
    index index.html;
  }
}
NGINXEOF
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo ln -sf /etc/nginx/sites-available/conecta /etc/nginx/sites-enabled

  if sudo nginx -t; then
    print_success "Configuração do Nginx válida"
  else
    print_error "Erro na configuração do Nginx"
    exit 1
  fi
  echo ""
  sleep 2
}

#######################################
# Setup for nginx.conf
# Arguments:
#   None
#######################################
function system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  echo ">>> Configurando /etc/nginx/conf.d/deploy.conf"
  sudo bash << EOF
cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END
EOF
  echo ""

  sleep 2
}

#######################################
# Setup certbot
# Arguments:
#   None
#######################################
function system_certbot_setup() {
  if [[ -z "$domain" ]] || [[ "$domain" == "_" ]]; then
    print_warning "Domínio não configurado, pulando configuração SSL"
    return 0
  fi

  print_banner
  printf "${WHITE} 💻 Configurando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  echo ">>> Executando: certbot --nginx para ${domain}"
  sudo certbot -m ${admin_email} \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains ${domain} \
          --redirect
  echo ""

  # Configurar renovação automática
  sudo systemctl enable certbot.timer
  sudo systemctl start certbot.timer

  sleep 2
}

#######################################
# Configura firewall UFW
# Arguments:
#   None
#######################################
function system_firewall_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando firewall (UFW)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if ! check_command ufw; then
    echo ">>> Instalando UFW"
    sudo apt-get install -y ufw
  fi

  echo ">>> Configurando regras do firewall"
  # Permitir SSH (porta 22) - importante fazer primeiro
  sudo ufw allow 22/tcp comment 'SSH' 2>/dev/null || true
  # Permitir HTTP (porta 80)
  sudo ufw allow 80/tcp comment 'HTTP' 2>/dev/null || true
  # Permitir HTTPS (porta 443)
  sudo ufw allow 443/tcp comment 'HTTPS' 2>/dev/null || true
  
  # Habilitar firewall se não estiver habilitado
  if ! sudo ufw status | grep -q "Status: active"; then
    echo ">>> Habilitando firewall (UFW)"
    echo "y" | sudo ufw enable 2>/dev/null || sudo ufw --force enable
  else
    print_info "Firewall já está ativo"
  fi
  
  echo ""
  sudo ufw status
  echo ""

  sleep 2
}

#######################################
# Configura limites do sistema para o usuário conecta
# Arguments:
#   None
#######################################
function system_limits_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando limites do sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  echo ">>> Configurando limites do sistema para ${DEPLOY_USER}"
  sudo tee /etc/security/limits.d/conecta.conf > /dev/null << LIMITSEOF
${DEPLOY_USER} soft nofile 65536
${DEPLOY_USER} hard nofile 65536
${DEPLOY_USER} soft nproc 32768
${DEPLOY_USER} hard nproc 32768
LIMITSEOF
  echo "Limites configurados: nofile=65536, nproc=32768"
  echo ""

  sleep 2
}

#######################################
# Verificação final pós-instalação
# Arguments:
#   None
#######################################
function system_post_install_check() {
  print_banner
  printf "${WHITE} ✅ Verificação final da instalação...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local errors=0
  local warnings=0

  echo ">>> Verificando serviços..."
  
  # Verificar PostgreSQL
  if systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL está rodando"
  else
    print_error "PostgreSQL NÃO está rodando"
    ((errors++))
  fi
  
  # Verificar Nginx
  if systemctl is-active --quiet nginx; then
    print_success "Nginx está rodando"
  else
    print_error "Nginx NÃO está rodando"
    ((errors++))
  fi
  
  # Verificar PM2
  if sudo -u "${DEPLOY_USER}" pm2 list &>/dev/null; then
    print_success "PM2 está configurado"
    echo ""
    echo ">>> Processos PM2:"
    sudo -u "${DEPLOY_USER}" pm2 list
  else
    print_warning "PM2 não está configurado corretamente"
    ((warnings++))
  fi
  
  # Verificar se o backend está rodando no PM2
  if sudo -u "${DEPLOY_USER}" pm2 list | grep -q "conecta-backend.*online"; then
    print_success "Backend está rodando no PM2"
  else
    print_warning "Backend NÃO está rodando no PM2"
    ((warnings++))
  fi
  
  # Verificar se o diretório frontend/dist existe
  if [[ -d "${APP_DIR}/frontend/dist" ]]; then
    print_success "Frontend compilado encontrado"
  else
    print_warning "Frontend não foi compilado ou não encontrado"
    ((warnings++))
  fi
  
  # Verificar configuração do Nginx
  if sudo nginx -t &>/dev/null; then
    print_success "Configuração do Nginx é válida"
  else
    print_error "Configuração do Nginx tem erros"
    ((errors++))
  fi
  
  echo ""
  if [[ $errors -eq 0 ]] && [[ $warnings -eq 0 ]]; then
    print_success "Instalação concluída com sucesso!"
  elif [[ $errors -eq 0 ]]; then
    print_warning "Instalação concluída com $warnings aviso(s)"
  else
    print_error "Instalação concluída com $errors erro(s) e $warnings aviso(s)"
  fi
  
  echo ""
  echo "=============================================="
  echo "  INFORMAÇÕES IMPORTANTES"
  echo "=============================================="
  echo ""
  echo "📁 Diretório da aplicação: ${APP_DIR}"
  echo "👤 Usuário: ${DEPLOY_USER}"
  echo "🌐 Domínio: ${domain:-Não configurado}"
  echo ""
  if [[ -n "$domain" ]] && [[ "$domain" != "_" ]]; then
    echo "🔗 Acesse: https://${domain}"
  else
    echo "🔗 Acesse: http://$(hostname -I | awk '{print $1}')"
  fi
  echo ""
  echo "📋 Comandos úteis:"
  echo "  - Ver logs do backend: sudo -u ${DEPLOY_USER} pm2 logs conecta-backend"
  echo "  - Reiniciar backend: sudo -u ${DEPLOY_USER} pm2 restart conecta-backend"
  echo "  - Status dos serviços: sudo systemctl status nginx postgresql"
  echo ""
  
  sleep 2
}

#######################################
# Delete system
# Arguments:
#   None
#######################################
function deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos deletar o Conecta...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local empresa="${empresa_delete:-conecta}"

  sudo bash <<EOF
  cd && rm -rf /etc/nginx/sites-enabled/${empresa}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa}-backend
EOF

  sleep 2

  sudo -u postgres bash <<EOF
  dropuser ${empresa} 2>/dev/null || true
  dropdb ${empresa} 2>/dev/null || true
EOF

  sleep 2

  sudo -u "${DEPLOY_USER}" bash <<EOF
  rm -rf /home/${DEPLOY_USER}/${empresa}
  pm2 delete ${empresa}-frontend ${empresa}-backend 2>/dev/null || true
  pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instancia/Empresa ${empresa} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# Block system
# Arguments:
#   None
#######################################
function configurar_bloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos bloquear o Conecta...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local empresa="${empresa_bloquear:-conecta}"

  sudo -u "${DEPLOY_USER}" bash <<EOF
  pm2 stop ${empresa}-backend
  pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Bloqueio da Instancia/Empresa ${empresa} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# Unblock system
# Arguments:
#   None
#######################################
function configurar_desbloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos Desbloquear o Conecta...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  local empresa="${empresa_desbloquear:-conecta}"

  sudo -u "${DEPLOY_USER}" bash <<EOF
  pm2 start ${empresa}-backend
  pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Desbloqueio da Instancia/Empresa ${empresa} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

