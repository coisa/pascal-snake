# A modern Pascal Snake

Implementation recipe for [issue #1](https://github.com/coisa/pascal-snake/issues/1).
The owner authorized the general refactor, English translation, issue and PR,
then the baseline 0.1.0 release, merge and modernized 1.0.0 release.
Container image publication is outside this delivery.

## Outcome

Turn a university programming exercise into a polished desktop Snake game,
keeping the application, deterministic rules and rule tests in Free Pascal.
SDL2 and SDL2_ttf provide platform services. A separate CRT executable keeps
the terminal experience usable through Docker without loading a graphics stack.

## Instruction map and reading route

The current root governs a local terminal proof of concept. Its four existing
children govern implementation, tests, documentation and the implementation
recipe. Retain those boundaries and update all five contracts to English.
Read root then the corresponding child before editing. The target `src/`
contract separates pure rules, desktop presentation/platform bindings and CRT
presentation. `tests/` owns deterministic and synthetic integration checks.
`docs/` owns provenance, architecture, the reusable challenge and evidence.
No new instruction subtree is needed for generated screenshots in `build/`.
Add `.github/AGENTS.md` for the durable CI boundary: read-only repository
permissions, pinned actions, bounded validation jobs and no publishing. Its
workflow subdirectory is structural and follows that contract directly.

## Implementation

1. Keep `SnakeGame.pas` as the graphical entry point; build `SnakeTerminal.pas`
   separately. Share CLI seed parsing and the deterministic engine.
2. Add a rule-level wall/wrap mode with tests for boundary transitions,
   collision and food invariants. Keep finite food placement, growth by five,
   no direct reversal, one accepted turn per simulation tick and full-board win.
3. Implement an SDL2 adapter with explicit C ABI records and resource cleanup.
   Use SDL2_ttf for readable type, bounded texture caching, procedural visuals
   and audio. Do not add a browser, JavaScript game logic or a game framework.
4. Draw a responsive letterboxed desktop composition with a live board,
   mode/difficulty choices, score, session best, visible shortcuts and state
   overlays. Add smooth movement, food pulses, particles and transition feedback.
   Make reduced motion, mute, keyboard and pointer controls first-class.
5. Separate the simulation clock from frame rendering. Pause on focus loss;
   avoid catch-up bursts after a stall. Ensure paused/finished games do not move.
6. Translate terminal UI and every authored document/comment. Document the
   owner-confirmed college origin and the single-prompt experiment without
   inventing course details, dates, grades or an objectively best AI model.
7. Extend the pinned Docker toolchain for graphics and font dependencies.
   Use a dummy SDL driver for bounded graphical replay/screenshots, preserve
   the non-root, network-free terminal image and document native dependencies.
8. Run the complete suite, inspect rendered frames, obtain independent review,
   resolve reproducible findings, commit and push only this project's changes,
   then open a PR linked to the issue.
9. Run the same container checks on GitHub's standard Linux AMD64 and ARM64
   runners. Keep CI read-only, with no deployment or image publishing step.
10. Preserve the original master commit as v0.1.0. Close the changelog, verify
    the final PR checks and review, merge the PR and tag the resulting master
    commit as v1.0.0. Publish English release notes and verify both tag targets.

## Acceptance matrix

| Requirement | Proof |
|---|---|
| Pascal remains the foundation | Source tree and Pascal compilation |
| Safe deterministic rules | Pascal assertions, seeds, full-board and wrap cases |
| Playable terminal | Synthetic PTY and packaged-image checks |
| Functional graphical controls | SDL event replay and state assertions |
| Polished visuals | Actual renderer screenshots inspected at full size |
| Resource lifecycle | Repeated startup, exit and missing-dependency checks |
| English/provenance | Repository text review and linked source history |
| Reproducible delivery | Pinned build, exact commit, clean diff, independent review |

## Risks and rollback

Native macOS and Linux dependency layouts differ; document tested paths and
avoid claiming support from compilation alone. SDL's C ABI must match the
headers, especially events and audio. Emoji fonts vary by platform, so draw
icons procedurally instead of depending on emoji width or color-font support.
Never write player state into personal folders. Session records are in memory.

Revert the relevant commits as a set to restore code, build definitions and
contracts together. Git preserves the original university source. Keep build
artifacts and screenshots in ignored `build/` or `tmp/` directories.
