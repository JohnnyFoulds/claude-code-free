# Model Selection Guide

This guide helps you choose an OpenRouter model for use with Claude Code. It covers rate limits, benchmark performance, privacy, and practical trade-offs.

---

## The core trade-off

Free models on OpenRouter are rate-limited. The default model (`stepfun/step-3.5-flash:free`) is chosen because it has the highest rate limit (50 requests/minute) and the strongest agentic coding performance among free options — not because it is the only viable choice.

Claude Code is an agentic tool. A single user request ("refactor this function") may trigger 5–20 API calls internally as the model reads files, writes code, runs tests, and iterates. At 8 requests/minute (the limit for most free models), that means hitting rate limits within seconds of sustained use. At 50 requests/minute, you get meaningful headroom.

---

## Free tier mechanics

### How the free tier works

Appending `:free` to a model ID routes to a provider that serves that model at zero cost. These are permanent free endpoints, not trials — but individual models can be deprecated when providers stop offering free capacity.

### Rate limits

| Model | Free req/min | Free context |
| --- | --- | --- |
| `stepfun/step-3.5-flash:free` | **50** | 256K |
| `qwen/qwen3-coder:free` | 8 | 262K |
| `meta-llama/llama-3.3-70b-instruct:free` | 8 | 65K ¹ |
| `openai/gpt-oss-120b:free` | undocumented | 131K |
| `openai/gpt-oss-20b:free` | undocumented | 131K |
| `nvidia/nemotron-3-super-120b-a12b:free` | undocumented | 262K |
| `google/gemma-3-27b-it:free` | undocumented | 131K |

¹ Context window is halved on the free variant (65K vs 131K on paid).

**Without a credit deposit:** very low daily cap — not suitable for regular use.
**With ~$10 credit deposit:** daily cap rises to approximately 1,000 free requests across all free models.

OpenRouter's own documentation describes free models as "generally not suitable for production use." For interactive coding sessions this is a real constraint.

### Privacy

The free tier routes to whichever provider offers free capacity. That provider's data policy applies to your prompts — which means your code.

| Model | Free provider | Data policy |
| --- | --- | --- |
| `stepfun/step-3.5-flash:free` | StepFun | Retains prompts; no training use |
| `qwen/qwen3-coder:free` | Venice | No retention; no training |
| `meta-llama/llama-3.3-70b-instruct:free` | Venice | No retention; no training |
| `openai/gpt-oss-120b:free` | OpenInference | **Retains prompts; used for training; may be published** |
| `openai/gpt-oss-20b:free` | OpenInference | **Retains prompts; used for training; may be published** |
| `nvidia/nemotron-3-super-120b-a12b:free` | NVIDIA | **All prompts logged for model improvement (trial use only)** |
| `google/gemma-3-27b-it:free` | Google AI Studio | **55-day retention; used for training** |

If you are working with proprietary code, avoid the gpt-oss, nemotron, and gemma free endpoints.

The paid variants of all models use privacy-respecting providers. OpenRouter also lets you add `"data_collection": "deny"` to requests to block prompt-retaining providers explicitly.

---

## Benchmark comparison

These benchmarks measure capabilities most relevant to Claude Code use:

- **SWE-bench Verified** — resolving real GitHub issues end-to-end (most relevant)
- **TerminalBench 2.0** — real terminal command execution (directly tests bash tool use)
- **LiveCodeBench** — competitive programming (contamination-resistant coding benchmark)
- **MMLU-Pro** — hard multi-step reasoning (better discriminator than standard MMLU)

| Model | SWE-bench | TerminalBench | LiveCodeBench | MMLU-Pro | Free? |
| --- | --- | --- | --- | --- | --- |
| Claude Sonnet 4.5 (reference) | 77% | ~52% | — | — | No |
| **step-3.5-flash** | **74%** | **51%** | **86%** | **84%** | **Yes** |
| nemotron-3-super-120b | 60% | 31% | 81% | 84% | Yes ² |
| qwen3-coder-480B | ~71% ³ | — | — | ~81% ³ | Yes |
| gpt-oss-120b | 62% | — | — | ~89% | Yes ⁴ |
| gpt-oss-20b | 61% | — | — | ~83% | Yes ⁴ |
| llama-3.3-70b | not evaluated | — | — | 69% | Yes |
| gemma-3-27b-it | not evaluated | — | 39% | ~68% | Yes ⁵ |

