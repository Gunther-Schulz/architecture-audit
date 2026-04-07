# Architecture Audit Procedure

*A systematic procedure for objective architecture review. Not tied to any specific codebase, technology, or project. Applicable to any software system where correctness matters.*

*Origin: Created after a session where six rounds of "review" failed to catch fundamental problems — error swallowing, missing security, god services, incompatible subsystems. Each round found what the previous should have caught. The procedure exists to make round one find what previously took round six.*

---

## Why audits fail

The default behavior when asked to "review" or "audit":

1. Read the code
2. Check if it does what the docs say
3. Look for obvious bugs
4. Report findings

This finds surface issues. It never finds architectural problems because it never
questions whether the architecture is right — only whether the implementation
matches it.

Structural problems are invisible to surface review:
- A function that silently converts errors to defaults **works correctly** in every test
- A service that handles 8 responsibilities **compiles and serves requests**
- Two incompatible pattern systems **both produce correct results** in isolation
- Missing auth on an endpoint **doesn't cause test failures**

These only manifest under conditions tests don't cover, or as escalating
maintenance cost. A review that checks "does this code work?" will never find
them. The review must ask "should this code exist in this form?"

---

## The three layers

Mandatory. Applied in order: deep first, surface last. A finding from a deeper
layer overrides a shallower one — if the architecture is wrong, individual bugs
are symptoms, not root causes. Fixing symptoms without fixing structure means
they recur.

### Layer 1: Structural audit

**Goal:** Is the architecture the right shape, or did it grow into this shape?

**1. Responsibility inventory.** For each component: list what it does. Not what
it's called — what it actually does. If the list has more than 3 items, the
component may be accumulating responsibilities. If two components share a
responsibility, there's duplication.

**2. Growth direction test.** If one more feature were added, where would it go?
If the answer is "add it to the existing component because it needs the same
data" — the component is a gravity well. Features accumulate not because they
belong together but because they share a database. This is how god services form.

**3. Duplication check.** Are there two implementations of the same concept? Two
pattern matchers, two auth mechanisms, two serialization formats for the same
data? Each duplication is a potential mismatch. Ask: why do both exist? If the
answer is "historical" or "slightly different" — one should be eliminated.

**4. Security structure check.** Is security a property of the architecture or of
individual endpoints? If it's per-endpoint, every new endpoint is a security
decision someone can get wrong. If it's structural (all writes go through an
authenticated boundary), security is guaranteed by construction. Check: is there
a way to add a write endpoint that accidentally skips auth?

**5. Audit trail completeness.** Can every decision be reconstructed from stored
records alone — without reading the code? Not "an audit log exists" — can you
answer "why was this specific request approved at this specific time?" If you
need source code to interpret the trail, it's insufficient.

**6. Failure mode inventory.** For each dependency: what happens when it fails?
Does the system fail-open, fail-closed, or fail-loud? Is this explicit (chosen
by design) or implicit (whatever the code happens to do)? Implicit failure modes
are findings.

**Verification:** For each structural finding, describe: the current shape, why
it's problematic, what the alternative is, what would break or improve. Findings
without alternatives are complaints, not analysis.

**Deepening:** For each finding, trace its implications. What else must be true
if this finding exists? What adjacent issues does it predict? A finding about
one component predicts similar issues in components with the same shape. A
missing abstraction in one area predicts missing abstractions in adjacent areas.

This is not a second pass of the same checks. It is a targeted investigation
driven by what was already found. Each finding is a lead — follow it until it
stops producing new findings. Findings from deepening are added to the same
layer they originated from.

### Layer 2: Boundary audit

**Goal:** Do components agree on what they exchange?

**1. Name every boundary.** Every interface between components: service-to-service,
function-to-function, code-to-database, code-to-external-system.

**2. Check agreement.** Does the producer's output match the consumer's expected
input? Not "do the docs say they match" — does the actual code on both sides
agree? Check: field names, types, encoding, null handling, error representation.

**3. Check transformation.** If data is transformed at a boundary: is the
transformation documented, tested end-to-end through real infrastructure (not
mocked), and traceable?

**4. Check what's NOT there.** What does the consumer need that the producer
doesn't provide? What does the producer send that the consumer ignores?

