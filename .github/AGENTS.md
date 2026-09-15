# AGENTS.md

## Purpose

Run reproducible validation and publish documentation from the default branch.

## Ownership

The repository root owns release and publication authority. CI supplies test
evidence and cannot merge or publish artifacts to a registry. The owner also
authorized docs-to-Wiki automation; it uses a dedicated configured secret only
on default-branch publication runs.

## Local Contracts

Write in English. Pin external actions by commit. Grant read-only repository
permissions, use standard public runners and bound job time. Never require
secrets or privileged pull-request events for tests.

## Work Guidance

Use the same Makefile and Docker targets as local validation. A new platform
becomes verified only after its job succeeds, not when added to the matrix.

## Verification

Check YAML structure and the actual run result at the PR commit.

## Child DOX Index

- `workflows/ci.yml`: Linux AMD64/ARM64 build, rule, SDL and terminal checks.
- `workflows/wiki.yml`: credential-free PR preview and default-branch Wiki sync.
- [wiki_sync.md](wiki_sync.md): renderer inputs, outputs, failures and verification.
- `test_wiki_sync.py`: isolated rendering and managed-file boundary tests.
- `requirements.txt`: hash-pinned Markdown parser installed in `build/wiki-venv`.
- `dependabot.yml`: weekly Actions, Docker and Python update PRs, without auto-merge.
