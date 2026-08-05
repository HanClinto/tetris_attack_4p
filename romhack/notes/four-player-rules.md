# Four-Player Rules

The target ruleset follows the GameCube Panel de Pon included in `NINTENDO Puzzle Collection` where the behavior is documented, while preserving the SNES garbage shapes and timing where exact GameCube implementation details are unavailable.

## Sources

- [Nintendo Puzzle Collection](https://www.nintendo.co.jp/ngc/gpzj/index.html): official 1-4 player count and 2-4 player support.
- [Official Panel de Pon page](https://www.nintendo.co.jp/ngc/gpzj/panepon/index.html): multiplayer garbage battle, score attack, and stage clear modes.
- [Japanese Panel de Pon series reference](https://ja.wikipedia.org/wiki/%E3%83%91%E3%83%8D%E3%83%AB%E3%81%A7%E3%83%9D%E3%83%B3#2%E4%BA%BA_-_4%E4%BA%BA%E7%94%A8): GameCube 3-4 player targeting and elimination behavior.
- [Color-targeting gameplay explanation](https://www.youtube.com/watch?v=Lx2hiKI_HKg): panel-color targets, purple random routing, chain-final-color routing, self-attacks, and multi-color attacks.
- [Four-player versus modes](https://www.youtube.com/watch?v=X0aLja2VmQo): elimination order, restart behavior, and final standings.

The Nintendo pages are primary sources for player count and available modes. Detailed routing comes from matching Japanese reference text and direct gameplay captions; those rules should be treated as the behavioral target rather than proof of the original GameCube implementation internals.

## Target garbage battle

- Free-for-all; no team mode.
- Last non-eliminated player wins.
- Assign four normal panel colors to the four colored player frames.
- Garbage generated from a color targets the player with the matching frame color.
- A player can target themselves by clearing their own frame color.
- Purple/neutral targets a random eligible player other than the attacker.
- A chain's target is determined by the final link's cleared color.
- A simultaneous clear containing multiple colors can target multiple players.
- Surprise/gray attacks target all eligible opponents.
- Preserve the SNES combo and chain garbage dimensions unless later traces show a compelling compatibility issue.

## Initial approximation decisions

The exact GameCube accounting for a multi-color combo is not confirmed. The first SNES implementation will:

1. Generate the original SNES garbage slabs once.
2. Build the distinct target list from colors present in the clear.
3. Distribute generated slabs round-robin across those targets.

This avoids multiplying attack strength while preserving multi-target behavior. If a deterministic color names an eliminated player, the first implementation will drop that target rather than reroute it. Purple chooses uniformly from live non-self players.

## Elimination

- Record finishing places in top-out order.
- Do not accept new incoming garbage for eliminated players.
- A restart-after-elimination attacker is a later milestone; the first implementation may freeze eliminated boards until the last survivor is known.
- End the match when one live player remains and show persistent `1st`-`4th` results.

## UI

- Player frames communicate color targeting; no manual target cursor is required.
- Pending garbage should eventually be shown above each board.
- Eliminated frames should be dimmed or marked with finishing place.
- The current compact `OK`/`!!` indicator remains a board-height warning, not a pending-attack indicator.

## Implementation sequence

1. Map the existing SNES outgoing garbage generation and incoming queue.
2. Preserve native two-player sizing while separating generation from target selection.
3. Record the final cleared color and distinct colors in simultaneous clears.
4. Route native attacks by frame color into four persistent queues.
5. Feed each queue into its native slot when that player is scheduled.
6. Add elimination and standings after four-way garbage delivery is stable.