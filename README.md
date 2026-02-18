# Instalador Automático Conecta

Instalador automatizado para o sistema Conecta - Multi-atendente WhatsApp SaaS.

## Instalação direta (mesmo formato do modelo)

```bash
sudo apt install -y git && rm -rf ./install && git clone https://github.com/isaque-silva/Instalador-conecta.git install && sudo chmod -R 777 ./install && cd ./install && sudo ./install_primaria
```

**Nota:** O comando `rm -rf ./install` remove a pasta `install` se ela já existir, evitando conflitos ao clonar o repositório.

### Importante

Para esse comando funcionar exatamente assim, o **repositório clonado** precisa ser o **repositório do instalador**, contendo na raiz:

- `install_primaria`
- `install_instancia`
- `lib/`, `utils/`, `variables/`

Se hoje esses arquivos estão dentro de uma pasta (ex.: `Instalador conecta/`) dentro do repositório principal do Conecta, então você tem 2 opções:

- **Opção A (recomendado)**: publicar **um repositório só do instalador** (com esses arquivos na raiz). Aí o comando acima funciona sem mudanças.
- **Opção B**: clonar o repositório do Conecta e entrar na pasta do instalador (o comando muda).

## O que será instalado

- Node.js 20.x
- PM2 (gerenciador de processos)
- PostgreSQL
- Nginx (proxy reverso)
- Certbot (SSL automático)
- Dependências do sistema

## Durante a instalação

O script solicitará:

1. **Domínio** (opcional): Para configurar SSL automaticamente
2. **E-mail do admin**: E-mail do usuário administrador padrão
3. **Senha do admin**: Senha do usuário administrador padrão
4. **Link do repositório Git** (opcional): Link do repositório do projeto Conecta. Se não informado, usará o repositório padrão.
5. **Senha do PostgreSQL**: Senha do banco de dados (ou gerar automaticamente)
6. **JWT Secret**: Chave secreta para tokens (ou gerar automaticamente)

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

### Ver processos PM2
```bash
sudo -u conecta pm2 list
```

### Ver logs do backend
```bash
sudo -u conecta pm2 logs conecta-backend
```

### Reiniciar backend
```bash
sudo -u conecta pm2 restart conecta-backend
```

### Ver logs do Nginx
```bash
sudo tail -f /var/log/nginx/error.log
```

## Menu de Gerenciamento

Ao executar o instalador novamente, você terá acesso ao menu:

- **[0] Instalar Conecta** - Instalação completa
- **[1] Atualizar Conecta** - Atualiza código e dependências
- **[2] Deletar Conecta** - Remove instância completamente
- **[3] Bloquear Conecta** - Para backend (bloqueia acesso)
- **[4] Desbloquear Conecta** - Reativa backend
- **[5] Alterar domínio Conecta** - Altera domínios e configura SSL

## Requisitos

- Ubuntu/Debian Linux
- Acesso root/sudo
- Conexão com internet
- (Opcional) Domínio configurado apontando para o servidor (para SSL)

## Estrutura do Instalador

```
install/
├── install_primaria      # Script principal (primeira instalação)
├── install_instancia    # Script para novas instâncias
├── variables/           # Variáveis e configurações
├── utils/               # Utilitários (banner, helpers)
└── lib/                 # Funções principais
    ├── _system.sh      # Funções do sistema
    ├── _backend.sh     # Funções do backend
    ├── _frontend.sh    # Funções do frontend
    └── _inquiry.sh     # CLI interativo
```

## Notas Importantes

- O arquivo `config` é gerado automaticamente e contém senhas sensíveis
- Todas as senhas são geradas automaticamente se não informadas
- O sistema suporta instalação com ou sem domínio (SSL opcional)
- O frontend é servido diretamente pelo Nginx
- O backend usa PM2 para gerenciamento de processos

## Suporte

Para mais informações sobre o projeto Conecta, consulte o README principal do repositório.
