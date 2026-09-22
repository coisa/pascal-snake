# Origin and baseline

The owner confirmed this was a university project. No course, institution,
assignment date or grade has been inferred. The experiment began by asking
what a modern frontier AI could do with an old Pascal exercise.

The original repositories were inspected on September 13, 2026 through Git
and the GitHub API. Their Pascal files were read in full.

| Evidence | Snake | Chess |
|---|---|---|
| Repository | [coisa/pascal-snake](https://github.com/coisa/pascal-snake) | [coisa/pascal-chess](https://github.com/coisa/pascal-chess) |
| Base commit | `15477b37f4d26bc9571228086d40884991633efb` | `bec5c0cedae44637e2086ba9d6d52eb42a64b945` |
| Commit date | 2024-01-06 | 2017-12-01 |
| Tracked files | 3 | 1 |
| Pascal source | 4,107 bytes | 6,516 bytes |
| History | 2 commits | 1 commit |
| Public | Yes | Yes |
| Archived when inspected | No | Yes |

The commit dates are repository evidence, not claimed assignment dates. Snake
was still unarchived on September 15; no unarchive operation was necessary.
Chess was inspected only and is unchanged. Neither inspected tree contained
a repository license; this refactor does not choose one for the owner.

Snake was the smaller, more complete game. Chess moved pieces without turn,
movement, path, check or mate validation and had no exit from its main loop.
Building a chess rules engine would have changed the size of the experiment.

## What the original teaches

The [original SnakeGame.pas](https://github.com/coisa/pascal-snake/blob/15477b37f4d26bc9571228086d40884991633efb/SnakeGame.pas)
uses records, an array of segments, procedures, conditions and a timed CRT
loop. It begins with five segments, uses WASD, grows by five per apple,
accelerates and ends on collision. Those fundamentals remain recognizable.

Static inspection found concrete limitations:

- Increasing length by five did not initialize the new segments.
- The array held 1,400 segments while the useful board held 3,696 cells.
- Food placement did not exclude occupied cells.
- Re-seeding happened inside the main loop; there was no deterministic seed.
- The display expected 79 columns and 50 rows and used DOS code-page glyphs.
- There was no pause, restart, explicit quit, score, help, README or test suite.
- Rules, rendering, input and time were mixed.
- The Docker compiler image had no pinned version or digest.

These are code observations. Executed compilation results are recorded in
[validation.md](https://github.com/coisa/pascal-snake/blob/master/docs/validation.md).

## Deliberate changes

This is a feature and correctness refactor, not visual/timing equivalence.
Desktop graphics, wrap mode, scores, gradual safe growth, bounded acceleration,
pause/restart, victory and automated checks are intentional additions. The
desktop and terminal boards fit their respective interfaces. The game needs
no account, server or persistent player data.

Git is the archive of the original. There is one current implementation,
with shared rules and two actively maintained presentation targets.
