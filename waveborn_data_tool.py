# waveborn_data_tool.py
# Waveborn TD – Dateneditor, Validator, Balancing- & Content-Tool
# Enthält:
# - Global: Backups-Schalter (Backups an/aus)
# - Maps: Manager (Liste, Inline-Edit, Löschen), Vorlage (6 Stages), Stage-Duplikation, Stage-Rewards (+), Stage-Groups (+)
# - Map-ID-Registry (map_id_registry.json)
# - Quests: Generator (Kategorie, Auto-ID, Rewards aus ItemData), Liste & Löschen
# - Units: CSV/Excel-Import, Sortierung, Löschen
# - Enemies: Katalog CRUD, Datei schreiben
# - Items: NEU – Katalog CRUD (Anlegen, Bearbeiten, Löschen), Datei schreiben
# - Analyse: Balancing, Unused
# - QS: Formatter, Sortierung
# - Validatoren: Items/Maps/Units/Quests/Enemies

import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from tkinter.scrolledtext import ScrolledText
import os, re, datetime, difflib, io, csv, json
from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Optional, Callable

# ---- Optional (Excel / Charts) ----
try:
    import pandas as pd
    HAS_PANDAS = True
except Exception:
    HAS_PANDAS = False

try:
    import matplotlib
    matplotlib.use("TkAgg")
    import matplotlib.pyplot as plt
    HAS_MPL = True
except Exception:
    HAS_MPL = False

# -------------------------------------------
# Konfiguration
# -------------------------------------------
BACKUP_DIR = "_backups_wtd"
MAX_BACKUPS_PER_FILE = 10
MAP_ID_REG_PATH = "map_id_registry.json"   # Persistente Registry MapKey ↔ PlaceId

# -------------------------------------------
# Datenmodelle
# -------------------------------------------
@dataclass
class Issue:
    file_path: str
    severity: str  # INFO | WARN | ERROR | SUGGEST
    code: str
    message: str
    fix: Optional[Callable[[str, Dict[str, "FileEntry"]], str]] = None
    fix_label: Optional[str] = None

@dataclass
class FileEntry:
    path: str
    content: str
    original: str
    issues: List[Issue] = field(default_factory=list)

@dataclass
class MapInfo:
    key: str
    display: str
    place_id: str

@dataclass
class ItemInfo:
    id: str
    display: str
    category: str
    rarity: str = "Common"
    iconId: str = ""
    desc: str = ""

@dataclass
class EnemyInfo:
    id: str
    display: str
    hp: int
    speed: float
    reward: int
    etype: str

# -------------------------------------------
# Utilities
# -------------------------------------------
def now_ts() -> str:
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

def ensure_backup_dir():
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR, exist_ok=True)

def backup_file(path: str, content: str):
    ensure_backup_dir()
    base = os.path.basename(path)
    out = os.path.join(BACKUP_DIR, f"{base}.{now_ts()}.bak")
    with open(out, "w", encoding="utf-8") as f:
        f.write(content)
    same = sorted([p for p in os.listdir(BACKUP_DIR) if p.startswith(base + ".")])
    while len(same) > MAX_BACKUPS_PER_FILE:
        try:
            os.remove(os.path.join(BACKUP_DIR, same.pop(0)))
        except Exception:
            break

def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def write_text(path: str, text: str):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

def unified_diff(a: str, b: str, name: str) -> str:
    diff = difflib.unified_diff(
        a.splitlines(keepends=True),
        b.splitlines(keepends=True),
        fromfile=f"{name} (original)",
        tofile=f"{name} (modified)"
    )
    return "".join(diff)

def load_map_id_registry() -> Dict[str, str]:
    if not os.path.exists(MAP_ID_REG_PATH):
        return {}
    try:
        with open(MAP_ID_REG_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, dict):
                return {k: str(v) for k, v in data.items()}
            return {}
    except Exception:
        return {}

def save_map_id_registry(reg: Dict[str, str]):
    try:
        with open(MAP_ID_REG_PATH, "w", encoding="utf-8") as f:
            json.dump(reg, f, indent=2, ensure_ascii=False)
    except Exception:
        pass

# -------------------------------------------
# Lua Parsing Helpers
# -------------------------------------------
def extract_item_ids(item_lua: str) -> List[str]:
    return list(dict.fromkeys(re.findall(r'\[\s*"([^"]+)"\s*\]\s*=', item_lua)))

def extract_items(item_lua: str) -> List[ItemInfo]:
    out: List[ItemInfo] = []
    for m in re.finditer(r'\[\s*"([^"]+)"\s*\]\s*=\s*{(.*?)}\s*,?', item_lua, flags=re.S):
        iid = m.group(1)
        body = m.group(2)
        dn = re.search(r'displayName\s*=\s*"([^"]+)"', body)
        cat = re.search(r'category\s*=\s*"([^"]+)"', body)
        rar = re.search(r'rarity\s*=\s*"([^"]+)"', body)
        ico = re.search(r'iconId\s*=\s*"([^"]+)"', body)
        dsc = re.search(r'desc\s*=\s*"([^"]+)"', body)
        out.append(ItemInfo(
            id=iid,
            display=dn.group(1) if dn else iid,
            category=cat.group(1) if cat else "Item",
            rarity=rar.group(1) if rar else "Common",
            iconId=ico.group(1) if ico else "",
            desc=dsc.group(1) if dsc else ""
        ))
    return out

def extract_enemy_ids(enemy_lua: str) -> List[str]:
    return list(dict.fromkeys(re.findall(r'\[\s*"([^"]+)"\s*\]\s*=\s*{', enemy_lua)))

def extract_enemies(enemy_lua: str) -> List[EnemyInfo]:
    out: List[EnemyInfo] = []
    for m in re.finditer(r'\[\s*"([^"]+)"\s*\]\s*=\s*{(.*?)}\s*,?', enemy_lua, flags=re.S):
        eid = m.group(1)
        body = m.group(2)
        dn   = re.search(r'displayName\s*=\s*"([^"]+)"', body)
        hp   = re.search(r'\bhp\s*=\s*(\d+)', body)
        spd  = re.search(r'\bspeed\s*=\s*([0-9.]+)', body)
        rew  = re.search(r'\breward\s*=\s*(\d+)', body)
        ety  = re.search(r'\btype\s*=\s*"([^"]+)"', body)
        out.append(EnemyInfo(
            id=eid,
            display=dn.group(1) if dn else eid,
            hp=int(hp.group(1)) if hp else 100,
            speed=float(spd.group(1)) if spd else 1.0,
            reward=int(rew.group(1)) if rew else 5,
            etype=ety.group(1) if ety else "Ground"
        ))
    return out

def iterate_map_blocks(map_lua: str):
    for m in re.finditer(r'(\[\s*"([^"]+)"\s*\]\s*=\s*{)(.*?)(\n\s*},)', map_lua, flags=re.S):
        yield m.group(2), (m.start(3), m.end(3)), m.group(3)

def extract_map_info_list(map_lua: str) -> List[MapInfo]:
    infos: List[MapInfo] = []
    for key, (_s,_e), body in iterate_map_blocks(map_lua):
        dn = re.search(r'DisplayName\s*=\s*"([^"]+)"', body)
        pid = re.search(r'PlaceId\s*=\s*(\d+)', body)
        infos.append(MapInfo(
            key=key,
            display=dn.group(1) if dn else key,
            place_id=pid.group(1) if pid else ""
        ))
    return infos

def extract_stages_from_map_body(body: str) -> List[Tuple[int, str, Tuple[int,int]]]:
    out = []
    stg = re.search(r'Stages\s*=\s*{(.*?)}\s*,?\s*\n', body, flags=re.S)
    if not stg:
        return out
    inner = stg.group(1)
    offset = stg.start(1)
    for sm in re.finditer(r'({\s*[^}]*?StageId\s*=\s*(\d+).*?}\s*,?)', inner, flags=re.S):
        blk = sm.group(1)
        sid = int(sm.group(2))
        out.append((sid, blk, (offset + sm.start(1), offset + sm.end(1))))
    return out

def get_stage_metrics(stage_block: str) -> Tuple[int,int,Optional[float]]:
    w = re.search(r'WaveCount\s*=\s*(\d+)', stage_block)
    t = re.search(r'TotalEnemies\s*=\s*(\d+)', stage_block)
    b = re.search(r'BossScaling\s*=\s*([0-9.]+)', stage_block)
    wc = int(w.group(1)) if w else 0
    te = int(t.group(1)) if t else 0
    bs = float(b.group(1)) if b else None
    return wc, te, bs

def rewards_block(stage_block: str) -> str:
    m = re.search(r'Rewards\s*=\s*{(.*?)}', stage_block, flags=re.S)
    return m.group(1) if m else ""

def parse_rewards_items(rew_block: str) -> List[Tuple[str,int]]:
    out: List[Tuple[str,int]] = []
    for m in re.finditer(r'{\s*type\s*=\s*"([^"]+)"\s*,\s*(?:id\s*=\s*"([^"]+)"\s*,\s*)?amount\s*=\s*(\d+)', rew_block):
        rtype, rid, amt = m.group(1), m.group(2), int(m.group(3))
        if rtype == "Eclipsium":
            out.append(("Eclipsium", amt))
        else:
            if rid:
                out.append((rid, amt))
    return out

def reward_types_and_amounts(rew_block: str) -> List[Tuple[str, Optional[str], int]]:
    out = []
    for m in re.finditer(r'{\s*type\s*=\s*"([^"]+)"\s*,\s*(?:id\s*=\s*"([^"]+)"\s*,\s*)?amount\s*=\s*(\d+)', rew_block):
        out.append((m.group(1), m.group(2), int(m.group(3))))
    return out

def units_in_text(unit_lua: str) -> List[str]:
    m = re.search(r'Units\.BaseUnits\s*=\s*{\s*(.*?)\n}\s*,?\s*\n', unit_lua, flags=re.S)
    if not m:
        return []
    inner = m.group(1)
    keys = re.findall(r'([A-Za-z0-9_]+)\s*=\s*{', inner)
    return list(dict.fromkeys(keys))

# -------------------------------------------
# Lua Edit Helpers
# -------------------------------------------
def insert_top_level_table_entry(content: str, table_decl_pattern: str, new_entry: str) -> str:
    m = re.search(table_decl_pattern, content, flags=re.S)
    if not m:
        raise ValueError("Zieltabelle nicht gefunden.")
    start, end = m.span(1)
    inner = m.group(1)
    if inner.strip() and not inner.rstrip().endswith(","):
        inner += ","
    inner += "\n" + new_entry.strip() + "\n"
    return content[:start] + inner + content[end:]

def delete_top_level_keyed_entry(content: str, key: str) -> str:
    patt = re.compile(rf'\[\s*"{re.escape(key)}"\s*\]\s*=\s*{{.*?}},\s*', flags=re.S)
    new, n = re.subn(patt, "", content, count=1)
    if n == 0:
        patt2 = re.compile(rf'\[\s*"{re.escape(key)}"\s*\]\s*=\s*{{.*?}}\s*', flags=re.S)
        new = re.sub(patt2, "", content, count=1)
    return new

def insert_into_units(content: str, unit_entry: str) -> str:
    pat = r'Units\.BaseUnits\s*=\s*{\s*(.*?)\n}\s*,?\s*\n'
    return insert_top_level_table_entry(content, pat, unit_entry)

def delete_unit_entry(content: str, unit_key: str) -> str:
    patt = re.compile(rf'\b{re.escape(unit_key)}\s*=\s*{{.*?}},\s*', flags=re.S)
    new, n = re.subn(patt, "", content, count=1)
    if n == 0:
        patt2 = re.compile(rf'\b{re.escape(unit_key)}\s*=\s*{{.*?}}\s*', flags=re.S)
        new = re.sub(patt2, "", content, count=1)
    return new

def insert_into_map(content: str, new_map_block: str) -> str:
    pat = r'local\s+MapData\s*=\s*{\s*(.*?)\n}\s*\n'
    return insert_top_level_table_entry(content, pat, new_map_block)

def delete_map_block(content: str, map_key: str) -> str:
    return delete_top_level_keyed_entry(content, map_key)

def insert_stage_into_map(content: str, map_key: str, stage_entry: str) -> str:
    for key, (bstart, bend), body in iterate_map_blocks(content):
        if key != map_key:
            continue
        stg = re.search(r'(Stages\s*=\s*{)(.*?)(\})', body, flags=re.S)
        if not stg:
            raise ValueError(f"Stages in Map '{map_key}' nicht gefunden.")
        inner = stg.group(2)
        if inner.strip() and not inner.rstrip().endswith(","):
            inner += ","
        inner += "\n" + stage_entry.strip() + "\n"
        new_body = body[:stg.start(2)] + inner + body[stg.end(2):]
        return content[:bstart] + new_body + content[bend:]
    raise ValueError(f"Map '{map_key}' nicht gefunden.")

def replace_or_set_nextstage(stage_block: str, next_map_key: str, next_stage_id: int = 1) -> str:
    if re.search(r'\bNextStage\s*=\s*{', stage_block):
        stage_block = re.sub(r'NextStage\s*=\s*{[^}]*}',
                             f'NextStage = {{ MapName = "{next_map_key}", StageId = {next_stage_id} }}',
                             stage_block, flags=re.S)
    else:
        stage_block = re.sub(r'}\s*,?\s*$',
                             f',\n                    NextStage = {{\n                        MapName = "{next_map_key}",\n                        StageId = {next_stage_id}\n                    }}\n                }},',
                             stage_block.strip())
    return stage_block

