# Harness Engineering

> Building the environment around the model so long-running agents can do useful work without immediately wandering into a ditch.

Harness engineering is the practical work of designing the runtime, feedback loops, constraints, tools, and artifacts around a model so it can complete multi-step tasks reliably [1][2].

The model still matters. Quite a lot, in fact. But for long-running agentic applications, the model is only one component in the system. The harness is everything that turns raw capability into repeatable behavior.

Or, less poetically, it is the part that keeps your expensive stochastic intern from freehanding production architecture.

---

## What It Is

A harness is the operational wrapper around an agentic workflow. It usually includes:

- tool access and validation
- controller logic and stop conditions
- task decomposition
- state handoff between runs or sessions
- testing, evaluation, and retries
- observability, logs, traces, and metrics
- repository-local documentation and constraints

In other words, the harness is not the model prompt alone. It is the whole execution environment that makes prompts actionable.

A useful mental split:

| Part | Job |
|---|---|
| Model | Generate decisions, code, plans, or tool calls |
| Harness | Decide how work is structured, checked, bounded, and continued |
| Application runtime | Execute the actual software and expose signals back |

The model proposes. The harness verifies, routes, limits, and loops.

---

## Why It Matters

Short tasks can often survive on raw model ability plus a decent prompt. Long-running applications usually cannot.

As task duration increases, several things happen:

- context gets noisy or overloaded
- partial failures accumulate
- the model loses coherence or finishes early
- self-evaluation gets suspiciously generous
- hidden application state starts mattering more than chat history
- humans stop being able to manually babysit every step

This is where harness engineering becomes load-bearing.

Both OpenAI and Anthropic describe the same broad pattern from different angles: stronger outcomes came less from asking the model to try harder, and more from building better scaffolding around it [1][2]. That scaffolding included structured docs, runtime visibility, evaluation loops, task decomposition, and explicit boundaries.

If your agent works for thirty seconds, a prompt may be enough. If it works for four hours, you now own a system.

---

## Harness vs. Model

This distinction is easy to blur, so it is worth stating plainly.

The model is the reasoning engine. The harness is the control system.

The model can:

- suggest the next step
- write code
- call tools
- summarize state
- respond to evaluator feedback

The harness can:

- reset or compact context
- choose whether to continue or stop
- expose browser, logs, metrics, and repo docs
- reject invalid tool calls
- split work into phases or sprints
- run tests and evaluators
- preserve structured artifacts across sessions

A stronger model often lets you simplify the harness. It does not eliminate the need for one.

That is one of the more useful lessons from both articles: as models improve, some scaffolding stops being necessary, but the interesting harness work does not disappear. It moves outward to the next bottleneck [1][2].

---

## Practical Design Principles

### 1. Make the Environment Legible

Agents can only use what they can see and interpret.

That means exposing:

- repository docs as the system of record
- architecture maps and conventions
- runtime logs and metrics
- browser state for UI work
- explicit plans and progress artifacts

OpenAI describes this as increasing legibility for the agent, not just for humans [1]. If important knowledge lives in chat threads, meetings, or tribal memory, it may as well be stored in a cave.

Bad:

- Keep architecture decisions in Slack, product constraints in someone else's head, and runtime failures in a dashboard the agent cannot query.

Good:

- Put the important rules in the repo, expose the logs, and let the agent inspect the running system directly.

### 2. Keep State Structured

Long-running systems degrade when they carry too much raw transcript and too little durable state.

Prefer:

- explicit task files
- execution plans
- sprint contracts
- machine-readable progress markers
- compact summaries with next actions

Anthropic highlights structured handoff artifacts as critical for multi-session work, especially when context resets are needed [2]. A fresh session with a clean state document often performs better than one exhausted agent dragging an oversized conversation behind it.

Bad:

- Assume one increasingly tired session will remember what mattered three thousand tokens ago.

Good:

- Reset or compact when needed, and carry forward the actual state in a form the next run can use.

### 3. Separate Generation from Evaluation

Models are often poor judges of their own output, especially when the output is merely acceptable. They can become strangely proud of mediocre work. A very human trait, admittedly.

A better pattern is:

- one agent generates
- another evaluates
- the generator iterates against concrete feedback

This is especially useful for:

- UI quality
- product completeness
- bug finding
- acceptance testing
- code review-like checks

Anthropic found evaluator agents materially improved both design quality and application completeness, but only after tuning the evaluator to be skeptical rather than flattering [2].

Bad:

- Ask the same agent to build the feature and then grade its own work with complete objectivity.

Good:

- Use an external evaluator with explicit criteria and pass/fail thresholds.

### 4. Encode Rules Mechanically

If a rule matters, make it enforceable.

Examples:

- schema validation on tool calls
- architectural dependency checks
- file size limits
- structured logging requirements
- type or boundary validation
- hard iteration and timeout caps

