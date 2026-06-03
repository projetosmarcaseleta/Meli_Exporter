"""
exporter.py – Extrai 5 campos de uma lista de MLBs em batch + paralelo.

Campos: SKU | MLB | TIPO ANÚNCIO | CATÁLOGO | QTD VENDIDA

Fluxo:
  Fase 1 – Batch de até 20 MLBs por requisição, batches em paralelo
  Fase 2 – Monta linhas com os 5 campos
"""

import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

from api import get_products_batch, BATCH_SIZE, LISTING_LABELS
from config import MAX_WORKERS

HEADERS = ["SKU", "MLB", "TIPO ANÚNCIO", "CATÁLOGO", "QTD VENDIDA"]


def _resolve_sku(produto: dict) -> str:
    """SKU: seller_custom_field > atributo SELLER_SKU."""
    sku = produto.get("seller_custom_field") or ""
    if not sku:
        attrs = {a["id"]: a for a in (produto.get("attributes") or []) if "id" in a}
        sku = attrs.get("SELLER_SKU", {}).get("value_name") or ""
    return sku


def _build_row(produto: dict) -> list:
    listing_id = produto.get("listing_type_id", "")
    return [
        _resolve_sku(produto),
        produto.get("id", ""),
        LISTING_LABELS.get(listing_id, listing_id),
        "SIM" if produto.get("catalog_listing") else "NÃO",
        produto.get("sold_quantity", 0),
    ]


def process_mlbs(mlb_list: list[str], token: str, progress_callback=None) -> tuple[list, list]:
    """
    Processa MLBs em batch paralelo e retorna (rows, errors).
    rows[0] é sempre a linha de cabeçalho.
    """
    mlbs = [m.strip().upper() for m in mlb_list if m.strip()]
    total = len(mlbs)
    all_rows = [HEADERS]
    errors = []

    if not mlbs:
        return all_rows, errors

    # Fase 1: busca em batch paralela
    produtos = {}
    batches = [mlbs[i:i + BATCH_SIZE] for i in range(0, total, BATCH_SIZE)]
    lock = threading.Lock()
    completed = 0

    def _fetch(batch):
        nonlocal completed
        result = get_products_batch(batch, token)
        with lock:
            produtos.update(result)
            completed += len(batch)
            if progress_callback:
                progress_callback(completed, total, f"Buscando... {completed}/{total}")

    with ThreadPoolExecutor(max_workers=min(len(batches), MAX_WORKERS)) as pool:
        futures = [pool.submit(_fetch, b) for b in batches]
        for f in as_completed(futures):
            f.result()

    # Registra MLBs não encontrados
    for mlb in mlbs:
        if mlb not in produtos:
            errors.append(f"[{mlb}] Não encontrado ou erro na API.")

    # Fase 2: monta linhas mantendo ordem original
    for mlb in mlbs:
        produto = produtos.get(mlb)
        if produto:
            all_rows.append(_build_row(produto))

    return all_rows, errors
