# Board Engine Notes

These findings refer to the headerless US ROM with SHA-1 `2dc56eab3e70c0910ae47119d8b69f494e6000df`.

## Deterministic versus path

The research scripts drive the original menus through this path:

1. Leave the title screen.
2. Select `2PLAYER GAME`.
3. Select `VS.`.
4. Confirm both player levels.
5. Confirm both characters.
6. Capture initialization and live gameplay state.

The first live gameplay frames occur after the `003/002/001` countdown, around frame 4700 in the headless Mesen run.

## Cell planes

The engine uses parallel 16-bit planes with a player-context stride of `$0100`:

- Plane 0 base: `$7E:0D7C`
- Plane 1 base: `$7E:0F7C`
- Plane 2 base: `$7E:117C`
- Plane 3 base: `$7E:137C`

Within a context, the visible 6x12 grid begins at plane offset `$0032`:

```text
cell = plane_base + player_offset + $32 + row * $10 + column * 2
player_offset = $0000 or $0100
```

The `$10` row stride leaves four bytes after each six-cell row.

In live versus snapshots, Plane 1 contains panel colors `1-5`:

- P1 color grid: `$7E:0FAE-$7E:1069`
- P2 color grid: `$7E:10AE-$7E:1169`

The corresponding Plane 0 grids begin at `$7E:0DAE` and `$7E:0EAE`.

## Context indexing evidence

The match initializer at `$86:BC5E` loads `X=$0032` for P1. Its second half at `$86:C09C` loads `X=$0132` for P2. Both halves traverse all 72 cells.

Live routines also use both selectors:

- `$82:A227-$82:A2A0`
- `$82:D9D9-$82:DA9C`
- `$85:EFD4-$85:EFED`
- `$86:875C-$86:8CC8`
- `$86:B650-$86:B70F`

The helper at `$82:D840` accesses all four planes in lockstep, confirming that `$117C` and `$137C` are active field planes rather than free relocation space.

## Four-player implication

Using native offsets `$0232/$0332` directly is not possible:

- P3 Plane 0 would overlap P1 Plane 1.
- P4 Plane 0 would overlap P2 Plane 1.
- The same overlap repeats across later planes.

A trace-scoped relocation audit of initialization plus active gameplay found:

- 332 executed direct-operand accesses into the existing Plane 1 range.
- 261 additional executed callbacks using indirect, pointer-based, or otherwise nontrivial addressing.

Relocating and widening every plane is therefore too brittle without a substantially fuller disassembly.

## Selected strategy

Use the two native player slots as execution slots and keep P3/P4 contexts in backing WRAM:

1. Save native P1/P2 slot state.
2. Copy P3/P4 backing contexts into the native slots.
3. Invoke the existing context-indexed update routines.
4. Copy the updated state back to P3/P4 backing storage.
5. Restore P1/P2 before original rendering and unrelated game logic continue.

The remaining research task is to enumerate all per-player state outside the four cell planes and locate the smallest outer update dispatcher that processes one native context.
