# Agents

> When one prompt and one tool call stop being enough.

By this point, we have already separated a few concerns:

- prompts define what one step should do
- context decides what that step gets to see
- tools expose actions the runtime can execute
- skills make recurring classes of steps behave consistently

Agents add the next layer: a controller that decides which step or tool happens next.

That sounds grander than it is. In most production systems, an agent is just a bounded loop around a model, some tools,
some state, and a stop condition.

---

## What Agents Add

Skills shape behavior. Tools expose actions. Agents decide which step or tool comes next, what state to carry forward,
and when to stop.

Bad:

- One prompt that tries to research, compare options, call tools, validate the result, and decide whether it should try
  again.

Good:

- A controller loop that asks the model for the next step, executes one bounded action, updates state, and checks
  whether the task is done.

Minimal sketch:

```python
while not done:
    decision = llm(state)
    result = execute(decision)
    state = update(state, result)
    done = should_stop(state)
```

The loop is the feature. The problems usually come free with it.

---

## When to Use One

Use an agent if the task needs:

- multiple tool calls
- branching based on intermediate results
- bounded iteration
- state carried across steps
- human review at the end or on failure

Bad fit:

- a deterministic CRUD workflow with validation rules
- a single lookup or transformation
- a job where strict reproducibility matters more than flexibility

If a plain function call or explicit workflow already solves the problem, keep the plain function call or explicit
workflow. Business logic does not become better because a language model touched it.

---

## A Minimal Safe Pattern

For most teams, the practical baseline looks like this:

1. A model with structured tool calling [2]
2. A deterministic controller loop
3. Strict argument validation
4. Structured state instead of raw transcripts
5. Hard step limits and stop conditions
6. Human fallback when confidence or safety drops

Bad:

- A "self-improving" swarm with no step cap, no validation, and no clear owner for failure.

Good:

- One controller, a small tool set, explicit schemas, a maximum iteration count, and a boring escalation path.

This is less cinematic than a multi-agent society. It is also easier to operate.

---

## A Concrete OpenCode Loop

Suppose you want an agent to apply one OpenSpec task in a small codebase.

At that point, a skill alone is often not enough because the system has to inspect state, make progress, react to
results, and stop cleanly.

A compact working state might look like this:

```json
{
  "goal": "Implement the next task for change add-audit-logging",
  "change": "add-audit-logging",
  "step": 0,
  "max_steps": 8,
  "completed_tasks": [],
  "current_file": null,
  "status": "running"
}
```

One bounded loop could be:

1. Ask `openspec` for the current change status.
2. Read the context files for the next pending task.
3. Inspect the relevant source files.
4. Make the code change.
5. Run the relevant test or check.
6. Mark the task complete only if the result passes.
7. Stop if the change is blocked, complete, unclear, or over the step cap.

That is an agent because the next action depends on intermediate results.

Bad:

- One giant prompt that says "implement the next task, fix anything broken, keep going until done, and tell me if you got confused."

Good:

- One controller loop with explicit state, explicit stop conditions, and a small tool set.

Typical stop conditions are boring on purpose:

- all tasks complete
- a test failed and needs human judgment
- the task description is ambiguous
- the step cap or cost budget was reached

Boring stop conditions are underrated. They are also how the system eventually stops.

---

## Common Failure Modes

### 1. Tool Hallucination

The model invents a tool, a parameter, or both.

Mitigation:

- strict schema validation
- hard rejection on invalid calls
- retries only when the failure is recoverable

### 2. Looping

The agent keeps planning because nothing told it to stop clearly enough.

Mitigation:

- hard iteration caps
- explicit success and failure states
- cost or latency cutoffs

### 3. Bad State

The loop keeps carrying stale or noisy information forward.

Mitigation:

- keep working state compact
- prefer structured state over free-form summaries
- drop or summarize irrelevant history aggressively

### 4. Cost Explosion

Recursive reasoning, retrieval, and verbose logs are all charming until the invoice arrives.

Mitigation:

- token budgets per task
- summarized checkpoints
- smaller tool sets
- bounded retrieval

---

## Pattern Variants

### 1. ReAct

ReAct interleaves reasoning and actions in one loop [1].

Good for:

- exploratory tasks
- search-heavy tasks
- cases where intermediate actions need to influence the next step

Risk:

- too many steps
- too many tokens
- too much confidence in mediocre plans

### 2. Planner + Executor

One component plans. Another executes. The controller decides whether to continue.

Good for:

- longer tasks where decomposition helps
- systems that need clearer separation between planning and execution

Risk:

- extra moving parts
- more state to keep consistent

### 3. Multi-Agent Systems

Sometimes useful. Usually early.

Good for:

- narrow cases where separate specialists genuinely reduce complexity

Risk:

- orchestration overhead
- duplicated context
- debugging as a lifestyle

Start with one bounded agent. Earn the second one.

---

## Observability

If an agent matters, instrument it like a service.

Track at minimum:

- prompts per step
- tool calls and failures
- token usage
- latency per iteration
- final outcome versus cost

Bad:

- "The agent looked confused."

Good:

- "It exceeded the step cap after three invalid tool calls and consumed 18k tokens."

Without traces, you are debugging folklore.

For the example above, a useful trace is not literary:

```text
step=1 tool=openspec.status result=ready
step=2 tool=read_context_files result=4 files
step=3 tool=edit_code result=src/main/java/.../AuditService.java
step=4 tool=run_tests result=1 failed
step=5 status=paused reason=test_failure
```

That is enough to tell you what happened without pretending the agent had a rich inner life.

---

## Where Multi-Agent and Harness Enter

Once one bounded loop is doing useful work, there are two common reasons to add more structure.

Use a multi-agent workflow when you want separate bounded roles, such as implementation plus review, or parallel
exploration plus synthesis.

Use harness engineering when the surrounding system becomes load-bearing: state handoff, retries, evaluators,
observability, browser checks, repo-local docs, and operational limits.

The next two chapters follow exactly that path.

---

## Practical Posture

Agents are not autonomous employees. They are probabilistic control loops.

Useful for:

- messy inputs
- multi-step workflows
- bridging structured and unstructured systems

Expensive in:

- non-determinism
- operations
- tokens

The mature posture is neither hype nor contempt. Treat agents as an integration layer with real leverage and real failure
costs.

---

## Navigation

[⬅ Skills](../11_skills/README.md) | [🏠 Home](../README.md) | [Multi-Agent Workflow ➡](../13_multiagent_workflow/README.md)

[1]: https://arxiv.org/abs/2210.03629

[2]: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
