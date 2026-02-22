# Context Engineering

> Designing the input so the model doesn’t have to guess what you meant.

Most AI failures are not model failures. They are context failures.  
The model did exactly what you asked. You just didn’t mean it that way.

Context engineering is the discipline of deliberately shaping what a model sees, in what order, and with what
constraints, so that its probabilistic guess aligns with your intent. It is less glamorous than fine-tuning and cheaper
than explaining to your CFO why you need more GPUs.

---

## What “Context” Actually Means

In practical terms, context is everything inside the model’s token window:

- System instructions
- User input
- Retrieved documents
- Tool results
- Conversation history
- Hidden scaffolding (schemas, formatting contracts, guardrails)

If it fits inside the window, it influences the output.  
If it doesn’t, it might as well not exist.

This sounds obvious. It becomes less obvious at scale.

---

## Why Context Engineering Matters

Modern LLM systems rarely fail because the model is “dumb.” They fail because:

- The prompt is underspecified.
- Retrieved data is irrelevant or noisy.
- Important constraints appear too late.
- The output format is ambiguous.
- The conversation history drifts.

In other words, entropy wins.

Throwing a larger model at the problem often helps. So does doubling the context window. But that’s similar to adding
microservices to fix a naming issue: technically possible, operationally expensive.

---

## Core Principles

### 1. Explicit Over Implicit

Models infer. That’s their job.  
Your job is to remove the need for inference.

Bad:

- “Summarize this.”

Better:

- “Summarize in 5 bullet points. Focus on architectural trade-offs. No marketing language.”

Ambiguity is paid for in tokens.

---

### 2. Order Matters

Transformers are not mystical oracles. They are sequence processors.

Information placed:

- Early influences framing.
- Late influences detail.
- Repeated influences weighting.

If constraints appear after the data dump, expect creative interpretation.

A reliable pattern:

1. Role and objective
2. Constraints and output schema
3. Primary task
4. Supporting data

Yes, it feels rigid. So does type safety. It’s still useful.

---

### 3. Retrieval Is a First-Class Concern

In RAG systems, retrieval quality dominates outcome quality.

If your retriever returns:

| Scenario                        | Result                   |
|---------------------------------|--------------------------|
| Highly relevant, concise chunks | Focused, grounded output |
| Semi-related documents          | Confident hallucination  |
| Everything vaguely related      | Token overflow and vibes |

Practical guidelines:

- Keep chunks semantically coherent.
- Avoid overlong documents.
- Rank aggressively.
- Prefer precision over recall when stakes are high.

The model cannot ignore irrelevant context reliably. It will try to make sense of it. That is both admirable and
inconvenient.

---

### 4. Constrain the Output Shape

Free-form generation is entertaining but operationally fragile.

If the output feeds:

- A parser
- An automation workflow
- A database
- Another model

Define a schema.

Example:

~~~json
{
  "decision": "approve | reject",
  "risk_level": "low | medium | high",
  "rationale": "string"
}