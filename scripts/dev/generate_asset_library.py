#!/usr/bin/env python3
"""Generate SpriteFrames .tres, TileSet stubs metadata, avatars, and asset catalog for Stage 2."""
from __future__ import annotations

import json
import re
import struct
from pathlib import Path

GM = Path("/home/deck/Guild Master: Chronicles of the Realm/guild_master")
CATALOG: list[dict] = []


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    return struct.unpack(">II", data[16:24])


def uid(name: str) -> str:
    h = abs(hash(name)) % (10**12)
    return f"uid://s2{h:012d}"


def write_import(path: Path) -> None:
    """Nearest / no mipmaps / lossless import sidecar."""
    imp = path.with_suffix(path.suffix + ".import")
    rel = "res://" + str(path.relative_to(GM)).replace("\\", "/")
    dest = f"res://.godot/imported/{path.name}-{abs(hash(rel)) & 0xFFFFFFFFFFFFFFFF:016x}.ctex"
    imp.write_text(
        f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid(rel)}"
path="{dest}"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{rel}"
dest_files=["{dest}"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_mipmaps=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
""",
        encoding="utf-8",
    )


def anim_name_from_file(stem: str, class_name: str) -> str | None:
    s = stem
    # Strip class prefixes
    for prefix in (
        f"{class_name}_",
        f"{class_name.capitalize()}_",
        "Warrior_",
        "Archer_",
        "Lancer_",
        "Monk_",
        "Pawn_",
    ):
        if s.startswith(prefix):
            s = s[len(prefix) :]
            break
    s_low = s.lower().replace(" ", "_")
    mapping = {
        "idle": "idle",
        "run": "run",
        "attack1": "attack1",
        "attack2": "attack2",
        "guard": "guard",
        "shoot": "shoot",
        "heal": "heal",
        "heal_effect": "heal_effect",
        "arrow": None,  # projectile, skip as character anim
    }
    if s_low in mapping:
        return mapping[s_low]
    # directional lancer attacks etc.
    if "attack" in s_low:
        return "attack_" + s_low.replace("_attack", "").replace("attack_", "")
    if "defence" in s_low or "defense" in s_low:
        return "defence_" + re.sub(r"_?(defence|defense)", "", s_low).strip("_")
    if s_low.startswith("idle_"):
        return s_low  # pawn idle variants
    if s_low.startswith("run_"):
        return s_low
    if s_low.startswith("interact"):
        return s_low
    if s_low in ("idle", "run"):
        return s_low
    # Monk Idle.png / Run.png already handled
    if stem.lower() == "idle":
        return "idle"
    if stem.lower() == "run":
        return "run"
    if stem.lower() == "heal":
        return "heal"
    if stem.lower() == "heal_effect":
        return "heal_effect"
    return s_low


def make_sprite_frames(
    out_path: Path,
    texture_res: str,
    animations: dict[str, list[tuple[int, int, int, int]]],
    speed: float = 8.0,
) -> None:
    """animations: name -> list of (x,y,w,h) regions."""
    lines: list[str] = []
    lines.append('[gd_resource type="SpriteFrames" load_steps=%d format=3]\n' % (2 + sum(len(v) for v in animations.values())))
    lines.append(f'[ext_resource type="Texture2D" path="{texture_res}" id="1_tex"]\n')
    sub_id = 0
    anim_payload = []
    for aname, regions in animations.items():
        frame_refs = []
        for region in regions:
            sub_id += 1
            sid = f"Atlas_{sub_id}"
            x, y, w, h = region
            lines.append(f'[sub_resource type="AtlasTexture" id="{sid}"]')
            lines.append("atlas = ExtResource(\"1_tex\")")
            lines.append(f"region = Rect2({x}, {y}, {w}, {h})\n")
            frame_refs.append(sid)
        frames_str = ", ".join(
            '{("duration": 1.0, "texture": SubResource("%s")}' % sid for sid in frame_refs
        )
        # Fix Godot format - use proper dict syntax
        frames_godot = []
        for sid in frame_refs:
            frames_godot.append('{"duration": 1.0, "texture": SubResource("%s")}' % sid)
        anim_payload.append(
            {
                "frames": frames_godot,
                "loop": "true",
                "name": aname,
                "speed": speed,
            }
        )

    # Rebuild load_steps accurately
    total_subs = sub_id
    header = f'[gd_resource type="SpriteFrames" load_steps={1 + total_subs + 1} format=3]\n'
    body_lines = [header, f'[ext_resource type="Texture2D" path="{texture_res}" id="1_tex"]\n']
    sub_id = 0
    anims_out = []
    for aname, regions in animations.items():
        frame_sids = []
        for region in regions:
            sub_id += 1
            sid = f"Atlas_{sub_id}"
            x, y, w, h = region
            body_lines.append(f'[sub_resource type="AtlasTexture" id="{sid}"]')
            body_lines.append('atlas = ExtResource("1_tex")')
            body_lines.append(f"region = Rect2({x}, {y}, {w}, {h})\n")
            frame_sids.append(sid)
        frames_joined = ", ".join(
            '{"duration": 1.0, "texture": SubResource("%s")}' % s for s in frame_sids
        )
        anims_out.append(
            '{"frames": [%s], "loop": true, "name": &"%s", "speed": %.1f}'
            % (frames_joined, aname, speed)
        )
    body_lines.append("[resource]")
    body_lines.append("animations = [%s]\n" % ", ".join(anims_out))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(body_lines), encoding="utf-8")


def strip_regions(w: int, h: int, frame_w: int | None = None, frame_h: int | None = None) -> list[tuple[int, int, int, int]]:
    fh = frame_h or h
    fw = frame_w or fh  # square by default
    if fw <= 0 or w < fw:
        return [(0, 0, w, h)]
    count = w // fw
    return [(i * fw, 0, fw, fh) for i in range(count)]


def add_catalog(**kwargs) -> None:
    CATALOG.append(kwargs)


def build_tiny_swords_units() -> None:
    classes = ["warrior", "archer", "lancer", "monk", "pawn"]
    palettes = ["blue", "red", "black", "yellow", "purple"]
    for cl in classes:
        for pal in palettes:
            folder = GM / f"assets/tiny_swords/units/{cl}/{pal}"
            if not folder.exists():
                continue
            # Group animations: each PNG is one animation strip
            # For multi-file units we create ONE SpriteFrames per unit combining all anims
            # that share the same folder — but textures differ per file.
            # Godot SpriteFrames can reference multiple textures via multiple AtlasTextures.
            # We'll create one .tres per unit that embeds all anims from all PNGs.
            anims_spec: list[tuple[str, Path, list]] = []
            for png in sorted(folder.glob("*.png")):
                write_import(png)
                w, h = png_size(png)
                name = anim_name_from_file(png.stem, cl)
                if name is None:
                    continue
                regions = strip_regions(w, h)
                if not regions:
                    continue
                anims_spec.append((name, png, regions))

            if not anims_spec:
                continue

            # Build multi-texture SpriteFrames manually
            out = GM / f"resources/sprite_frames/tiny_swords/unit_{cl}_{pal}.tres"
            _write_multi_tex_frames(out, anims_spec, speed=8.0 if cl != "lancer" else 10.0)
            add_catalog(
                id=f"unit.{cl}.{pal}",
                pack="Tiny Swords",
                category="Unit",
                source="; ".join(str(p.relative_to(GM)) for _, p, _ in anims_spec),
                frame_size=f"{anims_spec[0][2][0][2]}x{anims_spec[0][2][0][3]}",
                frame_count=sum(len(r) for _, _, r in anims_spec),
                animations=", ".join(a for a, _, _ in anims_spec),
                palettes=pal,
                purpose="Guild Hub / world / combat preview",
                limits="flip_h for facing; do not mix with Neighbours scale",
                resource=str(out.relative_to(GM)),
            )


def _write_multi_tex_frames(out_path: Path, anims_spec: list, speed: float) -> None:
    ext_lines = []
    sub_lines = []
    anim_parts = []
    tex_ids = {}
    next_tex = 1
    next_sub = 1
    for aname, png, regions in anims_spec:
        rel = "res://" + str(png.relative_to(GM)).replace("\\", "/")
        if rel not in tex_ids:
            tid = f"{next_tex}_tex"
            tex_ids[rel] = tid
            ext_lines.append(f'[ext_resource type="Texture2D" path="{rel}" id="{tid}"]')
            next_tex += 1
        tid = tex_ids[rel]
        frame_sids = []
        for region in regions:
            sid = f"Atlas_{next_sub}"
            next_sub += 1
            x, y, w, h = region
            sub_lines.append(f'[sub_resource type="AtlasTexture" id="{sid}"]')
            sub_lines.append(f'atlas = ExtResource("{tid}")')
            sub_lines.append(f"region = Rect2({x}, {y}, {w}, {h})")
            sub_lines.append("")
            frame_sids.append(sid)
        frames_joined = ", ".join(
            '{"duration": 1.0, "texture": SubResource("%s")}' % s for s in frame_sids
        )
        anim_parts.append(
            '{"frames": [%s], "loop": true, "name": &"%s", "speed": %.1f}'
            % (frames_joined, aname, speed)
        )
    load_steps = 1 + len(tex_ids) + (next_sub - 1)
    parts = [f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]', ""]
    parts.extend(ext_lines)
    parts.append("")
    parts.extend(sub_lines)
    parts.append("[resource]")
    parts.append("animations = [%s]" % ", ".join(anim_parts))
    parts.append("")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(parts), encoding="utf-8")


def build_buildings() -> None:
    for pal in ["blue", "red", "black", "yellow", "purple"]:
        folder = GM / f"assets/tiny_swords/buildings/{pal}"
        for png in sorted(folder.glob("*.png")):
            write_import(png)
            w, h = png_size(png)
            stem = png.stem.lower().replace(" ", "_")
            bid = {
                "castle": "building.castle",
                "house1": "building.house_01",
                "house2": "building.house_02",
                "house3": "building.house_03",
                "monastery": "building.monastery",
                "tower": "building.tower",
                "archery": "building.archery",
                "barracks": "building.barracks",
            }.get(stem, f"building.{stem}")
            add_catalog(
                id=f"{bid}.{pal}",
                pack="Tiny Swords",
                category="Building",
                source=str(png.relative_to(GM)),
                frame_size=f"{w}x{h}",
                frame_count=1,
                animations="—",
                palettes=pal,
                purpose="Guild Hub exterior",
                limits=f"pivot bottom-center; click≈{w}x{h}; y-sort by feet",
                resource=str(png.relative_to(GM)),
            )


def build_fx_and_deco() -> None:
    for folder, cat, prefix in [
        (GM / "assets/tiny_swords/effects", "FX", "fx"),
        (GM / "assets/tiny_swords/decorations", "Decoration", "decoration"),
        (GM / "assets/tiny_swords/resources", "Resource", "resource"),
        (GM / "assets/tiny_swords/terrain", "Terrain", "terrain"),
    ]:
        for png in sorted(folder.glob("*.png")):
            write_import(png)
            w, h = png_size(png)
            stem = re.sub(r"[^a-z0-9]+", "_", png.stem.lower()).strip("_")
            aid = f"{prefix}.{stem}"
            if cat == "FX" and w > h and h > 0 and w % h == 0:
                regions = strip_regions(w, h)
                out = GM / f"resources/sprite_frames/tiny_swords/{stem}.tres"
                _write_multi_tex_frames(out, [(stem, png, regions)], speed=10.0)
                add_catalog(
                    id=aid,
                    pack="Tiny Swords",
                    category=cat,
                    source=str(png.relative_to(GM)),
                    frame_size=f"{regions[0][2]}x{regions[0][3]}",
                    frame_count=len(regions),
                    animations=stem,
                    palettes="—",
                    purpose="VFX gallery / combat",
                    limits="",
                    resource=str(out.relative_to(GM)),
                )
            else:
                add_catalog(
                    id=aid,
                    pack="Tiny Swords",
                    category=cat,
                    source=str(png.relative_to(GM)),
                    frame_size=f"{w}x{h}",
                    frame_count=1,
                    animations="—",
                    palettes="—",
                    purpose="Hub / world dressing",
                    limits="",
                    resource=str(png.relative_to(GM)),
                )


def build_neighbours() -> None:
    # Emotions: 64x16 = 4 frames of 16x16
    emo_map = {
        "Angry_emote_16x16": "angry",
        "Evil_emote_16x16": "evil",
        "Exclamation_emote_16x16": "exclamation",
        "Happy_emote_16x16": "happy",
        "HeartBreak_emote_16x16": "broken_heart",
        "Heart_emote_16x16": "heart",
        "Interrogation_emote_16x16": "question",
        "Sad_emote_16x16": "sad",
        "Star_emote_16x16": "star",
        "Surprised_emote_16x16": "surprised",
    }
    for png in sorted((GM / "assets/tiny_neighbours/emotions").glob("*.png")):
        write_import(png)
        eid = emo_map.get(png.stem, re.sub(r"_emote.*", "", png.stem.lower()))
        regions = [(i * 16, 0, 16, 16) for i in range(4)]
        out = GM / f"resources/sprite_frames/tiny_neighbours/emotion_{eid}.tres"
        _write_multi_tex_frames(out, [(eid, png, regions)], speed=6.0)
        add_catalog(
            id=f"emotion.{eid}",
            pack="Tiny Neighbours",
            category="Emotion",
            source=str(png.relative_to(GM)),
            frame_size="16x16",
            frame_count=4,
            animations=eid,
            palettes="—",
            purpose="NPC dialogue bubble",
            limits="",
            resource=str(out.relative_to(GM)),
        )

    # NPC sheets 128x208 = 4 cols x 4 rows of 32x52
    fw, fh = 32, 52
    for i in range(1, 16):
        png = GM / f"assets/tiny_neighbours/npc/NPC_{i}.png"
        if not png.exists():
            continue
        write_import(png)
        w, h = png_size(png)
        assert (w, h) == (128, 208), (png, w, h)
        # row0 idle, row1 walk, row2/3 extras as idle2/walk2 if present
        idle = [(c * fw, 0, fw, fh) for c in range(4)]
        walk = [(c * fw, fh, fw, fh) for c in range(4)]
        anims = [("idle", png, idle), ("walk", png, walk)]
        # extra rows
        for r, name in [(2, "idle_b"), (3, "walk_b")]:
            anims.append((name, png, [(c * fw, r * fh, fw, fh) for c in range(4)]))
        out = GM / f"resources/sprite_frames/tiny_neighbours/npc_{i:02d}.tres"
        _write_multi_tex_frames(out, anims, speed=6.0)
        # avatar: first idle frame via writing a note; actual crop done separately if Pillow missing
        # Store atlas region as avatar metadata — create tiny atlas tres reference
        add_catalog(
            id=f"npc.neighbour.{i:02d}",
            pack="Tiny Neighbours",
            category="NPC",
            source=str(png.relative_to(GM)),
            frame_size=f"{fw}x{fh}",
            frame_count=16,
            animations="idle, walk, idle_b, walk_b",
            palettes="—",
            purpose="Interiors / dialogue",
            limits="Do not place on Tiny Swords plane without scale adapt",
            resource=str(out.relative_to(GM)),
            avatar_region="0,0,32,52",
        )


def build_kings() -> None:
    char_dirs = {
        "human_king": "character.human_king",
        "king_pig": "character.king_pig",
        "pig": "character.pig",
    }
    for folder_name, cid in char_dirs.items():
        folder = GM / f"assets/kings_and_pigs/characters/{folder_name}"
        anims_spec = []
        for png in sorted(folder.glob("*.png")):
            write_import(png)
            w, h = png_size(png)
            m = re.search(r"\((\d+)x(\d+)\)", png.stem)
            if m:
                fw, fh = int(m.group(1)), int(m.group(2))
            else:
                fw, fh = h, h
                if w % h == 0:
                    fw = h
            name = re.sub(r"\s*\(\d+x\d+\)", "", png.stem).strip().lower().replace(" ", "_")
            regions = strip_regions(w, h, fw, fh)
            anims_spec.append((name, png, regions))
        if not anims_spec:
            continue
        out = GM / f"resources/sprite_frames/kings_and_pigs/{folder_name}.tres"
        _write_multi_tex_frames(out, anims_spec, speed=10.0)
        add_catalog(
            id=cid,
            pack="Kings and Pigs",
            category="Character",
            source=str(folder.relative_to(GM)),
            frame_size="varies",
            frame_count=sum(len(r) for _, _, r in anims_spec),
            animations=", ".join(a for a, _, _ in anims_spec),
            palettes="—",
            purpose="Side-view interiors",
            limits="Separate scale from Tiny Swords",
            resource=str(out.relative_to(GM)),
        )

    # Door
    door_dir = GM / "assets/kings_and_pigs/doors"
    door_anims = []
    mapping = {
        "Idle": "closed",
        "Opening (46x56)": "opening",
        "Closiong (46x56)": "closing",
    }
    for png in sorted(door_dir.glob("*.png")):
        write_import(png)
        w, h = png_size(png)
        key = png.stem
        aname = mapping.get(key, key.lower().replace(" ", "_"))
        m = re.search(r"\((\d+)x(\d+)\)", key)
        fw, fh = (int(m.group(1)), int(m.group(2))) if m else (w, h)
        if aname == "closed":
            regions = [(0, 0, w, h)]
        else:
            regions = strip_regions(w, h, fw, fh)
        door_anims.append((aname, png, regions))
    # synthetic open = last frame of opening
    if door_anims:
        out = GM / "resources/sprite_frames/kings_and_pigs/door.tres"
        _write_multi_tex_frames(out, door_anims, speed=8.0)
        add_catalog(
            id="door.basic",
            pack="Kings and Pigs",
            category="Door",
            source=str(door_dir.relative_to(GM)),
            frame_size="46x56",
            frame_count=sum(len(r) for _, _, r in door_anims),
            animations=", ".join(a for a, _, _ in door_anims),
            palettes="—",
            purpose="Interior transitions",
            limits="",
            resource=str(out.relative_to(GM)),
        )

    for png in (GM / "assets/kings_and_pigs/terrain").glob("*.png"):
        write_import(png)
        w, h = png_size(png)
        stem = re.sub(r"[^a-z0-9]+", "_", png.stem.lower()).strip("_")
        add_catalog(
            id=f"tileset.kap.{stem}",
            pack="Kings and Pigs",
            category="Terrain",
            source=str(png.relative_to(GM)),
            frame_size="32x32 tiles",
            frame_count=(w // 32) * (h // 32),
            animations="—",
            palettes="—",
            purpose="Side-view TileSet",
            limits="Do not mix with Tiny Swords TileSet",
            resource=str(png.relative_to(GM)),
        )

    # objects
    for png in (GM / "assets/kings_and_pigs/objects").rglob("*.png"):
        write_import(png)


def write_catalog() -> None:
    out_json = GM / "resources/asset_catalog/tiny_assets.json"
    out_json.write_text(json.dumps(CATALOG, ensure_ascii=False, indent=2), encoding="utf-8")
    md = GM / "docs/assets/TINY_ASSET_CATALOG.md"
    lines = [
        "# Tiny Asset Catalog",
        "",
        "Stage 2 registry. Machine-readable: `res://resources/asset_catalog/tiny_assets.json`.",
        "",
        "| ID | Pack | Category | Frame | Anims | Palettes | Resource | Purpose | Limits |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for e in CATALOG:
        lines.append(
            "| {id} | {pack} | {category} | {frame_size} | {animations} | {palettes} | `{resource}` | {purpose} | {limits} |".format(
                **{k: str(e.get(k, "")).replace("|", "/") for k in [
                    "id", "pack", "category", "frame_size", "animations", "palettes", "resource", "purpose", "limits"
                ]}
            )
        )
    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append("- Tiny Swords / Neighbours / Kings and Pigs use different scales — do not mix on one plane.")
    lines.append("- `.aseprite` sources live under `assets/*/source/` and are not used by game scenes.")
    lines.append("- Packs shipped without a separate LICENSE file; purchased Tiny packs (Pixel Frog / Vryell) — verify itch license terms.")
    lines.append("")
    md.write_text("\n".join(lines), encoding="utf-8")
    print(f"Catalog entries: {len(CATALOG)}")


def main() -> None:
    build_tiny_swords_units()
    build_buildings()
    build_fx_and_deco()
    build_neighbours()
    build_kings()
    write_catalog()
    print("OK")


if __name__ == "__main__":
    main()
