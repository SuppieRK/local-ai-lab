# Context Engineering

> Deciding what the model sees, what it does not see, and what arrives too late to help.

Many LLM failures are context failures rather than raw model failures.

Context engineering is the practice of deciding what information enters the window, how it is ordered, what is omitted,
and what the application must do outside the prompt.

It is less about phrasing a clever instruction and more about making sure the model sees the right material, in the
right form, at the right time. Slightly less glamorous than fine-tuning, but usually more useful.

If prompt engineering is how you write the instruction, context engineering is how you decide what surrounds it.

---

## What Context Includes

In practical terms, context is everything the application sends with the request:

- System instructions
- User input
- Retrieved documents
- Tool results
- Conversation history
- Hidden scaffolding such as schemas, routing hints, and guardrails

If the application does not send it, the model cannot rely on it. If the application sends too much, the useful parts
compete with everything else.

---

## A Simple Assembly Order

Start with a boring structure.

1. Persistent instructions and non-negotiable constraints
2. The current user goal
3. Retrieved evidence or tool results
4. Short conversational state, if it still matters
5. Anything expendable

Bad:

- A large pile of retrieved documents followed by the actual rule near the end.

Good:

- The governing instruction first, the current task second, the supporting evidence after that.

Do not make the model excavate the important rule from a document landfill.

---

## Division of Labor

Prompt engineering decides how to ask for the result.

Context engineering decides what evidence, state, and constraints are available when the model answers.

In practice, systems usually degrade because:

- the wrong documents were retrieved
- the right documents arrived buried in noise
- critical constraints were present but too late
- stale conversation state overrode the current task
- the application expected the model to remember what it never sent

A larger model or larger window can mask some of this. It does not remove the need to choose the inputs well.

---

## Core Practices

### 1. Include Only What The Step Needs

The question is not "what could be relevant?" The question is "what must be present for this step to succeed?"

Bad:

- Send the entire ticket history, design doc, incident log, and previous sprint notes to answer one narrow question.

Good:

- Send only the current task, the directly relevant excerpt, and the one prior result the model still needs.

Useful context is:

- relevant to the current task
- trustworthy enough for the required decision
- small enough that the important parts stay visible

Everything else is overhead wearing a helpful disguise.

---

### 2. Put High-Leverage Material First

Order still matters inside a large window.

Bad:

- Present ten pages of retrieved material and mention the actual constraint afterward.

Good:

- Put the non-negotiable rule first, then the task, then the evidence needed to complete it.

Early context frames the task. Later context fills in details. Repeated context gets extra weight whether it deserves it
or not.

---

### 3. Use Progressive Disclosure

Do not send everything up front just because you can.

Bad:

- Start the step with the full repository summary, six retrieved documents, recent chat history, and raw tool output,
  before the model has even shown that it needs them.

Good:

- Start with the governing rule, the current goal, and the minimum supporting context. Retrieve or append more only if
  the current step actually needs it.

Progressive disclosure keeps context windows cleaner, reduces noise, and makes failure cases easier to debug.

---

### 4. Retrieval Defines The Trust Boundary

If the answer must come from retrieved material, say so, and retrieve accordingly.

Bad:

- "Use the documents if helpful."

Good:

- "Answer only from the supplied documents. Cite the supporting chunk IDs. If the answer is not present, return
  `not_found`."

Useful retrieval policy usually means:

- chunks that preserve semantic units
- ranking that prefers relevance over volume
- clear source identifiers for citation
- a defined fallback when the answer is not present

If the relevant material fits comfortably in context, the simplest retrieval strategy is sometimes no retrieval at all.

Weak retrieval does not just reduce quality. It changes what the model is able to justify.

---

### 5. Manage Conversation State Deliberately

Conversation history is not free context. It is accumulated bias.

Bad:

- Keep the full conversation forever and hope the model politely ignores the stale parts.

Good:

- Keep only unresolved references, current preferences that still matter, and prior results needed for this step.

Keep history only when it still helps with:

- unresolved references
- user preferences that actually matter
- prior tool results still needed for the current step

Summarize or drop the rest. Old turns are often more dangerous than missing turns because they still look authoritative.

---

### 6. Keep Orchestration Outside The Prompt When Possible

One prompt should not retrieve, decide, validate, retry, summarize, and escalate unless you enjoy debugging avoidable
ambiguity.

Bad:

- A single prompt that tries to gather evidence, judge sufficiency, call tools, write the answer, validate the answer,
  and decide whether to retry.

Good:

- The application decides when to retrieve and when to call tools; the model handles one bounded step at a time.

A more stable pattern is:

- the application decides when to retrieve
- the application decides when to call tools
- the model handles one bounded step at a time
- the application decides whether to continue, retry, or stop

This is context engineering too. The boundary between prompt and application logic is part of the design.

---

## Common Failure Modes

Bad:

- A system that keeps adding more context whenever the answer looks wrong.

Good:

- A system that asks which missing input, stale state, or weak retrieval decision caused the answer to drift.

Common problems:

- irrelevant retrieval results
- chunks that split meaning across boundaries
- repeated rules scattered across prompt and history
- stale state carried forward by habit
- citations requested vaguely or not at all
- tool results included in full when a short summary would do

Context windows are large enough to let you make expensive mistakes at scale.

---

## Practical Checklist

Before blaming the model, check:

1. Did we send the minimum necessary context for this step?
2. Is the most important instruction visible early?
3. Are retrieved chunks relevant, bounded, and attributable?
4. Is stale conversation state still being carried forward?
5. Is the application expecting the model to infer a rule it never received?
6. Should this be one prompt, or several smaller steps?

Context engineering is mostly input selection with fewer illusions.

---

## Navigation

[⬅ Prompt Engineering](../08_prompt_engineering/README.md) | [🏠 Home](../README.md) | [Skills ➡](../10_skills/README.md)
