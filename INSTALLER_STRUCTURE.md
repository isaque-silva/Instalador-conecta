# Estrutura do Instalador Conecta

Este documento descreve a estrutura modular do instalador automático do Conecta, baseado na arquitetura do instalador Whaticket SaaS.

## Estrutura de Diretórios

```
Conecta/
├── install_primaria          # Script principal para primeira instalação
├── install_instancia        # Script para instalar novas instâncias
├── config                    # Arquivo de configuração com senhas (gerado automaticamente)
├── variables/               # Variáveis e configurações
│   ├── manifest.sh          # Carrega todos os arquivos de variáveis
│   ├── _app.sh              # Variáveis da aplicação (JWT, DB, paths, ports)
│   ├── _general.sh          # Variáveis gerais (cores)
│   ├── _background.sh        # Cores de fundo
│   └── _fonts.sh            # Cores e estilos de fonte
├── utils/                   # Utilitários
│   ├── manifest.sh          # Carrega utilitários
│   └── _banner.sh           # Função para exibir banner ASCII
└── lib/                     # Bibliotecas de funções
    ├── manifest.sh          # Carrega todas as bibliotecas
    ├── _system.sh           # Funções do sistema (instalações, nginx, etc)
    ├── _backend.sh          # Funções do backend
    ├── _frontend.sh         # Funções do frontend
    └── _inquiry.sh          # CLI interativo e coleta de dados
```

## Fluxo de Execução

### 1. Script Principal (`install_primaria` ou `install_instancia`)

- Define `PROJECT_ROOT` (diretório do script)
- Carrega os manifests:
  - `variables/manifest.sh` → carrega variáveis
  - `utils/manifest.sh` → carrega utilitários
  - `lib/manifest.sh` → carrega funções
- Cria/verifica arquivo `config` com senhas
- Protege `config` (chmod 700, root:root)
- Executa `inquiry_options()` para menu interativo

### 2. Menu Interativo (`lib/_inquiry.sh`)

Opções disponíveis:
- **[0] Instalar Conecta** - Instalação completa (primeira vez)
- **[1] Atualizar Conecta** - Atualiza código e dependências
- **[2] Deletar Conecta** - Remove instância completamente
- **[3] Bloquear Conecta** - Para backend (bloqueia acesso)
- **[4] Desbloquear Conecta** - Reativa backend
- **[5] Alterar domínio Conecta** - Altera domínios e configura SSL

### 3. Processo de Instalação (opção 0)

#### A. Coleta de Dados (`inquiry_options()`):
- Domínio (opcional para SSL)
- E-mail do administrador padrão
- Senha do administrador padrão
- Senha do PostgreSQL (ou gerar automaticamente)
- JWT Secret (ou gerar automaticamente)

#### B. Dependências do Sistema (`lib/_system.sh`):
- `system_update()` - Atualiza sistema e instala dependências básicas
- `system_node_install()` - Instala Node.js 20.x, configura timezone
- `system_pm2_install()` - Instala PM2 globalmente
- `system_postgresql_install()` - Instala PostgreSQL
- `system_nginx_install()` - Instala e configura Nginx
- `system_certbot_install()` - Instala Certbot

#### C. Configuração do Sistema:
- `system_create_user()` - Cria usuário `conecta` com sudo

#### D. Backend (`lib/_backend.sh`):
- `system_git_clone()` - Copia projeto para `/home/conecta/conecta`
- `backend_set_env()` - Cria arquivo `.env` do backend
- `backend_db_create()` - Cria banco PostgreSQL
- `backend_node_dependencies()` - `npm install`
- `backend_node_build()` - `npm run build`
- `backend_db_migrate()` - `npx prisma migrate deploy` ou `db push`
- `backend_db_seed()` - Seed será executado na primeira inicialização
- `backend_start_pm2()` - Inicia backend com PM2
- `backend_nginx_setup()` - Configura Nginx para backend

#### E. Frontend (`lib/_frontend.sh`):
- `frontend_set_env()` - Cria `.env` do frontend
- `frontend_node_dependencies()` - `npm install`
- `frontend_node_build()` - `npm run build`
- `frontend_start_pm2()` - Frontend servido pelo Nginx
- `frontend_nginx_setup()` - Configura Nginx para frontend

#### F. Rede:
- `system_nginx_conf()` - Configura `client_max_body_size`
- `system_nginx_restart()` - Reinicia Nginx
- `system_certbot_setup()` - Configura SSL com Let's Encrypt

## Características Importantes

1. **Modularidade**: Código organizado em módulos por responsabilidade
2. **Segurança**: Senhas em arquivo protegido (`config`)
3. **Idempotência**: Validação de URLs e configurações
4. **Interatividade**: CLI com menu e prompts
5. **Gerenciamento**: Funções para atualizar, deletar, bloquear e alterar domínios
6. **Suporte Multi-instância**: Suporta múltiplas instâncias (via `install_instancia`)

## Diferenças entre Scripts

- **`install_primaria`**: Instala todas as dependências do sistema (primeira instalação)
- **`install_instancia`**: Foca apenas na instalação da aplicação (assume dependências já instaladas)

## Variáveis Principais

Definidas em `variables/_app.sh`:
- `DEPLOY_USER`: usuário do sistema (padrão: `conecta`)
- `APP_DIR`: diretório da aplicação (padrão: `/home/conecta/conecta`)
- `BACKEND_PORT`: porta do backend (padrão: `3001`)
- `FRONTEND_PORT`: porta do frontend (padrão: `3000`)
- `POSTGRES_USER`: usuário do PostgreSQL (padrão: `conecta`)
- `POSTGRES_DB`: nome do banco (padrão: `conecta`)

## Uso

### Instalação Inicial:
```bash
sudo chmod +x install_primaria
sudo ./install_primaria
```

### Instalar Nova Instância:
```bash
sudo chmod +x install_instancia
sudo ./install_instancia
```

## Notas

- O arquivo `config` é gerado automaticamente e contém senhas sensíveis
- Todas as funções usam `print_banner()` para exibir banner ASCII
- O sistema suporta instalação com ou sem domínio (SSL opcional)
- O frontend é servido diretamente pelo Nginx (não usa PM2)
- O backend usa PM2 para gerenciamento de processos
