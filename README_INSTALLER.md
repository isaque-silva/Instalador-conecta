# Instalador Automático Conecta

## Instalação Rápida

```bash
sudo apt install -y git && \
git clone https://github.com/isaque-silva/conecta.git install && \
sudo chmod -R 777 ./install && \
cd ./install && \
sudo ./install_primaria
```

## O que será instalado

- ✅ Node.js 20.x
- ✅ PM2 (gerenciador de processos)
- ✅ PostgreSQL
- ✅ Nginx (proxy reverso)
- ✅ Certbot (SSL automático)

## Durante a instalação

O script solicitará:

1. **Domínio** (opcional): Para configurar SSL automaticamente
2. **E-mail do admin**: E-mail do usuário administrador padrão
3. **Senha do admin**: Senha do usuário administrador padrão
4. **Senha do PostgreSQL**: Senha do banco de dados (ou gerar automaticamente)
5. **JWT Secret**: Chave secreta para tokens (ou gerar automaticamente)

## Após a instalação

- **Acesse**: `http://SEU_IP` ou `https://SEU_DOMINIO`
- **Login**: Use as credenciais configuradas durante a instalação
- **Logs**: `sudo -u conecta pm2 logs`
- **Reiniciar**: `sudo -u conecta pm2 restart all`

## Estrutura criada

```
/home/conecta/conecta/
├── backend/          # API Node.js
├── frontend/         # React build
└── ...
```

## Gerenciamento

```bash
# Ver processos PM2
sudo -u conecta pm2 list

# Ver logs do backend
sudo -u conecta pm2 logs conecta-backend

# Reiniciar backend
sudo -u conecta pm2 restart conecta-backend

# Ver logs do Nginx
sudo tail -f /var/log/nginx/error.log
```
