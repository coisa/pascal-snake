# AGENTS.md

## Purpose

Implement deterministic Snake rules and two Pascal presentation targets.

## Ownership

The engine owns rules. The desktop and terminal layers own input, time and
presentation. The SDL adapter owns C ABI declarations and platform calls.

## Local Contracts

- `snake_engine` has no graphics, CRT, clock, filesystem or network dependency.
- Initialize through the public API. Records also support explicit test fixtures.
- Check collisions before mutation; initialize every new body segment.
- Food occupies a free cell; filling the board wins. Wrap mode changes edges,
  never self-collision rules. Randomness belongs to each game instance.
- Use English and simple records/procedures. Keep resource lifetimes explicit.
- Graphical effects must not influence simulation; reduced motion disables
  interpolation, pulses and particles. Audio failure must not stop gameplay.

## Work Guidance

Update Pascal tests for rule changes and synthetic integration checks for
input, timing, rendering or lifecycle changes. Cache text with bounded ownership.

## Verification

Run `make test` and `make smoke`; compile with range and overflow checks.
Inspect a frame from the actual SDL renderer after visual changes.

## Child DOX Index

- `snake_engine.pas`: deterministic state and rules.
- `snake_terminal.pas`: CRT input, incremental drawing and cleanup.
- `snake_cli.pas`: shared strict decimal seed parsing.
- `snake_sdl.pas`: minimal SDL2 and SDL2_ttf C ABI.
- `snake_desktop.pas`: graphical game loop, visuals, input and audio.
