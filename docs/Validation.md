# Validation evidence

Local validation on September 15, 2026. Code revision:
`21c1de8536b0b2d473b7187a942173b0d9a11703`. Later documentation commits do
not change the runtime. Any subsequent code fix requires the relevant checks
to run again.

## Environments

| Environment | Components | Evidence |
|---|---|---|
| Linux ARM64 container | Docker/OrbStack 29.4.0; FPC 3.2.2+dfsg-20; SDL2 2.26.5; SDL2_ttf 2.20.1; DejaVu Sans | Full build, rule, PTY, SDL and runtime-image checks |
| Native macOS ARM64 | macOS 27.0; Homebrew FPC 3.2.2_1; SDL2-compat 2.32.72; SDL2_ttf 2.24.0; Arial | Compilation, rule tests, PTY, SDL replay and actual desktop renderer capture |
| CI targets | Standard Ubuntu 24.04 AMD64 and ARM64 runners | Workflow configured; the current PR checks are authoritative for completion |

The native compiler and SDL2_ttf were fetched as official Homebrew bottles,
checksum-verified and extracted beneath ignored project scratch. The temporary
SDL2_ttf library was relocated to already installed Homebrew dependencies and
ad-hoc signed. No global compiler installation, package upgrade or host link
change was needed. These scratch tools are not shipped with the project.

## Executed checks

```sh
make test image smoke preview
docker compose config --quiet
git diff --check
```

| Check | Result |
|---|---|
| Both Pascal executables compile with range/overflow/I/O checks | Passed |
| Initialization, dimensions, seed limits and unoccupied food | Passed |
| Movement, direct reversal and one accepted turn per tick | Passed |
| Gradual initialized growth and score | Passed |
| Walls, self-collision and tail vacancy/growth | Passed |
| Last free cell, full-board victory and 800-cell capacity | Passed |
| Ready, pause, resume, restart and speed bounds | Passed |
| Wrap across all four edges, food and self-collision | Passed |
| 51,200 paired deterministic steps across both modes | Passed |
| Terminal help, invalid CLI, non-TTY rejection and seed limits | Passed |
| PTY controls, small window, resize pause, loss and restart | Passed |
| Q, Esc and Ctrl-C restore cursor and terminal modes | Passed |
| SDL event replay: start, pause, arrows, focus loss, modes, pace and mouse | Passed |
| Food feedback, session record, finished-state freeze and restart | Passed |
| Repeated SDL initialization/cleanup and unavailable-audio fallback | Passed |
| Five distinct rendered states with image-content checks | Passed |
| Missing font, bad video driver and unwritable snapshot destination | Passed |
| Non-root terminal runtime through the host Docker PTY | Passed |
| Compose configuration | Passed |
| Actual Linux and macOS renderer images inspected | Passed |

The Pascal suite reports **8 groups and 1,062,997 assertions**. This includes
many repeated state invariants; it is not a claim of a million independent
scenarios. Linux compilation produces no source warnings. Native linking
prints FPC 3.2.2 warnings about obsolete Apple linker switches; binaries
compile and execute successfully.

The graphical smoke runs the real event handler and simulation, then captures
the actual SDL renderer. Image assertions detect blank/missing output and
indistinguishable states; visual inspection remains a separate check. The
README preview is a declared fixture, not an alleged human score.

The runtime image was inspected as ARM64, user `65532:65532`, entry point
`/usr/local/bin/SnakeTerminal`. Test commands use no network while playing.

## Regressions found and resolved

- The original terminal POC exposed CRT's Linux-console cursor codes.
  Explicit ANSI mode 25 now restores an xterm-style cursor.
- A synthetic PTY has no foreground process group. The test sends SIGWINCH
  after resize so the Docker transport forwards geometry changes.
- Native Metal initialization raised a floating-point exception with FPC's
  default trap mask. Saving/masking the floating-point environment at the SDL
  boundary, and restoring it during cleanup, allowed both native replay and
  real renderer capture to pass.
- macOS sets the kernel `PENDIN` retype flag when canonical mode returns.
  A separate Python-only PTY experiment reproduced that exact bit change with
  a direct save/raw/restore cycle, without the game. Native PTY comparison
  excludes only that macOS bookkeeping bit; all other flags, speeds and
  control characters remain checked.
- Screenshot allocation uses renderer output dimensions, since Retina
  physical pixels can exceed the logical canvas.

## Original baseline

On September 13, the original commit
`15477b37f4d26bc9571228086d40884991633efb` failed its untouched Docker build
with `Fatal: Can't find unit crt used by SnakeGame`. Its floating compiler
image resolved to index
`sha256:91da1f657792b48b3780c1c198d7892e99d25fdb4eb42e6a4167be81ee6e3b52`.

The unchanged 169-line original source compiled successfully in the replacement
Debian toolchain. That proved the packaging difference, not the original's
gameplay safety. Chess was read but not compiled or changed.

## Limits

- Linux graphical validation uses SDL's dummy/software driver; a Linux desktop
  session has not been manually play-tested here.
- Native macOS covers compilation, synthetic interaction and actual rendering,
  not an exhaustive matrix of displays, input devices or audio hardware.
- Generated audio was exercised through SDL, including mute and missing-device
  behavior; subjective listening quality has not been independently assessed.
- Windows and non-ANSI terminals have not been validated.
- The previous local AMD64 attempt could not execute without emulation. This
  change supplies a native AMD64 CI job; inspect that job rather than treating
  a multi-architecture base manifest as proof.
- Inputs are pinned for the container build; cross-platform binary identity is
  not asserted.
- Deterministic tests and independent review are not a security certification.
  No external agentic security scanner was run.

The owner authorized [issue #1](https://github.com/coisa/pascal-snake/issues/1)
and a PR. Snake was already unarchived. Merge and release publication remain
separate actions.
