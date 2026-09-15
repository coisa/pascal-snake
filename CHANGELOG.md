# Changelog

## [1.0.0] - 2026-09-15

### Added

- Native Pascal/SDL2 desktop edition with smooth movement, procedural icons,
  particles, apple pulses, panel transitions and synthesized audio.
- Classic and Wrap worlds, three paces, per-world/pace session records,
  countdown, focus-loss pause, mouse controls and fullscreen.
- Reduced motion, mute, strict CLI seeds, snapshots and graceful error paths.
- Pure deterministic Pascal rules and tests, full-board victory, terminal PTY
  checks, graphical event replay and rendered-frame checks.
- English documentation explaining the university origin, architecture and
  reusable AI modernization challenge.
- Reproducible Docker toolchain and CI for Linux AMD64 and ARM64.

### Changed

- All authored UI, comments, contracts and documentation now use English.
- `SnakeGame.pas` launches the desktop game; `SnakeTerminal.pas` keeps a
  standalone CRT experience with the same rule engine.
- Desktop uses 28 × 18 cells; terminal uses 30 × 14 with incremental drawing.
- Docker uses a pinned Debian image, APT snapshot, Free Pascal 3.2.2 and a
  non-root, network-free terminal runtime.

### Fixed

- Growth initializes each segment and respects board/array capacity.
- Food always occupies a free cell and placement terminates on nearly full boards.
- One valid turn per tick prevents instant reversal.
- Collision accounts for whether the tail moves or remains during growth.
- Resizing pauses the terminal edition; focus loss pauses the desktop edition.
- SDL's floating-point expectations are handled explicitly on native macOS.

## [0.1.0] - 2026-09-15

- Preserve the original university exercise at commit `15477b37f4d26bc9571228086d40884991633efb`
  as the historical baseline before modernization.

[1.0.0]: https://github.com/coisa/pascal-snake/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/coisa/pascal-snake/releases/tag/v0.1.0
