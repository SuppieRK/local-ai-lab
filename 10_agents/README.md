# LLM Agents

> Autonomous loops around large language models: surprisingly useful, occasionally theatrical, and very good at
> generating logs.

LLM agents are what happen when we decide a single prompt isn’t enough ceremony and wrap a language model in a control
loop. Instead of “ask once, get answer,” we get: think → act → observe → repeat. In other words, a distributed system,
but mostly inside a while-loop.

They are not magic. They are not sentient. They are an LLM plus scaffolding. The scaffolding is the interesting part.

---

## What Is an LLM Agent?

At minimum, an agent consists of:

1. **A model** (the reasoning engine).
2. **Tools** (APIs, databases, file systems, browsers).
3. **A loop** (stateful orchestration).
4. **Memory** (context beyond a single prompt).

Conceptually:

~~~python
while not done:
    plan = llm(state)
    action = select_tool(plan)
    result = action.execute()
    state = update(state, result)
~~~

If you squint, it resembles a very small operating system. If you squint harder, it resembles a very large prompt.

---

## Why Agents Exist

Plain prompting breaks down when tasks require:

- Multi-step reasoning
- External data retrieval
- Iterative refinement
- Tool invocation
- Persistent context

A single completion call is fine for summarization. It is less fine for “research competitors, extract pricing, update
CRM, draft email, schedule follow-up.” That workflow wants state and side effects.

Agents are the compromise between “just call the model” and “rewrite the company in Rust.”

---

## Core Architectural Patterns

### 1. ReAct (Reason + Act)

The model alternates between reasoning steps and tool calls.

**Strengths**

- Transparent chain of thought (sometimes).
- Simple control loop.

**Weaknesses**

- Can spiral into verbose overthinking.
- Token-heavy.

This pattern underpins many early frameworks like [1] and [2].

---

### 2. Planner + Executor

Split responsibilities:

| Component  | Responsibility            |
|------------|---------------------------|
| Planner    | High-level decomposition  |
| Executor   | Tool usage per step       |
| Controller | State + termination logic |

This reduces model thrashing and improves determinism. It also introduces more components, which engineers find
emotionally satisfying.

---

### 3. Tool-Calling / Function-Calling Agents

Modern models natively emit structured tool calls.

Example tool schema:

~~~json
{
  "name": "fetch_customer",
  "parameters": {
    "customer_id": "string"
  }
}
~~~

The model selects tools; the orchestrator executes them. This reduces prompt gymnastics and improves reliability.

It also moves complexity from prompt engineering to interface design—arguably a healthier failure mode.

---

## Memory: The Quiet Source of Chaos

Agents typically use:

- **Short-term memory**: conversation context
- **Long-term memory**: vector database retrieval
- **External state**: databases, documents, logs

The temptation is to store everything “just in case.” This produces:

- Rising token costs
- Retrieval noise
- Slower responses
- Subtle hallucinations reinforced by stale memory

Actionable guidance:

- Keep short-term memory bounded.
- Use retrieval filters aggressively.
- Prefer structured state over free-form summaries.
- Log everything. You will need it.

---

## Tooling and Frameworks

A non-exhaustive ecosystem:

- [1] LangChain
- [2] AutoGPT
- [3] OpenAI function calling
- [4] LlamaIndex

They provide orchestration primitives, memory abstractions, and tool adapters.

Practical perspective:

- Frameworks accelerate prototyping.
- They obscure control flow.
- You will eventually bypass abstractions.
- That’s fine.

Start with a framework. Migrate to a thin internal orchestration layer once requirements stabilize. Resist building a
universal “agent platform” on day two. It will not age well.

---

## Failure Modes

Agents fail in specific, predictable ways:

### 1. Tool Hallucination

Model invents tools or parameters.

Mitigation:

- Strict schema validation
- Hard rejection + retry logic

### 2. Infinite Loops

The agent keeps planning.

Mitigation:

- Max iteration caps
- Explicit termination checks
- Cost-based cutoffs

### 3. Over-decomposition

Simple task → 12-step plan.

Mitigation:

- Constrain planning depth
- Penalize unnecessary steps
- Add heuristics

### 4. Cost Explosion

Recursive reasoning + retrieval + verbose logs.

Mitigation:

- Token budgeting
- Summarization checkpoints
- Structured state instead of raw transcripts

---

## When to Use Agents

Use an agent if:

- The workflow requires multiple tool calls.
- The task is open-ended or exploratory.
- Human-in-the-loop review is acceptable.
- Latency of several seconds is tolerable.

Do not use an agent if:

- A deterministic workflow already exists.
- The task is CRUD with validation.
- You need strict reproducibility.
- A single function call solves it.

Agents are orchestration tools, not replacements for business logic.

---

## A Minimal Production-Ready Pattern

For most teams, a pragmatic design looks like:

1. **LLM with tool-calling**
2. **Strict JSON schema validation**
3. **Deterministic controller loop**
4. **Hard iteration limit**
5. **Structured execution logs**
6. **Fallback to human review**

No multi-agent swarm. No recursive meta-agents. No “self-healing cognitive substrate.” Just a loop with guardrails.

If someone suggests a GPU cluster for a support ticket router, ask for metrics first.

---

## Observability: Treat It Like a Service

Agents are opaque by default. Make them observable:

- Log every prompt and tool call.
- Track token usage per iteration.
- Record execution traces.
- Correlate outputs with cost.

Agents without observability are indistinguishable from random number generators with confidence.

---

## The Strategic View

LLM agents are not autonomous employees. They are probabilistic workflow engines.

Their value lies in:

- Handling messy inputs
- Bridging structured and unstructured systems
- Accelerating human decision loops

Their cost lies in:

- Non-determinism
- Operational complexity
- Token economics

The mature posture is neither dismissal nor hype. Treat agents as a new integration layer—useful, imperfect, and
expensive enough to warrant discipline.

---

## Navigation

- What Is an LLM Agent?
- Core Architectural Patterns
- Memory
- Tooling
- Failure Modes
- When to Use Agents
- Production Pattern
- Observability

---

## References

[1]: https://github.com/langchain-ai/langchain

[2]: https://github.com/Significant-Gravitas/AutoGPT

[3]: https://platform.openai.com/docs/guides/function-calling

[4]: https://github.com/run-llama/llama_index  