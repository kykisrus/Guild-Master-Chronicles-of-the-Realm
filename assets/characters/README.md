# Character asset pack

Prepared for **Guild Master: Chronicles of the Realm**.

Imported into the Godot project as:

```text
guild_master/assets/characters/{guildmaster,pronyra}/
guild_master/resources/sprite_frames/characters/{guildmaster,pronyra}.tres
```

## Layout

Each character (`guildmaster`, `pronyra`) contains:

- `source/` — normalized `.png` source sheets and generated chroma-key masters;
- `alpha/` — full sheets converted to RGBA;
- `frames/idle/` — the original eight-frame idle/stance strip;
- `frames/directions/` — eight static directions, named `s`, `se`, `e`, `ne`,
  `n`, `nw`, `w`, `sw`;
- `frames/walk/` — generated four-frame directional walk candidates;
- `frames/walk_reference_se/` — the original eight-frame southeast walk cycle;
- `frames/talk/`, `inspect/`, `enter/`, `exit/` — four frames per action;
- `portraits/` — `neutral`, `confident`, `skeptical`, `surprised`, `annoyed`,
  `thoughtful`, `determined`, and `speaking`.

Map/action frames are RGBA PNG files on a 192×192 canvas with a bottom-center
anchor and an 8 px bottom margin. Portraits are RGBA PNG files on a 320×320
canvas.

## Integration notes

- Use `frames/directions/` for reliable static facing directions.
- Use `frames/walk_reference_se/` when the original southeast walk fidelity is
  more important than matching the generated four-frame cycles.
- The generated directional walk and action frames are production candidates,
  but should receive an in-engine animation pass before final art lock.
- The original painted ground shadow remains in the original idle/walk art
  because it is part of the source pixels. Generated action/portrait assets have
  no cast shadow.
- All filenames use lowercase ASCII snake_case and include `.png`.

## Rebuilding

Run:

```bash
./tools/prepare_character_assets.sh
```

The script removes the baked white/checker or green chroma backgrounds, slices
the sheets, scales with nearest-neighbour sampling, and aligns the results.

## Generation record

The built-in image generation tool was used in edit/reference mode. The prompt
set requested:

1. A 4×4 sheet per character containing `talk`, `inspect`, `enter`, and `exit`,
   preserving identity, costume, palette, pixel density, and bottom-center
   alignment.
2. An 8×4 directional walk candidate per character with columns
   `S, SW, W, NW, N, NE, E, SE` and four gait phases.
3. A 4×2 dialogue portrait sheet per character with the eight expressions
   listed above.

Every generation prompt required a perfectly flat `#00ff00` background, no
labels, grid lines, shadows, checkerboard, text, watermark, 3D rendering, anime
styling, smoothing, or character redesign.
