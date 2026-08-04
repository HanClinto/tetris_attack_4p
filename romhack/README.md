# Tetris Attack 4-Player ROM Hack

An experimental four-player extension for the headerless US SNES release of Tetris Attack, targeting the standard Super Multitap in controller port 2.

This repository does not contain copyrighted ROM data. The build requires a legally obtained source ROM with this fingerprint:

- Filename: `Tetris Attack (USA) (En,Ja).sfc`
- Size: 1,048,576 bytes
- SHA-1: `2dc56eab3e70c0910ae47119d8b69f494e6000df`

Place the source ROM in `resources/`, then run:

```sh
brew install asar
cd romhack
make
```

The generated 2 MiB ROM is written to `romhack/build/tetris-attack-4p.sfc` and is ignored by Git.

With Mesen 2.1.1 installed at the default path used below, run the headless integration tests with:

```sh
make test
```

Set `MESEN_BIN` to use a different Mesen executable.

The current probe builds reproducibly with Asar 1.91:

- Size: 2,097,152 bytes
- SHA-1: `5483147e8c387ddde82bf0e8e668f674d2a07ccf`

## Test environment

- Mesen 2.1.1, native Apple Silicon build: verified booting and running through the attract-mode tutorial
- ares v148: installed as an independent accuracy check, but currently advances both the original and patched ROMs at only 1 VPS with a black display on this macOS host

## Current experiment

The first probe expands the ROM to 2 MiB, redirects the controller polling routine at `$80:9C04` to new code at `$A0:8000`, reproduces the overwritten instructions, and rejoins the original routine at `$80:9C10`. It is behavior-neutral and validates the expansion, hook, and Mesen workflow.

The next probe implements protocol-level Super Multitap detection through `$4016/$4017`. Its headless test verifies both sides:

- A Multitap on controller port 2 is detected.
- An ordinary controller on port 2 is rejected.

The manual polling probe now reads all four Multitap subports:

- WRIO bit 7 high selects subports A/B.
- WRIO bit 7 low selects subports C/D.
- Each `$4017` read returns one serial bit for two controllers in bits 0-1.
- The original WRIO value is restored before returning to the game.

Both a deterministic bus test and an end-to-end Mesen Multitap device test verify four distinct 16-bit controller words. Raw experimental state is stored at `$7F:FE00-$7F:FE09`. An untouched-game trace found no accesses to `$7F:FE00-$7F:FE2F` during 3600 steady-state frames after startup initialization.

The `multitap-auto-read` experiment routes P1 through `$421E` to investigate automatic reads from the Multitap's second data line. Its automated button-input test is currently inconclusive because Mesen 2.1.1's Lua `setInput` path does not update the SNES serial shift buffer in this headless workflow.

See [`notes/rom-map.md`](notes/rom-map.md) for confirmed addresses.
