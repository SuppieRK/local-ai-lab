# MCP

> As if we were short on three-letter acronyms.

## What is MCP?

Model Context Protocol (MCP) is, in practice, a structured JSON interface that exposes external capabilities to an LLM.
If you prefer the canonical phrasing, see the official [documentation][1].

Conceptually, the flow looks like this:

```text
User → Chat → LLM → MCP Client → MCP Server → External System
```

It's a thin integration layer. Not magic. Just REST API plumbing with better branding.

---

## When it is actually useful

MCP is worth caring about when you need one of these:

- a standard way to expose internal tools to multiple clients
- a remote capability that does not fit cleanly into your current runtime
- a shared interface for search, docs, databases, or internal APIs

Bad fit:

- adding a web-search server because the acronym sounded expensive
- wrapping one local script that your agent runtime can already call directly
- introducing another process boundary before you have a concrete integration problem

If your current tool setup is one shell command and a good attitude, MCP may be a future concern rather than a present one.

### Oh, I read about those – I need them!

Let's do a brief reality check — read [The State of MCP report][2] first.

Personally, I've had underwhelming results with free web-search MCP servers, so I won't recommend them. Traditional
search engines (and their built-in AI features) work fine.

If you're using OpenCode, the [WebFetch tool][3] can retrieve content directly from a URL. Yes, that may involve
copy-paste. It builds character.

### Should I care?

Not unless you have a concrete use case.

If you're curious which MCP servers exist, browse [awesome-mcp-servers][4].

If you decide you actually need one, add it directly to your OpenCode configuration per the [documentation][5].

In other words, treat MCP as a protocol option, not a rite of passage.

---

## Navigation

[⬅ Coding Agent](../04_coding_agent/README.md) | [🏠 Home](../README.md) | [Spec Driven Development ➡](../06_spec_driven_development/README.md)

[1]: https://modelcontextprotocol.io/docs/getting-started/intro

[2]: https://glama.ai/blog/2025-12-07-the-state-of-mcp-in-2025

[3]: https://opencode.ai/docs/tools/#webfetch

[4]: https://github.com/punkpeye/awesome-mcp-servers

[5]: https://opencode.ai/docs/mcp-servers
