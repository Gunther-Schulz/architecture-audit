# Observations

Documented patterns of how architecture audits fail and what techniques produce better results. Each observation is grounded in real incidents. These inform what the procedure needs to mitigate.

---

## 1. Shallow-first discovery

When asked to audit code, AI finds real issues — but surface issues first. Each round goes slightly deeper than the last: naming, then error handling, then missing auth, then swallowed errors, then "the whole service is a god service." Round 6's finding was the root cause of rounds 1-5's symptoms.

The procedural response: start deep (structure), not shallow (bugs). If the architecture is wrong, individual bugs are symptoms.

---

## 2. Findings without follow-through

In a real incident: an audit found "data layer has too many responsibilities" (correct finding) and "a subsystem lacks a formal interface" (correct finding). It stopped there. The implications were never traced:

- "Subsystem lacks formal interface" → where are contracts for this subsystem defined today? → found: an ad-hoc interface in a consumer package
- Are there other ad-hoc interfaces? → found: two more consumer packages each defining their own single-method subset of the same concept

The audit had the information to find all three. It found the first and moved on. Each finding is a lead — but the default behavior is to record it and advance to the next checklist item rather than following the thread.

The procedural response: after each layer, take each finding and trace its implications. Ask "what else must be true if this finding exists?" Follow the thread until it stops producing new findings. This is the **deepening** step.

---

## 3. Checklist as ceiling

When given a checklist of 6 structural checks, the audit performs all 6 and reports findings. Issues outside the checklist categories are not found — not because they were checked and cleared, but because they were never looked for. The checklist becomes the scope of the audit rather than the minimum.

This is the same pattern as Bildhauer observation 7 (procedure narrows attention). The procedural response is finding-driven deepening: the checklist seeds the investigation, but findings expand it beyond the checklist categories.

---

## 4. Component-level thinking misses concept-level issues

The structural audit inventories components (services, packages, files) and checks responsibilities per component. This finds god services and accumulated packages. But it misses issues that exist at the concept level:

- Where is this contract owned? (Interface in consumer vs. domain package)
- Are there multiple definitions of the same concept? (Ad-hoc interfaces duplicating domain interfaces)
- Does the domain package define all the contracts that consumers need?

These are visible only when you ask "for this concept (e.g., session tracking), trace all its definitions and usages across the codebase." Component-level inventory doesn't ask this question.

The procedural response: the deepening step after Layer 1 explicitly asks "what concepts are defined in the wrong place?" and the deepening step after Layer 2 checks contract ownership.

---

## 5. Boundary checks verify data but not contract location

The boundary audit checks "does the producer's output match the consumer's expected input?" This verifies data agreement. It does not verify where the contract is defined. A consumer-defined interface that duplicates a domain interface is a boundary smell — the consumer is dictating the contract instead of the domain. The data flows correctly, so the boundary check passes, but the architecture has a structural weakness.

The procedural response: the deepening step after Layer 2 includes "for each interface defined in a consumer package, does a domain interface already exist that it should use instead?"
