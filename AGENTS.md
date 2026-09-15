# AGENTS.md

## Purpose

A university Snake exercise modernized into an approachable Pascal game.
The application, rules and rule tests remain Pascal.

## Ownership

The history of `coisa/pascal-snake` is the source of the exercise. The owner
authorized this refactor, its GitHub issue and PR. Merging, changing visibility
and publishing container images require their own authorization.

## Local Contracts

- Keep `SnakeGame.pas` as the graphical entry point and `SnakeTerminal.pas`
  as the terminal entry point; share the deterministic rule engine.
- Write all UI, documentation, comments and identifiers in English.
- Separate rules from graphics, audio, input and time. Use SDL2 for platform
  services and Free Pascal CRT for the terminal edition.
- Git preserves the original. Do not maintain parallel legacy source copies.
- `build/` and `tmp/` are ignored outputs. Do not mount HOME or Docker sockets
  in containers. Gameplay needs no network, account or personal files.
- Keep implementation recipes in `plans/` and factual evidence in `docs/`.
  Never invent a license, approval, issue or validation result.

## Work Guidance

Read the relevant child contract before editing. Use focused commits and
synthetic tests. Keep the changelog and implementation recipe current.
The pinned Docker build is the reproducible validation reference; document
native platform testing separately.

## Verification

Run `make test`, `make image`, `make smoke` and `git diff --check`.
Inspect actual graphical output. Obtain independent review of the final diff
before describing the implementation as reviewed.

## Child DOX Index

- [plans/AGENTS.md](plans/AGENTS.md): implementation recipe and acceptance.
- [src/AGENTS.md](src/AGENTS.md): rules, platform adapter and presentation.
- [tests/AGENTS.md](tests/AGENTS.md): deterministic, SDL and PTY checks.
- [docs/AGENTS.md](docs/AGENTS.md): origin, architecture and evidence.
- [.github/AGENTS.md](.github/AGENTS.md): automated validation on Linux runners.
- [README.md](README.md): build, play, controls and the experiment.
- [CHANGELOG.md](CHANGELOG.md): observable project changes.
