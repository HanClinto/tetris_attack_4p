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

## Context backing proof

High WRAM `$7F:0000-$2FFF` is bulk-cleared during mode transitions but is untouched during active versus gameplay. Backing contexts must therefore be initialized after match setup.

The `context-swap-probe` experiment uses:

- P1 backing: `$7F:0000-$03FF`
- P2 backing: `$7F:0400-$07FF`
- P3 backing: `$7F:0800-$0BFF`
- P4 backing: `$7F:0C00-$0FFF`

Each `$0400` context stores four `$0100` plane slices. The experiment:

1. Saves native P1/P2 into backing storage.
2. Fills P3/P4 backing with distinct marker bytes.
3. Loads P3/P4 into native slots.
4. Saves them back out.
5. Restores native P1/P2.

A byte-exact Mesen test verifies all eight native plane/player slices, both native backups, and both extra-player marker contexts.

The exhaustive CPU loop is not production-ready. It copies 8 KiB in one invocation and lasts long enough for a nested NMI to re-enter the controller hook. The isolated probe disables further NMIs and exits immediately after validation.

### Block-move timing proof

`experiments/context-block-move-probe.asm` replaces the byte loops with one 65816 `MVN` per `$0100` plane slice. It performs the same 8 KiB save/load/save/restore transaction without disabling NMI. The byte-exact Mesen assertion passes, and `context_block_move_timing.lua` confirms the transaction crosses no more than one frame boundary.

Direct DMA through the WRAM data port (`$2180`) is not usable for this transfer: a WRAM-bank source and the WRAM I/O destination contend for the same bus, and an isolated probe copied `$00` instead of the native byte. The original ROM also declares no cartridge SRAM (`$7FD8 = $00`), so adding SRAM merely as a DMA staging area would impose a new cartridge requirement. `MVN` is therefore the current production candidate.

The 8 KiB proof is still not atomic: an NMI can occur while extra-player data occupies the native slots. A production update should reduce the critical section to one 4 KiB slot transaction (save native, load extra, update extra, save extra, restore native) and likely alternate P3/P4 across frames. That keeps unrelated NMI work from observing both temporary contexts at once and leaves more frame time for the original board update routine.

## Per-context dispatcher proof

The active versus loop calls `$82:A9C8` once per native player:

- P1 caller `$82:9DA6`, with `$7E:0360 = $0000`
- P2 caller `$82:9E5C`, with `$7E:0360 = $0002`

`experiments/context-dispatch-probe.asm` virtualizes the P2 plane slot around the real P2 update slice. It clones P2 into P3 backing, lets the unmodified `$82:A9C8` dispatcher run while that virtual context occupies native slot 2, saves the result to P3 backing, and restores P2. The Mesen assertion verifies dispatcher entry, virtual-context residency, P3 save-back, the P2 backup, and byte-exact P2 restoration.

Instruction-level tracing reduced non-plane dispatcher state to 19 native player word pairs across `$03EE-$04FA`. Four cursor words extend the persisted scalar sidecar to 23 words: logical column/row `$03A6/$03AA` and mirrored presentation coordinates `$03AE/$03B2`. It also maps the native P2 input words at `$00B5`, `$00B9`, `$00BD`, `$00C7`, and `$00CD` to P3's processed input structure at `$7F:FE10-$7F:FE18`.

The balanced scheduler virtualizes both native slots independently:

- Slot 1 alternates native P1 and virtual P3.
- Slot 2 alternates native P2 and virtual P4.

P3 planes/scalars use `$7F:0800/$0C00`; P4 uses `$7F:1000/$1400`. Native P1/P2 plane backups use `$7F:0000/$0400`, with separate scalar and input backups in `$7F:0D00-$0D7F`. The active-match ownership guard covers the complete `$7F:0000-$14FF` allocation.

The strengthened test injects A presses for both extra players and verifies two independent updates apiece. During each virtual phase, native slot 2 contains the selected player's planes, scalar sidecar, and processed input. The original update slice changes that virtual board, saves it back to the correct P3/P4 context, and restores every captured P2 plane, scalar, and input byte. This establishes repeated P3/P4 board execution through the native engine.

All four players now receive one board update every two native match ticks. `balanced_context_dispatch_probe.lua` verifies both dispatcher return paths, equal virtual completion counts, intervening native updates, independent save-back, and byte-exact restoration of each native slot.

The live renderer experiment wraps the active P1 pre-hook with a one-time auto-arm routine. It clears scheduler state, sets `$7F:2000=$A5`, and latches `$7F:200B=$5A` so the original 2P VS path launches the four-player prototype without Lua writes. Match setup clears high WRAM before the next launch.
