# Skills

> Reusable, constrained capabilities that sit between one-off prompts and full agent loops.

A skill packages a narrow piece of model behavior so it can be reused with the same inputs, rules, and expected
outputs.

If a prompt says "do something like this," a skill says "do this bounded kind of task under these constraints."

Skills do not execute external actions. They shape how the model handles a specific class of work.

If prompts are one-off instructions and tools are external actions, skills sit in the useful middle: a repeatable way to
perform one bounded kind of task without immediately graduating to a controller loop.

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

```yaml
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
```

This converts "please clean this up" into a bounded transformation.

---

## Prompts, Tools, Skills, and Agents

These are different layers:

- `prompt`: one instruction for one step
- `context`: the information available to that step
- `tool`: an external action the runtime can execute
- `skill`: a reusable, constrained way to perform one class of step
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

## Worked Example: OpenSpec in OpenCode

The repository already contains a better example than an invented toy schema:

- `example-java-spring-project/.opencode/skills/openspec-new-change/SKILL.md`
- `example-java-spring-project/.opencode/skills/openspec-apply-change/SKILL.md`

Take the first one. Without a skill, the user interaction might look like this:

- "Start a new OpenSpec change for adding audit logging. Use the default workflow unless I say otherwise. Ask me if the name is unclear. Show me the first artifact template, then stop."

That works once. It also relies on the prompt being phrased correctly every time.

The skill version turns that into a reusable contract:

```yaml
name: openspec-new-change
description: Start a new OpenSpec change using the experimental artifact workflow.
```

From there, the skill file adds what the one-off prompt usually forgets under pressure:

- when to ask the user for clarification
- when to infer a kebab-case name
- which `openspec` command to run
- when to stop instead of continuing optimistically into the next step
- what the output summary should contain

That last point matters more than people like to admit. A good skill constrains both behavior and stopping.

The `openspec-apply-change` skill is the next escalation. It still is not an agent runtime by itself, but it defines a
repeatable implementation loop:

- select the active change
- inspect status and instructions
- read the context files
- implement the next task
- pause on ambiguity, blockers, or design drift

That is exactly the kind of work skills are good at: recurring, bounded, rule-heavy, and annoying to restate.

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

## Where Skills Sit in the Stack

Skills usually sit on top of prompts, context, and tools.

The common progression is:

1. Write a prompt that works once.
2. Give it the right context.
3. Add tools when the model needs to inspect or change something external.
4. Turn the repeated pattern into a skill.
5. Add an agent only when the next step depends on model judgment across multiple steps.

That next layer is useful when one step is no longer enough.

---

## Navigation

[⬅ Tools](../10_tools/README.md) | [🏠 Home](../README.md) | [Agents ➡](../12_agents/README.md)
