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

## What can we do?

### More efficient data retrieval

Context windows are limited, even with compression tricks and quantization. Expecting an LLM to remember everything is
optimistic.

By default, the LLM will leverage `grep` to locate relevant information in your codebase. You can modestly improve this
with [ripgrep][1], which is faster and respects `.gitignore`, reducing noise and token waste.

A further iteration is [ast-grep][2], which relies on [tree-sitter][3] to search via `Abstract Syntax Trees` (**ASTs**).
Instead of matching text, it matches structure — occasionally a useful distinction.

[Another approach][4], used by OpenCode, launches the appropriate `Language Server Protocol` (**LSP**) servers for your
project and [exposes LSP features as a tool][5] to the LLM. Under the hood, this also leverages **ASTs**, but with
broader language support and richer semantics. It is essentially what your IDE already knows.

`Retrieval Augmented Generation` (**RAG**) is popular for documents. It works reasonably well for similarity search:
split documents into chunks, embed them, store vectors, retrieve top-K matches via cosine similarity, and feed the "most
relevant" fragments back into the model.

This is generally better than shoving the entire corpus into context and hoping for the best. It also introduces
chunking, the art of slicing documents precisely enough that embeddings behave as expected. Like most arts, it is easier
in theory.

### Less verbose tooling

Tools should return exactly what is required. No narrative. No commentary. No interpretive essays from your build
system.

If a tool emits five screens of output when three lines would suffice, the model will ingest all of it. You will be
billed for all of it. The model will reason about all of it.

[Rust Token Killer][6] is a practical example of disciplined tooling. It filters and compresses command output before it
reaches the LLM context, reducing token consumption by 60–90% on common operations.

---

## Improving our stack

### ripgrep

We have to have this tool since codebases will contain files that should be read fast and not represent the code (YAML,
Markdown, JSON, etc.).

Thankfully, the [installation is straightforward][7].

If you are using OpenCode, by [default OpenCode will use ripgrep][8].

### Rust Token Killer

In progress

---

## Navigation

[⬅ Spec Driven Development](../06_spec_driven_development/README.md) | [🏠 Home](../README.md)

[1]: https://github.com/BurntSushi/ripgrep

[2]: https://ast-grep.github.io/

[3]: https://tree-sitter.github.io/tree-sitter/

[4]: https://opencode.ai/docs/lsp/

[5]: https://opencode.ai/docs/tools/#lsp-experimental

[6]: https://github.com/rtk-ai/rtk

[7]: https://github.com/BurntSushi/ripgrep?tab=readme-ov-file#installation

[8]: https://opencode.ai/docs/tools/#internals