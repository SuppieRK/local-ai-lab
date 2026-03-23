# Context

By now, you presumably have your own LLM stack running and occasionally doing what you asked. It may even complete tasks
with something approaching reliability. You have likely also performed the quiet, slightly sobering calculation of
whether hosting your own AI stack makes economic sense — or whether Claude, Codex, Copilot, or another coding agent is
simply billing you more efficiently.

> The best part – both OpenCode and OpenSpec support other coding agents as well. Vendor lock-in is overrated.

What's next?

## Tokens are everything

Tokens are the real currency. Not GPUs. Not model size. Not whatever the current hype cycle insists is indispensable.

Every architectural decision eventually reduces to tokens:

- How many do you send.
- How many do you receive.
- How often do you repeat yourself.
- How much accidental verbosity your prompts contain.
- How much "helpful reasoning" your model insists on emitting.

Context windows are finite. Budgets are finite. Patience is especially finite. If you optimize one thing, optimize token
flow. Everything else follows.

That gives us a practical order of operations: first control what enters the window, then make the instruction itself
precise, then decide how context and state are assembled for each step.

## What can we do?

### More efficient data retrieval

Context windows are limited, and model-side compression does not eliminate retrieval problems. Expecting an LLM to
remember everything is optimistic.

In practice, coding agents usually start with text search. If your stack exposes plain `grep`, switching to
[ripgrep][1] is an easy upgrade: it is faster and respects `.gitignore`, which reduces noise and token waste.

A further iteration is [ast-grep][2], which relies on [tree-sitter][3] to search via `Abstract Syntax Trees` (**ASTs**).
Instead of matching text, it matches structure — occasionally a useful distinction.

[Another approach][4], used by OpenCode, is to start the appropriate `Language Server Protocol` (**LSP**) servers for
your project and [expose selected LSP features as a tool][5] to the LLM. That gives the model access to definitions,
references, symbols, and diagnostics using the same language-aware analysis your editor already depends on.

`Retrieval Augmented Generation` (**RAG**) is popular for document-heavy workflows. A typical pipeline splits documents
into chunks, embeds them, stores vectors, retrieves a small candidate set with similarity search, and feeds the most
relevant fragments back into the model.

This is generally better than shoving the entire corpus into context and hoping for the best. It also introduces
chunking, the art of slicing documents precisely enough that embeddings behave as expected. Like most arts, it is easier
in theory.

### Less verbose tooling

Tools should return exactly what is required. No narrative. No commentary. No interpretive essays from your build
system.

If a tool emits five screens of output when three lines would suffice, the model will ingest all of it. You will be
billed for all of it. The model will reason about all of it.

[CCP][6] is a practical example of disciplined tooling. It acts as a CLI proxy that compacts noisy terminal output
before it reaches the LLM context, while preserving command behavior, exit codes, and critical diagnostics.

---

## Improving our stack

For a practical baseline, add `ripgrep` first and `CCP` second. Reach for `ast-grep`, LSP-backed tooling, or RAG only
when plain text search stops being good enough.

### ripgrep

We should have this tool because codebases contain plenty of material that still matters to the model but is not best
handled by language-aware tooling alone: docs, config, JSON, YAML, shell scripts, and the usual debris.

Thankfully, the [installation is straightforward][7].

If you are using OpenCode, by [default OpenCode will use ripgrep][8].

### CCP

CCP stands for `Command Compression Proxy`. You can run it directly as `ccp <command>` or use `ccp init` to wire it
into supported coding agents while keeping their usual command shape. It preserves exit codes and critical diagnostics,
falls back to native output for ambiguous or precision-sensitive cases, and gives you a way to measure the effect with
`ccp gain`.

This chapter is about context discipline at the budget level: keeping inputs small, relevant, and cheap enough to use
repeatedly. The next chapter moves one layer up and looks at the instruction itself.

---

## Navigation

[⬅ Spec Driven Development](../06_spec_driven_development/README.md) | [🏠 Home](../README.md) | [Prompt Engineering ➡](../08_prompt_engineering/README.md)

[1]: https://github.com/BurntSushi/ripgrep

[2]: https://ast-grep.github.io/

[3]: https://tree-sitter.github.io/tree-sitter/

[4]: https://opencode.ai/docs/lsp/

[5]: https://opencode.ai/docs/tools/#lsp-experimental

[6]: https://github.com/SuppieRK/ccp

[7]: https://github.com/BurntSushi/ripgrep?tab=readme-ov-file#installation

[8]: https://opencode.ai/docs/tools/#internals
