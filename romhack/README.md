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

The current probe builds reproducibly with Asar 1.91:

- Size: 2,097,152 bytes
- SHA-1: `5483147e8c387ddde82bf0e8e668f674d2a07ccf`

## Test environment

- Mesen 2.1.1, native Apple Silicon build: verified booting and running through the attract-mode tutorial
- ares v148: installed as an independent accuracy check, but currently advances both the original and patched ROMs at only 1 VPS with a black display on this macOS host

## Current experiment

The first probe expands the ROM to 2 MiB, redirects the controller polling routine at `$80:9C04` to new code at `$A0:8000`, reproduces the overwritten instructions, and rejoins the original routine at `$80:9C10`. It is behavior-neutral and validates the expansion, hook, and Mesen workflow.

See [`notes/rom-map.md`](notes/rom-map.md) for confirmed addresses.
