# Beginning

> Assumes Git, Python, and npm are installed. If not, install them.

## Landscape

Below is a simplified map of the current LLM ecosystem. It is incomplete by design. The landscape evolves weekly and
occasionally reintroduces the same concept under different branding.

A linearized stack, bottom to top:

1. **Hardware (CPU / GPU / RAM)**  
   Hosts LLMs. VRAM is usually the limiting factor.

2. **LLM Runner (Ollama | LM Studio | vLLM | etc.)**  
   Loads LLM weights, manages inference, exposes an API or CLI.

3. **LLM (Model Weights)**  
   The neural network itself. It predicts tokens. It does not "understand" anything; it approximates probability
   distribution over the next token.

4. **Tools / Skills / MCP**  
   Structured function calls, external APIs, databases, file systems.  
   This is how the model interacts with external systems instead of fabricating a plausible version of them.

5. **Agents**  
   Control loops around the LLM: `plan → call tool → observe → repeat`.  
   Mostly orchestration logic, occasionally wrapped in a framework and a manifesto.

6. **Applications (Chat UIs, Services, Integrations)**  
   The visible layer. Packages everything above into something deployable.

---

## Hardware

This is the primary constraint. It determines what runs locally and how long you will wait for it.

For AI workloads, the variables that matter are:

- System **RAM**
- **CPU** cores and clock speed
- **GPU** model and, more importantly, **VRAM**

Everything else is secondary. Based on your hardware, you will compensate with smaller models, KV quantization, or
patience.

My reference setup (a baseline for trade-offs, not a lifestyle statement):

| What | Capacity                       |
|------|--------------------------------|
| OS   | Windows 11 Pro (WSL2)          |
| RAM  | **32 GB** DDR5 6000MHz         |
| CPU  | **8-core, 16-thread**, 4.7 GHz |
| GPU  | **16 GB** GDDR7 VRAM           |
| SSD  | 1 TB NVMe                      |

---

## LLM Runner

You do not need a distributed microservice architecture to run a 7B model locally. You need:

- A compatible runner
- Enough RAM/VRAM
- Realistic expectations

Choose and install based on your goals - bear in mind that upcoming files will be for LM Studio only:

| Tool           | Recommended | Note                                                                                           |
|----------------|-------------|------------------------------------------------------------------------------------------------|
| [Ollama][1]    | 🔴          | Straightforward local model management with minimal ceremony; has issues with LLM using tools  |
| [LM Studio][2] | 🟢          | GUI-first; useful for experimentation; good enough for home lab                                |
| [vLLM][3]      | 🔴          | Optimized serving; relevant when throughput or scale actually matters; overkill for a home lab |

All three move numbers through silicon. The differences are ergonomics, performance characteristics, and how much
infrastructure you want to explain later.

Start simple. You can always optimize for tokens per second or introduce an agent framework once you feel insufficiently
abstracted.

---

## Navigation

[🏠 Home](../README.md) | [Choosing LLM ➡](../02_choosing_llm/README.md)

[1]: https://ollama.com/

[2]: https://lmstudio.ai/

[3]: https://vllm.ai/