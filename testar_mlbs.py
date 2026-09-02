"""
testar_mlbs.py - Testa token + MLBs direto na API do Mercado Livre (sem banco).
Uso:  python testar_mlbs.py SEU_TOKEN MLB1 MLB2 ...
Ou:   defina o token na 1a linha abaixo e liste os MLBs.
"""
import sys, json, urllib.request, urllib.error

TOKEN = ""  # opcional: cole o token aqui se nao quiser passar por argumento
MLBS = [
    "MLB5119953177","MLB7493200732","MLB7521335338","MLB7531243248","MLB7531230792",
    "MLB7480198604","MLB7520874760","MLB7498427592","MLB7485720894","MLB5138187493",
]

args = sys.argv[1:]
if args:
    TOKEN = args[0]
    if len(args) > 1:
        MLBS = args[1:]
if not TOKEN:
    TOKEN = input("Cole o token do Mercado Livre: ").strip()

def get(url):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]
    except Exception as e:
        return "ERR", str(e)[:300]

st, me = get("https://api.mercadolibre.com/users/me")
print("users/me ->", st, "| id:", me.get("id") if isinstance(me, dict) else me)

ids = ",".join(MLBS)
st, data = get(f"https://api.mercadolibre.com/items?ids={ids}")
print(f"\n/items -> HTTP {st} | {len(data) if isinstance(data,list) else data}")
if isinstance(data, list):
    print(f"{'MLB':<16} {'code':<5} {'catalogo':<9} {'status':<10} titulo")
    for it in data:
        b = it.get("body") or {}
        cat = "CATALOGO" if b.get("catalog_listing") else "tradicional"
        print(f"{b.get('id',''):<16} {it.get('code',''):<5} {cat:<9} {str(b.get('status','')):<10} {(b.get('title') or '')[:50]}")
