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
    # Clonar projeto do link fornecido
    print_info "Clonando projeto do repositório: ${link_git}"
    sudo -u "${DEPLOY_USER}" bash <<EOF
    git clone ${link_git} "${APP_DIR}"
EOF
  else
    # Tentar clonar do repositório padrão do Conecta
    print_info "Clonando projeto Conecta do repositório padrão: ${CONECTA_REPO}"
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

  sudo apt -y update
  sudo apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils

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

  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  sleep 2
  sudo npm install -g npm@latest
  sleep 2
  sudo timedatectl set-timezone America/Sao_Paulo

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
    return 0
  fi

  sudo npm install -g pm2

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

  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update -y && sudo apt-get -y install postgresql

  wait_for_service postgresql

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

  sudo apt install -y nginx
  sudo rm -f /etc/nginx/sites-enabled/default

  wait_for_service nginx

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

  sudo apt install -y certbot python3-certbot-nginx

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

  sudo systemctl restart nginx
  wait_for_service nginx

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

  sudo bash << EOF
cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END
EOF

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

  sudo certbot -m ${admin_email} \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains ${domain} \
          --redirect

  # Configurar renovação automática
  sudo systemctl enable certbot.timer
  sudo systemctl start certbot.timer

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

