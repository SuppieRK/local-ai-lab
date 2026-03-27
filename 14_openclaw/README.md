# OpenClaw

> A personal assistant platform that takes ~message the agent~ more literally than most.

OpenClaw is an open-source, self-hosted personal assistant platform. You run a Gateway on your own machine or server,
connect the communication channels you already use, and let an agent operate through tools, browser control, device
nodes, automations, and a workspace that lives under your control [1][2][3].

That description is still too tidy.

What makes OpenClaw interesting is not just that it is "an agent with tools." Plenty of projects can say that with a
straight face. What makes it distinctive is the combination of:

- a single long-lived Gateway as control plane
- broad messaging-channel support
- optional device-local nodes
- multi-agent routing with isolated workspaces and sessions
- a practical workspace model built around files, skills, and tools
- a security model that is explicit about being powerful first and multi-tenant second [1][4][5][6]

In other words, OpenClaw is not trying to be a cleaner chat window. It is trying to be a usable assistant substrate.
That is a different ambition, and a messier one.

---

## What It Is

At a high level, OpenClaw sits between your models and the places where your life or work already happens.

Bad:

- A single browser tab where the assistant only exists while you are looking directly at it.

Good:

- A Gateway that stays up, receives messages from WhatsApp, Telegram, Slack, Discord, WebChat, and other channels, and
  routes them into one or more agent sessions with tools and local state [1][2][4].

The OpenClaw project describes the Gateway as the control plane and the assistant as the actual product [1]. That is a
useful distinction. The Gateway is not "the AI." It is the thing that keeps channels, sessions, tools, nodes, and
clients from turning into an ambitious pile of side effects.

---

## Why It Stands Out

There are other agent runtimes. There are other self-hosted assistants. OpenClaw is interesting because it combines a
few things that are often separate elsewhere.

### 1. It lives in existing channels

The assistant can answer in messaging surfaces you already use, instead of insisting that every interaction happen in
its own bespoke app [1].

That matters more than it sounds. A lot of assistant products fail at the exact moment they require you to remember that
they exist.

### 2. The Gateway is a real control plane

OpenClaw does not treat channels, sessions, and devices as disconnected hacks. The Gateway owns them as one long-lived
system exposed through a typed WebSocket API [3].

### 3. Devices are first-class nodes

macOS, iOS, Android, and headless nodes can pair with the Gateway and expose concrete capabilities such as camera,
screen recording, notifications, location, canvas functions, or local command execution [1][3].

### 4. It separates agents cleanly

An OpenClaw agent is not just a prompt preset. It has its own workspace, state directory, auth profiles, and session
store. Multi-agent support is routing plus isolation, not just vibes plus naming [4].

### 5. It is honest about security tradeoffs

The docs are unusually direct: OpenClaw is built around a personal-assistant trust model, not a hostile multi-tenant one
[6]. That does not make it safer by magic, but it does make the threat model less fictional.

---

## The Big Picture

The easiest way to understand OpenClaw is to see the shape of the system.

~~~mermaid
flowchart TD
    U[User] --> C[Channel or Client]

    subgraph Surfaces
        WA[WhatsApp]
        TG[Telegram]
        SL[Slack or Discord]
        WC[WebChat or Control UI]
        CLI[CLI]
        APP[macOS app]
    end

    C --> G[Gateway]
    WA --> G
    TG --> G
    SL --> G
    WC --> G
    CLI --> G
    APP --> G

    subgraph Gateway Runtime
        R[Routing and Sessions]
        A[Embedded Agent Runtime]
        T[Tools and Skills]
        E[Events and Presence]
    end

    G --> R
    R --> A
    A --> T
    G --> E

    subgraph External Capabilities
        B[Browser]
        N[Nodes]
        X[Exec or Files]
        H[Hooks or Cron]
    end

    T --> B
    T --> N
    T --> X
    T --> H
~~~

The general pattern is simple enough:

1. something sends a message or request into the Gateway
2. the Gateway decides which agent and session should receive it
3. the agent runs with its workspace, tools, and session state
4. tool calls go out through the runtime or paired nodes
5. results come back through the Gateway and are delivered to the original surface

That sounds almost reasonable when written as five bullets. Which is why the architecture section exists.

---

## How It Actually Works

### Gateway

The Gateway is the long-lived daemon and the center of the system [3]. It:

- maintains provider and channel connections
- exposes a typed WebSocket control plane
- validates frames against schemas
- emits events like agent, chat, presence, heartbeat, and cron
- serves web surfaces such as the Control UI and Canvas host on the same HTTP surface [1][3]

By default, it listens on ~127.0.0.1:18789~ [3]. That default is not accidental. OpenClaw is local-first in the most
literal sense: keep the powerful thing close unless you have a good reason not to.