def duplicate_stage(content: str, src_map: str, stage_id: int, dst_map: str, new_stage_id: int,
                    auto_set_next: bool = False, next_world_key: str = "") -> str:
    src_blk = None
    for key, (_s,_e), body in iterate_map_blocks(content):
        if key != src_map:
            continue
        for sid, blk, _span in extract_stages_from_map_body(body):
            if sid == stage_id:
                src_blk = blk; break
    if not src_blk:
        raise ValueError("Quell-Stage nicht gefunden.")
    new_blk = re.sub(r'StageId\s*=\s*\d+', f"StageId = {new_stage_id}", src_blk, count=1)
    new_blk = re.sub(r'Name\s*=\s*"([^"]+)"', lambda m: f'Name = "{m.group(1)} (Copy)"', new_blk, count=1)
    if auto_set_next and new_stage_id == 6 and next_world_key:
        new_blk = replace_or_set_nextstage(new_blk, next_world_key, 1)
    return insert_stage_into_map(content, dst_map, new_blk)

def insert_quest_into_category(content: str, category: str, quest_entry: str) -> str:
    cat_pat = rf'{category}\s*=\s*{{\s*(.*?)\n\s*}},?'
    m = re.search(cat_pat, content, flags=re.S)
    if not m:
        raise ValueError(f"Kategorie '{category}' nicht gefunden.")
    start, end = m.span(1)
    inner = m.group(1)
    if inner.strip() and not inner.rstrip().endswith(","):
        inner += ","
    inner += "\n" + quest_entry.strip() + "\n"
    return content[:start] + inner + content[end:]

def delete_quest_by_id(content: str, category: str, quest_id: str) -> str:
    cat_pat = rf'({category}\s*=\s*{{\s*)(.*?)(\n\s*}},?)'
    m = re.search(cat_pat, content, flags=re.S)
    if not m:
        raise ValueError(f"Kategorie '{category}' nicht gefunden.")
    prefix, inner, suffix = m.group(1), m.group(2), m.group(3)
    inner_new, n = re.subn(r'{\s*([^{}]|{[^}]*})*?id\s*=\s*"' + re.escape(quest_id) + r'".*?},\s*\n?', '', inner, flags=re.S)
    if n == 0:
        raise ValueError(f"Quest '{quest_id}' nicht gefunden.")
    return content[:m.start(2)] + inner_new + content[m.end(2):]

def update_map_fields(content: str, map_key: str, new_display: str, new_placeid: str) -> str:
    updated = False
    for key, (bstart, bend), body in iterate_map_blocks(content):
        if key != map_key:
            continue
        body_new = body
        if new_display:
            if re.search(r'DisplayName\s*=\s*"', body_new):
                body_new = re.sub(r'(DisplayName\s*=\s*")([^"]*)(")', rf'\1{re.escape(new_display)}\3', body_new, count=1)
            else:
                body_new = re.sub(r'(PlaceId\s*=)', f'DisplayName = "{new_display}",\n            \\1', body_new, count=1)
        if new_placeid and re.match(r'^\d+$', new_placeid):
            if re.search(r'PlaceId\s*=\s*\d+', body_new):
                body_new = re.sub(r'(PlaceId\s*=\s*)\d+', rf'\g<1>{new_placeid}', body_new, count=1)
            else:
                body_new = re.sub(r'(DisplayName\s*=\s*"[^"]+"\s*,?)', rf'\1\n            PlaceId     = {new_placeid},', body_new, count=1)
        if body_new != body:
            content = content[:bstart] + body_new + content[bend:]
            updated = True
        break
    if not updated:
        raise ValueError(f"Map '{map_key}' nicht gefunden oder keine änderbaren Felder entdeckt.")
    return content

# -------------------------------------------
# Formatter
# -------------------------------------------
def format_lua_simple(text: str) -> str:
    lines = text.splitlines()
    indent = 0
    out = []
    for raw in lines:
        line = raw.rstrip()
        if re.search(r'^\s*},?\s*$', line) or re.search(r'^\s*}\s*,?\s*--', line):
            indent = max(0, indent - 1)
        out.append(("    " * indent) + line.strip())
        opens = line.count("{")
        closes = line.count("}")
        indent = max(0, indent + opens - closes)
    s = "\n".join(out)
    s = re.sub(r'(\n\s*}\))', r'\1', s)
    return s

def sort_units_alphabetically(unit_lua: str) -> str:
    m = re.search(r'(Units\.BaseUnits\s*=\s*{\s*)(.*?)(\n}\s*,?\s*\n)', unit_lua, flags=re.S)
    if not m:
        return unit_lua
    prefix, inner, suffix = m.group(1), m.group(2), m.group(3)
    entries = re.findall(r'([A-Za-z0-9_]+)\s*=\s*{.*?}\s*,?', inner, flags=re.S)
    parts = re.finditer(r'([A-Za-z0-9_]+\s*=\s*{.*?}\s*,?)', inner, flags=re.S)
    mapping = {}
    for p in parts:
        k = re.match(r'([A-Za-z0-9_]+)', p.group(1)).group(1)
        mapping[k] = p.group(1)
    keys_sorted = sorted(entries, key=lambda x: x.lower())
    new_inner = "\n".join(mapping[k] for k in keys_sorted)
    return prefix + new_inner + suffix

# -------------------------------------------
# Validatoren
# -------------------------------------------
class BaseValidator:
    def scan(self, fe: FileEntry, ctx: Dict[str, FileEntry]): ...

class ItemDataValidator(BaseValidator):
    def scan(self, fe: FileEntry, ctx: Dict[str, FileEntry]):
        txt = fe.content
        if re.search(r'displayName\s*=\s*"Univversal_Fragment"', txt):
            fe.issues.append(Issue(
                fe.path, "WARN", "ITEM_TYPO",
                'displayName "Univversal_Fragment" → "Universal Fragment".',
                lambda c,_: re.sub(r'displayName\s*=\s*"Univversal_Fragment"',
                                   'displayName = "Universal Fragment"', c),
                "Tippfehler korrigieren"
            ))
        if "Category" not in txt and "Catergory" in txt:
            fe.issues.append(Issue(
                fe.path, "INFO", "ITEM_COMMENT_TYPO",
                'Kommentar "Catergory" → "Category".',
                lambda c,_: c.replace("Catergory", "Category"),
                "Kommentarfix"
            ))

class EnemyDataValidator(BaseValidator):
    def scan(self, fe: FileEntry, ctx: Dict[str, FileEntry]):
        for e in extract_enemies(fe.content):
            if e.hp <= 0:
                fe.issues.append(Issue(
                    fe.path, "WARN", "ENEMY_HP_NONPOS",
                    f'Enemy "{e.id}" hat hp <= 0.'
                ))
            if e.speed <= 0:
                fe.issues.append(Issue(
                    fe.path, "WARN", "ENEMY_SPD_NONPOS",
                    f'Enemy "{e.id}" hat speed <= 0.'
                ))

class MapDataValidator(BaseValidator):
    def scan(self, fe: FileEntry, ctx: Dict[str, FileEntry]):
        item_ids = extract_item_ids(ctx.get("ItemDataModule.lua").content) if ctx.get("ItemDataModule.lua") else []
        enemy_ids = extract_enemy_ids(ctx.get("EnemyDataModule.lua").content) if ctx.get("EnemyDataModule.lua") else []

        for key, (_bstart, _bend), body in iterate_map_blocks(fe.content):
            for sid, blk, _span in extract_stages_from_map_body(body):
                rw = rewards_block(blk)
                missing = [sid_ for sid_ in re.findall(r'id\s*=\s*"([^"]+)"', rw) if sid_ not in item_ids]
                if missing:
                    def mkfix(ids_missing: List[str]) -> Callable[[str, Dict[str, FileEntry]], str]:
                        def _fix(content: str, _ctx: Dict[str, FileEntry]) -> str:
                            if "ItemDataModule.lua" not in _ctx:
                                return content
                            item_fe = _ctx["ItemDataModule.lua"]
                            for mid in ids_missing:
                                stub = f'''["{mid}"] = {{
    displayName = "{mid}",
    iconId = "rbxassetid://0",
    category = "Scroll",
    rarity = "Common",
    desc = "Auto‑generated by tool.",
}},'''
                                item_fe.content = insert_top_level_table_entry(
                                    item_fe.content,
                                    r'local\s+ItemData\s*=\s*{\s*(.*?)\n}\s*\n',
                                    stub
                                )
                            return content
                        return _fix
                    fe.issues.append(Issue(
                        fe.path, "ERROR", "MAP_REWARD_ITEM_UNKNOWN",
                        f"[{key} Stage {sid}] Unbekannte Reward‑ItemIDs: {', '.join(missing)}",
                        mkfix(missing),
                        "Fehlende Items jetzt anlegen"
                    ))

        for key, (_s,_e), body in iterate_map_blocks(fe.content):
            for sid, blk, _span in extract_stages_from_map_body(body):
                for m in re.finditer(r'{\s*type\s*=\s*"([^"]+)"\s*,', blk):
                    et = m.group(1)
                    if enemy_ids and et not in enemy_ids:
                        def mkfix(enemy_id: str) -> Callable[[str, Dict[str, FileEntry]], str]:
                            def _fix(content: str, _ctx: Dict[str, FileEntry]) -> str:
                                if "EnemyDataModule.lua" not in _ctx:
                                    return content
                                efe = _ctx["EnemyDataModule.lua"]
                                stub = f'''["{enemy_id}"] = {{
    displayName = "{enemy_id}",
    hp = 100,
    speed = 1.0,
    reward = 5,
    type = "Ground",
}},'''
                                efe.content = insert_top_level_table_entry(
                                    efe.content,
                                    r'local\s+EnemyData\s*=\s*{\s*(.*?)\n}\s*\n',
                                    stub
                                )
                                return content
                            return _fix
                        fe.issues.append(Issue(
                            fe.path, "ERROR", "MAP_GROUPPOOL_ENEMY_UNKNOWN",
                            f"[{key} Stage {sid}] GroupPool Enemy-Typ unbekannt: {et}",
                            mkfix(et),
                            "Enemy im Katalog anlegen"
                        ))

        for key, (_s,_e), body in iterate_map_blocks(fe.content):
            for sid, blk, _span in extract_stages_from_map_body(body):
                wc, te, _bs = get_stage_metrics(blk)
                if wc and te:
                    avg = te / max(1, wc)
                    if avg < 3:
                        fe.issues.append(Issue(
                            fe.path, "WARN", "MAP_STAGE_LOW_DENSITY",
                            f"[{key} Stage {sid}] Sehr wenige Gegner pro Welle (~{avg:.1f})."
                        ))
                    if avg > 100:
                        fe.issues.append(Issue(
                            fe.path, "WARN", "MAP_STAGE_HIGH_DENSITY",
                            f"[{key} Stage {sid}] Sehr viele Gegner pro Welle (~{avg:.1f})."
                        ))

        txt = fe.content
        if "--[[!strict" in txt:
            fe.issues.append(Issue(
                fe.path, "INFO", "MAP_TRAILING_DUMP",
                "Kommentierter Dump am Dateiende erkannt – entfernen.",
                lambda c,_: c.split("--[[!strict")[0].rstrip() + "\n",
                "Dump entfernen"
            ))

class UnitDataValidator(BaseValidator):
    def scan(self, fe: FileEntry, ctx: Dict[str, FileEntry]):
        txt = fe.content
        for m in re.finditer(r'BaseStar\s*=\s*(\d+)', txt):
            v = int(m.group(1))
            if not (1 <= v <= 7):
                fe.issues.append(Issue(
                    fe.path, "WARN", "UNIT_BASESTAR_RANGE",
                    f"BaseStar außerhalb 1–7: {v}"
                ))
        for ub in re.finditer(r'([A-Za-z0-9_]+)\s*=\s*{(.*?)}\s*,', txt, flags=re.S):
            unit_key = ub.group(1); block = ub.group(2)
            missing = []
            for field in ["name","modelName","type","BaseStar","MaxStar"]:
                if re.search(rf'\b{field}\s*=', block) is None:
                    missing.append(field)
            if missing:
                fe.issues.append(Issue(
                    fe.path, "WARN", "UNIT_MISSING_FIELDS",
                    f"Unit '{unit_key}' fehlt: {', '.join(missing)}"
                ))

class QuestDataValidator(BaseValidator):
    def scan(self, fe: FileEntry, ctx: Dict[str, FileEntry]):
        items = extract_items(ctx.get("ItemDataModule.lua").content) if ctx.get("ItemDataModule.lua") else []
        item_ids = {it.id for it in items}
        for rid in re.findall(r'id\s*=\s*"([^"]+)"', fe.content):
            if rid and rid not in item_ids:
                def fix(content: str, _ctx: Dict[str, FileEntry]) -> str:
                    if "ItemDataModule.lua" not in _ctx:
                        return content
                    item_fe = _ctx["ItemDataModule.lua"]
                    stub = f'''["{rid}"] = {{
    displayName = "{rid}",
    iconId = "rbxassetid://0",
    category = "Scroll",
    rarity = "Common",
    desc = "Auto‑generated by tool.",
}},'''
                    item_fe.content = insert_top_level_table_entry(
                        item_fe.content,
                        r'local\s+ItemData\s*=\s*{\s*(.*?)\n}\s*\n',
                        stub
                    )
                    return content
                fe.issues.append(Issue(
                    fe.path, "ERROR", "QUEST_ITEM_ID_UNKNOWN",
                    f"Unbekannte Reward‑ItemID: {rid}",
                    fix,
                    "Fehlendes Item anlegen"
                ))

VALIDATORS: Dict[str, BaseValidator] = {
    "ItemDataModule.lua":  ItemDataValidator(),
    "EnemyDataModule.lua": EnemyDataValidator(),
    "MapDataModule.lua":   MapDataValidator(),
    "UnitDataModule.lua":  UnitDataValidator(),
    "QuestDataModule.lua": QuestDataValidator(),
}

