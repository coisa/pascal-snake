# AGENTS.md

## Purpose

Run reproducible validation for pull requests and the main branch.

## Ownership

The repository root owns release and publication authority. CI supplies test
evidence and cannot merge, deploy or publish artifacts to a registry.

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
