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

The game initializes this page during startup. After frame 120, access-counter and exact-range traces observed no original-game reads or writes to `$7F:FE00-$7F:FE2F` over the following 3600 frames. This is sufficient for experiments but remains provisional until more game modes are traced.