**Verification:** For each boundary, point to: producer code, consumer code,
and a test that verifies actual data crosses correctly. If the test mocks either
side, it verifies the mock, not the boundary.

**Deepening:** For each finding, trace its implications. A boundary mismatch in
one place predicts mismatches at similar boundaries. A missing contract in one
consumer predicts missing contracts in other consumers. A misplaced abstraction
(defined in the wrong layer) predicts other misplaced abstractions.

Check contract ownership: for each interface or contract, is it defined where
the concept lives (domain layer) or where it's consumed? Consumer-defined
contracts that duplicate domain concepts are boundary violations.

### Layer 3: Error path audit

**Goal:** Can this system fail silently?

**1. Trace every error.** For every function that can fail: where does the error
go? Propagated? Logged? Stored? Swallowed?

**2. Classify:**
- **Propagated** — caller receives the error and can act. ✓
- **Handled and recorded** — error caught, policy applied, handling logged. ✓
- **Degraded without signal** — error caught, processing continues with partial
  output, but the caller cannot distinguish degraded results from complete
  results. The handling is reasonable (continue past partial failure); the
  response contract is not (reporting success when something was lost).
  **Always a finding.** The fix is not to fail — it's to signal: a status
  that reflects incompleteness, a count of what was lost, a field that says
  "this result is partial." See observation 1.
- **Swallowed** — error caught, converted to default. Caller can't tell. **Always a finding.**

A swallowed error is a lie to the caller. A degraded-without-signal result is
a subtler lie — the error was handled reasonably, but the response pretends
nothing was lost. Both produce callers that act on incomplete information.

**3. Impact.** If swallowed or degraded-without-signal: what happens downstream?
Wrong decision? Incorrect output? Skipped security check? Wasted operator time
investigating why results look different? Impact determines severity.

**Verification:** For each error path: where it originates, where it's handled,
what the caller sees. If the chain can't be traced, the path is untested.

**Deepening:** For each finding, trace its implications. An error swallowed in
one function predicts swallowed errors in similar functions. A fire-and-forget
write predicts other fire-and-forget writes. A side effect that logs errors
but doesn't record them predicts other side effects with the same pattern.

---

## What the audit produces

A single document with:

1. **Structural findings** — god components, duplications, decorative security,
   incomplete audit trails, implicit failure modes.

2. **Boundary findings** — mismatches, untested boundaries, assumptions crossing
   component boundaries without verification.

3. **Error path findings** — every swallowed error, every degraded-without-signal
   result, every untraced path, with severity based on downstream impact.

4. **For each finding:** specific code location, impact if unfixed, classification:
   bug (fix the code), design gap (fix the design), or architecture problem
   (fix the structure).

5. **Fix everything cheap.** After reporting, fix every finding that can be
   resolved in the current session without architectural change. Do not defer
   fixes that take minutes. Do not bury low-severity findings or signal they
   can be ignored. Present all findings with equal clarity. Severity classifies
   impact, not urgency — a 5-minute fix with low impact is still worth doing now.
   Defer only what requires out-of-scope structural work.


6. **An honest answer to:** "Is this architecture sound, or does it need
   rethinking?" Not "it's fine for now." Either the architecture supports the
   requirements or it doesn't.

---

## What the audit must NOT do

- **Accept "tests pass" as evidence.** Tests verify what they test. They don't
  verify what they don't test.

- **Evaluate code against what it was supposed to do.** Evaluate against what it
  SHOULD do. If the design says "errors treated as defaults" — the audit should
  say "that design is wrong."

- **Protect sunk cost.** If the architecture needs rethinking, say so. "We
  already built it" is not a reason to avoid the finding.

- **List findings without severity.** "Missing auth" and "could improve log
  message" are not the same. Every finding needs impact.

- **Stop after one pass.** Each pass finds what the previous missed. Two passes
  minimum. The first finds obvious issues. The second finds structural ones.

- **Treat findings as isolated.** A finding is a lead, not a conclusion. Every
  finding predicts adjacent issues. The deepening step exists because the
  default behavior is to record a finding and move to the next checklist item.

---

## When to apply

- Before declaring any significant implementation "done"
- When the system has grown substantially since the last audit
- When bugs are found that "should have been caught by review"
- When asked to review, audit, or assess — this is the minimum standard
- When the impulse is to say "looks good" — that's the signal to go deeper
