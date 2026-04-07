# Architecture Audit — Observations

Patterns observed during real audits. Each observation documents a gap
the procedure didn't cover or a technique that improved results.

---

## Observation 1: Degraded-without-signal is a distinct error category

**Date:** April 2026
**Context:** Ingestion pipeline audit (agentplane). Dedup failure kept all
rules (no dedup applied). Rule submission failure skipped individual rules.
Both logged warnings but the pipeline returned success status. The caller
(test harness, operator looking at run.json) saw "completed" with a lower
rule count and no explanation.

**What happened:** The audit correctly identified both as error swallowing
and classified them as "pre-existing, out of scope." The procedure's three
error categories (propagated, handled-and-recorded, swallowed) didn't fit:
the errors *were* handled (logged, pipeline continued), and continuing was
the right choice (don't fail a 30-minute extraction because one rule
couldn't submit). But the response looked identical to a fully successful
run. The degradation was invisible.

**The gap:** The procedure's error classification is binary: either the
error is propagated/recorded (good) or swallowed (bad). But there's a
third failure mode that's harder to spot: the error is handled reasonably,
processing continues with reduced output, but the caller can't tell. The
result *looks* complete. A batch job that processes 239 items, fails to
save any of them, and reports "completed" with `rule_count: 0` — that's
not swallowing (the error was logged), but it's not honest either.

**The pattern (universal):** Any system that continues past a partial
failure and reports a success-like status without indicating what was lost.
Examples across codebases:
- HTTP 200 with partial data (should be 206 or include a completeness indicator)
- Batch job skips failed items, reports success, count is just lower
- Pipeline step fails, next step gets fewer inputs, final output is smaller
  but status is "done"
- Retry logic gives up silently and returns what it has

**The check:** When a function continues past an error, does the return
value or status indicate that something was lost? If not, that's a finding.
The fix is never "fail instead" — it's "signal the degradation" via status
code, warning field, count of failures, or explicit partial-result marker.

**Procedure update:** Added "degraded without signal" as a fourth error
classification in Layer 3, between "handled and recorded" and "swallowed."

---

## Observation 2: Cursory findings get walked past

**Date:** April 2026
**Context:** Same ingestion pipeline audit. Two error-handling issues
(dedup failure silent, rule submission failure silent) were noticed during
the scoped audit of the strategy system. They were cheap fixes — add a
warning, add a trace field. The audit classified them as "pre-existing,
out of scope" and moved on.

**What happened:** The "fix everything cheap" rule existed but didn't
explicitly cover things noticed in passing outside the audit scope. The
ambiguity allowed inventing a "pre-existing = out of scope" exemption.
The rule was clear in intent but not in application.

**Procedure update:** Added "this includes issues noticed in passing
outside the audit scope — offer to fix them" to the fix-everything-cheap
rule. One sentence. The audit scope doesn't expand; you just don't walk
past cheap fixes you happened to see.

