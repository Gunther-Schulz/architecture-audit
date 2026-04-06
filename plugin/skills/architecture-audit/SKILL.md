---
name: architecture-audit
description: This skill should be used when the user says "audit", "review architecture", "code review", "is this robust?", "check the architecture", "full audit", or asks to evaluate whether the current implementation is sound. Use proactively before declaring significant implementations complete.
version: 0.1.0
license: MIT
---

# Architecture Audit

## Load this now

Read `PROCEDURE.md` and `OBSERVATIONS.md` from the architecture-audit repository. The procedure defines what to do. The observations document failure patterns — read them to calibrate judgment before starting.

The procedure has three mandatory layers, applied deep-first:
1. **Structural audit** — is the architecture the right shape?
2. **Boundary audit** — do components agree on what they exchange?
3. **Error path audit** — can the system fail silently?

Start with structure, not surface bugs. If the architecture is wrong, individual bugs are symptoms.

## Critical rules

- **Never say "looks good" without completing all three layers.** The impulse to say "looks good" is the signal to go deeper.
- **Never accept "tests pass" as evidence of correctness.** Tests verify what they test.
- **Never protect sunk cost.** If the architecture needs rethinking after 7 phases of implementation, say so.
- **Swallowed errors are always findings.** No exceptions. A function that converts an error to a default value is lying to its caller.
- **Two passes minimum.** The first pass finds obvious issues. The second finds structural ones.

## After the audit

Produce a single document with findings organized by layer (structural → boundary → error path). Each finding has: code location, impact, classification (bug / design gap / architecture problem). End with an honest answer: is this architecture sound, or does it need rethinking?
