# LLM Agent Skills

> Teaching large language models to do one thing well, instead of everything poorly.

LLM agents are impressive right up until you ask them to do something specific, repeatable, and non-trivial. Then they
enthusiastically improvise.

“Skills” attempt to fix that.

Systems like OpenCode skills from :contentReference[oaicite:0]{index=0} package structured capabilities into reusable,
declarative units. Instead of hoping a model infers your workflow from vibes, you define it explicitly. The model still
reasons — it just does so within guardrails that resemble engineering rather than astrology.

---

## What Is an LLM Skill?

A skill is a constrained, composable capability that an agent can invoke deterministically.

Think of it as:

- A typed interface around model behavior
- A structured prompt with contract-level guarantees
- A reusable execution workflow
- A way to prevent “creative reinterpretation” of instructions

If raw prompting is scripting, skills are APIs.

The shift is subtle but material:  
You move from “generate something like this” to “execute this defined capability.”

---

## Why Skills Exist

LLM agents without structure tend to:

- Over-generalize
- Lose state
- Drift from objectives
- Hallucinate glue code
- Invent abstractions that nobody asked for

Skills address this by:

- Narrowing scope
- Encoding input/output schemas
- Defining tool usage rules
- Externalizing memory boundaries

This is less magical, but more deployable.

---

## Anatomy of a Skill

A typical skill definition includes:

| Component       | Purpose                        |
|-----------------|--------------------------------|
| Name            | Unique capability identifier   |
| Description     | Natural language intent        |
| Input Schema    | Strict argument contract       |
| Output Schema   | Typed response expectation     |
| Execution Rules | Constraints, tools, guardrails |
| Examples        | Canonical usage patterns       |

At runtime, the agent selects a skill based on context and executes it under defined constraints.

If that sounds like function calling, that’s because it is — just formalized and reusable.

---

## Minimal Example

Below is a simplified conceptual skill definition:

~~~yaml
name: refactor_method
description: Refactor a Java method for readability and maintainability
input_schema:
  type: object
  properties:
    code:
      type: string
output_schema:
  type: object
  properties:
    refactored_code:
      type: string
    explanation:
      type: string
rules:
  - Do not change behavior
  - Preserve public signatures
  - Avoid introducing new dependencies
~~~

This converts “please clean this up” into a bounded transformation.

No hype cycle required.

---

## How Skills Differ From Prompt Templates

| Prompt Template    | Skill              |
|--------------------|--------------------|
| Free-form          | Schema-constrained |
| Single-use         | Reusable           |
| Implicit structure | Explicit contracts |
| Hard to validate   | Machine-verifiable |
| Easy to drift      | Guarded execution  |

Prompt templates scale poorly because they depend on human discipline. Skills scale because they depend on interfaces.

Engineers tend to prefer the latter.

---

## Skills vs. Tools vs. Agents

Clarifying terminology helps prevent architectural improv.

- **Tool**: External capability (API, database, CLI)
- **Skill**: Structured reasoning workflow
- **Agent**: Orchestrator that selects skills and tools

If everything is an “agent,” nothing is.  
Skills introduce middle-layer composability.

This reduces the temptation to build a 14-layer agent framework to send a POST request.

---

## When to Use Skills

Use skills when:

- Behavior must be repeatable
- Output must conform to a schema
- Domain logic matters
- You need composability
- You want deterministic-ish orchestration

Avoid skills when:

- You’re prototyping ideas
- The task is genuinely open-ended
- Precision is unnecessary
- You’re still exploring problem boundaries

Not every prompt needs governance.

---

## Skill Design Guidelines

### 1. Narrow Scope Aggressively

Small skills compose better.

“Generate full backend system” is not a skill.  
“Generate DTO with validation annotations” is.

---

### 2. Enforce Input Contracts

Define strict schemas.  
Loose inputs produce loose outputs.

Use:

- Required fields
- Enumerations
- Explicit constraints

Ambiguity is the enemy of reproducibility.

---

### 3. Make Rules Operational

Bad rule:

- “Be clean and efficient”

Good rule:

- “Do not introduce new third-party libraries”
- “Maintain time complexity”

LLMs respond better to constraints than aspirations.

---

### 4. Provide Canonical Examples

Examples anchor behavior.

Without examples, the model interpolates.  
Interpolation is creative. Creativity is not always helpful.

---

### 5. Keep Skills Stateless

State management belongs to orchestration layers.

Embedding implicit memory into a skill:

- Reduces portability
- Breaks composability
- Encourages accidental complexity

State is where agent systems go to become research projects.

---

## Operational Benefits

Skills introduce engineering leverage:

- Versioning
- Testing
- Observability
- Reuse
- Governance

You can:

- Unit test skill outputs
- Track invocation metrics
- Roll back skill versions
- Benchmark behavior changes

This is how LLM systems move from demo to production.

---

## Failure Modes

Even skill-based systems can degrade.

Common issues:

- Overfitting to examples
- Schema mismatch
- Excessive skill granularity
- Skill explosion (every tiny behavior becomes a skill)
- Orchestrator confusion

There is a local maximum where:

- The system works
- You can reason about it
- You don’t need a GPU cluster to justify its existence

Aim for that point.

---

## Integration Workflow

A practical rollout pattern:

1. Identify repeated prompt patterns.
2. Convert them into structured skill definitions.
3. Add schemas and rules.
4. Validate against regression cases.
5. Instrument usage.
6. Version explicitly.
7. Refactor orchestration gradually.

Do not rewrite your entire system around “agents.”  
Replace unstable edges incrementally.

---

## Relationship to Broader Ecosystem

Skills complement:

- Function calling interfaces [1]
- Tool invocation APIs [2]
- Retrieval pipelines [3]

They are not a replacement for reasoning models.  
They are a containment strategy.

The goal is not to make the model smarter.  
It is to make its behavior narrower.

---

## Practical Takeaways

- Treat skills like APIs, not prompts.
- Constrain aggressively.
- Keep them small and composable.
- Test them.
- Version them.
- Resist the urge to abstract prematurely.

LLM agents are capable.  
They are not disciplined.

Skills add discipline.

And in software, discipline scales better than optimism.

---

## References

[1] Function calling interfaces in modern LLM APIs  
[2] Structured tool invocation patterns  
[3] Retrieval-augmented generation architectures

---

## Navigation

- Next: Designing Agent Orchestrators
- Previous: Structured Prompt Engineering
- Index: LLM Systems Architecture Guide  