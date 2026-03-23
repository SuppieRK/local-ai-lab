# Skills

> Reusable, constrained capabilities that sit between one-off prompts and full agent loops.

A skill packages a narrow piece of model behavior so it can be reused with the same inputs, rules, and expected
outputs.

If a prompt says "do something like this," a skill says "do this bounded kind of task under these constraints."

Skills do not execute external actions. They shape how the model handles a specific class of work.

---

## What a Skill Contains

A practical skill usually includes:

- a name
- when to use it
- required inputs
- expected output shape
- rules and exclusions
- one or two canonical examples

Bad:

- "Refactor this however you think is best."

Good:

- "Refactor this method for readability. Do not change behavior, public signatures, or dependencies. Return the revised
  code and a short explanation."

Minimal sketch:

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

This converts "please clean this up" into a bounded transformation.

---

## Skills, Tools, and Agents

These are different layers:

- `prompt`: one instruction for one step
- `skill`: a reusable, constrained way to perform one class of step
- `tool`: an external action the runtime can execute
- `agent`: a controller that decides which step or tool comes next

Bad:

- Calling every structured behavior an agent.

Good:

- Use a skill to shape a repeatable transformation, a tool to fetch or change something outside the model, and an agent
  only when a bounded loop is actually needed.

If everything is an agent, the architecture diagram will be more exciting than the system deserves.

---

## When to Use Skills

Use skills when:

- behavior should be repeatable
- output should stay within a known shape
- domain rules matter
- the same transformation appears more than once

Bad fit:

- early prototyping
- genuinely open-ended exploration
- tasks where precision does not matter much

Not every prompt needs governance. Some just need a sentence and better luck.

---

## Design Rules

### 1. Keep the scope narrow

Bad:

- "Generate a full backend system."

Good:

- "Generate a DTO with validation annotations."

Small skills compose better and fail in smaller, more recognizable ways.

---

### 2. Make inputs and outputs explicit

Bad:

- "Take whatever you need and return something useful."

Good:

- "Require `code` as input and return `refactored_code` plus `explanation`."

Use required fields, enums, and explicit output structure where possible.

---

### 3. Write operational rules

Bad:

- "Be clean and efficient."

Good:

- "Do not introduce new libraries."
- "Preserve public interfaces."

Models respond better to constraints than aspirations.

---

### 4. Include canonical examples

Bad:

- Describe the desired style in three paragraphs and hope the model internalizes the mood.

Good:

- Include one or two examples that show the exact transformation you want.

Examples reduce drift better than extra adjectives.

---

### 5. Keep state outside the skill

Bad:

- A skill that only works if it silently remembers the previous five turns.

Good:

- A skill that takes the required state as input and behaves the same way every time.

If the skill depends on hidden memory, it is harder to reuse, test, and trust.

---

## Common Failure Modes

Bad:

- A system where every slightly different behavior becomes its own skill.

Good:

- A small set of well-bounded skills with clear inputs, outputs, and examples.

Typical problems:

- overfitting to examples
- schema mismatch
- skills that are too broad
- skills that are too granular
- hidden state leaking into behavior

There is a local maximum where the system works, you can reason about it, and nobody needs to mention a GPU cluster.
Aim for that one.

---

## Practical Workflow

1. Find a repeated prompt pattern.
2. Extract the task into a named capability.
3. Add input and output structure.
4. Add explicit rules.
5. Add one or two examples.
6. Test against saved cases.
7. Version it if it survives contact with production.

Do not rewrite the whole system around skills on day one. Replace unstable edges incrementally.

---

## Where Tools Enter

Skills make one step more reliable. Tools make external actions available. Agents combine both in a bounded loop.

That next layer is useful when one step is no longer enough.

---

## Navigation

[⬅ Context Engineering](../09_context_engineering/README.md) | [🏠 Home](../README.md) | [Tools ➡](../11_tools/README.md)
