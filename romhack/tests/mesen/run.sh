#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
romhack_dir=$(CDPATH= cd -- "$script_dir/../.." && pwd)
mesen_bin=${MESEN_BIN:-"$HOME/Applications/Mesen.app/Contents/MacOS/Mesen"}
probe_rom="$romhack_dir/build/multitap-detect.sfc"
lua_test="$script_dir/multitap_detect.lua"

if [ ! -x "$mesen_bin" ]; then
    printf 'error: Mesen executable not found: %s\n' "$mesen_bin" >&2
    exit 1
fi

common_args="--testRunner --timeout=10 --noVideo --noAudio --doNotSaveSettings"

# shellcheck disable=SC2086
"$mesen_bin" $common_args \
    --snes.port2.type=Multitap \
    --snes.port2A.type=SnesController \
    --snes.port2B.type=SnesController \
    --snes.port2C.type=SnesController \
    --snes.port2D.type=SnesController \
    "$lua_test" "$probe_rom" >"$romhack_dir/build/mesen-multitap.log" 2>&1

set +e
# shellcheck disable=SC2086
"$mesen_bin" $common_args \
    --snes.port2.type=SnesController \
    "$lua_test" "$probe_rom" >"$romhack_dir/build/mesen-controller.log" 2>&1
controller_result=$?
set -e

if [ "$controller_result" -ne 10 ]; then
    printf 'error: standard-controller control returned %s; expected 10\n' \
        "$controller_result" >&2
    exit 1
fi

printf 'Mesen Multitap detection tests passed\n'
