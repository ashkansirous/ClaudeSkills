---
name: scaffold-genai-service
description: Scaffold a GenAI/LLM service under /ai-services/<name>/ with the Anthropic SDK wired up and prompt caching enabled. Folder name reflects purpose (e.g. news-llm, summarizer), not model. Run when adding a fresh AI service to the monorepo. Triggers: "add the AI service", "scaffold the news LLM", "add a GenAI component", "init the AI service", or invocation as `/scaffold-genai-service`.
---

This skill scaffolds a GenAI service that calls an LLM API (Claude by
default). Assumes the monorepo skeleton already exists.

Folder name under `/ai-services/` should describe the **purpose**, not
the model — e.g. `news-llm/`, `summarizer/`. This leaves room for
parallel services (`stock-ml/`, etc.) later.

## When to use this skill

Invoke this skill **only**:

- After `scaffold-monorepo` has run, so `/ai-services/` exists.
- When adding a new AI service that calls an LLM (news processor,
  summarizer, classifier, etc.).

Do **not** invoke this skill:

- For non-LLM ML work (training stock-price models, computer vision,
  etc.) — those need a different skill once you decide on the approach.
- To modify an existing AI service — edit the files directly.

## Fetch current docs and versions before running — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not**
scaffold any AI-service code until you have logged context7 queries
against:

- `/anthropics/anthropic-sdk-python`, `/anthropics/anthropic-sdk-typescript`, or `/anthropics/anthropic-sdk-dotnet` — depending on the language chosen.
- `/anthropics/anthropic-cookbook` — for prompt caching and tool-use
  patterns currently recommended.

State the library IDs you're about to query before calling, so the
user sees the rule being followed. Claude API features change often
— prompt-caching parameters, tool-use schemas, and model IDs in
particular. Confirm the **latest stable Claude model ID** via
context7 before hard-coding one. Do not rely on training-data
knowledge of model names; the wrong model ID is a silent
mis-deployment.

## Process

1. **Preflight:**
   - Verify `/ai-services/` exists.
   - Ask the user **once**: what is the service's purpose? (Default:
     `news-llm`.) Use the answer as the folder name.
   - Ask **once**: Python (FastAPI) or C# for this service? Default
     Python — most AI tooling is Python-first. If the user prefers C#
     to keep one backend language, that's fine.

2. **Delegate Anthropic-specific code to the `claude-api` skill.** That
   skill knows the current best practices for prompt caching, model
   selection, error handling, and SDK setup. This skill orchestrates
   the file layout; `claude-api` fills in the LLM-specific code.

3. **Generate the service layout** (Python example; C# is analogous
   with ASP.NET Core minimal API):

   ```
   ai-services/<name>/
     pyproject.toml         # or .csproj
     README.md
     .env.example           # ANTHROPIC_API_KEY=
     src/
       main.py              # FastAPI app, POST /process endpoint
       llm_client.py        # Anthropic client, prompt caching enabled
       prompts.py           # system + user prompt templates
     tests/
       test_process.py      # mocks the Anthropic client
     Dockerfile
   ```

   Pin language toolchain versions only loosely — use the language's
   current LTS, confirmed via context7
   (`/python/cpython` for Python, etc.). Do not pin major versions
   inside this skill file.

4. **The `/process` endpoint:**
   - Input: JSON `{ "articles": [{"title": "...", "body": "..."}] }`.
   - Calls Claude with a cached system prompt + the article batch
     (uncached) and returns the model output as JSON.
   - Returns 503 with retry-after on Anthropic API errors. Use the
     error-handling pattern from the `claude-api` skill.

5. **`.env.example`** lists every env var with comments. Do not create
   a real `.env` — `.gitignore` from `scaffold-monorepo` already
   excludes it.

6. **Add `ai-services/<name>/README.md`** — run locally, test, build
   container, env-var checklist.

7. **Sanity check:**
   - Lint + test pass.
   - With `ANTHROPIC_API_KEY` set, `curl -X POST /process` returns a
     valid LLM response.
   - The mocked test passes **without** a real API key.

8. **Commit** with a message like `feat(ai-services): scaffold <name>
   service with Anthropic SDK + prompt caching`.

## Verification

- The mocked test passes with no `ANTHROPIC_API_KEY` in the env —
  proves the test harness doesn't accidentally hit the real API.
- With a real key, the live endpoint returns a coherent LLM response
  for a sample article.
- The Anthropic client matches what the `claude-api` skill currently
  prescribes (prompt caching on, latest model from context7).