# -------------------------------------------
# Analysefunktionen
# -------------------------------------------
def collect_unused_items_and_units(files: Dict[str, FileEntry]) -> Tuple[List[str], List[str]]:
    item_ids = []
    unit_ids = []
    if "ItemDataModule.lua" in files:
        item_ids = extract_item_ids(files["ItemDataModule.lua"].content)
    if "UnitDataModule.lua" in files:
        unit_ids = units_in_text(files["UnitDataModule.lua"].content)

    used_items = set()
    used_units = set()

    if "MapDataModule.lua" in files:
        for _map, (_s,_e), body in iterate_map_blocks(files["MapDataModule.lua"].content):
            for _sid, blk, _span in extract_stages_from_map_body(body):
                rw = rewards_block(blk)
                for _, rid, _amt in reward_types_and_amounts(rw):
                    if rid:
                        used_items.add(rid)
    if "QuestDataModule.lua" in files:
        for rid in re.findall(r'id\s*=\s*"([^"]+)"', files["QuestDataModule.lua"].content):
            if rid:
                used_items.add(rid)

    for uid in unit_ids:
        refs = 0
        for name, fe in files.items():
            if name == "UnitDataModule.lua":
                continue
            if re.search(rf'\b{re.escape(uid)}\b', fe.content):
                refs += 1
        if refs == 0:
            used_units.add(uid)

    unused_items = [iid for iid in item_ids if iid not in used_items]
    unused_units = list(used_units)
    return unused_items, unused_units

def analyze_balancing(files: Dict[str, FileEntry]):
    data = []
    if "MapDataModule.lua" not in files:
        return data
    txt = files["MapDataModule.lua"].content
    for key, (_s,_e), body in iterate_map_blocks(txt):
        for sid, blk, _span in extract_stages_from_map_body(body):
            wc, te, bs = get_stage_metrics(blk)
            rw = rewards_block(blk)
            ecl = sum(amt for (t, _rid, amt) in reward_types_and_amounts(rw) if t == "Eclipsium")
            data.append({
                "map": key, "stage": sid,
                "wavecount": wc, "total": te, "boss_scaling": bs if bs is not None else 0.0,
                "eclipsium": ecl,
            })
    return data

# -------------------------------------------
# Referenz-Scanner (für Löschbestätigung)
# -------------------------------------------
def find_map_references(map_key: str, files: Dict[str, FileEntry]) -> List[str]:
    refs = []
    fe = files.get("MapDataModule.lua")
    if not fe:
        return refs
    for key, (_s,_e), body in iterate_map_blocks(fe.content):
        for sid, blk, _span in extract_stages_from_map_body(body):
            if re.search(rf'MapName\s*=\s*"{re.escape(map_key)}"', blk):
                refs.append(f"{key}.Stage{sid} -> NextStage.MapName")
    return refs

def find_item_references(item_id: str, files: Dict[str, FileEntry]) -> List[str]:
    refs = []
    fe_map = files.get("MapDataModule.lua")
    fe_q   = files.get("QuestDataModule.lua")
    if fe_map:
        for key, (_s,_e), body in iterate_map_blocks(fe_map.content):
            for sid, blk, _span in extract_stages_from_map_body(body):
                if re.search(rf'id\s*=\s*"{re.escape(item_id)}"', blk):
                    refs.append(f"Map:{key}.Stage{sid}.Rewards")
    if fe_q:
        for m in re.finditer(r'{[^}]*id\s*=\s*"' + re.escape(item_id) + r'"[^}]*}', fe_q.content):
            refs.append("QuestDataModule.lua: rewards")
    return refs

def find_unit_references(unit_id: str, files: Dict[str, FileEntry]) -> List[str]:
    refs = []
    for name, fe in files.items():
        if name == "UnitDataModule.lua":
            continue
        if re.search(rf'\b{re.escape(unit_id)}\b', fe.content):
            refs.append(f"{name}")
    return refs

