# Compact Panel Artwork

Edit `starter_8x8` in `panels.json`. Each panel has eight strings of eight hexadecimal palette indices (`0-F`):

```json
"starter_8x8": [
  "4444444F",
  "44444444",
  "42222224",
  "42222224",
  "44222244",
  "44422444",
  "44444444",
  "F444444F"
]
```

Index `0` is transparent. The other indices select colors from that panel's `palette_rgb` array. Keep every row at exactly eight pixels and use only hexadecimal digits.

From `romhack/`, regenerate the derived artwork and SNES tile data with:

```sh
make panel-assets
```

The data flow is:

```text
panels.json starter_8x8
  -> panel-*-8x8.png
  -> panel-starter-8x8.png and preview
  -> build/panel-tiles.4bpp (normal, selected, label, frame, status, and menu tiles)
  -> live-four-boards experiment
```

The PNGs are generated previews, not compiler inputs. The `source_16x16` rows and `panel-*-16x16.png` files are reference exports from the original game. Running `make panel-assets` overwrites the generated 8x8 PNGs.

Panel order:

- `panel-a`: heart
- `panel-b`: circle
- `panel-c`: triangle
- `panel-d`: star
- `panel-e`: diamond