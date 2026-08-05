#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
romhack_dir=$(CDPATH= cd -- "$script_dir/../.." && pwd)
mesen_bin=${MESEN_BIN:-"$HOME/Applications/Mesen.app/Contents/MacOS/Mesen"}
probe_rom="$romhack_dir/build/multitap-detect.sfc"
poll_rom="$romhack_dir/build/tetris-attack-4p.sfc"
four_wells_rom="$romhack_dir/build/static-four-wells.sfc"
context_block_move_rom="$romhack_dir/build/context-block-move-probe.sfc"
context_dispatch_rom="$romhack_dir/build/context-dispatch-probe.sfc"
context_swap_rom="$romhack_dir/build/context-swap-probe.sfc"
live_four_boards_rom="$romhack_dir/build/live-four-boards.sfc"
source_rom="$romhack_dir/../resources/Tetris Attack (USA) (En,Ja).sfc"
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

"$mesen_bin" $common_args \
    "$script_dir/multitap_poll.lua" \
    "$poll_rom" >"$romhack_dir/build/mesen-poll-bus.log" 2>&1

"$mesen_bin" $common_args \
    "$script_dir/multitap_input_state.lua" \
    "$poll_rom" >"$romhack_dir/build/mesen-input-state.log" 2>&1

"$mesen_bin" $common_args \
    "$script_dir/multitap_repeat.lua" \
    "$poll_rom" >"$romhack_dir/build/mesen-repeat.log" 2>&1

# shellcheck disable=SC2086
"$mesen_bin" $common_args \
    --snes.port2.type=Multitap \
    --snes.port2A.type=SnesController \
    --snes.port2B.type=SnesController \
    --snes.port2C.type=SnesController \
    --snes.port2D.type=SnesController \
    "$script_dir/multitap_poll_device.lua" \
    "$poll_rom" >"$romhack_dir/build/mesen-poll-device.log" 2>&1

"$mesen_bin" $common_args --timeout=20 \
    "$script_dir/wram_scratch.lua" \
    "$source_rom" \
    >"$romhack_dir/build/mesen-wram.log" 2>&1

"$mesen_bin" $common_args --timeout=20 \
    "$script_dir/static_four_wells.lua" \
    "$four_wells_rom" >"$romhack_dir/build/mesen-four-wells.log" 2>&1

"$mesen_bin" $common_args --timeout=30 \
    "$script_dir/dynamic_four_wells.lua" \
    "$four_wells_rom" >"$romhack_dir/build/mesen-dynamic-wells.log" 2>&1

"$mesen_bin" $common_args --timeout=30 \
    "$script_dir/context_swap_probe.lua" \
    "$context_swap_rom" >"$romhack_dir/build/mesen-context-swap.log" 2>&1

"$mesen_bin" $common_args --timeout=30 \
    "$script_dir/context_swap_probe.lua" \
    "$context_block_move_rom" \
    >"$romhack_dir/build/mesen-context-block-move.log" 2>&1

"$mesen_bin" $common_args --timeout=30 \
    "$script_dir/context_block_move_timing.lua" \
    "$context_block_move_rom" \
    >"$romhack_dir/build/mesen-context-block-move-timing.log" 2>&1

"$mesen_bin" $common_args --timeout=55 \
    "$script_dir/context_dispatch_probe.lua" \
    "$context_dispatch_rom" \
    >"$romhack_dir/build/mesen-context-dispatch.log" 2>&1

"$mesen_bin" $common_args --timeout=55 \
    "$script_dir/live_four_boards.lua" \
    "$live_four_boards_rom" \
    >"$romhack_dir/build/mesen-live-four-boards.log" 2>&1

"$mesen_bin" $common_args --timeout=45 \
    "$script_dir/context_backing_guard.lua" \
    "$poll_rom" >"$romhack_dir/build/mesen-context-backing.log" 2>&1

printf 'Mesen input, WRAM, renderer, and context-swap tests passed\n'
