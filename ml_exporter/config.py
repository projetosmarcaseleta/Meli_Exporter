"""
config.py – Configurações do Relatorios Meli
"""

import os

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

API_BASE_URL = os.environ.get("ML_API_BASE_URL", "https://api.mercadolibre.com")
PROXY        = os.environ.get("HTTP_PROXY", None)
HTTP_TIMEOUT = int(os.environ.get("HTTP_TIMEOUT", "30"))
MAX_WORKERS  = int(os.environ.get("MAX_WORKERS", "10"))