² Nemotron free tier logs all prompts — trial use only.
³ Based on related Qwen3-Coder-Next (80A3) model scores; 480B scores not published separately.
⁴ gpt-oss free tier trains on and may publish your code — use paid variant only for private code.
⁵ Gemma free tier does not support tool use — it cannot function as a Claude Code backend.

### What the benchmarks mean in practice

**SWE-bench Verified** is the closest thing to a real-world coding agent test. Claude Sonnet 4.5 at 77% and Step-3.5-Flash at 74% are within noise for many tasks. The gap widens for novel, complex, or multi-step problems.

**HumanEval** scores are not included here because they are saturated — almost all models score 87–88%, making them useless for choosing between models. If you see a model advertised on HumanEval alone, treat it with scepticism.

**Important caveat:** SWE-bench scores depend heavily on the agent scaffold (SWE-Agent, OpenHands, Claude Code's own harness). Claude's 77% is measured with Claude Code; free models' scores are measured with open scaffolds. The comparison is directionally valid but not exact.

---

## Model profiles

### stepfun/step-3.5-flash:free — Recommended default

196B MoE model (11B active per token). Released January 2026.

**Why it's the default:** Highest rate limit of any free model (50 RPM), strong agentic benchmarks (SWE-bench 74%, TerminalBench 51%), and privacy-safe free provider. The 11B active parameter count makes it fast and inference-efficient despite the 196B total size.

**Trade-offs:** Mandatory reasoning tokens (`<think>` blocks) add latency and token overhead. The thinking can be verbose for simple tasks.

**Paid pricing:** $0.10/$0.30 per million tokens (input/output) — very affordable if you exceed free limits.

---

### qwen/qwen3-coder:free — Best coding quality, stricter limits

480B MoE model (35B active per token). Released July 2025. Supports function calling and tool use.

**Why you might prefer it:** Strongest coding-focused model on the list. If you hit rate limits infrequently and want the best possible code output, this is the choice. Privacy-safe provider (Venice).

**Trade-offs:** 8 RPM limit means one request every 7.5 seconds — agentic tasks will hit this quickly. 262K context is large but the 480B model is slower than Step-3.5-Flash.

**Paid pricing:** $0.22/$1.00 per million tokens — the most expensive option here, but still a fraction of Claude API rates.

---

### openai/gpt-oss-120b:free and gpt-oss-20b:free — Pay for privacy

Open-weight MoE models from OpenAI. Released August 2025. SWE-bench 62% (120B) / 61% (20B).

**Free tier: avoid for private code.** The free provider (OpenInference) retains your prompts, uses them for training, and may publish them. Use the paid variants ($0.039/$0.19 and $0.03/$0.11 per million tokens) — gpt-oss-20b in particular offers excellent cost/performance.

**Unique feature:** Reasoning effort level (low/medium/high) lets you trade latency for quality on a per-request basis.

---

### nvidia/nemotron-3-super-120b-a12b:free — Trial use only

Hybrid architecture model (Mamba-2 + MoE). Released March 2026. Strong reasoning benchmarks (MMLU-Pro 84%, GPQA 83%).

**Free tier: trial use only.** NVIDIA explicitly labels this as trial-only and logs all prompts and outputs for model improvement. Do not use with private or proprietary code.

**Paid pricing:** $0.10/$0.50 per million tokens.

---

### meta-llama/llama-3.3-70b-instruct — Simple tasks, short context

Dense 70B model. Privacy-safe free provider (Venice). Good instruction following (IFEval 92%).

**Limitations:** Context window halved to 65K on free tier. No SWE-bench evaluation published. MMLU-Pro 69% vs 84% for Step-3.5-Flash indicates a real capability gap for complex reasoning. Best for straightforward single-step code tasks.

---

### google/gemma-3-27b-it:free — Not compatible with Claude Code

The free provider (Google AI Studio) does not support tool parameters or structured outputs. Since Claude Code relies on tool calls for file operations, bash execution, and code editing, this model **cannot function as a Claude Code backend on the free tier**.

The paid variant (DeepInfra, $0.08/$0.16 per million tokens) does support tool use, but LiveCodeBench performance (39%) is substantially weaker than alternatives at similar price.

---

## Choosing a model

**Start here:**

1. **Default (`step-3.5-flash:free`)** — works out of the box, best rate limits, strong performance. Change the model only if you have a specific reason.

2. **Want better code quality, willing to accept slower pace** → `qwen/qwen3-coder:free`. Expect to hit the 8 RPM limit during sustained agentic sessions.

3. **Working with private/proprietary code and want free** → `qwen/qwen3-coder:free` or `meta-llama/llama-3.3-70b-instruct:free` (both use Venice, no data retention). Avoid gpt-oss, nemotron, and gemma free tiers.

4. **Willing to pay a small amount for much better experience** → `openai/gpt-oss-20b` at $0.03/$0.11 per million tokens. A typical agentic session costs under $0.01. This removes rate limits and privacy concerns entirely.

5. **Want the closest thing to Claude for a fraction of the cost** → Add OpenRouter credits and use `qwen/qwen3-coder` (paid) at $0.22/$1.00 per million tokens, or try `openai/gpt-oss-120b` at $0.039/$0.19 per million tokens.

---

## Cost comparison

| Option | Typical session cost ¹ | Monthly (10 sessions/day) |
| --- | --- | --- |
| Free OpenRouter models | $0 | $0 (rate limited) |
| gpt-oss-20b paid | ~$0.005 | ~$1.50 |
| step-3.5-flash paid | ~$0.02 | ~$6 |
| qwen3-coder paid | ~$0.05 | ~$15 |
| Claude API (Sonnet 4.5) | ~$0.40 | ~$120 |
| Claude Pro subscription | flat $20/month | $20 |
| Claude Max 5x | flat $100/month | $100 |

¹ Estimated at 50K tokens per session (70% input, 30% output).

The Claude Pro subscription is better value than the API for regular daily use. The break-even point between API and Pro is roughly 50 sessions/month at typical usage.

---

## Known failure modes

**Rate limit errors (HTTP 429):** The most common issue. Switch to the paid variant of the same model or switch to step-3.5-flash (higher RPM). Adding a credit deposit raises daily caps.

**Tool call loops:** Documented in some Qwen3 Coder variants (particularly local/quantised deployments). The model repeatedly attempts the same edit or tool call with no change. If this occurs, start a new session.

**Context degradation:** All models degrade at long context. Practical limit is roughly 60–80K tokens before quality noticeably drops. Multi-day projects with long tool call histories can exhaust this.

**Structured output / tool use failures:** Some free providers do not support tool parameters (`gemma-3-27b-it:free` is the most notable). If you see errors about missing tool schemas, check whether the free provider supports tool use.

**Reasoning loops (step-3.5-flash via llama.cpp):** A known bug in llama.cpp (issue #19283) causes occasional infinite reasoning loops. This does not affect the OpenRouter hosted endpoint — only local llama.cpp deployments.

---

## Changing the model

Edit `~/.claude-code-free/.env`:

```env
OPENROUTER_MODEL=qwen/qwen3-coder:free
```

Then restart the container:

```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down
docker compose --env-file ~/.claude-code-free/.env -f ~/.claude-code-free/docker-compose.yml up -d
```

The full list of OpenRouter models is at [openrouter.ai/models](https://openrouter.ai/models). Any model with an OpenAI-compatible API should work — not just the ones listed here.

---

## Sources

All benchmark figures are from official model cards or peer-reviewed technical reports accessed in March 2026. Rate limit and pricing data is from OpenRouter model pages. Community observations are from HackerNews discussions. Full bibliography in the [internal research notes](../../research/openrouter-model-review/README.md).

Key sources:
- StepFun Step-3.5-Flash model card: huggingface.co/stepfun-ai/Step-3.5-Flash
- NVIDIA Nemotron-3-Super model card: huggingface.co/nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16
- GPT-OSS technical report: arxiv.org/abs/2508.10925
- Gemma 3 technical report: arxiv.org/abs/2503.19786
- Qwen3-Coder-Next technical report: arxiv.org/abs/2603.00729
- Meta Llama 3.3 model card: huggingface.co/meta-llama/Llama-3.3-70B-Instruct
- OpenRouter documentation: openrouter.ai/docs
