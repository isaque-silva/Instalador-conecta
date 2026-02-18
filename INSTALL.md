# Instalador Automático - Conecta

Este instalador automatiza a instalação completa do Conecta em um servidor Ubuntu/Debian.

## Pré-requisitos

- Sistema operacional: Ubuntu 20.04+ ou Debian 11+
- Acesso root ou sudo
- Conexão com internet

## Instalação Rápida

```bash
sudo apt install -y git && \
git clone https://github.com/isaque-silva/conecta.git install && \
sudo chmod -R 777 ./install && \
cd ./install && \
sudo ./install_primaria
```

## O que o instalador faz

1. **Atualiza o sistema** (apt update && apt upgrade)
2. **Instala dependências**:
   - Node.js 20.x
   - PM2 (gerenciador de processos)
   - PostgreSQL
   - Nginx
   - Certbot (para SSL)
3. **Configura o sistema**:
   - Cria usuário `conecta` para deploy
   - Clona/copia o projeto para `/home/conecta/conecta`
4. **Configura o backend**:
   - Cria arquivo `.env` com variáveis de ambiente
   - Cria banco de dados PostgreSQL
   - Instala dependências npm
   - Compila TypeScript
   - Executa migrations do Prisma
   - Inicia com PM2
5. **Configura o frontend**:
   - Cria arquivo `.env` com URL da API
   - Instala dependências npm
   - Compila para produção
6. **Configura Nginx**:
   - Configura proxy reverso para API
   - Serve arquivos estáticos do frontend
   - Configura WebSocket para Socket.IO
   - Configura SSL com Certbot (se domínio fornecido)

## Configuração Interativa

Durante a instalação, o script solicitará:

- **Domínio**: Domínio do servidor (ex: `conecta.exemplo.com`) - opcional, pode pular para instalar sem SSL
- **E-mail do administrador**: E-mail do usuário admin padrão (padrão: `admin@conecta.local`)
- **Senha do administrador**: Senha do usuário admin padrão (padrão: `Admin@123`)
- **Senha do PostgreSQL**: Senha do banco de dados (gerada automaticamente se não informada)
- **JWT Secret**: Chave secreta para tokens JWT (gerada automaticamente se não informada)

## Estrutura de Arquivos

```
install/
├── install_primaria          # Script principal
├── variables/
│   └── manifest.sh          # Variáveis padrão
├── utils/
│   └── manifest.sh          # Funções utilitárias
├── lib/
│   └── manifest.sh          # Funções principais
└── config                    # Arquivo de configuração (criado durante instalação)
```

## Arquivo de Configuração

O arquivo `config` é criado durante a instalação e contém senhas e configurações sensíveis. Ele é protegido com permissões 700 e propriedade root.

## Pós-instalação

Após a instalação:

1. **Acesse o sistema**:
   - Com domínio: `https://seu-dominio.com`
   - Sem domínio: `http://IP_DO_SERVIDOR`

2. **Login inicial**:
   - Use as credenciais configuradas durante a instalação

3. **Gerenciar processos**:
   ```bash
   sudo -u conecta pm2 list          # Listar processos
   sudo -u conecta pm2 logs           # Ver logs
   sudo -u conecta pm2 restart all    # Reiniciar tudo
   ```

4. **Ver logs do backend**:
   ```bash
   sudo -u conecta pm2 logs conecta-backend
   ```

5. **Verificar status dos serviços**:
   ```bash
   sudo systemctl status nginx
   sudo systemctl status postgresql
   ```

## Troubleshooting

### Backend não inicia
- Verifique os logs: `sudo -u conecta pm2 logs conecta-backend`
- Verifique se o PostgreSQL está rodando: `sudo systemctl status postgresql`
- Verifique o arquivo `.env` em `/home/conecta/conecta/backend/.env`

### Frontend não carrega
- Verifique se o build foi feito: `ls -la /home/conecta/conecta/frontend/dist`
- Verifique os logs do Nginx: `sudo tail -f /var/log/nginx/error.log`
- Verifique a configuração do Nginx: `sudo nginx -t`

### Erro de permissões
- Certifique-se de que o usuário `conecta` tem acesso aos diretórios:
  ```bash
  sudo chown -R conecta:conecta /home/conecta/conecta
  ```

### Reinstalar
Para reinstalar, remova o diretório e execute novamente:
```bash
sudo rm -rf /home/conecta/conecta
sudo ./install_primaria
```

## Variáveis de Ambiente

O backend usa as seguintes variáveis (em `/home/conecta/conecta/backend/.env`):

- `DATABASE_URL`: String de conexão PostgreSQL
- `JWT_SECRET`: Chave secreta para tokens JWT
- `PORT`: Porta do backend (padrão: 3001)
- `CORS_ORIGIN`: Origem permitida para CORS
- `DEFAULT_ADMIN_EMAIL`: E-mail do admin padrão
- `DEFAULT_ADMIN_PASSWORD`: Senha do admin padrão
- `DEFAULT_ADMIN_NAME`: Nome do admin padrão
- `MEDIA_PATH`: Caminho para arquivos de mídia
- `AUTH_SESSIONS_PATH`: Caminho para sessões do Baileys

O frontend usa (em `/home/conecta/conecta/frontend/.env`):

- `VITE_API_URL`: URL da API (configurada automaticamente)

## Atualização

Para atualizar o código:

```bash
cd /home/conecta/conecta
sudo -u conecta git pull
sudo -u conecta pm2 restart conecta-backend
cd frontend && sudo -u conecta npm run build
sudo systemctl reload nginx
```