OpenAI's article makes this point clearly: documentation helps, but invariants enforced by linters, CI, and structural tests do more to keep an agent-produced codebase coherent [1].

The dry operational truth is that agents respect whatever fails the build.

Bad:

- Write ~please keep the architecture clean~ in a long prompt and hope for the best.

Good:

- Add the rule to linting, tests, or the harness controller so violations are visible and expensive.

### 5. Decompose Only as Much as Needed

Task decomposition is useful, but it is not free.

Common patterns include:

- planner -> generator -> evaluator
- bounded phases with acceptance criteria
- context resets between phases
- one feature at a time
- final QA pass instead of per-phase QA

Anthropic's experience is instructive here: some decomposition patterns were essential for weaker or earlier model behavior, then became removable overhead as newer models improved [2].

So the right question is not, ~What is the most advanced harness we can imagine?~

It is, ~Which parts are still load-bearing for this model and this task?~

That is less cinematic, but it generally ships better.

---

## Common Failure Modes

### 1. Context Drift

The agent forgets what matters, latches onto stale details, or starts wrapping up too early.

Mitigations:

- structured handoff artifacts
- context resets where needed
- compact working state
- explicit next-step plans

### 2. Positive Self-Assessment

The agent implements half a feature, declares victory, and writes a very confident summary.

Mitigations:

- external evaluator
- executable acceptance criteria
- browser-driven QA
- threshold-based pass/fail checks

### 3. Tool and Workflow Thrashing

The system loops on similar actions without making progress.

Mitigations:

- step caps
- repeated-call detection
- cost and latency cutoffs
- stricter completion criteria

### 4. Architectural Drift

The agent copies bad local patterns at machine speed.

Mitigations:

- custom lint rules
- enforced layering
- recurring cleanup jobs
- repo-local principles and examples

### 5. Hidden Runtime Failures

The code looks plausible, but the actual application is broken in use.

Mitigations:

- drive the app directly
- inspect logs, metrics, and traces
- validate real user journeys
- test against running infrastructure, not just static code

---

## Concrete Examples

### Example 1: Browser App Builder

A team wants an agent to build a browser-based internal tool over several hours.

A minimal useful harness might include:

- planner that expands a short prompt into a spec
- generator that works one feature at a time
- evaluator that drives the app via browser automation
- logs and traces exposed to the agent
- step limits, retry policy, and final escalation

Without the harness, the model may produce a nice-looking demo that fails on click two.

With the harness, it can iteratively build, test, fail, inspect, fix, and continue.

### Example 2: Repository Maintenance Agent

A coding agent opens dependency upgrade PRs in a large monorepo.

Useful harness components:

- repository architecture docs
- ownership metadata
- lint and test pipelines
- strict tool schemas
- PR review agent
- recurring refactoring and cleanup jobs

The model writes changes. The harness keeps those changes from becoming archaeological layers of fresh nonsense.

---

## When Teams Actually Need It

Not every team needs a serious harness.

You probably do not need much harness engineering if:

- the task is single-step
- the workflow is deterministic
- a plain script or function call already works
- humans remain in the loop for every meaningful decision
- failure is cheap and immediately visible

You probably do need it if:

- agents work for many minutes or hours
- tasks span multiple tools and intermediate states
- the application must be validated while running
- context must survive handoffs or resets
- quality depends on iterative critique
- cost, latency, or safety need hard operational bounds

A good rule of thumb:

- if you are building a clever assistant, start simple
- if you are building an autonomous workflow, invest in the harness early
- if you are building an autonomous workflow that edits code, ships PRs, and tests live software, the harness is the product

The model is the engine. The harness is the vehicle. A very advanced engine on a shopping cart is still a shopping cart.

---

## A Practical Baseline

For most engineering teams, a sensible starting point is:

1. One capable model with structured tool use
2. A deterministic controller loop
3. Strict tool and input validation
4. Repository-local docs and architecture maps
5. Structured state artifacts instead of transcript-only memory
6. Hard caps on steps, time, and spend
7. Independent evaluation on meaningful outputs
8. Observability for prompts, tool calls, cost, latency, and failures
9. Human fallback for ambiguous or high-risk cases

Start there. Add complexity only when traces show a real gap.

Because traces are the difference between engineering and folklore.

---

## Closing

Harness engineering is the discipline of making agentic systems operationally real.

It matters because long-running applications fail less from lack of raw model intelligence than from lack of structure around that intelligence. The hard part is not only getting the model to act. It is getting the whole system to remain coherent, testable, bounded, and inspectable over time.

That sounds less magical than ~just let the model code.~ It is also how you end up with software instead of a demo and a troubling cloud bill [1][2].

---

## Navigation

[⬅ Agents](../12_agents/README.md) | [🏠 Home](../README.md)

[1]: https://openai.com/index/harness-engineering/

[2]: https://www.anthropic.com/engineering/harness-design-long-running-apps
