# Tiny GUI import settings

All pixel textures under assets/tiny_gui must use:
- compress/mode = Lossless or Disabled
- process/fix_mipmaps = false
- process/fix_normal_map = false  
- Default texture filter: Nearest (project already sets canvas_textures/default_texture_filter=0)

Godot regenerates .import on open; project default filter is Nearest.
