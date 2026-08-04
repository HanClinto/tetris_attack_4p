#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_rom=${SOURCE_ROM:-"$script_dir/../resources/Tetris Attack (USA) (En,Ja).sfc"}
build_dir=${BUILD_DIR:-"$script_dir/build"}
output_rom=${OUTPUT_ROM:-"$build_dir/tetris-attack-4p.sfc"}
expected_sha1=2dc56eab3e70c0910ae47119d8b69f494e6000df

if ! command -v asar >/dev/null 2>&1; then
    printf 'error: Asar is required (brew install asar)\n' >&2
    exit 1
fi

if [ ! -f "$source_rom" ]; then
    printf 'error: source ROM not found: %s\n' "$source_rom" >&2
    exit 1
fi

actual_sha1=$(shasum -a 1 "$source_rom" | awk '{print $1}')
if [ "$actual_sha1" != "$expected_sha1" ]; then
    printf 'error: source ROM SHA-1 is %s; expected %s\n' "$actual_sha1" "$expected_sha1" >&2
    exit 1
fi

mkdir -p "$build_dir"
cp "$source_rom" "$output_rom"
dd if=/dev/zero bs=1048576 count=1 >> "$output_rom" 2>/dev/null
asar --fix-checksum=on "$script_dir/patch.asm" "$output_rom"

output_size=$(wc -c < "$output_rom" | tr -d ' ')
if [ "$output_size" != "2097152" ]; then
    printf 'error: output size is %s bytes; expected 2097152\n' "$output_size" >&2
    exit 1
fi

hook_bytes=$(xxd -p -l 4 -s 0x1c04 "$output_rom")
if [ "$hook_bytes" != "5c0080a0" ]; then
    printf 'error: controller hook is %s; expected 5c0080a0\n' "$hook_bytes" >&2
    exit 1
fi

rom_size_byte=$(xxd -p -l 1 -s 0x7fd7 "$output_rom")
if [ "$rom_size_byte" != "0b" ]; then
    printf 'error: ROM size byte is %s; expected 0b\n' "$rom_size_byte" >&2
    exit 1
fi

printf 'built %s (%s bytes)\n' "$output_rom" "$output_size"
