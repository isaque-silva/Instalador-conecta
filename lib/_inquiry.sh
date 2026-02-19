#!/bin/bash
#
# Interactive CLI and data collection functions

function get_mysql_root_password() {
  print_banner
  printf "${WHITE} 💻 Insira senha para o usuario Deploy e Banco de Dados (Não utilizar caracteres especiais):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " mysql_root_password
}

function get_link_git() {
  print_banner
  printf "${WHITE} 💻 Insira o link do GITHUB do Conecta que deseja instalar (ou pressione Enter para usar o projeto atual):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " link_git
  link_git="${link_git:-}"
}

function get_instancia_add() {
  print_banner
  printf "${WHITE} 💻 Informe um nome para a Instancia/Empresa que será instalada (Não utilizar espaços ou caracteres especiais, Utilizar Letras minusculas):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " instancia_add
}

function get_max_whats() {
  print_banner
  printf "${WHITE} 💻 Informe a Qtde de Conexões/Whats que a ${instancia_add} poderá cadastrar:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " max_whats
}

function get_max_user() {
  print_banner
  printf "${WHITE} 💻 Informe a Qtde de Usuarios/Atendentes que a ${instancia_add} poderá cadastrar:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " max_user
}

function get_frontend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do FRONTEND/PAINEL para a ${instancia_add} (ou pressione Enter para usar IP):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " frontend_url
}

function get_backend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do BACKEND/API para a ${instancia_add} (ou pressione Enter para usar IP):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " backend_url
}

function get_frontend_port() {
  print_banner
  printf "${WHITE} 💻 Digite a porta do FRONTEND para a ${instancia_add}; Ex: 3000 A 3999 ${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " frontend_port
}

function get_backend_port() {
  print_banner
  printf "${WHITE} 💻 Digite a porta do BACKEND para esta instancia; Ex: 4000 A 4999 ${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " backend_port
}

function get_redis_port() {
  print_banner
  printf "${WHITE} 💻 Digite a porta do REDIS para a ${instancia_add}; Ex: 5000 A 5999 ${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " redis_port
}

function get_empresa_delete() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que será Deletada (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_delete
}

function get_empresa_atualizar() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Atualizar (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_atualizar
}

function get_empresa_bloquear() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Bloquear (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_bloquear
}

function get_empresa_desbloquear() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Desbloquear (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_desbloquear
}

function get_novo_dominio_frontend() {
  print_banner
  printf "${WHITE} 💻 Digite o NOVO domínio do FRONTEND/PAINEL (ex: app.conectazap.net):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_frontend_url
}

function get_novo_dominio_backend() {
  print_banner
  printf "${WHITE} 💻 Digite o NOVO domínio do BACKEND/API (ex: api.conectazap.net) ou Enter para derivar do frontend:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_backend_domain
}

function get_git_credentials_for_update() {
  print_banner
  printf "${WHITE} 💻 Credenciais GitHub (usadas em backend e frontend para git pull):${GRAY_LIGHT}"
  printf "\n\n"
  if [[ -z "${git_user}" ]]; then
    read -p "Usuário GitHub (ou Enter para repositório público): " git_user_input
    git_user="${git_user_input:-}"
  else
    read -p "Usuário GitHub [${git_user}] ou Enter para manter: " git_user_input
    git_user="${git_user_input:-${git_user}}"
  fi
  if [[ -n "${git_user}" ]]; then
    read -sp "Senha ou token GitHub: " git_password_input
    echo
    git_password="${git_password_input:-${git_password}}"
  else
    git_password=""
  fi
  if [[ -n "${git_user}" ]] && [[ -n "${git_password}" ]]; then
    GIT_ASKPASS_SCRIPT=$(mktemp /tmp/git-askpass-conecta.XXXXXX)
    GIT_CRED_USER=$(mktemp /tmp/git-cred-user.XXXXXX)
    GIT_CRED_PASS=$(mktemp /tmp/git-cred-pass.XXXXXX)
    echo "${git_user}" > "${GIT_CRED_USER}"
    echo "${git_password}" > "${GIT_CRED_PASS}"
    chmod 644 "${GIT_CRED_USER}" "${GIT_CRED_PASS}"
    cat > "${GIT_ASKPASS_SCRIPT}" << ASKPASSEOF
#!/bin/sh
case "\$1" in
  *[Uu]sername*) cat "${GIT_CRED_USER}" 2>/dev/null ;;
  *[Pp]assword*) cat "${GIT_CRED_PASS}" 2>/dev/null ;;
esac
ASKPASSEOF
    chmod 755 "${GIT_ASKPASS_SCRIPT}"
    export GIT_ASKPASS="${GIT_ASKPASS_SCRIPT}"
    export GIT_ASKPASS_SCRIPT GIT_CRED_USER GIT_CRED_PASS
  else
    unset GIT_ASKPASS GIT_ASKPASS_SCRIPT GIT_CRED_USER GIT_CRED_PASS
  fi
}

