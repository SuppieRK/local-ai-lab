# Agents

> When one prompt and one tool call stop being enough.

By this point, we have already separated a few concerns:

- prompts define what one step should do
- context decides what that step gets to see
- tools expose actions the runtime can execute

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

~~~python
while not done:
    decision = llm(state)
    result = execute(decision)
    state = update(state, result)
    done = should_stop(state)
~~~

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

[⬅ Tools](../11_tools/README.md) | [🏠 Home](../README.md)

[1]: https://arxiv.org/abs/2210.03629

[2]: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
