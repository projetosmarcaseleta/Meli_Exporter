#!/bin/bash
# ============================================================
# setup-vps.sh - Script de configuração inicial na VPS Linux
# Execute este script na VPS (Ubuntu/Debian) como root ou sudo:
# bash setup-vps.sh
# ============================================================

set -e

APP_DIR="/var/www/Meli_Exporter"
REPO_URL="https://github.com/projetosmarcaseleta/Meli_Exporter.git"

echo "============================================"
echo "  🚀 Setup Meli Exporter na VPS"
echo "============================================"

# 1. Instalar pacotes do sistema
echo ""
echo "📦 1. Instalando dependências do sistema (Python, Git, Nginx, etc.)..."
apt-get update -qq
apt-get install -y python3 python3-venv python3-pip git libpq-dev curl nginx -qq

# 2. Clonar ou atualizar o repositório
echo ""
echo "📥 2. Baixando repositório..."
if [ -d "$APP_DIR" ]; then
    echo "  Diretório já existe, atualizando..."
    cd "$APP_DIR"
    git fetch origin main
    git reset --hard origin/main
else
    mkdir -p /var/www
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

# 3. Criar ambiente virtual e instalar dependências Python
echo ""
echo "🐍 3. Configurando ambiente virtual Python..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip --quiet
pip install -r ml_exporter/requirements.txt --quiet

# 4. Criar arquivo .env se não existir
if [ ! -f "$APP_DIR/.env" ]; then
    echo ""
    echo "📝 4. Criando arquivo de configuração .env a partir do .env.example..."
    if [ -f "$APP_DIR/.env.example" ]; then
        cp "$APP_DIR/.env.example" "$APP_DIR/.env"
    else
        cat > "$APP_DIR/.env" << 'EOF'
PORT=3002
FLASK_DEBUG=0
SECRET_KEY=sua_chave_secreta_aqui
PUBLIC_EXPORT_URL=https://app.marcaseleta.shop/export
GUMGA_TOKEN=
ANYMARKET_PLATFORM=SELETA
EOF
    fi
    echo "  ⚠️  IMPORTANTE: Edite /var/www/Meli_Exporter/.env com seus tokens e senhas reais!"
fi

# 5. Instalar o serviço systemd
echo ""
echo "⚙️  5. Configurando serviço Systemd (meli-exporter)..."
cp "$APP_DIR/deploy/meli-exporter.service" /etc/systemd/system/meli-exporter.service
systemctl daemon-reload
systemctl enable meli-exporter
systemctl restart meli-exporter

# 6. Configurar Nginx (se existir arquivo de conf)
if [ -f "$APP_DIR/deploy/nginx-meli-exporter.conf" ]; then
    echo ""
    echo "🌐 6. Configurando Nginx..."
    cp "$APP_DIR/deploy/nginx-meli-exporter.conf" /etc/nginx/sites-available/meli-exporter.conf
    ln -sf /etc/nginx/sites-available/meli-exporter.conf /etc/nginx/sites-enabled/meli-exporter.conf
    nginx -t && systemctl reload nginx || echo "⚠️ Verifique as configurações de domínio no Nginx."
fi

echo ""
echo "============================================"
echo "  ✅ Setup concluído com sucesso!"
echo "============================================"
echo ""
echo "  📍 Status do serviço: systemctl status meli-exporter"
echo "  📍 Logs em tempo real: journalctl -u meli-exporter -f"
echo "  📍 Reiniciar serviço:  systemctl restart meli-exporter"
echo "  📍 Atualizar no futuro: bash /var/www/Meli_Exporter/deploy/update-vps.sh"
echo ""
