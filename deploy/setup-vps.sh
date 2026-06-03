#!/bin/bash
# ============================================================
# setup-vps.sh - Script de configuração inicial da VPS
# Execute este script UMA VEZ na VPS para configurar tudo
# Uso: bash setup-vps.sh
# ============================================================

set -e

APP_DIR="/var/www/Meli_Exporter"
REPO_URL="https://github.com/projetosmarcaseleta/Meli_Exporter.git"

echo "============================================"
echo "  🚀 Setup Meli Exporter na VPS"
echo "============================================"

# 1. Instalar dependências do sistema
echo ""
echo "📦 Instalando dependências do sistema..."
apt-get update -qq
apt-get install -y python3 python3-venv python3-pip git -qq

# 2. Clonar o repositório
echo ""
echo "📥 Clonando repositório..."
if [ -d "$APP_DIR" ]; then
    echo "  Diretório já existe, atualizando..."
    cd "$APP_DIR"
    git fetch origin main
    git reset --hard origin/main
else
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

# 3. Criar ambiente virtual e instalar dependências
echo ""
echo "🐍 Criando ambiente virtual..."
python3 -m venv venv
source venv/bin/activate
pip install -r ml_exporter/requirements.txt --quiet

# 4. Criar arquivo .env (se não existir)
if [ ! -f "$APP_DIR/.env" ]; then
    echo ""
    echo "📝 Criando arquivo .env..."
    cat > "$APP_DIR/.env" << 'EOF'
PORT=3002
FLASK_DEBUG=0
SECRET_KEY=ALTERE_PARA_UMA_CHAVE_SEGURA
PUBLIC_EXPORT_URL=https://app.marcaseleta.shop/export
EOF
    echo "  ⚠️  IMPORTANTE: Edite /var/www/Meli_Exporter/.env com suas configurações!"
fi

# 5. Instalar o serviço systemd
echo ""
echo "⚙️  Configurando serviço systemd..."
cp "$APP_DIR/deploy/meli-exporter.service" /etc/systemd/system/meli-exporter.service
systemctl daemon-reload
systemctl enable meli-exporter
systemctl start meli-exporter

echo ""
echo "============================================"
echo "  ✅ Setup concluído!"
echo "============================================"
echo ""
echo "  📍 App público: https://app.marcaseleta.shop/export"
echo "  📍 App local:   http://127.0.0.1:3002/export"
echo "  📁 Diretório: $APP_DIR"
echo "  🔧 Serviço: systemctl status meli-exporter"
echo ""
echo "  Comandos úteis:"
echo "    systemctl status meli-exporter   # Ver status"
echo "    systemctl restart meli-exporter  # Reiniciar"
echo "    journalctl -u meli-exporter -f   # Ver logs"
echo ""