function cleanup_git_credentials_temp() {
  [[ -n "${GIT_ASKPASS_SCRIPT}" ]] && [[ -f "${GIT_ASKPASS_SCRIPT}" ]] && rm -f "${GIT_ASKPASS_SCRIPT}"
  [[ -n "${GIT_CRED_USER}" ]] && [[ -f "${GIT_CRED_USER}" ]] && rm -f "${GIT_CRED_USER}"
  [[ -n "${GIT_CRED_PASS}" ]] && [[ -f "${GIT_CRED_PASS}" ]] && rm -f "${GIT_CRED_PASS}"
}

function config_save_git_credentials() {
  local cf="${PROJECT_ROOT:-.}/config"
  if [[ -f "$cf" ]]; then
    grep -v '^git_user=' "$cf" 2>/dev/null | grep -v '^git_password=' > "$cf.tmp" || true
    echo "git_user=${git_user}" >> "$cf.tmp"
    echo "git_password=${git_password}" >> "$cf.tmp"
    sudo tee "$cf" < "$cf.tmp" > /dev/null
    sudo chown root:root "$cf"
    sudo chmod 700 "$cf"
    rm -f "$cf.tmp"
  fi
}

function get_urls() {
  get_mysql_root_password
  get_link_git
  get_instancia_add
  get_max_whats
  get_max_user
  get_frontend_url
  get_backend_url
  get_frontend_port
  get_backend_port
  get_redis_port
}

function inquiry_options() {
  print_banner
  printf "${WHITE} 💻 Bem vindo(a) ao Gerenciador Conecta SaaS, Selecione abaixo a proxima ação!${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [0] Instalar Conecta\n"
  printf "   [1] Atualizar Conecta\n"
  printf "   [2] Deletar Conecta\n"
  printf "   [3] Bloquear Conecta\n"
  printf "   [4] Desbloquear Conecta\n"
  printf "   [5] Alterar dominio Conecta\n"
  printf "\n"
  read -p "> " option

  case "${option}" in
    0) 
      # Para instalação simples (não multi-instância), usar valores padrão
      if [[ -z "${instancia_add}" ]]; then
        instancia_add="conecta"
        backend_port="${BACKEND_PORT}"
        frontend_port="${FRONTEND_PORT}"
        redis_port="6379"
        domain="${domain:-}"
        admin_email="${admin_email:-admin@conecta.local}"
        admin_password="${admin_password:-Admin@123}"
        admin_name="${admin_name:-Administrador}"
        
        # Gerar senhas se não existirem
        if [[ -z "${postgres_password}" ]]; then
          postgres_password="$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)"
        fi
        if [[ -z "${jwt_secret}" ]]; then
          jwt_secret="$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)"
        fi
        if [[ -z "${deploy_password}" ]]; then
          deploy_password="$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)"
        fi
        
        # Coletar informações básicas (domínios para HTTPS: frontend e backend separados)
        read -p "Digite o domínio do FRONTEND (ex: app.conectazap.net) ou Enter para pular SSL: " frontend_domain_input
        frontend_domain="${frontend_domain_input:-}"
        read -p "Digite o domínio do BACKEND (ex: api.conectazap.net) ou Enter para derivar do frontend: " backend_domain_input
        backend_domain="${backend_domain_input:-}"
        if [[ -n "${frontend_domain}" ]] && [[ -z "${backend_domain}" ]]; then
          base_d=""
          if [[ "${frontend_domain}" == *.*.* ]]; then base_d="${frontend_domain#*.}"; else base_d="${frontend_domain}"; fi
          backend_domain="api.${base_d}"
        fi
        domain="${frontend_domain:-${domain}}"

        read -p "E-mail do administrador padrão [${admin_email}]: " admin_email_input
        admin_email="${admin_email_input:-${admin_email}}"
        
        read -sp "Senha do administrador padrão [${admin_password}]: " admin_password_input
        echo
        admin_password="${admin_password_input:-${admin_password}}"
        
        # Perguntar sobre repositório Git (opcional)
        read -p "Link do repositório Git do Conecta (ou Enter para usar padrão): " link_git_input
        link_git="${link_git_input:-}"
        
        mysql_root_password="${postgres_password}"
      else
        get_urls
      fi
      ;;
    1) 
      get_git_credentials_for_update
      config_save_git_credentials
      backend_update
      frontend_update
      cleanup_git_credentials_temp
      exit
      ;;
    2) 
      get_empresa_delete
      deletar_tudo
      exit
      ;;
    3) 
      get_empresa_bloquear
      configurar_bloqueio
      exit
      ;;
    4) 
      get_empresa_desbloquear
      configurar_desbloqueio
      exit
      ;;
    5) 
      get_novo_dominio_frontend
      get_novo_dominio_backend
      configurar_dominio
      exit
      ;;        
    *) exit ;;
  esac
}