# -------------------------------------------
# GUI
# -------------------------------------------
class AutoCompleteCombo(ttk.Combobox):
    def __init__(self, master=None, **kw):
        super().__init__(master, **kw)
        self._all_values: List[str] = list(self['values']) if 'values' in self.keys() else []
        self.bind("<KeyRelease>", self._on_keyrelease)
        self.bind("<<ComboboxSelected>>", self._on_selected)

    def set_values(self, values: List[str]):
        self._all_values = list(values)
        self['values'] = values

    def _on_selected(self, _e=None):
        self['values'] = self._all_values

    def _on_keyrelease(self, event: tk.Event):
        if event.keysym in ("BackSpace", "Left", "Right", "Up", "Down", "Home", "End", "Escape", "Return", "Tab"):
            if event.keysym == "Escape":
                self.set("")
                self['values'] = self._all_values
            return
        typed = self.get()
        if not typed:
            self['values'] = self._all_values
            return
        pat = typed.lower()
        filtered = [v for v in self._all_values if pat in v.lower()]
        self['values'] = filtered if filtered else self._all_values
        self.event_generate('<Down>')

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Waveborn TD – Data Tool (Pro)")
        self.geometry("1720x1080")

        self.files: Dict[str, FileEntry] = {}
        self.map_index: List[MapInfo] = []
        self.item_index: List[ItemInfo] = []
        self.enemy_index: List[EnemyInfo] = []
        self.unit_index: List[str] = []

        # Registry
        self.map_id_registry: Dict[str, str] = load_map_id_registry()

        # Global: Backups-Schalter
        self.use_backups = tk.BooleanVar(value=True)

        # Refs für globale Comboboxen (für Refresh)
        self.sd_src_combo: Optional[AutoCompleteCombo] = None
        self.sd_dst_combo: Optional[AutoCompleteCombo] = None
        self.sd_nextworld_combo: Optional[AutoCompleteCombo] = None
        self.sr_map_combo: Optional[AutoCompleteCombo] = None
        self.sg_map_combo: Optional[AutoCompleteCombo] = None

        # Deleter für Units/Items
        self.del_unit_combo: Optional[AutoCompleteCombo] = None
        self.del_item_combo: Optional[AutoCompleteCombo] = None

        # Quest Delete UI
        self.q_list_tree: Optional[ttk.Treeview] = None
        self.q_list_cat = tk.StringVar(value="Daily")

        # Map-Manager Edit-State
        self.mm_edit_selected_key: Optional[str] = None

        self._build_ui()

    # ---------- Helper (Backups berücksichtigen) ----------
    def maybe_backup(self, fe: FileEntry):
        if self.use_backups.get():
            backup_file(fe.path, fe.content)

    # ---------- UI Grundgerüst ----------
    def _build_ui(self):
        top = ttk.Frame(self); top.pack(side=tk.TOP, fill=tk.X, padx=8, pady=6)

        ttk.Button(top, text="Lua‑Dateien öffnen…", command=self.open_files).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Scannen", command=self.scan_all).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Alle Auto‑Fixes", command=self.apply_all_fixes).pack(side=tk.LEFT, padx=4)

        ttk.Button(top, text="Batch‑Save", command=self.batch_save).pack(side=tk.LEFT, padx=8)
        ttk.Checkbutton(top, text="Backups erstellen", variable=self.use_backups).pack(side=tk.LEFT, padx=(0,10))
        ttk.Button(top, text="Diff (markierte)", command=self.show_diff_selected).pack(side=tk.LEFT, padx=4)

        main = ttk.Panedwindow(self, orient=tk.HORIZONTAL)
        main.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)

        # Linke Seite: Dateiliste + Vorschau/Issues
        left = ttk.Notebook(main)
        main.add(left, weight=1)

        self.file_list_box = ttk.Frame(left)
        left.add(self.file_list_box, text="Dateien")
        self._build_file_list_panel(self.file_list_box)

        self.preview_issue_tab = ttk.Frame(left)
        left.add(self.preview_issue_tab, text="Vorschau & Issues")
        self._build_preview_issues_panel(self.preview_issue_tab)

        # Rechte Seite: Domänen-Tabs
        right = ttk.Notebook(main)
        main.add(right, weight=3)

        maps_tab = ttk.Notebook(right)
        right.add(maps_tab, text="Maps")
        self._build_map_tabs(maps_tab)

        quests_tab = ttk.Notebook(right)
        right.add(quests_tab, text="Quests")
        self._build_quests_tabs(quests_tab)

        units_tab = ttk.Frame(right)
        right.add(units_tab, text="Units")
        self._build_units_tab(units_tab)

        items_tab = ttk.Frame(right)
        right.add(items_tab, text="Items")
        self._build_items_tab(items_tab)  # NEU: kompletter Item-Editor

        enemies_tab = ttk.Frame(right)
        right.add(enemies_tab, text="Enemies")
        self._build_enemies_tab(enemies_tab)

        analysis_tab = ttk.Frame(right)
        right.add(analysis_tab, text="Analyse")
        self._build_analysis_tab(analysis_tab)

        qs_tab = ttk.Frame(right)
        right.add(qs_tab, text="QS")
        self._build_qs_tab(qs_tab)

    # ---------- Linker Bereich ----------
    def _build_file_list_panel(self, parent: ttk.Frame):
        top = ttk.Frame(parent); top.pack(fill=tk.X)
        ttk.Label(top, text="Geladene Dateien").pack(side=tk.LEFT, padx=8, pady=6)

        self.file_list = tk.Listbox(parent, selectmode=tk.EXTENDED, height=20)
        self.file_list.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)
        self.file_list.bind("<<ListboxSelect>>", self.update_preview)

    def _build_preview_issues_panel(self, parent: ttk.Frame):
        split = ttk.Panedwindow(parent, orient=tk.VERTICAL)
        split.pack(fill=tk.BOTH, expand=True, padx=6, pady=6)

        prev_frame = ttk.Frame(split)
        self.preview = ScrolledText(prev_frame, wrap=tk.NONE, height=15)
        self.preview.pack(fill=tk.BOTH, expand=True)
        split.add(prev_frame, weight=1)

        issues_frame = ttk.Frame(split)
        self.issues_tree = ttk.Treeview(issues_frame, columns=("sev","code","msg"), show="headings")
        self.issues_tree.heading("sev", text="Stufe")
        self.issues_tree.heading("code", text="Code")
        self.issues_tree.heading("msg", text="Beschreibung")
        self.issues_tree.column("sev", width=100)
        self.issues_tree.column("code", width=300)
        self.issues_tree.column("msg", width=800)
        self.issues_tree.pack(fill=tk.BOTH, expand=True)
        fbtn = ttk.Frame(issues_frame); fbtn.pack(fill=tk.X)
        ttk.Button(fbtn, text="Auto‑Fix (markiert)", command=self.apply_selected_fix).pack(side=tk.LEFT, padx=4, pady=4)
        ttk.Button(fbtn, text="Vorschau aktualisieren", command=self.update_preview).pack(side=tk.LEFT, padx=4, pady=4)
        split.add(issues_frame, weight=1)

    # ---------- MAPS: Sammel-Tab ----------
    def _build_map_tabs(self, nb: ttk.Notebook):
        f_manager = ttk.Frame(nb); nb.add(f_manager, text="Manager")
        self._build_map_manager_tab(f_manager)

        f_tpl = ttk.Frame(nb); nb.add(f_tpl, text="Vorlage")
        self._build_map_template_tab(f_tpl)

        f_dup = ttk.Frame(nb); nb.add(f_dup, text="Stage kopieren")
        self._build_stage_duplicate_tab(f_dup)

        f_rewards = ttk.Frame(nb); nb.add(f_rewards, text="Stage‑Rewards")
        self._build_stage_rewards_tab(f_rewards)

        f_groups = ttk.Frame(nb); nb.add(f_groups, text="Stage‑Groups")
        self._build_stage_groups_tab(f_groups)

    # ---- Map‑Manager (Liste, Bearbeiten, Löschen, Registry) ----
    def _build_map_manager_tab(self, f: ttk.Frame):
        self.mm_list = ttk.Treeview(f, columns=("key","display","place"), show="headings", height=12, selectmode="browse")
        for cid, txt, w in [("key","MapKey",240),("display","DisplayName",280),("place","PlaceId",200)]:
            self.mm_list.heading(cid, text=txt)
            self.mm_list.column(cid, width=w, anchor=tk.W)
        self.mm_list.grid(row=0, column=0, columnspan=6, sticky="nsew", padx=8, pady=8)
        f.rowconfigure(0, weight=1); f.columnconfigure(1, weight=1)
        self.mm_list.bind("<<TreeviewSelect>>", self.mm_on_select)
        self.mm_list.bind("<Double-1>", self.mm_on_select)

        btns = ttk.Frame(f); btns.grid(row=1, column=0, columnspan=6, sticky="w", padx=8, pady=(0,6))
        ttk.Button(btns, text="Liste aktualisieren", command=self.mm_refresh_index).pack(side=tk.LEFT, padx=4)
        ttk.Button(btns, text="Auswahl löschen", command=self.mm_delete_selected).pack(side=tk.LEFT, padx=4)

        sep = ttk.Separator(f, orient=tk.HORIZONTAL); sep.grid(row=2, column=0, columnspan=6, sticky="ew", padx=8, pady=(0,6))
        ttk.Label(f, text="Map bearbeiten / anlegen").grid(row=3, column=0, sticky="w", padx=8, pady=(4,2))

        self.mm_key = tk.StringVar()
        self.mm_display = tk.StringVar()
        self.mm_place = tk.StringVar()

        ttk.Label(f, text="Map Key").grid(row=4, column=0, sticky="e", padx=6, pady=2)
        self.mm_key_entry = ttk.Entry(f, textvariable=self.mm_key, width=30)
        self.mm_key_entry.grid(row=4, column=1, sticky="w", padx=6, pady=2)

        ttk.Label(f, text="DisplayName").grid(row=4, column=2, sticky="e", padx=6, pady=2)
        ttk.Entry(f, textvariable=self.mm_display, width=30).grid(row=4, column=3, sticky="w", padx=6, pady=2)

        ttk.Label(f, text="PlaceId (Zahl)").grid(row=5, column=0, sticky="e", padx=6, pady=2)
        ttk.Entry(f, textvariable=self.mm_place, width=30).grid(row=5, column=1, sticky="w", padx=6, pady=2)

        reg_row = ttk.Frame(f); reg_row.grid(row=6, column=0, columnspan=4, sticky="w", padx=8, pady=4)
        ttk.Label(reg_row, text="Registry").pack(side=tk.LEFT, padx=(0,6))
        self.mm_reg_values = tk.StringVar()
        self.mm_reg_combo = ttk.Combobox(reg_row, textvariable=self.mm_reg_values, state="readonly", width=45,
                                         values=self._reg_list_values())
        self.mm_reg_combo.pack(side=tk.LEFT)
        ttk.Button(reg_row, text="Aus Registry übernehmen", command=self.mm_take_from_registry).pack(side=tk.LEFT, padx=6)
        ttk.Button(reg_row, text="Aktuelle in Registry speichern", command=self.mm_save_to_registry).pack(side=tk.LEFT, padx=6)

        btn_row = ttk.Frame(f); btn_row.grid(row=7, column=0, columnspan=6, sticky="w", padx=8, pady=8)
        self.mm_apply_btn = ttk.Button(btn_row, text="Änderungen übernehmen (Auswahl)", command=self.mm_apply_changes, state="disabled")
        self.mm_apply_btn.pack(side=tk.LEFT, padx=(0,8))
        ttk.Button(btn_row, text="Neue Map speichern", command=self.mm_save_map).pack(side=tk.LEFT, padx=4)

    def _reg_list_values(self) -> List[str]:
        return [f"{k} → {v}" for k,v in sorted(self.map_id_registry.items())]

    def mm_take_from_registry(self):
        sel = self.mm_reg_combo.get().strip()
        if not sel or "→" not in sel:
            return
        key, val = [p.strip() for p in sel.split("→", 1)]
        if not self.mm_key.get().strip():
            self.mm_key.set(key)
        self.mm_place.set(val)

    def mm_save_to_registry(self):
        key = self.mm_key.get().strip()
        place = self.mm_place.get().strip()
        if not key or not place.isdigit():
            messagebox.showwarning("Validierung", "Map Key und numerische PlaceId erforderlich.")
            return
        self.map_id_registry[key] = place
        save_map_id_registry(self.map_id_registry)
        self.mm_reg_combo['values'] = self._reg_list_values()
        messagebox.showinfo("Registry", f"Eintrag gespeichert: {key} → {place}")

    def mm_refresh_index(self):
        self.map_index = []
        fe = self.files.get("MapDataModule.lua")
        if fe:
            txt = fe.content.split("--[[!strict")[0]
            self.map_index = extract_map_info_list(txt)
        for i in self.mm_list.get_children(): self.mm_list.delete(i)
        for mi in self.map_index:
            self.mm_list.insert("", tk.END, values=(mi.key, mi.display, mi.place_id))
        self.mm_edit_selected_key = None
        self.mm_apply_btn.config(state="disabled")
        self.mm_key_entry.config(state="normal")
        self.mm_reg_combo['values'] = self._reg_list_values()
        self._refresh_map_dropdowns()

    def mm_on_select(self, _e=None):
        sel = self.mm_list.focus()
        if not sel:
            self.mm_edit_selected_key = None
            self.mm_apply_btn.config(state="disabled")
            self.mm_key_entry.config(state="normal")
            return
        vals = self.mm_list.item(sel, "values")
        if not vals: return
        key, display, place = vals
        self.mm_edit_selected_key = key
        self.mm_key.set(key); self.mm_display.set(display); self.mm_place.set(place)
        self.mm_key_entry.config(state="disabled")
        self.mm_apply_btn.config(state="normal")

    def mm_delete_selected(self):
        fe = self.files.get("MapDataModule.lua")
        if not fe:
            messagebox.showwarning("Hinweis", "Bitte 'MapDataModule.lua' laden.")
            return
        sel = self.mm_list.focus()
        if not sel:
            messagebox.showwarning("Hinweis", "Bitte eine Map aus der Liste markieren.")
            return
        vals = self.mm_list.item(sel, "values")
        if not vals:
            return
        mk = vals[0]
        refs = find_map_references(mk, self.files)
        if refs:
            if not messagebox.askyesno("Bestätigung",
                f"Map '{mk}' wird in folgenden NextStage‑Verweisen benutzt:\n- " + "\n- ".join(refs) + "\n\nTrotzdem löschen?"):
                return
        if self.use_backups.get():
            backup_file(fe.path, fe.content)
        new_txt = delete_map_block(fe.content, mk)
        if new_txt == fe.content:
            messagebox.showerror("Fehler", f'Map‑Block "{mk}" wurde nicht entfernt (Layout unerwartet).')
            return
        fe.content = new_txt
        write_text(fe.path, fe.content); fe.original = fe.content
        self.mm_refresh_index()
        self.update_preview()
        messagebox.showinfo("Gelöscht", f'Map "{mk}" entfernt.')

    def mm_apply_changes(self):
        if not self.mm_edit_selected_key:
            messagebox.showwarning("Hinweis", "Bitte zuerst eine Map aus der Liste markieren.")
            return
        fe = self.files.get("MapDataModule.lua")
        if not fe:
            messagebox.showwarning("Hinweis", "Bitte 'MapDataModule.lua' laden.")
            return
        display = self.mm_display.get().strip() or self.mm_edit_selected_key
        place = self.mm_place.get().strip()
        if not re.match(r'^\d+$', place):
            messagebox.showwarning("Validierung", "PlaceId muss numerisch sein."); return
        if self.use_backups.get():
            backup_file(fe.path, fe.content)
        fe.content = update_map_fields(fe.content, self.mm_edit_selected_key, display, place)
        write_text(fe.path, fe.content)
        fe.original = fe.content
        if self.mm_edit_selected_key in self.map_id_registry:
            self.map_id_registry[self.mm_edit_selected_key] = place
            save_map_id_registry(self.map_id_registry)
            self.mm_reg_combo['values'] = self._reg_list_values()
        self.mm_refresh_index()
        self.update_preview()
        messagebox.showinfo("OK", f"Änderungen für '{self.mm_edit_selected_key}' übernommen.")

    def mm_save_map(self):
        fe = self.files.get("MapDataModule.lua")
        if not fe:
            messagebox.showwarning("Hinweis", "Bitte 'MapDataModule.lua' laden.")
            return
        key = self.mm_key.get().strip()
        display = self.mm_display.get().strip() or key
        place = self.mm_place.get().strip()
        if not key:
            messagebox.showwarning("Validierung", "Map Key fehlt."); return
        if not re.match(r'^\d+$', place):
            messagebox.showwarning("Validierung", "PlaceId muss numerisch sein."); return
        if any(mi.key == key for mi in self.map_index):
            messagebox.showwarning("Validierung", f"Map Key '{key}' existiert bereits."); return
        block = f'''["{key}"] = {{
            DisplayName = "{display}",
            PlaceId     = {place},

            Stages = {{
                -- neue Stages hier hinzufügen
            }},
        }},'''
        if self.use_backups.get():
            backup_file(fe.path, fe.content)
        fe.content = insert_into_map(fe.content, block)
        write_text(fe.path, fe.content); fe.original = fe.content
        self.map_id_registry[key] = place
        save_map_id_registry(self.map_id_registry)
        self.mm_reg_combo['values'] = self._reg_list_values()
        self.mm_key.set(""); self.mm_display.set(""); self.mm_place.set("")
        self.mm_refresh_index()
        self.update_preview()
        messagebox.showinfo("OK", f"Map '{key}' gespeichert.")

    def _refresh_map_dropdowns(self):
        keys = [mi.key for mi in self.map_index]
        if self.sd_src_combo: self.sd_src_combo.set_values(keys)
        if self.sd_dst_combo: self.sd_dst_combo.set_values(keys)
        if self.sd_nextworld_combo: self.sd_nextworld_combo.set_values(keys)
        if self.sr_map_combo: self.sr_map_combo.set_values(keys)
        if self.sg_map_combo: self.sg_map_combo.set_values(keys)

    # ---- Map‑Vorlage (inkl. Registry) ----
    def _build_map_template_tab(self, f: ttk.Frame):
        self.mt_key = tk.StringVar()
        self.mt_display = tk.StringVar()
        self.mt_place = tk.StringVar()
        self.mt_theme = tk.StringVar(value="Generic")
        self.mt_next_world = tk.StringVar()

        row=0
        for label,var in [("Map Key", self.mt_key), ("DisplayName", self.mt_display), ("PlaceId (Zahl)", self.mt_place)]:
            ttk.Label(f, text=label).grid(row=row, column=0, sticky="e", padx=6, pady=4)
            ttk.Entry(f, textvariable=var, width=40).grid(row=row, column=1, sticky="w", padx=6, pady=4)
            row += 1

        ttk.Label(f, text="Registry").grid(row=row, column=0, sticky="e", padx=6, pady=4)
        self.mt_reg_sel = tk.StringVar()
        self.mt_reg_combo = ttk.Combobox(f, textvariable=self.mt_reg_sel, width=37, state="readonly",
                                         values=[f"{k} → {v}" for k,v in sorted(self.map_id_registry.items())])
        self.mt_reg_combo.grid(row=row, column=1, sticky="w", padx=6, pady=4)
        ttk.Button(f, text="Übernehmen", command=self.mt_take_from_registry).grid(row=row, column=2, sticky="w", padx=6, pady=4)
        ttk.Button(f, text="Aktuelle in Registry speichern", command=self.mt_save_to_registry).grid(row=row, column=3, sticky="w", padx=6, pady=4)
        row += 1

        ttk.Label(f, text="Theme").grid(row=row, column=0, sticky="e", padx=6, pady=4)
        ttk.Combobox(f, textvariable=self.mt_theme, values=["Generic","SpiritRealm","CityOfAshes"], width=37, state="readonly").grid(row=row, column=1, sticky="w", padx=6, pady=4); row+=1

        ttk.Label(f, text="Next‑World MapKey (optional Override)").grid(row=row, column=0, sticky="e", padx=6, pady=4)
        self.mt_theme_next_combo = AutoCompleteCombo(f, textvariable=self.mt_next_world, values=[], width=37, state="readonly")
        self.mt_theme_next_combo.grid(row=row, column=1, sticky="w", padx=6, pady=4); row+=1

        ttk.Button(f, text="Map mit Vorlage erstellen → MapDataModule.lua", command=self.create_map_template).grid(row=row, column=0, columnspan=2, pady=10)

    def mt_take_from_registry(self):
        sel = self.mt_reg_combo.get().strip()
        if not sel or "→" not in sel:
            return
        key, val = [p.strip() for p in sel.split("→", 1)]
        if not self.mt_key.get().strip():
            self.mt_key.set(key)
        self.mt_place.set(val)

    def mt_save_to_registry(self):
        key = self.mt_key.get().strip()
        place = self.mt_place.get().strip()
        if not key or not place.isdigit():
            messagebox.showwarning("Validierung", "Map Key und numerische PlaceId erforderlich.")
            return
        self.map_id_registry[key] = place
        save_map_id_registry(self.map_id_registry)
        self.mt_reg_combo['values'] = [f"{k} → {v}" for k,v in sorted(self.map_id_registry.items())]
        messagebox.showinfo("Registry", f"Eintrag gespeichert: {key} → {place}")

    def _need(self, name: str) -> Optional[FileEntry]:
        fe = self.files.get(name)
        if not fe:
            messagebox.showwarning("Hinweis", f"Bitte '{name}' laden.")
        return fe

    def create_map_template(self):
        fe = self._need("MapDataModule.lua"); 
        if not fe: return
        key = self.mt_key.get().strip()
        disp = self.mt_display.get().strip() or key
        place = self.mt_place.get().strip()
        if not re.match(r'^\d+$', place):
            messagebox.showwarning("Validierung", "PlaceId muss numerisch sein."); return
        theme = self.mt_theme.get()
        next_world = self.mt_next_world.get().strip()

        def group_pool(theme_name):
            if theme_name == "SpiritRealm":
                return [
                    '{ type = "Basic", count = 5, delay = 0.4, weight = 5 },',
                    '{ type = "Fast", count = 4, delay = 0.3, weight = 3 },',
                    '{ type = "Tank", count = 2, delay = 0.8, weight = 2 },'
                ]
            if theme_name == "CityOfAshes":
                return [
                    '{ type = "Basic", count = 5, delay = 0.5, weight = 5 },',
                    '{ type = "Miniboss", count = 1, delay = 1.2, weight = 1 },'
                ]
            return ['{ type = "Basic", count = 5, delay = 0.5, weight = 5 },']

        def boss_waves(theme_name):
            if theme_name == "SpiritRealm": return "{ 5, 10, 15 }"
            if theme_name == "CityOfAshes": return "{ 6, 12 }"
            return "{}"

        stages = []
        for sid in range(1,7):
            pool = "\n                        ".join(group_pool(theme))
            bw = boss_waves(theme)
            base_stage = f'''{{
                    StageId = {sid},
                    Name = "Stage {sid}",
                    WaveConfig = {{
                        WaveCount = {15 if sid>1 else 2},
                        TotalEnemies = {400 if sid>1 else 5},
                        MinEnemiesPerWave = {20 if sid>1 else 1},
                        BossScaling = 2.5,
                        SpawnRandomSeed = {42 + sid},
                        BossWaves = {bw},
                        GroupPool = {{
                        {pool}
                        }},
                    }},
                    Rewards = {{
                        {{ type = "Eclipsium", amount = {100 if sid<3 else 150 if sid<5 else 200} }},
                        {{ type = "Scroll", id = "SummonScroll_Common", amount = {1 if sid in (1,3,4,6) else 2} }},
                    }}'''
            if sid == 6 and next_world:
                base_stage += f''',
                    NextStage = {{
                        MapName = "{next_world}",
                        StageId = 1
                    }}'''
            base_stage += "\n                },"
            stages.append(base_stage)

        block = f'''["{key}"] = {{
            DisplayName = "{disp}",
            PlaceId     = {place},

            Stages = {{
{chr(10).join("                "+s for s in stages)}
            }},
        }},'''
        try:
            if self.use_backups.get():
                backup_file(fe.path, fe.content)
            fe.content = insert_into_map(fe.content, block)
            write_text(fe.path, fe.content); fe.original = fe.content
            self.map_id_registry[key] = place
            save_map_id_registry(self.map_id_registry)
            self.mm_refresh_index()
            self.update_preview()
            messagebox.showinfo("OK", f"Map '{key}' mit 6 Stages erstellt.{(' NextStage zu '+next_world+' gesetzt.' if next_world else '')}")
        except Exception as e:
            messagebox.showerror("Fehler", f"Einfügen fehlgeschlagen:\n{e}")

    # ---- Stage kopieren ----
    def _build_stage_duplicate_tab(self, f: ttk.Frame):
        self.sd_src_map = tk.StringVar()
        self.sd_src_id  = tk.IntVar(value=1)
        self.sd_dst_map = tk.StringVar()
        self.sd_new_id  = tk.IntVar(value=1)
        self.sd_auto_next = tk.BooleanVar(value=True)
        self.sd_next_world = tk.StringVar()

        ttk.Label(f, text="Quelle Map Key").grid(row=0, column=0, sticky="e", padx=6, pady=4)
        self.sd_src_combo = AutoCompleteCombo(f, textvariable=self.sd_src_map, values=[], width=34, state="readonly")
        self.sd_src_combo.grid(row=0, column=1, sticky="w", padx=6, pady=4)

        ttk.Label(f, text="Quelle StageId").grid(row=1, column=0, sticky="e", padx=6, pady=4)
        ttk.Entry(f, textvariable=self.sd_src_id, width=10).grid(row=1, column=1, sticky="w", padx=6, pady=4)

        ttk.Label(f, text="Ziel Map Key").grid(row=2, column=0, sticky="e", padx=6, pady=4)
        self.sd_dst_combo = AutoCompleteCombo(f, textvariable=self.sd_dst_map, values=[], width=34, state="readonly")
        self.sd_dst_combo.grid(row=2, column=1, sticky="w", padx=6, pady=4)

        ttk.Label(f, text="Neue StageId").grid(row=3, column=0, sticky="e", padx=6, pady=4)
        ttk.Entry(f, textvariable=self.sd_new_id, width=10).grid(row=3, column=1, sticky="w", padx=6, pady=4)

        ttk.Checkbutton(f, text="NextStage automatisch setzen (wenn neue StageId = 6)", variable=self.sd_auto_next).grid(row=4, column=0, columnspan=2, sticky="w", padx=6, pady=4)
        ttk.Label(f, text="Ziel‑Welt (NextStage Map) – optional").grid(row=5, column=0, sticky="e", padx=6, pady=4)
        self.sd_nextworld_combo = AutoCompleteCombo(f, textvariable=self.sd_next_world, values=[], width=34, state="readonly")
        self.sd_nextworld_combo.grid(row=5, column=1, sticky="w", padx=6, pady=4)

        ttk.Button(f, text="Stage duplizieren", command=self.do_stage_duplicate).grid(row=6, column=0, columnspan=2, pady=10)

    def do_stage_duplicate(self):
        fe = self._need("MapDataModule.lua")
        if not fe: return
        src_map = self.sd_src_map.get().strip()
        dst_map = self.sd_dst_map.get().strip()
        if not src_map or not dst_map:
            messagebox.showwarning("Validierung", "Bitte Quell‑ und Ziel‑Map wählen.")
            return
        sid = int(self.sd_src_id.get())
        nid = int(self.sd_new_id.get())
        auto_next = bool(self.sd_auto_next.get())
        next_world = self.sd_next_world.get().strip()

        try:
            fe.content = duplicate_stage(
                fe.content, src_map, sid, dst_map, nid,
                auto_set_next=auto_next, next_world_key=next_world
            )
            write_text(fe.path, fe.content); fe.original = fe.content
            self.update_preview()
            messagebox.showinfo("OK", f"Stage {sid} aus '{src_map}' → '{dst_map}' als Stage {nid} kopiert.")
        except Exception as e:
            messagebox.showerror("Fehler", str(e))

    # ---- Stage‑Rewards ----
    def _build_stage_rewards_tab(self, f: ttk.Frame):
        self.sr_map = tk.StringVar()
        self.sr_stage = tk.IntVar(value=1)
        top = ttk.Frame(f); top.pack(fill=tk.X, padx=8, pady=6)
        ttk.Label(top, text="Map Key").pack(side=tk.LEFT)
        self.sr_map_combo = AutoCompleteCombo(top, textvariable=self.sr_map, values=[], width=34, state="readonly")
        self.sr_map_combo.pack(side=tk.LEFT, padx=6)
        ttk.Label(top, text="StageId").pack(side=tk.LEFT, padx=(12,2))
        ttk.Entry(top, textvariable=self.sr_stage, width=8).pack(side=tk.LEFT)

        ttk.Button(top, text="Rewards laden", command=self._sr_load_rewards).pack(side=tk.LEFT, padx=12)
        ttk.Button(top, text="+ Reward", command=lambda: self._add_reward_row(self.sr_rows_frame, self.sr_rows)).pack(side=tk.LEFT)

        header = ttk.Frame(f); header.pack(fill=tk.X, padx=8, pady=(6,0))
        ttk.Label(header, text="Item-ID").grid(row=0, column=0, padx=2)
        ttk.Label(header, text="Amount").grid(row=0, column=1, padx=2)

        self.sr_rows_frame = ttk.Frame(f); self.sr_rows_frame.pack(fill=tk.X, padx=8, pady=4)
        self.sr_rows: List[Tuple[AutoCompleteCombo, tk.StringVar, tk.IntVar, ttk.Button]] = []

        ttk.Button(f, text="Rewards in MapDataModule.lua übernehmen", command=self._sr_apply_rewards).pack(pady=10)

    def _add_reward_row(self, parent: ttk.Frame, rows_store: List, default_item: Optional[str]=None, default_amount: int=1):
        item_var = tk.StringVar(value=default_item or "")
        amt_var  = tk.IntVar(value=default_amount)
        row = ttk.Frame(parent); row.pack(fill=tk.X, pady=2)
        combo = AutoCompleteCombo(row, textvariable=item_var, values=[it.id for it in self.item_index], width=34, state="readonly")
        combo.pack(side=tk.LEFT, padx=2)
        ttk.Entry(row, textvariable=amt_var, width=8).pack(side=tk.LEFT, padx=6)
        btn = ttk.Button(row, text="Entfernen", command=lambda: self._remove_reward_row(row, rows_store))
        btn.pack(side=tk.LEFT, padx=6)
        rows_store.append((combo, item_var, amt_var, btn))

    def _remove_reward_row(self, row: ttk.Frame, rows_store: List):
        for i, tup in enumerate(rows_store):
            if tup[0].master == row:
                rows_store.pop(i); break
        row.destroy()

    def _reward_line_from_item(self, item_id: str, amount: int) -> Optional[str]:
        if not item_id or amount <= 0: return None
        info = None
        for it in self.item_index:
            if it.id == item_id or (item_id == "Eclipsium" and it.category == "Eclipsium"):
                if item_id == "Eclipsium" and it.category != "Eclipsium":
                    continue
                info = it; break
        if item_id == "Eclipsium" and info is None:
            return f'{{ type = "Eclipsium", amount = {int(amount)} }},'
        if not info:
            return None
        cat = info.category
        if cat == "Eclipsium":
            return f'{{ type = "Eclipsium", amount = {int(amount)} }},'
        else:
            return f'{{ type = "{cat}", id = "{info.id}", amount = {int(amount)} }},'

    def _sr_load_rewards(self):
        fe = self._need("MapDataModule.lua")
        if not fe: return
        map_key = self.sr_map.get().strip()
        stage_id = int(self.sr_stage.get())
        if not map_key:
            messagebox.showwarning("Validierung", "Map Key wählen."); return

        for combo, iv, av, btn in list(self.sr_rows):
            combo.master.destroy()
        self.sr_rows.clear()

        found = False
        for key, (_s,_e), body in iterate_map_blocks(fe.content):
            if key != map_key: continue
            for sid, blk, _span in extract_stages_from_map_body(body):
                if sid != stage_id: continue
                found = True
                rb = rewards_block(blk)
                items = parse_rewards_items(rb)
                if not items:
                    self._add_reward_row(self.sr_rows_frame, self.sr_rows, default_item="Eclipsium", default_amount=100)
                else:
                    for item_id, amt in items:
                        self._add_reward_row(self.sr_rows_frame, self.sr_rows, default_item=item_id, default_amount=amt)
        if not found:
            messagebox.showwarning("Hinweis", f"Stage {stage_id} in Map '{map_key}' nicht gefunden.")

    def _sr_apply_rewards(self):
        fe = self._need("MapDataModule.lua")
        if not fe: return
        map_key = self.sr_map.get().strip()
        stage_id = int(self.sr_stage.get())
        if not map_key:
            messagebox.showwarning("Validierung", "Map Key wählen."); return

        lines = []
        for combo, item_var, amt_var, _btn in self.sr_rows:
            rid = item_var.get().strip()
            amt = int(amt_var.get())
            ln = self._reward_line_from_item(rid, amt)
            if ln: lines.append(ln)
        if not lines:
            messagebox.showwarning("Validierung", "Mindestens einen Reward auswählen."); return
        new_rewards_text = "                    " + "\n                    ".join(lines)

        txt = fe.content
        new_txt = txt
        replaced = False
        for key, (bstart, bend), body in iterate_map_blocks(txt):
            if key != map_key: continue
            stages = extract_stages_from_map_body(body)
            new_body = body
            for sid, blk, span in stages:
                if sid != stage_id: continue
                m = re.search(r'(Rewards\s*=\s*{)(.*?)(\n\s*}\s*,)', blk, flags=re.S)
                if not m:
                    messagebox.showerror("Fehler", "Rewards‑Block in Stage nicht gefunden.")
                    return
                blk_new = blk[:m.start(2)] + "\n" + new_rewards_text + blk[m.end(2):]
                rel_start, rel_end = span
                new_body = new_body[:rel_start] + blk_new + new_body[rel_end:]
                replaced = True
                break
            if replaced:
                new_txt = txt[:bstart] + new_body + txt[bend:]
                break

        if not replaced:
            messagebox.showwarning("Hinweis", "Kein passender Stage‑Block ersetzt.")
            return

        if self.use_backups.get():
            backup_file(fe.path, fe.content)
        fe.content = new_txt
        write_text(fe.path, fe.content); fe.original = fe.content
        self.update_preview()
        messagebox.showinfo("OK", f"Rewards für {map_key} – Stage {stage_id} übernommen.")

    # ---- Stage‑Groups ----
    def _build_stage_groups_tab(self, f: ttk.Frame):
        self.sg_map = tk.StringVar()
        self.sg_stage = tk.IntVar(value=1)
        top = ttk.Frame(f); top.pack(fill=tk.X, padx=8, pady=6)
        ttk.Label(top, text="Map Key").pack(side=tk.LEFT)
        self.sg_map_combo = AutoCompleteCombo(top, textvariable=self.sg_map, values=[], width=34, state="readonly")
        self.sg_map_combo.pack(side=tk.LEFT, padx=6)
        ttk.Label(top, text="StageId").pack(side=tk.LEFT, padx=(12,2))
        ttk.Entry(top, textvariable=self.sg_stage, width=8).pack(side=tk.LEFT)
        ttk.Button(top, text="Groups laden", command=self._sg_load_groups).pack(side=tk.LEFT, padx=12)
        ttk.Button(top, text="+ Group", command=self._sg_add_group_row).pack(side=tk.LEFT)

        header = ttk.Frame(f); header.pack(fill=tk.X, padx=8, pady=(6,0))
        for i, t in enumerate(["Enemy‑Type","Count","Delay","Weight"]):
            ttk.Label(header, text=t).grid(row=0, column=i, padx=4)
        self.sg_rows_frame = ttk.Frame(f); self.sg_rows_frame.pack(fill=tk.X, padx=8, pady=4)
        self.sg_rows: List[Tuple[AutoCompleteCombo, tk.IntVar, tk.DoubleVar, tk.IntVar, ttk.Button]] = []
        ttk.Button(f, text="Groups in MapDataModule.lua übernehmen", command=self._sg_apply_groups).pack(pady=10)

    def _sg_add_group_row(self, default_type: str = "", default_count: int = 1, default_delay: float = 0.5, default_weight: int = 1):
        row = ttk.Frame(self.sg_rows_frame); row.pack(fill=tk.X, pady=2)
        et_var = tk.StringVar(value=default_type)
        c_var  = tk.IntVar(value=default_count)
        d_var  = tk.DoubleVar(value=default_delay)
        w_var  = tk.IntVar(value=default_weight)
        combo = AutoCompleteCombo(row, textvariable=et_var, values=[e.id for e in self.enemy_index], width=30, state="readonly")
        combo.grid(row=0, column=0, padx=4)
        ttk.Entry(row, textvariable=c_var, width=8).grid(row=0, column=1, padx=4)
        ttk.Entry(row, textvariable=d_var, width=8).grid(row=0, column=2, padx=4)
        ttk.Entry(row, textvariable=w_var, width=8).grid(row=0, column=3, padx=4)
        btn = ttk.Button(row, text="Entfernen", command=lambda r=row: (self._sg_remove_row(r)))
        btn.grid(row=0, column=4, padx=6)
        self.sg_rows.append((combo, c_var, d_var, w_var, btn))

    def _sg_remove_row(self, row: ttk.Frame):
        for i, tup in enumerate(self.sg_rows):
            if tup[0].master == row:
                self.sg_rows.pop(i); break
        row.destroy()

    def _sg_load_groups(self):
        fe = self._need("MapDataModule.lua")
        if not fe: return
        if "EnemyDataModule.lua" in self.files:
            self.enemy_index = extract_enemies(self.files["EnemyDataModule.lua"].content)
        for combo, *_ in list(self.sg_rows):
            combo.master.destroy()
        self.sg_rows.clear()

        map_key = self.sg_map.get().strip()
        stage_id = int(self.sg_stage.get())
        if not map_key:
            messagebox.showwarning("Validierung", "Map Key wählen."); return

        found = False
        for key, (_s,_e), body in iterate_map_blocks(fe.content):
            if key != map_key: continue
            for sid, blk, _span in extract_stages_from_map_body(body):
                if sid != stage_id: continue
                found = True
                gpm = re.search(r'GroupPool\s*=\s*{(.*?)}\s*,', blk, flags=re.S)
                if not gpm:
                    self._sg_add_group_row()
                else:
                    inner = gpm.group(1)
                    for m in re.finditer(r'{\s*type\s*=\s*"([^"]+)"\s*,\s*count\s*=\s*(\d+)\s*,\s*delay\s*=\s*([0-9.]+)\s*,\s*weight\s*=\s*(\d+)\s*}', inner):
                        self._sg_add_group_row(m.group(1), int(m.group(2)), float(m.group(3)), int(m.group(4)))
        if not found:
            messagebox.showwarning("Hinweis", f"Stage {stage_id} in Map '{map_key}' nicht gefunden.")

    def _sg_apply_groups(self):
        fe = self._need("MapDataModule.lua")
        if not fe: return
        map_key = self.sg_map.get().strip()
        stage_id = int(self.sg_stage.get())

        lines = []
        for combo, c_var, d_var, w_var, _btn in self.sg_rows:
            et = combo.get().strip()
            if not et:
                continue
            lines.append(f'{{ type = "{et}", count = {int(c_var.get())}, delay = {float(d_var.get())}, weight = {int(w_var.get())} }},')

        new_gp_text = "                        " + "\n                        ".join(lines or ['{ type = "Basic", count = 5, delay = 0.5, weight = 5 },'])

        txt = fe.content
        new_txt = txt
        replaced = False
        for key, (bstart, bend), body in iterate_map_blocks(txt):
            if key != map_key: continue
            stages = extract_stages_from_map_body(body)
            new_body = body
            for sid, blk, span in stages:
                if sid != stage_id: continue
                m = re.search(r'(GroupPool\s*=\s*{)(.*?)(\n\s*}\s*,)', blk, flags=re.S)
                if not m:
                    messagebox.showerror("Fehler", "GroupPool in Stage nicht gefunden.")
                    return
                blk_new = blk[:m.start(2)] + "\n" + new_gp_text + blk[m.end(2):]
                rel_start, rel_end = span
                new_body = new_body[:rel_start] + blk_new + new_body[rel_end:]
                replaced = True
                break
            if replaced:
                new_txt = txt[:bstart] + new_body + txt[bend:]
                break

        if not replaced:
            messagebox.showwarning("Hinweis", "Kein passender Stage‑Block ersetzt.")
            return

        if self.use_backups.get():
            backup_file(fe.path, fe.content)
        fe.content = new_txt
        write_text(fe.path, fe.content); fe.original = fe.content
        self.update_preview()
        messagebox.showinfo("OK", f"GroupPool für {map_key} – Stage {stage_id} übernommen.")

    # ---------- Quests ----------
    def _build_quests_tabs(self, nb: ttk.Notebook):
        gen_tab = ttk.Frame(nb); nb.add(gen_tab, text="Generator")
        self._build_quest_generator_tab(gen_tab)

        list_tab = ttk.Frame(nb); nb.add(list_tab, text="Liste & Löschen")
        self._build_quest_list_tab(list_tab)

    def _build_quest_generator_tab(self, f: ttk.Frame):
        self.qg_cat = tk.StringVar(value="Daily")
        self.qg_id = tk.StringVar()
        self.qg_title = tk.StringVar()
        self.qg_desc = tk.StringVar()
        self.qg_type = tk.StringVar(value="StageClear")
        self.qg_goal = tk.IntVar(value=1)

        self.qg_rewards_frame = ttk.Frame(f)
        self.qg_reward_rows: List[Tuple[AutoCompleteCombo, tk.StringVar, tk.IntVar, ttk.Button]] = []

        grid = ttk.Frame(f); grid.pack(padx=8, pady=8, fill=tk.X)
        row=0

        ttk.Label(grid, text="Kategorie").grid(row=row, column=0, sticky="e", padx=6, pady=4)
        self.qg_cat_combo = ttk.Combobox(grid, textvariable=self.qg_cat, state="readonly",
                                         values=["Daily","Weekly","Story","Progress","Special","Trials"], width=37)
        self.qg_cat_combo.grid(row=row, column=1, sticky="w", padx=6, pady=4); row+=1

        ttk.Label(grid, text="Quest ID").grid(row=row, column=0, sticky="e", padx=6, pady=4)
        id_row = ttk.Frame(grid); id_row.grid(row=row, column=1, sticky="w")
        ttk.Entry(id_row, textvariable=self.qg_id, width=28).pack(side=tk.LEFT, padx=(0,6))
        ttk.Button(id_row, text="ID generieren", command=self.generate_next_qid).pack(side=tk.LEFT)
        row+=1

        for label,var in [("Titel", self.qg_title), ("Beschreibung", self.qg_desc)]:
            ttk.Label(grid, text=label).grid(row=row, column=0, sticky="e", padx=6, pady=4)
            ttk.Entry(grid, textvariable=var, width=40).grid(row=row, column=1, sticky="w", padx=6, pady=4); row+=1

        ttk.Label(grid, text="Typ").grid(row=row, column=0, sticky="e", padx=6, pady=4)
        ttk.Combobox(grid, textvariable=self.qg_type, values=["StageClear","Summon","RaidWin","UnitLevelUp","PlayerLevel"],
                     state="readonly", width=37).grid(row=row, column=1, sticky="w", padx=6, pady=4); row+=1

        ttk.Label(grid, text="Ziel (goal)").grid(row=row, column=0, sticky="e", padx=6, pady=4)
        ttk.Entry(grid, textvariable=self.qg_goal, width=12).grid(row=row, column=1, sticky="w", padx=6, pady=4); row+=1

        ttk.Label(f, text="Rewards (aus ItemDataModule)").pack(anchor="w", padx=8)
        header = ttk.Frame(f); header.pack(fill=tk.X, padx=8)
        ttk.Label(header, text="Item-ID").grid(row=0, column=0, padx=2)
        ttk.Label(header, text="Amount").grid(row=0, column=1, padx=2)
        ttk.Button(header, text="+ Reward", command=lambda: self._add_reward_row(self.qg_rewards_frame, self.qg_reward_rows)).grid(row=0, column=2, padx=8)
        self.qg_rewards_frame.pack(fill=tk.X, padx=8, pady=4)

        ttk.Button(f, text="Quest einfügen → QuestDataModule.lua", command=self.generate_quest).pack(pady=10)

        self._add_reward_row(self.qg_rewards_frame, self.qg_reward_rows, default_item="Eclipsium", default_amount=250)
        self._add_reward_row(self.qg_rewards_frame, self.qg_reward_rows, default_item="SummonScroll_Common", default_amount=1)

    def _build_quest_list_tab(self, f: ttk.Frame):
        top = ttk.Frame(f); top.pack(fill=tk.X, padx=8, pady=(8,4))
        ttk.Label(top, text="Kategorie").pack(side=tk.LEFT)
        qcat = ttk.Combobox(top, textvariable=self.q_list_cat, state="readonly", width=20,
                            values=["Daily","Weekly","Story","Progress","Special","Trials"])
        qcat.pack(side=tk.LEFT, padx=6)
        ttk.Button(top, text="Quests laden", command=self._q_list_refresh).pack(side=tk.LEFT, padx=6)
        ttk.Button(top, text="Ausgewählte Quest löschen", command=self._q_delete_selected).pack(side=tk.LEFT, padx=6)

        cols = ("id","title","type","goal")
        self.q_list_tree = ttk.Treeview(f, columns=cols, show="headings", height=14, selectmode="browse")
        self.q_list_tree.heading("id", text="ID");     self.q_list_tree.column("id", width=140, anchor=tk.W)
        self.q_list_tree.heading("title", text="Titel");self.q_list_tree.column("title", width=300, anchor=tk.W)
        self.q_list_tree.heading("type", text="Typ");   self.q_list_tree.column("type", width=140, anchor=tk.W)
        self.q_list_tree.heading("goal", text="Goal");  self.q_list_tree.column("goal", width=80, anchor=tk.E)
        self.q_list_tree.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)

    def generate_next_qid(self):
        fe = self._need("QuestDataModule.lua")
        if not fe: return
        cat = self.qg_cat.get().strip()
        prefix = {"Daily":"D_","Weekly":"W_","Story":"S_","Progress":"P_","Special":"SP_","Trials":"T_"}.get(cat, "Q_")
        cat_pat = rf'{cat}\s*=\s*{{(.*?)\n\s*}},?'
        m = re.search(cat_pat, fe.content, flags=re.S)
        existing_nums = []
        if m:
            for im in re.finditer(r'id\s*=\s*"([^"]+)"', m.group(1)):
                iid = im.group(1)
                if iid.startswith(prefix):
                    try:
                        n = int(re.findall(r'(\d+)$', iid)[0])
                        existing_nums.append(n)
                    except Exception:
                        pass
        next_num = (max(existing_nums) + 1) if existing_nums else 1
        self.qg_id.set(f"{prefix}{next_num:03d}")

    def generate_quest(self):
        fe = self._need("QuestDataModule.lua")
        if not fe: return
        cat = self.qg_cat.get().strip()
        qid = self.qg_id.get().strip()
        if not qid:
            self.generate_next_qid()
            qid = self.qg_id.get().strip()

        lines = []
        for combo, item_var, amt_var, _btn in self.qg_reward_rows:
            rid = item_var.get().strip()
            amt = int(amt_var.get())
            ln = self._reward_line_from_item(rid, amt)
            if ln: lines.append(ln)
        if not lines:
            messagebox.showwarning("Validierung", "Mindestens einen Reward auswählen."); return
        rewards_block_text = "\n                    ".join(lines)

        entry = f'''{{
                id = "{qid}",
                title = "{self.qg_title.get().strip()}",
                description = "{self.qg_desc.get().strip()}",
                type = "{self.qg_type.get().strip()}",
                goal = {int(self.qg_goal.get())},
                rewards = {{
                    {rewards_block_text}
                }}
            }},'''
        try:
            fe.content = insert_quest_into_category(fe.content, cat, entry)
            write_text(fe.path, fe.content); fe.original = fe.content
            self.update_preview()
            messagebox.showinfo("OK", f"Quest '{qid}' unter {cat} eingefügt.")
        except Exception as e:
            messagebox.showerror("Fehler", str(e))

    def _q_list_refresh(self):
        if not self.q_list_tree: return
        self.q_list_tree.delete(*self.q_list_tree.get_children())
        fe = self._need("QuestDataModule.lua")
        if not fe: return
        cat = self.q_list_cat.get().strip()
        cat_pat = rf'{cat}\s*=\s*{{(.*?)\n\s*}},?'
        m = re.search(cat_pat, fe.content, flags=re.S)
        if not m:
            return
        inner = m.group(1)
        for qm in re.finditer(r'{\s*(.*?)\s*}\s*,?', inner, flags=re.S):
            block = qm.group(1)
            idm = re.search(r'id\s*=\s*"([^"]+)"', block)
            tit = re.search(r'title\s*=\s*"([^"]+)"', block)
            typ = re.search(r'type\s*=\s*"([^"]+)"', block)
            goal= re.search(r'goal\s*=\s*(\d+)', block)
            if idm:
                self.q_list_tree.insert("", tk.END, values=(
                    idm.group(1),
                    tit.group(1) if tit else "",
                    typ.group(1) if typ else "",
                    int(goal.group(1)) if goal else 0
                ))

    def _q_delete_selected(self):
        fe = self._need("QuestDataModule.lua")
        if not fe or not self.q_list_tree: return
        sel = self.q_list_tree.focus()
        if not sel:
            messagebox.showwarning("Hinweis", "Bitte eine Quest aus der Liste wählen.")
            return
        vals = self.q_list_tree.item(sel, "values")
        qid = vals[0]
        cat = self.q_list_cat.get().strip()
        if not messagebox.askyesno("Bestätigung", f"Quest '{qid}' aus {cat} löschen?"):
            return
        try:
            if self.use_backups.get():
                backup_file(fe.path, fe.content)
            fe.content = delete_quest_by_id(fe.content, cat, qid)
            write_text(fe.path, fe.content); fe.original = fe.content
            self._q_list_refresh()
            self.update_preview()
            messagebox.showinfo("Gelöscht", f"Quest '{qid}' gelöscht.")
        except Exception as e:
            messagebox.showerror("Fehler", str(e))

    # ---------- Units ----------
    def _build_units_tab(self, f: ttk.Frame):
        row1 = ttk.Frame(f); row1.pack(fill=tk.X, padx=8, pady=6)
        ttk.Label(row1, text="CSV/Excel Schema: id,name,modelName,type,trait,BaseStar,MaxStar,image").pack(side=tk.LEFT)
        ttk.Button(row1, text="CSV/Excel wählen & importieren", command=self.bulk_import_units).pack(side=tk.LEFT, padx=8)
        ttk.Button(row1, text="Units alphabetisch sortieren", command=self.sort_units).pack(side=tk.LEFT, padx=8)

        box_u = ttk.Labelframe(f, text="Unit löschen"); box_u.pack(fill=tk.X, padx=8, pady=6)
        self.del_unit_id = tk.StringVar()
        self.del_unit_combo = AutoCompleteCombo(box_u, textvariable=self.del_unit_id, values=[], width=40, state="readonly")
        self.del_unit_combo.pack(side=tk.LEFT, padx=6, pady=6)
        ttk.Button(box_u, text="Unit löschen", command=self._delete_unit).pack(side=tk.LEFT, padx=6)

    def bulk_import_units(self):
        fe = self._need("UnitDataModule.lua")
        if not fe: return
        path = filedialog.askopenfilename(title="CSV/Excel wählen", filetypes=[("CSV","*.csv"),("Excel","*.xlsx *.xls"),("Alle Dateien","*.*")])
        if not path: return
        rows = []
        try:
            if path.lower().endswith((".xlsx",".xls")) and HAS_PANDAS:
                df = pd.read_excel(path)
                rows = df.to_dict(orient="records")
            elif path.lower().endswith(".csv"):
                with open(path, "r", encoding="utf-8") as f:
                    reader = csv.DictReader(f)
                    rows = list(reader)
            else:
                messagebox.showwarning("Hinweis", "Excel‑Import benötigt pandas/openpyxl; nutze CSV oder installiere pandas.")
                return
        except Exception as e:
            messagebox.showerror("Fehler", f"Konnte Datei nicht lesen:\n{e}")
            return

        added = 0
        for r in rows:
            try:
                uid = str(r.get("id","")).strip()
                if not uid: continue
                name = str(r.get("name","")).strip()
                modelName = str(r.get("modelName","")).strip()
                utype = str(r.get("type","Ground")).strip()
                trait = str(r.get("trait","None")).strip()
                base = int(float(r.get("BaseStar",1))); base = max(1, min(7, base))
                mstar = int(float(r.get("MaxStar",12)))
                image = str(r.get("image","")).strip()
                entry = f'''{uid} = {{
    name       = "{name}",
    image      = "{image}",
    modelName  = "{modelName}",
    type       = "{utype}",
    trait      = "{trait}",
    BaseStar   = {base},
    MaxStar    = {mstar}
}},'''
                fe.content = insert_into_units(fe.content, entry)
                added += 1
            except Exception:
                continue
        fe.content = sort_units_alphabetically(fe.content)
        write_text(fe.path, fe.content); fe.original = fe.content
        self.update_preview()
        self.refresh_unit_index()
        messagebox.showinfo("Import", f"{added} Units importiert und alphabetisch sortiert.")

    def sort_units(self):
        fe = self._need("UnitDataModule.lua")
        if not fe: return
        fe.content = sort_units_alphabetically(fe.content)
        write_text(fe.path, fe.content); fe.original = fe.content
        self.update_preview()
        self.refresh_unit_index()
        messagebox.showinfo("Sortierung", "Units alphabetisch sortiert.")

    def _delete_unit(self):
        fe = self._need("UnitDataModule.lua")
        if not fe: return
        uid = self.del_unit_id.get().strip()
        if not uid:
            messagebox.showwarning("Validierung", "Unit-ID wählen."); return
        refs = find_unit_references(uid, self.files)
        if refs:
            if not messagebox.askyesno("Bestätigung",
                f"Unit '{uid}' wird referenziert in:\n- " + "\n- ".join(refs) + "\n\nTrotzdem löschen?"):
                return
        if self.use_backups.get():
            backup_file(fe.path, fe.content)
        fe.content = delete_unit_entry(fe.content, uid)
        write_text(fe.path, fe.content); fe.original = fe.content
        self.refresh_unit_index()
        self.update_preview()
        messagebox.showinfo("Gelöscht", f'Unit "{uid}" entfernt.')

    # ---------- Items (NEU: CRUD) ----------
    def _build_items_tab(self, f: ttk.Frame):
        # Liste
        top = ttk.Frame(f); top.pack(fill=tk.X, padx=8, pady=(8,4))
        ttk.Button(top, text="Items laden/aktualisieren", command=self.item_refresh_index).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Neu anlegen (Form leeren)", command=self._item_clear_form).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Übernehmen/Update", command=self._item_apply_form).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="In Datei schreiben", command=self._item_write_back).pack(side=tk.LEFT, padx=12)

        cols = ("id","display","category","rarity")
        self.item_tree = ttk.Treeview(f, columns=cols, show="headings", height=12, selectmode="browse")
        self.item_tree.heading("id", text="ID");           self.item_tree.column("id", width=200, anchor=tk.W)
        self.item_tree.heading("display", text="Name");     self.item_tree.column("display", width=240, anchor=tk.W)
        self.item_tree.heading("category", text="Kategorie");self.item_tree.column("category", width=140, anchor=tk.W)
        self.item_tree.heading("rarity", text="Rarity");    self.item_tree.column("rarity", width=120, anchor=tk.W)
        self.item_tree.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)
        self.item_tree.bind("<<TreeviewSelect>>", self._item_on_select)
        self.item_tree.bind("<Double-1>", self._item_on_select)

        # Formular
        form = ttk.Labelframe(f, text="Item bearbeiten / anlegen"); form.pack(fill=tk.X, padx=8, pady=(0,8))
        self.it_id = tk.StringVar(); self.it_name = tk.StringVar(); self.it_cat = tk.StringVar(value="Scroll")
        self.it_rare = tk.StringVar(value="Common"); self.it_icon = tk.StringVar(); self.it_desc = tk.StringVar()

        grid = ttk.Frame(form); grid.pack(fill=tk.X, padx=6, pady=6)
        r=0
        for lbl, var, w in [
            ("ID", self.it_id, 30),
            ("DisplayName", self.it_name, 30),
            ("Kategorie", self.it_cat, 20),
            ("Rarity", self.it_rare, 20),
            ("iconId (rbxassetid://…)", self.it_icon, 40),
            ("Beschreibung", self.it_desc, 80),
        ]:
            ttk.Label(grid, text=lbl).grid(row=r, column=0, sticky="e", padx=6, pady=4)
            ttk.Entry(grid, textvariable=var, width=w).grid(row=r, column=1, sticky="w", padx=6, pady=4)
            r+=1

        # Delete-Box bleibt bestehen
        box_i = ttk.Labelframe(f, text="Item löschen"); box_i.pack(fill=tk.X, padx=8, pady=6)
        self.del_item_id = tk.StringVar()
        self.del_item_combo = AutoCompleteCombo(box_i, textvariable=self.del_item_id, values=[], width=40, state="readonly")
        self.del_item_combo.pack(side=tk.LEFT, padx=6, pady=6)
        ttk.Button(box_i, text="Item löschen", command=self._delete_item).pack(side=tk.LEFT, padx=6)

        # Initial laden
        self._item_refresh_table()

    def _item_refresh_table(self):
        if hasattr(self, "item_tree"):
            self.item_tree.delete(*self.item_tree.get_children())
        # Index neu aufbauen
        self.item_refresh_index()
        for it in self.item_index:
            self.item_tree.insert("", tk.END, values=(it.id, it.display, it.category, it.rarity))

    def _item_on_select(self, _e=None):
        sel = self.item_tree.focus()
        if not sel: return
        vals = self.item_tree.item(sel, "values")
        if not vals: return
        iid, name, cat, rar = vals
        # Finde vollständige Daten
        full = None
        for it in self.item_index:
            if it.id == iid:
                full = it; break
        if not full:
            return
        self.it_id.set(full.id)
        self.it_name.set(full.display)
        self.it_cat.set(full.category)
        self.it_rare.set(full.rarity)
        self.it_icon.set(full.iconId)
        self.it_desc.set(full.desc)

    def _item_clear_form(self):
        self.it_id.set(""); self.it_name.set(""); self.it_cat.set("Scroll")
        self.it_rare.set("Common"); self.it_icon.set(""); self.it_desc.set("")

    def _item_apply_form(self):
        fe = self._need("ItemDataModule.lua")
        if not fe: return
        iid = self.it_id.get().strip()
        if not iid:
            messagebox.showwarning("Validierung", "Item‑ID ist leer."); return
        name = self.it_name.get().strip() or iid
        cat = self.it_cat.get().strip() or "Item"
        rar = self.it_rare.get().strip() or "Common"
        icon= self.it_icon.get().strip() or "rbxassetid://0"
        dsc = self.it_desc.get().strip() or "—"

        entry = f'''["{iid}"] = {{
    displayName = "{name}",
    iconId = "{icon}",
    category = "{cat}",
    rarity = "{rar}",
    desc = "{dsc}",
}},'''

        # Remove existing, then insert
        fe.content = delete_top_level_keyed_entry(fe.content, iid)
        fe.content = insert_top_level_table_entry(
            fe.content,
            r'local\s+ItemData\s*=\s*{\s*(.*?)\n}\s*\n',
            entry
        )
        # Optional format
        fe.content = format_lua_simple(fe.content)
        write_text(fe.path, fe.content); fe.original = fe.content
        self._item_refresh_table()
        self.update_preview()
        messagebox.showinfo("OK", f'Item "{iid}" übernommen.')

    def _item_write_back(self):
        fe = self._need("ItemDataModule.lua")
        if not fe: return
        # Direkter Write (beachtet globalen Backup-Schalter bei Batch-Save; hier bewusst **kein** Auto-Backup)
        write_text(fe.path, fe.content)
        fe.original = fe.content
        messagebox.showinfo("Gespeichert", "ItemDataModule.lua geschrieben.")

    def _delete_item(self):
        fe = self._need("ItemDataModule.lua")
        if not fe: return
        iid = self.del_item_id.get().strip()
        if not iid:
            messagebox.showwarning("Validierung", "Item-ID wählen."); return
        refs = find_item_references(iid, self.files)
        if refs:
            if not messagebox.askyesno("Bestätigung",
                f"Item '{iid}' wird verwendet:\n- " + "\n- ".join(refs) + "\n\nTrotzdem löschen?"):
                return
        if self.use_backups.get():
            backup_file(fe.path, fe.content)
        fe.content = delete_top_level_keyed_entry(fe.content, iid)
        write_text(fe.path, fe.content); fe.original = fe.content
        self._item_refresh_table()
        self.update_preview()
        messagebox.showinfo("Gelöscht", f'Item "{iid}" entfernt.')

    # ---------- Enemies ----------
    def _build_enemies_tab(self, f: ttk.Frame):
        top = ttk.Frame(f); top.pack(fill=tk.X, padx=8, pady=6)
        ttk.Button(top, text="EnemyData laden/erstellen", command=self._enemy_ensure_file).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Neu anlegen", command=self._enemy_add_row).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Ausgewählten löschen", command=self._enemy_delete_selected).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="In Datei schreiben", command=self._enemy_write_back).pack(side=tk.LEFT, padx=12)

        cols = ("id","display","hp","speed","reward","etype")
        self.enemy_tree = ttk.Treeview(f, columns=cols, show="headings", height=12)
        for c, t, w in [("id","Id",180),("display","Name",220),("hp","HP",80),("speed","Speed",80),("reward","Reward",80),("etype","Type",120)]:
            self.enemy_tree.heading(c, text=t); self.enemy_tree.column(c, width=w, anchor=tk.W)
        self.enemy_tree.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)

        form = ttk.Frame(f); form.pack(fill=tk.X, padx=8, pady=8)
        self.en_id = tk.StringVar(); self.en_name = tk.StringVar(); self.en_hp = tk.IntVar(value=100)
        self.en_speed = tk.DoubleVar(value=1.0); self.en_reward = tk.IntVar(value=5); self.en_type = tk.StringVar(value="Ground")
        for i,(lbl,var,w) in enumerate([("Id",self.en_id,24),("Name",self.en_name,24),("HP",self.en_hp,8),("Speed",self.en_speed,8),("Reward",self.en_reward,8),("Type",self.en_type,12)]):
            ttk.Label(form, text=lbl).grid(row=0, column=2*i, sticky="e", padx=4, pady=2)
            ttk.Entry(form, textvariable=var, width=w).grid(row=0, column=2*i+1, sticky="w", padx=4, pady=2)
        ttk.Button(form, text="Übernehmen/Update", command=self._enemy_apply_form).grid(row=1, column=0, columnspan=12, pady=6)

        self._enemy_refresh_table()

    def _enemy_ensure_file(self):
        if "EnemyDataModule.lua" not in self.files:
            path = filedialog.asksaveasfilename(
                title="EnemyDataModule.lua anlegen",
                defaultextension=".lua",
                initialfile="EnemyDataModule.lua",
                filetypes=[("Lua","*.lua")]
            )
            if not path:
                return
            skeleton = '''-- EnemyDataModule.lua

local EnemyData = {
    ["Basic"] = { displayName = "Basic", hp = 100, speed = 1.0, reward = 5, type = "Ground" },
}

function EnemyData.Get(id)
    return EnemyData[id]
end

return EnemyData
'''
            write_text(path, skeleton)
            content = read_text(path)
            self.files["EnemyDataModule.lua"] = FileEntry(path=path, content=content, original=content, issues=[])
        self.enemy_index = extract_enemies(self.files["EnemyDataModule.lua"].content)
        self._enemy_refresh_table()
        messagebox.showinfo("OK", "EnemyDataModule.lua bereit.")

    def _enemy_refresh_table(self):
        self.enemy_tree.delete(*self.enemy_tree.get_children())
        if "EnemyDataModule.lua" in self.files:
            self.enemy_index = extract_enemies(self.files["EnemyDataModule.lua"].content)
        for e in self.enemy_index:
            self.enemy_tree.insert("", tk.END, values=(e.id, e.display, e.hp, e.speed, e.reward, e.etype))

    def _enemy_add_row(self):
        self.en_id.set(""); self.en_name.set(""); self.en_hp.set(100)
        self.en_speed.set(1.0); self.en_reward.set(5); self.en_type.set("Ground")

    def _enemy_apply_form(self):
        eid = self.en_id.get().strip()
        if not eid:
            messagebox.showwarning("Validierung", "Enemy Id leer."); return
        name = self.en_name.get().strip() or eid
        hp = int(self.en_hp.get()); spd = float(self.en_speed.get())
        rew = int(self.en_reward.get()); et = self.en_type.get().strip() or "Ground"

        entry = f'''["{eid}"] = {{
    displayName = "{name}",
    hp = {hp},
    speed = {spd},
    reward = {rew},
    type = "{et}",
}},'''
        fe = self._need("EnemyDataModule.lua")
        if not fe: return
        fe.content = delete_top_level_keyed_entry(fe.content, eid)
        fe.content = insert_top_level_table_entry(
            fe.content,
            r'local\s+EnemyData\s*=\s*{\s*(.*?)\n}\s*\n',
            entry
        )
        write_text(fe.path, fe.content); fe.original = fe.content
        self._enemy_refresh_table()
        self.update_preview()
        messagebox.showinfo("OK", f'Enemy "{eid}" gespeichert.')

    def _enemy_delete_selected(self):
        sel = self.enemy_tree.focus()
        if not sel:
            messagebox.showwarning("Hinweis", "Bitte Enemy auswählen."); return
        vals = self.enemy_tree.item(sel, "values")
        eid = vals[0]
        fe = self._need("EnemyDataModule.lua")
        if not fe: return
        if self.use_backups.get():
            backup_file(fe.path, fe.original)
        fe.content = delete_top_level_keyed_entry(fe.content, eid)
        write_text(fe.path, fe.content); fe.original = fe.content
        self._enemy_refresh_table()
        self.update_preview()
        messagebox.showinfo("Gelöscht", f'Enemy "{eid}" entfernt.')

    def _enemy_write_back(self):
        fe = self._need("EnemyDataModule.lua")
        if not fe: return
        write_text(fe.path, fe.content)
        fe.original = fe.content
        messagebox.showinfo("Gespeichert", "EnemyDataModule.lua geschrieben.")

    # ---------- Analyse ----------
    def _build_analysis_tab(self, parent: ttk.Frame):
        top = ttk.Frame(parent); top.pack(fill=tk.X, padx=8, pady=4)
        ttk.Button(top, text="Analysieren", command=self.run_analysis).pack(side=tk.LEFT, padx=4)
        if HAS_MPL:
            ttk.Button(top, text="Charts anzeigen", command=self.show_charts).pack(side=tk.LEFT, padx=4)
        self.analysis_out = ScrolledText(parent, wrap=tk.WORD, height=20)
        self.analysis_out.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)

    def run_analysis(self):
        data = analyze_balancing(self.files)
        unused_items, unused_units = collect_unused_items_and_units(self.files)
        buf = io.StringIO()
        buf.write("== Enemy-Scaling ==\n")
        for row in data:
            wc, te = row["wavecount"], row["total"]
            if wc and te:
                avg = te/max(1,wc)
                if avg<3 or avg>100:
                    buf.write(f"[{row['map']} S{row['stage']}]: avg={avg:.1f}  (Waves={wc}, Total={te})\n")
        buf.write("\n== Reward‑Effizienz (Eclipsium pro Stage/Wave grob) ==\n")
        for row in sorted(data, key=lambda x: (x["eclipsium"]/max(1,x["wavecount"]) if x["wavecount"] else 0.0), reverse=True)[:10]:
            ratio = row["eclipsium"]/max(1,row["wavecount"]) if row["wavecount"] else 0.0
            buf.write(f"[{row['map']} S{row['stage']}]: {ratio:.2f} (Ecl={row['eclipsium']}, Waves={row['wavecount']})\n")
        buf.write("\n== Unbenutzte Items ==\n")
        for iid in unused_items:
            buf.write(f"- {iid}\n")
        buf.write("\n== Möglicherweise unbenutzte Units ==\n")
        for uid in unused_units:
            buf.write(f"- {uid}\n")
        self.analysis_out.delete("1.0", tk.END)
        self.analysis_out.insert("1.0", buf.getvalue())

    def show_charts(self):
        if not HAS_MPL:
            messagebox.showwarning("Hinweis", "Matplotlib nicht installiert.")
        data = analyze_balancing(self.files)
        if not data:
            messagebox.showwarning("Hinweis", "Keine MapData geladen.")
            return
        xs = list(range(len(data))); ys = [d["wavecount"] for d in data]
        plt.figure("WaveCount per Stage"); plt.plot(xs, ys); plt.title("WaveCount per Stage"); plt.xlabel("Stage Index"); plt.ylabel("WaveCount")
        plt.figure("TotalEnemies per Stage"); ys2 = [d["total"] for d in data]; plt.plot(xs, ys2); plt.title("TotalEnemies per Stage"); plt.xlabel("Stage Index"); plt.ylabel("TotalEnemies")
        plt.figure("BossScaling per Stage"); ys3 = [d.get("boss_scaling",0.0) for d in data]; plt.plot(xs, ys3); plt.title("BossScaling per Stage"); plt.xlabel("Stage Index"); plt.ylabel("BossScaling")
        plt.show()

    # ---------- QS ----------
    def _build_qs_tab(self, parent: ttk.Frame):
        f = ttk.Frame(parent); f.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)
        ttk.Button(f, text="Lua formatieren (markierte)", command=self.format_selected).pack(side=tk.LEFT, padx=4)
        ttk.Button(f, text="Units alphabetisch sortieren", command=self.sort_units).pack(side=tk.LEFT, padx=4)

    def format_selected(self):
        sel = self.file_list.curselection()
        if not sel:
            messagebox.showwarning("Hinweis","Datei(en) auswählen.")
            return
        for idx in sel:
            name = self.file_list.get(idx)
            fe = self.files.get(name)
            if not fe: continue
            fe.content = format_lua_simple(fe.content)
        self.update_preview()
        messagebox.showinfo("Formatter", "Ausgewählte Dateien formatiert.")

    # ---------- Basis-UI Aktionen ----------
    def open_files(self):
        paths = filedialog.askopenfilenames(
            title="Lua‑Dateien wählen",
            filetypes=[("Lua","*.lua"),("Alle Dateien","*.*")]
        )
        for p in paths:
            try:
                content = read_text(p)
            except Exception as e:
                messagebox.showerror("Fehler", f"Konnte Datei nicht lesen:\n{p}\n{e}")
                continue
            name = os.path.basename(p)
            self.files[name] = FileEntry(path=p, content=content, original=content, issues=[])
        self.refresh_list()
        self.mm_refresh_index()
        self.item_refresh_index()
        self._item_refresh_table()
        self.refresh_unit_index()
        self._enemy_refresh_table()

    def refresh_list(self):
        self.file_list.delete(0, tk.END)
        for name in sorted(self.files.keys()):
            self.file_list.insert(tk.END, name)
        self.preview.delete("1.0", tk.END)
        if hasattr(self, "issues_tree"):
            self.issues_tree.delete(*self.issues_tree.get_children())

    def update_preview(self, event=None):
        sel = self.file_list.curselection()
        if not sel: return
        name = self.file_list.get(sel[0])
        fe = self.files.get(name)
        if not fe: return
        self.preview.delete("1.0", tk.END)
        self.preview.insert("1.0", fe.content)

    def scan_all(self):
        for fe in self.files.values():
            fe.issues.clear()
        for name, fe in self.files.items():
            v = VALIDATORS.get(name)
            if v:
                v.scan(fe, self.files)
        unused_items, unused_units = collect_unused_items_and_units(self.files)
        if "ItemDataModule.lua" in self.files:
            for iid in unused_items:
                self.files["ItemDataModule.lua"].issues.append(Issue(
                    self.files["ItemDataModule.lua"].path, "INFO", "ITEM_UNUSED",
                    f"Item potentiell unbenutzt: {iid}"
                ))
        if "UnitDataModule.lua" in self.files:
            for uid in unused_units:
                self.files["UnitDataModule.lua"].issues.append(Issue(
                    self.files["UnitDataModule.lua"].path, "INFO", "UNIT_UNUSED",
                    f"Unit potentiell unbenutzt: {uid}"
                ))
        self.populate_issues()
        self.item_refresh_index()
        self._item_refresh_table()
        self.refresh_unit_index()
        self._enemy_refresh_table()
        self.mm_refresh_index()

    def populate_issues(self):
        self.issues_tree.delete(*self.issues_tree.get_children())
        for fe in self.files.values():
            for iss in fe.issues:
                label = iss.code + f" [{os.path.basename(fe.path)}]"
                self.issues_tree.insert("", tk.END, values=(iss.severity, label, iss.message))

    def apply_selected_fix(self):
        focus = self.issues_tree.focus()
        if not focus: return
        vals = self.issues_tree.item(focus, "values")
        if len(vals) < 3: return
        code_file = vals[1]
        m = re.search(r'\[(.+?)\]$', code_file)
        if not m: return
        filename = m.group(1)
        fe = self.files.get(filename)
        if not fe: return
        msg = vals[2]
        for iss in list(fe.issues):
            if iss.message == msg and iss.fix:
                try:
                    fe.content = iss.fix(fe.content, self.files)
                    fe.issues.remove(iss)
                    self.populate_issues()
                    self.update_preview()
                    self.item_refresh_index()
                    self._item_refresh_table()
                    self.refresh_unit_index()
                    self._enemy_refresh_table()
                    self.mm_refresh_index()
                    messagebox.showinfo("Auto‑Fix", iss.fix_label or "Fix angewendet.")
                except Exception as e:
                    messagebox.showerror("Fehler", str(e))
                return
        messagebox.showwarning("Hinweis", "Für dieses Issue ist kein Auto‑Fix verfügbar.")

    def apply_all_fixes(self):
        fixed = 0
        for fe in self.files.values():
            for iss in list(fe.issues):
                if iss.fix:
                    try:
                        fe.content = iss.fix(fe.content, self.files)
                        fe.issues.remove(iss)
                        fixed += 1
                    except Exception:
                        pass
        self.populate_issues()
        self.update_preview()
        self.item_refresh_index()
        self._item_refresh_table()
        self.refresh_unit_index()
        self._enemy_refresh_table()
        self.mm_refresh_index()
        messagebox.showinfo("Auto‑Fix", f"Angewendete Fixes: {fixed}")

    def show_diff_selected(self):
        sel = self.file_list.curselection()
        if not sel:
            messagebox.showwarning("Hinweis", "Datei auswählen.")
            return
        name = self.file_list.get(sel[0])
        fe = self.files.get(name)
        if not fe: return
        diff = unified_diff(fe.original, fe.content, name)
        win = tk.Toplevel(self); win.title(f"Diff – {name}")
        txt = ScrolledText(win, wrap=tk.NONE, width=150, height=40)
        txt.pack(fill=tk.BOTH, expand=True)
        txt.insert("1.0", diff if diff.strip() else "Keine Änderungen.")

    def batch_save(self):
        if not self.files:
            messagebox.showwarning("Hinweis", "Keine Dateien geladen.")
        for name, fe in self.files.items():
            try:
                if self.use_backups.get():
                    backup_file(fe.path, fe.original)
                write_text(fe.path, fe.content)
                fe.original = fe.content
            except Exception as e:
                messagebox.showerror("Fehler", f"{name}\n{e}")
                return
        self.mm_refresh_index()
        self.item_refresh_index()
        self._item_refresh_table()
        self.refresh_unit_index()
        self._enemy_refresh_table()
        messagebox.showinfo("Gespeichert", "Alle Dateien gespeichert" + (" und Backups erstellt." if self.use_backups.get() else " (ohne Backups)."))

    # ----- Item/Unit Indizes -----
    def item_refresh_index(self):
        self.item_index = []
        fe = self.files.get("ItemDataModule.lua")
        if fe:
            self.item_index = extract_items(fe.content)
        ids = [it.id for it in self.item_index]
        if hasattr(self, "qg_reward_rows"):
            for combo, _iv, _av, _btn in self.qg_reward_rows:
                combo.set_values(ids)
        if hasattr(self, "sr_rows"):
            for combo, _iv, _av, _btn in self.sr_rows:
                combo.set_values(ids)
        if self.del_item_combo is not None:
            self.del_item_combo.set_values(ids)

    def _item_write_list_to_combo(self):
        if self.del_item_combo is not None:
            self.del_item_combo.set_values([it.id for it in self.item_index])

    def refresh_unit_index(self):
        self.unit_index = []
        fe = self.files.get("UnitDataModule.lua")
        if fe:
            self.unit_index = units_in_text(fe.content)
        if self.del_unit_combo is not None:
            self.del_unit_combo.set_values(self.unit_index)

if __name__ == "__main__":
    App().mainloop()