### Clients

Clients such as the CLI, web UI, and macOS app connect to the Gateway over WebSocket [3]. They are not talking directly
to the model. They are talking to the control plane.

That matters because the Gateway can then do things a naked chat session cannot:

- preserve session continuity
- unify delivery across channels
- expose health and presence
- gate access through auth and pairing
- route one incoming message to the right agent

### Nodes

Nodes also connect over WebSocket, but they declare themselves as nodes with explicit capabilities [3]. A node is how
OpenClaw reaches outside the Gateway host into devices that can do something local.

Examples include:

- macOS node mode
- iOS node pairing
- Android node pairing
- headless nodes with specific capabilities [1][3]

This is one of the system's more distinctive features. Instead of pretending every tool belongs on one machine,
OpenClaw treats devices as remote capability providers.

### Agent Runtime

OpenClaw runs a single embedded agent runtime on top of the Pi agent core, while owning the surrounding layers itself:
session management, routing, tool wiring, and delivery [4].

That runtime uses a workspace directory as the default working directory and injects a set of bootstrap files into the
first turn of a new session [4]. These include:

- ~AGENTS.md~
- ~SOUL.md~
- ~TOOLS.md~
- ~BOOTSTRAP.md~
- ~IDENTITY.md~
- ~USER.md~

This is one of the more concrete parts of the design. OpenClaw does not rely purely on one global system prompt. It uses
workspace-local files as stable, user-editable context [4].

### Skills

Skills are loaded from three places, with workspace definitions winning on conflicts:

- bundled skills
- managed or local skills under the ~/.openclaw/skills directory
- workspace skills under ~<workspace>/skills~ [4]

That gives OpenClaw a layered capability model. There is a shared base, a local extension layer, and an agent-specific
layer where the real personality and behavior differences usually appear.

---

## Message Flow

The protocol-level flow is one of the cleaner parts of the system.

~~~mermaid
sequenceDiagram
    participant User
    participant Surface as Channel or Client
    participant Gateway
    participant Agent
    participant Tool as Tool or Node

    User->>Surface: Send message
    Surface->>Gateway: Inbound event or request
    Gateway->>Gateway: Match binding and session
    Gateway->>Agent: Start or continue run
    Agent->>Tool: Tool request
    Tool-->>Agent: Result
    Agent-->>Gateway: Final response or stream
    Gateway-->>Surface: Deliver reply
    Surface-->>User: Response
~~~

The important part is not that messages go in and answers come out. Every assistant demo has managed that much.

The important part is that OpenClaw keeps the intermediate machinery explicit:

- routing is explicit
- session selection is explicit
- tools and nodes are explicit
- delivery back to the originating surface is explicit

That explicitness is most of the engineering value.

---

## Multi-Agent Routing

OpenClaw's multi-agent support is one of the more practical parts of the design [5]. One agent means:

- its own workspace
- its own state directory
- its own auth profiles
- its own session store
- its own local skills [4][5]

This is worth dwelling on because many systems call something "multi-agent" when what they actually mean is "the same
agent with two hats and poor boundaries."

OpenClaw uses bindings to route inbound messages to an agent. Matching is deterministic and most-specific wins [5].
That can be based on:

- channel
- account
- direct peer
- group
- guild or team context

So you can route different channels or even different peers to different agents with separate workspaces and behavior.

~~~mermaid
flowchart LR
    M[Inbound message] --> B{Binding match}
    B -->|Peer match| A1[Agent A]
    B -->|Account match| A2[Agent B]
    B -->|Channel fallback| A3[Default agent]

    A1 --> W1[Workspace A]
    A2 --> W2[Workspace B]
    A3 --> W3[Workspace Main]
~~~

This gives OpenClaw a nice property: the agent boundary is operational, not merely cosmetic.

---

## Sessions and State

Session transcripts are stored as JSONL, and OpenClaw owns the session IDs and session model [4]. That alone is not
revolutionary, but the surrounding design is what matters.

OpenClaw distinguishes between:

- the workspace, which is durable local context and files
- the session store, which is transcript and routing state
- the agent directory, which holds per-agent auth and configuration [4][5]

That separation is part of why the system can support multiple agents and accounts without collapsing into one giant,
emotional directory.

It also supports steering while streaming, queued follow-up modes, and block streaming behaviors for different delivery
surfaces [4]. In other words, OpenClaw is not just doing completion calls and pretending they are a messaging runtime.

---

## Tools, Browser, and Canvas

OpenClaw exposes a broad tool surface, but the most interesting parts are how those capabilities are integrated rather
than their mere existence.

### Browser control

Browser control is a first-class capability, using an OpenClaw-managed Chrome or Chromium environment [1]. This is not
particularly novel on its own anymore, but it matters because the browser is integrated into the same Gateway, routing,
and delivery model.

