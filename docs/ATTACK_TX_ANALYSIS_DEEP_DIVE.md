## Deep Root Cause Drill

> This document is executed **immediately** after the initial analysis (Phases 1→6) is complete.  
> Sole objective: identify the **deepest, irreducible code defect**.  
> No profit calculations, no fund-flow tables, no LP loss estimates—those are surface-level work and out of scope for this phase.

---

## Core Principles

**The root cause identified during the initial analysis (Phases 1→6) is almost always a "surface root cause."** It explains "what the attacker did," but often fails to answer "why the attacker was able to do it."

Typical "surface → deep" follow-up patterns:

- Surface: "The application-layer handler did not verify the message sender, so the attacker could trigger a privileged action"  
  → Deep follow-up: **How did the attacker's message/proof pass the upstream verification? Is the verification code itself correct?**
- Surface: "A function read a manipulated state value during an external call window"  
  → Deep follow-up: **Why was there no reentrancy lock / state lock on this window? Was there a commented-out or missing invariant check?**
- Surface: "Share pricing was transiently manipulated, triggering liquidation"  
  → Deep follow-up: **How were the pricing formula inputs (totalAssets/totalSupply) altered? Why does the entry point that modifies them lack access control or a delay?**

**You must keep following the causal chain until you reach "this line of code is the bug."**

---

## Execution Flow (strict sequential order)

### Step 1: Map the Trust Boundary Chain

From the attack entry point to the final state write, list every **trust boundary crossing** along the path:

```
Entry → [Boundary 1: who checks what?] → Intermediate layer → [Boundary 2: who checks what?] → ... → Final write
```

For each boundary, document:
- **Validation function name + source file**
- **One-sentence description of the validation logic** (e.g., "checks msg.sender == owner", "verifies Merkle proof", "checks source chain == trusted chain", "require(health > threshold)")

### Step 2: Open and Audit Each Boundary's Source Code

**Starting from the outermost boundary (closest to the entry point), open the full source code of each validation function in sequence.**

For each validation function, you must:
1. **Read the complete source code** (not just the function signature—read every line of the function body)
2. Answer the following questions:
   - Can this validation be bypassed? How?
   - Are there unchecked boundary conditions on input parameters? (e.g., `index >= length`, `length == 0`, `proof.length == 0`, empty arrays, zero addresses)
   - If cryptography/hashing/Merkle is involved, does the proof computation correctly **bind the verified data** to the **verification result**? (i.e., would modifying the verified data necessarily cause verification to fail?)
   - Is there a replay vector? (Can the same proof/signature be used for different requests/messages?)

3. **Skipping any validation function is not allowed.** Even if the previous layer's analysis "already provides a complete explanation of the attack," you must still inspect the next layer. Reasons:
   - The upper-layer fix recommendation may be wrong (if a deeper layer also has a bug, fixing the upper layer alone is insufficient)
   - The true root cause may reside in a deeper layer
   - The security team needs to know **all** exploited code defects, not just the most superficial one

### Step 3: Render a Verdict for Each Boundary

For each trust boundary, assign one of the following:
- **SECURE**: Validation logic is correct; the attacker cannot bypass it. Provide justification.
- **VULNERABLE**: Validation logic is flawed. Provide:
  - The specific line of code that is defective
  - A precise description of the flaw (what check is missing? where is the math/logic error?)
  - How the attacker exploits this flaw
- **[OPEN]**: Source code is unavailable or the determination is inconclusive. State what is needed to reach a conclusion.

### Step 4: Identify the Deepest Root Cause

Among all boundaries marked VULNERABLE, find the **deepest one** (i.e., if this bug were fixed, all upper-layer bugs would no longer be exploitable).

This is the deepest root cause. If multiple independent VULNERABLE boundaries exist (mutually non-dependent), list all of them.

### Step 5: Revise the Initial Analysis Conclusions

If the deepest root cause differs from the Phase 3→6 conclusions, **the Phase 6 root cause description must be updated** to include:
- **Surface root cause**: (original Phase 6 conclusion)
- **Deepest root cause**: (discovered in this step)
- **Relationship**: The deepest bug enables the surface bug to be exploited (or: the two are independent bugs, both requiring remediation)

---

## Output Format

Append the following after Phase 6 in result.md:

```
## Deep Root Cause Analysis

### Trust Boundary Chain
(Output from Step 1)

### Boundary-by-Boundary Audit
(Output from Steps 2–3, one subsection per boundary)

### Deepest Root Cause
(Conclusion from Step 4)

### Revisions to Initial Analysis
(Step 5, if any revisions apply)
```

After this section is complete, **do not stop**. Immediately continue to `ATTACK_TX_ANALYSIS_POC_REPLAY.md` and append the reverse-engineering / PoC / RPC replay sections after the Deep Root Cause Analysis section.

---

## Common "False Stopping Points" (traps you must avoid)

1. **"Missing application-layer authentication" is not the endpoint.** If the attacker submitted a "seemingly legitimate" message/proof, you must verify whether the verification layer's code is actually correct.
2. **"The proof passed so it must be legitimate" is not a valid argument.** The proof verification code itself may contain bugs (missing input validation, boundary condition errors, broken bindings).
3. **"Candidate A already provides a complete explanation" is not a reason to skip Candidate B.** Security audits require examining all attack surfaces, not stopping at the first plausible explanation.
4. **"The source code is too complex / too long" is not a reason to skip reading it.** Read the complete source code. If a function exceeds 100 lines, read it in segments.
5. **"[OPEN] — more data needed"** is only permissible when source code is genuinely unavailable. If the source code exists in `contract_sources/`, you must read it.
