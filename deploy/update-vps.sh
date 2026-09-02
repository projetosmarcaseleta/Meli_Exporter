#!/bin/bash
# ============================================================
# update-vps.sh - Atualiza o repositório e reinicia a aplicação
# Uso: bash /var/www/Meli_Exporter/deploy/update-vps.sh
# ============================================================

set -e

APP_DIR="/var/www/Meli_Exporter"

echo "🔄 Atualizando Meli Exporter na VPS..."
cd "$APP_DIR"

git fetch origin main
git reset --hard origin/main

source venv/bin/activate
pip install -r ml_exporter/requirements.txt --quiet

sudo systemctl restart meli-exporter

echo "✅ Meli Exporter atualizado e reiniciado com sucesso!"
echo "Status:"
sudo systemctl status meli-exporter --no-pager
