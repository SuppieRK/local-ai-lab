# Tools

> Callable external actions the model can request, but the runtime must execute.

A tool is a contract between the model and the runtime.

The model can ask for `search_docs`, `get_weather`, or `run_sql`. It does not perform those actions itself. The runtime
decides whether the request is valid, safe, authorized, and worth executing.

---

## What a Tool Is

A practical tool definition includes:

- a name
- a plain description of what it does
- a strict argument schema
- a defined result shape

Bad:

- Let the model emit vaguely structured arguments and hope downstream code interprets them correctly.

Good:

- Give the model one clearly named tool with a strict schema, validate the request, then return a structured result.

Minimal loop:

~~~text
User -> Model -> Tool request -> Runtime validates and executes -> Tool result -> Model -> Final answer
~~~

Example:

~~~json
{
  "name": "get_weather",
  "description": "Fetch current weather by city",
  "parameters": {
    "type": "object",
    "properties": {
      "city": {
        "type": "string"
      }
    },
    "required": ["city"]
  }
}
~~~

Modern APIs from OpenAI and Anthropic support structured tool calls [1][2].

---

## Tools vs. Skills

A skill constrains how the model performs a task.

A tool exposes something outside the model: an API, database, search index, shell command, or internal service.

Bad:

- Treat a tool as a bundle of reasoning, planning, and side effects.

Good:

- Keep the tool contract narrow. Let the runtime execute it. Let prompts, skills, or agents decide when to ask for it.

Tools are actions, not orchestration.

---

## Common Execution Patterns

### 1. Single-step tool use

Bad:

- Build a planning loop for a single deterministic lookup.

Good:

- Call one tool, return the result, stop.

Best for:

- lookups
- deterministic queries
- stateless operations

If one call solves the problem, stop celebrating and take the win.

---

### 2. Repeated tool use inside a loop

Bad:

- Let the model keep calling tools until it feels spiritually complete.

Good:

- Bound the loop, log the calls, and stop when the task has a defined completion state.

Useful for:

- multi-hop retrieval
- exploratory workflows
- tasks where one tool result affects the next step

Loops belong to the runtime or agent layer, not to the tool definition itself.

---

### 3. Tool chaining

Bad:

- Allow arbitrary chains with no step cap, no timeout, and no visibility.

Good:

- Enforce max steps, timeouts, and repeated-call detection.

If the system calls the same tool four times with nearly identical arguments, it is probably not discovering anything
new.

---

## Runtime Responsibilities

Tool calls are untrusted input from a probabilistic system.

At minimum, the runtime should handle:

- schema validation
- authorization
- timeouts
- logging
- rate limits
- step limits when calls happen in a loop

Bad:

- Pass raw model arguments directly into shell commands, SQL, or privileged internal APIs.

Good:

- Validate, authorize, constrain, and log everything before execution.

The model is probabilistic. Your infrastructure should not be.

---

## Cost and Observability

Tools do not remove operational cost. They move it around.

Track at minimum:

- tool call frequency
- argument distributions
- failure rates
- token usage per task
- latency per step

Bad:

- "It seems slower when the model uses tools."

Good:

- "This workflow averages 4 tool calls, 11 seconds, and 9k tokens, with a 7% validation failure rate."

Without instrumentation, you are debugging vibes again.

---

## Where Agents Enter

One tool call does not require an agent.

Agents become useful when the system must choose which step or tool comes next across multiple steps, carry state
forward, and decide when to stop.

Bad:

- Use an agent for a fixed workflow with known steps and rule-based branching.

Good:

- Use ordinary application code for fixed workflows, and add an agent only when the next step genuinely depends on model
  judgment.

If the workflow is fixed, ordinary code is usually the better controller.

---

## Navigation

[⬅ Skills](../10_skills/README.md) | [🏠 Home](../README.md) | [Agents ➡](../12_agents/README.md)

[1]: https://platform.openai.com/docs/guides/function-calling

[2]: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
