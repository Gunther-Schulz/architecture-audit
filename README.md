# Architecture Audit

A Claude Code skill plugin providing a systematic procedure for objective architecture review.

Three mandatory layers, applied deep-first:
1. **Structural audit** — is the architecture the right shape, or did it grow into this shape?
2. **Boundary audit** — do components agree on what they exchange?
3. **Error path audit** — can the system fail silently?

Not tied to any specific codebase, technology, or project. Applicable to any software system where correctness matters.

## Installation

```bash
claude plugin marketplace add architecture-audit-marketplace --source github:Gunther-Schulz/architecture-audit
claude plugin install architecture-audit@architecture-audit-marketplace
```

## Usage

In Claude Code, trigger with: "audit", "review architecture", "code review", "is this robust?"

Or invoke directly: `/architecture-audit`

## Origin

Created after a session where six rounds of "review" failed to catch fundamental problems. Each round found what the previous should have caught. The procedure exists to make round one find what previously took round six.