### Canvas and A2UI

The Gateway also serves a Canvas host and an A2UI host on the same HTTP surface [1][3]. This gives the agent a visual,
interactive surface it can push updates to and control.

That is one of the stranger and more interesting parts of the system. OpenClaw is not only text-in, text-out. It can
drive an assistant experience that includes a live visual workspace.

### Nodes as tools

When a node is paired, the agent can call into device-local functions via node invocation. Depending on the platform,
that can include camera operations, screen recording, notifications, location, and on macOS even command execution if
the operator permits it [1][3][6].

That is powerful. It is also exactly why the docs spend so much time discussing trust boundaries.

---

## Security Model: The Good, the Bad, and the Honest

This is the part where nuance matters.

OpenClaw is not trying to be a secure multi-tenant platform for adversarial users sharing one Gateway. The docs say this
directly: it assumes a personal assistant trust model, meaning one trusted operator boundary per Gateway [6].

That leads to a few consequences.

### What this model gets right

- It is honest about the actual trust assumption.
- It defaults to loopback-first deployment.
- It uses pairing, allowlists, auth, and explicit node approval.
- It gives operators meaningful knobs around sandboxing, DM policy, and tool policy [1][5][6].

### What it does not claim to solve

- hostile co-tenancy
- one shared assistant for mutually untrusted users
- perfect protection against prompt injection
- magic separation between powerful tools and careless operators [6]

That honesty is part of what makes OpenClaw special. Many agent systems imply a cleaner security story than they have.
OpenClaw mostly does not.

Bad:

- Treat one shared, tool-enabled Gateway as a secure boundary between adversarial users.

Good:

- Treat one Gateway as one trust boundary, split gateways or hosts when trust boundaries diverge, and harden tools and
  sessions accordingly [6].

---

## A More Exact Architecture View

If you want a more mechanical picture, it looks roughly like this.

~~~mermaid
flowchart TB
    subgraph Gateway
        WS[Typed WebSocket API]
        RT[Routing and bindings]
        SS[Session store]
        AR[Embedded agent runtime]
        HTTP[HTTP surfaces: Control UI and Canvas]
    end

    subgraph Agent Scope
        W[Workspace]
        F[Injected files]
        S[Skills]
        P[Per-agent auth and config]
    end

    subgraph Remote Capability
        CH[Channels]
        ND[Nodes]
        BR[Browser]
        AU[Automation and cron]
    end

    CH --> WS
    WS --> RT
    RT --> SS
    RT --> AR
    AR --> W
    AR --> F
    AR --> S
    AR --> P
    AR --> ND
    AR --> BR
    AR --> AU
    HTTP --> WS
~~~

The key point is that OpenClaw is layered in a way that makes the control plane, runtime, and capability surfaces
distinct. That separation is what allows it to support a fairly chaotic set of channels and devices without becoming
immediately incomprehensible.

Immediately is doing some work there, but still.

---

## Where It Is Strongest

OpenClaw looks especially strong when you want:

- one personal assistant reachable through several channels
- local-first control over workspaces, credentials, and behavior
- device-local capabilities through paired nodes
- multiple isolated assistants behind one Gateway
- a system that treats files, skills, and routes as first-class operating pieces

It is less compelling if what you really want is:

- a simple coding agent in one terminal
- a neat SaaS abstraction with one trust boundary you do not manage
- a strongly isolated multi-user agent platform

OpenClaw is interesting precisely because it is trying to be more like a personal operating layer than a thin chat
product.

---

## Why This Chapter Exists

OpenClaw is worth studying even if you never deploy it.

It demonstrates a few ideas that matter beyond one project:

- the Gateway as control plane for agent systems
- routing and workspace isolation as first-class concepts
- device nodes as part of the tool surface
- repository files as durable injected context
- security language that admits where the real trust boundary is

That last one is refreshing. Agent systems usually become most dangerous when they are most vague about who is allowed to
make them do interesting things.

OpenClaw is still ambitious, sometimes sprawling, and very much willing to do real work on real machines. That is part
of the appeal and most of the risk.

Which, in fairness, is also true of many engineers.

---

## Navigation

[⬅ Harness Engineering](../13_harness_engineering/README.md) | [🏠 Home](../README.md)

[1]: https://raw.githubusercontent.com/openclaw/openclaw/main/README.md

[2]: https://raw.githubusercontent.com/openclaw/openclaw/main/VISION.md

[3]: https://docs.openclaw.ai/concepts/architecture

[4]: https://docs.openclaw.ai/concepts/agent

[5]: https://docs.openclaw.ai/concepts/multi-agent

[6]: https://docs.openclaw.ai/gateway/security
