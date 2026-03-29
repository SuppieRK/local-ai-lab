# My personal notes on a home AI lab

> Practical notes on local models, coding agents, and the infrastructure around them, without pretending any of this needs a small datacenter.

## Introduction

You have probably seen those "simple home AI lab" or "build your own agent" guides featuring Mac clusters, Lenovo
ThinkStation PX boxes, or an RTX 6000 mentioned as casually as a USB stick.

As an engineer who enjoys learning, tinkering, and occasionally gaming, building a personal AI lab seemed like a
reasonable idea and a convenient argument that the GPU purchase was, in fact, career development.

The problem is the usual one: too much AI content, too much hype, and too many diagrams where every box is apparently a
platform.

This repository exists to document what actually worked for me, from the home lab itself to the workflow built on top of
it, without affiliate links, breathless futurism, or unnecessary abstractions.

## How to Read This Repo

The chapters start with setup and basic usage, then move into the workflow stack that sits on top of the model.

The conceptual ladder in the second half is:

`prompt -> context -> tool -> skill -> agent -> multi-agent -> harness -> OpenClaw`

That is the explanation flow. The reading order keeps a couple of practical chapters earlier because using the system a
bit before theorizing about it remains a sound engineering habit.

## Table of Contents

### Foundation

- [Beginning](./01_beginning/README.md)
- [Choosing LLM](./02_choosing_llm/README.md)
- [LLM Settings](./03_llm_settings/README.md)
- [Coding Agent](./04_coding_agent/README.md)
- [MCP](./05_mcp/README.md)
- [Spec Driven Development](./06_spec_driven_development/README.md)

### Workflow Layers

- [Prompt Engineering](./07_prompt_engineering/README.md)
- [Context](./08_context/README.md)
- [Context Engineering](./09_context_engineering/README.md)
- [Tools](./10_tools/README.md)
- [Skills](./11_skills/README.md)
- [Agents](./12_agents/README.md)

### Advanced Systems

- [Multi-Agent Workflow](./13_multiagent_workflow/README.md)
- [Harness Engineering](./14_harness_engineering/README.md)
- [OpenClaw](./15_openclaw/README.md)

## Goals

- Focus on practical aspects of a home AI lab and the local workflows around it.
- Prefer open-source software because vendor lock-in is unnecessary for a hobby.
- Preserve offline capability for flexibility and mild paranoia.
- Keep the writing straightforward and low on fluff.
- Include small Bash snippets where useful. Not a framework. Not a platform. Just scripts.

## Non-goals

- Exhaustive coverage of every possible configuration.
- Being the definitive guide to anything.
- Packaging everything into a one-click NPM abstraction that installs 400 dependencies and calls itself minimal.

> If it helps you, good. If not, fork it and make it better.
