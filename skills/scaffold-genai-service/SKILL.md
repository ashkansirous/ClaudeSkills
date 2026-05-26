---
name: scaffold-genai-service
description: Scaffold a GenAI/LLM service under /ai-services (e.g. news LLM processing) with the Anthropic SDK wired up and prompt caching enabled. Use when the user says "add the AI service", "scaffold the news LLM", "add a GenAI component", "init the AI service", or invokes `/scaffold-genai-service`.
---

This skill scaffolds a GenAI service that calls an LLM API (Claude by
default). Assumes the monorepo skeleton already exists.

The folder name under `/ai-services/` should describe the **purpose**,
not the model — e.g. `news-llm/`, `summarizer/`. This leaves room for
parallel services (`stock-ml/`, etc.) later.

**Always uses the `claude-api` skill's defaults** — prompt caching
enabled, latest Claude model, Anthropic SDK. Do not skip prompt
caching even for "simple" services; it's cheap insurance against future
cost growth.

## Process

1. **Preflight:**
   - Verify `/ai-services` exists.
   - Ask the user **once**: what's the purpose of this service?
     (Default: `news-llm`.) Use the answer as the folder name.
   - Ask **once**: Python (FastAPI) or C# for this service? Default
     Python — most AI tooling is Python-first. If the user picked C#
     to keep one backend language, that's fine.
   - Use `context7` MCP (`/anthropics/anthropic-sdk-python` or
     `/anthropics/anthropic-sdk-typescript` or `/anthropics/anthropic-sdk-dotnet`) to confirm current SDK API — Claude
     API features (caching, models, system prompts) change often.

2. **Invoke the `claude-api` skill** to handle the SDK setup. That
   skill knows the current best practices for prompt caching, model
   selection, and error handling. This skill orchestrates the file
   layout; `claude-api` fills in the Anthropic-specific code.

3. **Generate the service layout** (Python example; C# is analogous
   with ASP.NET Core minimal API):

   ```
   ai-services/news-llm/
     pyproject.toml         # or .csproj
     README.md
     .env.example           # ANTHROPIC_API_KEY=
     src/
       main.py              # FastAPI app, POST /process endpoint
       llm_client.py        # Anthropic client, prompt caching configured
       prompts.py           # system + user prompt templates
     tests/
       test_process.py      # mocks the Anthropic client
     Dockerfile
   ```

4. **The `/process` endpoint:**
   - Input: JSON `{ "articles": [{"title": "...", "body": "..."}] }`.
   - Calls Claude with a system prompt (cached) + the article batch
     (uncached) and returns the model output as JSON.
   - Returns 503 on Anthropic API errors with retry-after; the
     `claude-api` skill knows the right error-handling patterns.

5. **`.env.example`** lists every env var with comments. Do **not**
   create a real `.env` — `.gitignore` from `scaffold-monorepo`
   already excludes it.

6. **Add `ai-services/news-llm/README.md`** — run locally (`uvicorn
   src.main:app --reload` or `dotnet run`), test (`pytest` or
   `dotnet test`), build container, env-var checklist.

7. **Sanity check:**
   - Lint + test pass (`ruff check && pytest` or `dotnet test`).
   - With `ANTHROPIC_API_KEY` set, `curl -X POST /process` with a
     sample payload returns a valid LLM response.
   - The test that mocks the Anthropic client passes without an API
     key.

8. **Commit** with a message like `feat(ai-services): scaffold
   news-llm service with Anthropic SDK + prompt caching`.

## Verification

- The mocked test passes with **no `ANTHROPIC_API_KEY` in the env** —
  proves the test harness doesn't accidentally hit the real API.
- With a real key, the live endpoint returns a coherent LLM response
  for a sample news article.
- The Anthropic client config matches what the `claude-api` skill
  prescribes (prompt caching on, latest model).
