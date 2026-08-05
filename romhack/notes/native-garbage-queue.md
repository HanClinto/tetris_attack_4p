# Native Garbage Queue

A deterministic Mesen trace maps the original two-player combo-garbage path from a P1 four-clear to a three-cell slab on P2.

## Reproduction

At P1 cursor `(3,9)`, the native swap helper targets Plane 1 cells `$1012/$1014`. The test seeds a vertical four-clear, presses A through the normal controller path, and observes these states:

1. `$82:B2EE` swaps the cells and marks them `$0101/$0102`.
2. Four color-1 panels transition through `$4001` and `$1001` before clearing.
3. `$82:B0EB` publishes clear size `4` at `$7E:66E4`.
4. `$89:AEE1` increments P2 three-wide staging at `$7E:0446`.
5. `$82:ABDD` adds staging `$0446` to pending `$0442`, then clears staging.
6. `$82:AB43` sees pending `$0442` and calls `$86:97EB`.
7. `$86:9808-$9848` writes the three-cell slab and `$86:9854` decrements pending.

`tests/mesen/native_garbage_queue.lua` asserts clear-size publication, native staging-to-pending transfer, and slab materialization. It injects staging immediately after `$82:B0EF` publishes size `4` because the natural `$89:AEE1` enqueue is presentation-driven and not deterministic under headless Mesen timing; the natural producer address remains trace-verified.

## Per-player fields

The native players use interleaved words. P1 fields are at the even base address and P2 fields are at base plus two.

| Shape | P1 pending | P2 pending | P1 staging | P2 staging | Materializer |
|---|---:|---:|---:|---:|---:|
| Three wide | `$0440` | `$0442` | `$0444` | `$0446` | `$86:97EB` |
| Four wide | `$0448` | `$044A` | `$044C` | `$044E` | `$86:9867` |
| Five wide | `$0450` | `$0452` | `$0454` | `$0456` | `$86:9903` |
| Six wide | `$0458` | `$045A` | `$045C` | `$045E` | `$86:99B9` |
| Chain/special | `$046C` | `$046E` | `$0470` | `$0472` | `$86:9A66` |

The materializers first call `$86:94C3`, which only verifies that the six top-row cells are empty. Garbage is represented directly in the four board planes. A three-wide slab starts with Plane 0 words `$0003,$0003,$0003` and Plane 1 words `$0401,$0402,$0403`.

## Four-player reuse

The balanced scheduler already persists all pending and staging fields:

- P3 virtualizes native slot P1. Its scalar sidecar starts at `$7F:0C00`; three-wide pending/staging are `$7F:0C0A/$7F:0C0C`.
- P4 virtualizes native slot P2. Its scalar sidecar starts at `$7F:1400`; three-wide pending/staging are `$7F:140A/$7F:140C`.

This permits routing native attacks by redirecting staging increments. No custom slab encoding is required; each selected player consumes the original counters and materializers when their native or virtual context is scheduled.

The live experiment's first routing proof hooks the native P1 three-wide increment at `$89:AEDD` and increments P3 staging at `$7F:0C0C` instead. `tests/mesen/routed_garbage_p3.lua` verifies that P2 staging remains zero, P3 transfers staging into pending during its virtual P1 update, the original `$86:97EB` materializer runs, and the slab is saved into P3's `$7F:0800-$0BFF` board context.

Persistent fall/landing is not yet complete. Tracing identified additional landing scalars at `$0460/$0464/$0468`, per-cell metadata at `$84F6-$85F5`, and slot link records at `$2000-$23FF`, but copying all of them around every virtual update exceeded the current scheduler/render timing budget and still did not preserve the slab. That experimental expansion was removed; the remaining runtime state needs a narrower ownership strategy.
