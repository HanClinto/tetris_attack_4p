# Confirmed ROM Map

Addresses refer to the headerless US ROM with SHA-1 `2dc56eab3e70c0910ae47119d8b69f494e6000df`.

## Cartridge

- Mapping: FastROM LoROM (`$30` at file offset `$7FD5`)
- Original size: 1 MiB (`$0A` at `$7FD7`)
- Expanded size: 2 MiB (`$0B` at `$7FD7`)
- Original checksum complement/checksum: `$D30C/$2CF3`

## Controller polling

- Poll routine: `$80:9C04-$80:9C82`
- Main interrupt-path callers: `$80:8E55` and `$80:8E83`
- Automatic joypad busy wait: `$80:9C04-$80:9C0F`
- Player 1 automatic read (`$4218`): `$80:9C10`
- Player 2 automatic read (`$421A`): `$80:9C50`
- Routine exit (`PLP`, `RTL`): `$80:9C80-$80:9C81`

The routine updates direct-page words for current, newly pressed, repeated, and previous input state. Exact semantics still need debugger confirmation.

## Expansion probe

- Original entry replaced by `JML $A0:8000`
- Behavior-neutral trampoline: `$A0:8000`
- Rejoin point: `$80:9C10`
- Deterministic output SHA-1 with Asar 1.91: `5483147e8c387ddde82bf0e8e668f674d2a07ccf`
- Execution verified through the attract-mode tutorial in Mesen 2.1.1

## Super Multitap

The protocol-level detection probe is implemented at `$A0:8100`:

1. Write `$01` to `$4016` to assert the controller strobe.
2. Read `$4017` and retain data bit 1.
3. Write `$00` to `$4016` to release the strobe.

Mesen 2.1.1 returns bit 1 set for a Multitap and clear for an ordinary controller. Headless positive and negative controls verify both outcomes.

The SNES automatic-read registers `$421C-$421F` are unused by the original game. `$421E/$421F` are the candidate path for the second data line on controller port 2, but synthetic button propagation through this path is not yet verified.

## Manual Multitap polling

The manual polling probe at `$A0:8200`:

- Preserves A/X/Y, DBR, processor flags, and WRIO.
- Latches all controllers once through `$4016`.
- Reads subports A/B with WRIO bit 7 high.
- Reads subports C/D with WRIO bit 7 low.
- Produces the same 16-bit button order used by the SNES automatic-read registers.
- Returns to the original P1/P2 poll routine without changing game behavior.

Experimental state currently uses:

- `$7F:FE00`: subport A raw state
- `$7F:FE02`: subport B raw state
- `$7F:FE04`: subport C raw state
- `$7F:FE06`: subport D raw state
- `$7F:FE08`: saved WRIO byte
- `$7F:FE10-$7F:FE19`: P3 current/pressed/repeat/previous/timer
- `$7F:FE20-$7F:FE29`: P4 current/pressed/repeat/previous/timer

The game initializes this page during startup. After frame 120, access-counter and exact-range traces observed no original-game reads or writes to `$7F:FE00-$7F:FE3F` over the following 3600 frames. This is sufficient for experiments but remains provisional until more game modes are traced.

## Mode 2 board renderer

The tutorial enters its Mode 2 setup at `$89:E43E`; the register-shadow tuple begins at `$89:E444`:

- `$7E:01BA = $02`: BGMODE 2
- `$7E:01BC = $72`: BG1 tilemap at VRAM word `$7000`, 64x32
- `$7E:01BD = $78`: BG2 tilemap at VRAM word `$7800`, 32x32
- `$7E:01BE = $60`: BG3 offset map at VRAM word `$6000`, 32x32
- BG1/BG2 character data begins at VRAM word `$2000`

`$80:9B20` copies the PPU shadow block to hardware registers. `$80:9E14-$80:9E20` configures VRAM transfers.

In Mode 2, BG3's vertical-offset row begins at VRAM word `$6020`. For BG2, bit `$4000` enables the per-column vertical offset and bits 0-9 contain the scroll value.

The static four-well experiment uses BG2 columns 1-6, 9-14, 17-22, and 25-30. All four groups start at offset word `$4000`; independent Up/Down input then changes each group's 10-bit offset separately.

## Panel graphics extraction

At tutorial frame 3600, the visible 16x16 panel metatiles are four 8x8 SNES 4bpp tiles each, relative to character-data byte base `$4000`:

- Heart: tiles `$0A0-$0A3`, palette 1
- Circle: tiles `$0A4-$0A7`, palette 1
- Triangle: tiles `$0A8-$0AB`, palette 1
- Star: tiles `$0AC-$0AF`, palette 1
- Diamond: tiles `$0B0-$0B3`, palette 2

`tests/mesen/tilemap_dump.lua` captures VRAM and CGRAM. `tools/export_panel_tiles.rb` assembles the metatiles and produces palette-index JSON plus naive 8x8 PNG starters under `assets/panels/`.

`tools/compile_panel_tiles.rb` reverses the editable `starter_8x8` JSON rows into six SNES 4bpp tiles: transparent tile `$3E0` and panels `$3E1-$3E5`. The live four-board experiment uploads the 192-byte result at VRAM word `$5E00` and renders two rows per NMI across six phases.

Dynamic experiment state:

- `$7F:FE30`: well 1 vertical offset
- `$7F:FE32`: well 2 vertical offset
- `$7F:FE34`: well 3 vertical offset
- `$7F:FE36`: well 4 vertical offset
- `$7F:FE3E`: Mode 2 layout initialization flag

Each offset is masked to 10 bits. Raw Up (`$0800`) decrements it and raw Down (`$0400`) increments it. Tests verify independent wrap/decrement/increment behavior and the corresponding BG3 words.

Rendering from the controller hook is too late in VBlank. The successful experiment hooks the original `JSL $80:90F3` calls at `$80:8E4D` and `$80:8E7B`, calls the original routine, then performs experimental VRAM writes. Both NMI branches are required.
