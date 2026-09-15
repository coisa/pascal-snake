# Architecture and rules

The application has two Pascal entry points. `SnakeGame.pas` launches the
SDL2 desktop edition; `SnakeTerminal.pas` launches the CRT edition. Neither
presentation layer owns collision, growth, food or victory rules.

```text
keyboard / pointer -> presentation -> engine intentions
monotonic clock    -> presentation -> StepGame -> TGame
                                         |
                       Pascal rule tests + both renderers
```

## A simulation step

1. Ignore steps outside the running phase.
2. Calculate the next head using the first accepted turn in this tick.
3. In Wrap mode, map an edge crossing to the opposite edge.
4. Check food, growth, walls and body before changing any segment.
5. Exclude the tail from obstacles only if it will move away.
6. Grow by at most one initialized segment, shift the body and place the head.
7. Update score, win on a full board, or choose food from the free cells.

A fatal move preserves valid body positions. Each apple adds five units of
growth debt, capped by remaining capacity. The engine supports boards from
6 × 2 to 40 × 20 (800 cells). Desktop uses 28 × 18; terminal uses 30 × 14.

The public record supports readable fixtures. Normal callers initialize it
through `InitializeGame` and preserve body continuity, uniqueness and bounds.
The engine imports no graphics, time, audio, filesystem or networking units.

## Randomness and input

A temporary occupancy bitmap marks the body. A Park–Miller generator, local to
each game, picks an index among free cells; a finite scan finds that cell.
Even one remaining free cell terminates predictably. The multiplication uses
`Int64`. This is a gameplay generator, not a cryptographic one.

Identical seeds and tick-level intentions produce identical game states.
Timing of a human's key presses is not a deterministic replay contract.
Same-direction and reverse inputs are ignored; only the first perpendicular
turn is accepted per tick. This prevents a rapid pair of turns becoming an
instant reversal.

Chill, Classic and Quick start at 180, 110 and 70 ms per step. Each apple
subtracts 2 ms down to 45 ms.

## Desktop presentation

[snake_sdl.pas](../src/snake_sdl.pas) declares the small subset of the
[SDL2 C API](https://wiki.libsdl.org/SDL2/CategoryAPI) used by the game.
Libraries are loaded dynamically, with a clear missing-dependency error.
C record packing and runtime size checks cover events, vertices and audio.
Text uses [SDL2_ttf](https://wiki.libsdl.org/SDL2_ttf/TTF_RenderUTF8_Blended)
and a bounded 128-texture cache. Fonts come from the system or `SNAKE_FONT`.

The renderer uses a 1200 × 800 logical canvas with aspect-preserving scaling,
procedural geometry, a gradient snake, direction-aware eyes and apple icons.
There are no downloaded art or audio assets. Sound is an enveloped sine wave
with a quiet overtone, queued through
[SDL_QueueAudio](https://wiki.libsdl.org/SDL2/SDL_QueueAudio). Queues are bounded;
muting clears queued sound. Failure to open audio leaves the game playable.

The loop targets roughly 60 frames per second. Simulation is independent of
drawing; a long frame is clamped and cannot trigger a catch-up burst. Rendering
interpolates previous/current body positions, without interpolating across the
whole board at a wrap edge. Reduced motion disables interpolation, particles,
pulses, impact flashes and the short panel transition. Direction arrows and
apple/head shapes provide cues in addition to color.

Focus loss pauses; returning focus never resumes automatically. Restart keeps
the seed and selected settings. Session records are separated by world and
pace and disappear at exit.

C graphics libraries expect non-trapping IEEE floating-point arithmetic.
The desktop boundary saves the FPC exception mask, masks floating-point traps
while SDL is active, then restores the original mask on cleanup. This fixes an
observed native Metal initialization failure. Pascal range, integer overflow
and I/O checks remain enabled.

Cleanup closes audio, textures, fonts, renderer, window and libraries, including
partial initialization failures. `SNAKE_DEBUG=1` enables a diagnostic backtrace.

## Terminal presentation

The CRT edition uses two columns per cell, incremental drawing and ASCII
labels. It pauses on resize and keeps quit available below its minimum size.
Only cursor visibility uses explicit ANSI private mode 25, because
[FPC 3.2.2 CRT](https://github.com/fpc/FPCSource/blob/release_3_2_2/packages/rtl-console/src/unix/crt.pp)
uses Linux-console cursor sequences. PTY tests verify controls and terminal
restoration, including Q, Esc and Ctrl-C.

## Build boundary

The [Dockerfile](../Dockerfile) pins the official Debian image digest, APT
snapshot `20260901T000000Z` and `fp-compiler-3.2.2=3.2.2+dfsg-20`.
APT signatures and package hashes remain mandatory; only historical-index
expiry is disabled. See [Debian snapshots](https://snapshot.debian.org/).

`toolchain` contains compilation/platform dependencies. `build` compiles
both programs and runs rule tests. `test` runs rules and synthetic integration
checks. `game` contains only the terminal binary and runs as UID/GID 65532,
without network, volumes, extra capabilities or writable root filesystem.

This is reproducibility through fixed inputs and behavioral checks, not a
claim of byte-identical binaries across architectures. Native builds use
installed platform libraries and are documented separately.
