# Prompt Engineering

> Or: specification work with better branding.

Prompt engineering is the practice of writing instructions so a model is more likely to return the kind of output you
actually need.

Models generate likely continuations from patterns in their training data. They are sensitive to input shape, can sound
confident while being wrong, and will happily follow a vague prompt into a ditch.

That sounds more dramatic than it is. In practice, getting started usually means being explicit about the task, the
constraints, the context, and the output format.

The goal is not clever wording. The goal is predictable results under pressure.

This is the smallest useful unit in the workflow stack: before tools, loops, and orchestration, you still need one step
to be well specified.

---

## A Simple Prompt Structure

Start here.

```
Role:
[who the model should act as]

Task:
[what it should do]

Context:
[the facts it should rely on]

Constraints:
- [limits, exclusions, required behavior]

Output:
[exact format, length, or schema]

Failure:
[what to do if the answer is missing, unsafe, or uncertain]
```

Bad:

- "Review this migration plan and tell me what you think."

Good:

- "Act as a backend reviewer. Identify the top 3 operational risks in this migration plan. Use bullet points. Do not
  invent missing details. If key information is missing, say what is missing."

If the model keeps drifting, the fix is usually not better poetry. It is clearer requirements.

---

## Core Parts

### 1. Role and Task

State who the model is supposed to be and what it should do.

Bad:

- "Explain Kubernetes."

Good:

- "Explain Kubernetes to a senior backend engineer with no DevOps background. Focus on the control plane and
  scheduling."

This does not grant expertise. It narrows tone, scope, and likely framing.

---

### 2. Constraints and Forbidden Behavior

State the limits explicitly: what to do, what not to do, and what to refuse.

Bad:

- "Give me a recommendation."

Good:

- "Recommend one approach. Use bullet points. Avoid speculative claims. Do not introduce external frameworks. If the
  input is missing critical data, say so instead of guessing."

Useful constraints often include:

- Length limits
- Allowed tools or libraries
- Forbidden assumptions
- Required approach
- Refusal paths
- Citation requirements
- PII handling

If a behavior matters, say it once and say it plainly. `must` ages better than `should`.

---

### 3. Output Shape and Failure Shape

If you want structured output, specify it.

Bad:

- "Summarize this architecture decision."

Good:

- "Return valid JSON with keys `summary`, `benefits`, `risks`, and `status`. If the input is incomplete, set `status`
  to `insufficient_input` and list what is missing. Output only JSON."

For more predictable output:

- Enforce output shape
- Repeat critical constraints when they matter
- Define fallback behavior
- Require explicit uncertainty instead of invented certainty
- Leave escape hatches for incomplete or unsafe inputs

Production prompts should fail cleanly. "Do your best" is not failure handling.

---

### 4. Context Boundaries in the Prompt

Provide the facts the model should rely on, and make the trust boundary explicit.

Bad:

- "Use the documents if helpful."

Good:

- "Answer only from the supplied documents. Cite the supporting chunk IDs. If the answer is not present in the
  provided context, return `not_found`. Do not use external knowledge."

Most model API calls are stateless unless your application supplies prior context. At the prompt level, that mainly
means being explicit about what sources the answer may use.

Two practical rules:

- If the answer must come from supplied context, say so.
- If context is chunked badly, the prompt cannot rescue it.

Chunking should preserve semantic coherence. Large or vague chunks blur meaning; tiny chunks lose it in pieces.

---

### 5. Examples

Examples are useful when the task is mostly about pattern matching: classification, extraction, rewriting, or style.

Bad:

- "Classify these support tickets by urgency."

Good:

- "Classify these support tickets by urgency using the examples below, then classify the new ticket with the same label
  set."

Common mistakes:

- Too many examples for a simple task
- Examples that contradict the written rules
- Inconsistent labels or formatting
- Over-explaining what the examples already show

Examples define behavior. Bad examples define bad behavior more efficiently.

---

### 6. Reasoning Instructions

You can ask the model to work carefully without asking it to print a diary.

Bad:

- "Show all your reasoning before the answer."

Good:

- "Work through the problem carefully, but return only the final answer and a short justification. If uncertain,
  state the uncertainty explicitly."

The practical goal is not visible verbosity. It is better decisions with controlled output.

---

## Common Mistakes

Bad:

- A prompt with repeated rules, buried constraints, no explicit failure behavior, and examples that do not match the
  instructions.

Good:

- A prompt with a clear task, explicit constraints, a defined output shape, one or two representative examples, and a
  failure path.

Bad prompts usually show the same symptoms:

- Instructions scattered everywhere
- Contradictory constraints
- Role mixed with task mixed with examples
- Emotional filler instead of explicit requirements
- No clear failure behavior
- Weak citation requirements when retrieval is involved

When a prompt misbehaves, do the boring fix first:

1. Extract the intent in one sentence.
2. Separate role, task, context, constraints, and output.
3. Replace vague words like `should` with `must` where needed.
4. Normalize repeated rules so they appear once.
5. Add or fix examples.
6. Re-test against known cases.

Prompt refactoring is still refactoring. The tools are just worse.

---

## Testing and Iteration

A strong prompt behaves more like a testable specification than a clever instruction.

Bad:

- "Keep tweaking this until it feels smarter."

Good:

- "Test this prompt against five representative inputs. Check schema compliance, refusal behavior, citation behavior,
  and one edge case with missing information. Then change one thing at a time."

In practice, testing usually means:

- Running representative inputs
- Checking output shape
- Checking failure behavior
- Checking retrieval or citation behavior if applicable
- Saving a few regression cases

Generation creates possibilities. Evaluation constrains reality.

Bad:

- "Write the answer and judge whether it is good."

Good:

- "First generate an answer. Then, in a separate evaluation step, score it for accuracy, completeness, and format
  compliance."

If a prompt matters in production, version it. If it only exists in someone's chat history, it is not a system.

---

## Production Concerns

Production prompts should fail safely.

Bad:

- "Do your best."

Good:

- "If required information is missing, return `status: needs_input`, list the missing fields, and ask for the next
  step."

Many production systems also wrap prompts in a state machine or decision tree.

Bad:

- A single prompt that tries to decide, retrieve, generate, validate, retry, and escalate on its own.

Good:

- A prompt that handles one step well, while the application decides when to retry, retrieve more context, escalate, or
  stop.

The prompt is usually a one-shot function. The application owns the transitions.

That handoff is the subject of the next chapter: not how to phrase the instruction, but how the application chooses and
orders the material around it.

---

## When Prompting Is Not Enough

Better prompting does not solve every problem. Some tasks also need:

- Retrieval from current or private documents [1]
- Tool use for computation or external actions [3]
- Fine-tuning for narrow, repeated behavior [2]

Bad:

- "Answer from company policy," when the policy is not in the prompt and the model has no tool or retrieval access.

Good:

- "Answer only from the supplied policy excerpts. Cite the supporting section IDs. If the answer is not present,
  return `not_found`."

Prompting shapes behavior. System design sets the real limits.

---

## Practical Workflow

1. Define the output format.
2. Define the failure format.
3. Write the simplest prompt that could work.
4. Test it on a small set of representative inputs.
5. Fix one problem at a time.
6. Version it once it is stable.

Treat prompts as configuration, not folklore.

---

## Navigation

[⬅ Spec Driven Development](../06_spec_driven_development/README.md) | [🏠 Home](../README.md) | [Context ➡](../08_context/README.md)

[1]: https://arxiv.org/abs/2005.11401

[2]: https://platform.openai.com/docs/guides/fine-tuning

[3]: https://platform.openai.com/docs/guides/function-calling
