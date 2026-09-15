# AGENTS.md

## Purpose

Verify rules and interaction with synthetic inputs and no personal data.

## Ownership

Pascal tests own rule evidence. Python helpers drive isolated PTYs and SDL
subprocesses; application behavior remains in Pascal.

## Local Contracts

Write in English. Use fixed seeds, bounded subprocesses and behavior assertions.
Fixtures may construct valid states to reach rare cases. Use only Python's
standard library. Temporary output belongs below `build/`, never HOME.
Do not mount Docker sockets or expose ports.

## Work Guidance

A regression must produce an observable failure. Exercise initialization,
normal play, error paths and cleanup. The desktop's SDL replay runs through
the same event handler and update loop as interactive play.

## Verification

`make test` runs Pascal, PTY and graphical checks in a pinned container.
`make smoke` tests the terminal runtime image through a host PTY.
Inspect actual renderer output separately from programmatic image assertions.

## Child DOX Index

- `test_snake_engine.pas`: rules, both modes and state invariants.
- `smoke_terminal.py`: CLI, controls, resize and terminal restoration.
- `smoke_desktop.py`: SDL replay, rendered states, CLI and failure cleanup.
