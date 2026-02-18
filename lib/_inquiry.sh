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

function get_empresa_dominio() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Alterar os Dominios:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_dominio
}

function get_alter_frontend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o NOVO domínio do FRONTEND/PAINEL para a ${empresa_dominio}:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_frontend_url
}

function get_alter_backend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o NOVO domínio do BACKEND/API para a ${empresa_dominio}:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_backend_url
}

function get_alter_frontend_port() {
  print_banner
  printf "${WHITE} 💻 Digite a porta do FRONTEND da Instancia/Empresa ${empresa_dominio}; A porta deve ser o mesma informada durante a instalação ${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_frontend_port
}

function get_alter_backend_port() {
  print_banner
  printf "${WHITE} 💻 Digite a porta do BACKEND da Instancia/Empresa ${empresa_dominio}; A porta deve ser o mesma informada durante a instalação ${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_backend_port
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
  printf "   [5] Alter. dominio Conecta\n"
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
        
        # Coletar informações básicas
        read -p "Digite o domínio (ex: conecta.exemplo.com) ou pressione Enter para pular SSL: " domain_input
        domain="${domain_input:-}"
        
        read -p "E-mail do administrador padrão [${admin_email}]: " admin_email_input
        admin_email="${admin_email_input:-${admin_email}}"
        
        read -sp "Senha do administrador padrão [${admin_password}]: " admin_password_input
        echo
        admin_password="${admin_password_input:-${admin_password}}"
        
        mysql_root_password="${postgres_password}"
      else
        get_urls
      fi
      ;;
    1) 
      get_empresa_atualizar
      backend_update
      frontend_update
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
      get_empresa_dominio
      get_alter_frontend_url
      get_alter_backend_url
      get_alter_frontend_port
      get_alter_backend_port
      configurar_dominio
      exit
      ;;        
    *) exit ;;
  esac
}
