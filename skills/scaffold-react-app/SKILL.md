---
name: scaffold-react-app
description: Scaffold a fresh TypeScript + React frontend under /frontend (latest stable TS and React, via Vite) with ESLint and a sample page that hits the backend /health endpoint. Run when /frontend exists and is empty. Triggers: "add the React frontend", "scaffold the UI", "init the frontend", "add the web app", or invocation as `/scaffold-react-app`.
---

This skill scaffolds the frontend under `/frontend`. Assumes the monorepo
skeleton already exists — run `scaffold-monorepo` first if `/frontend` is
missing.

The sample page hits the backend `/health` endpoint so the first vertical
slice (backend + frontend talking) works out-of-the-box — matches the
"vertical slices over horizontal layers" rule in `home/CLAUDE.md`.

## When to use this skill

Invoke this skill **only**:

- After `scaffold-monorepo` has run, so `/frontend` exists and is empty.
- When the user wants a fresh TS + React frontend (the default in
  `home/CLAUDE.md`).

Do **not** invoke this skill:

- If `/frontend` already has a `package.json` — modify by hand.
- For non-React frontends (Svelte, Vue, plain JS, etc.) — those would
  need their own skill.

## Fetch current docs and versions before running

Use the **context7 MCP** at the start of every invocation:

- `/reactjs/react.dev` — confirm current React major and component
  idioms.
- `/microsoft/TypeScript` — confirm current TypeScript major.
- `/vitejs/vite` — confirm current Vite scaffolding flags.

Do not pin specific React/TypeScript/Vite versions in this skill. Use
whatever context7 reports as the current stable major at invocation
time.

## Process

1. **Preflight:**
   - Verify `/frontend` exists and is empty.
   - Verify Node.js meets the current Vite / React requirements (check
     via context7 — the minimum LTS shifts).

2. **Generate the project:**

   ```bash
   cd frontend
   npm create vite@latest . -- --template react-ts
   npm install
   ```

3. **Upgrade React + TypeScript to current stable.** Vite's default
   template often lags. Edit `package.json` to use the current major
   for `react`, `react-dom`, and `typescript` (versions confirmed via
   context7). Run `npm install` again.

4. **Replace the default page with a vertical-slice demo:**
   - `src/App.tsx` — one component that calls `fetch('/api/health')`
     on mount and displays the response (loading / error / success
     states all handled).
   - Configure Vite dev-server proxy in `vite.config.ts` to forward
     `/api/*` to the backend (default `http://localhost:5000` for
     .NET; ask if a different port is configured).
   - Delete the default Vite logos and sample CSS.

5. **ESLint setup:**
   - Use Vite's default `eslint.config.js`; add `eslint-plugin-react`
     and `eslint-plugin-react-hooks` if not present.
   - Add `"lint": "eslint ."` and `"lint:fix": "eslint . --fix"`
     scripts.
   - Run `npm run lint` and fix violations — frontend code MUST pass
     ESLint per `home/CLAUDE.md`.

6. **Add `frontend/README.md`** — run locally (`npm run dev`), build
   (`npm run build`), lint (`npm run lint`).

7. **Sanity check:**
   - `npm run lint` clean.
   - `npm run build` succeeds.
   - `npm run dev` loads the page at `http://localhost:5173` and
     fetches `/health` from the backend (true end-to-end smoke test
     when both are running).

8. **Commit on the current feature branch** with a message like
   `feat(frontend): scaffold React + TS app with health check demo`.
   Do not push or open a PR unless asked.

## Verification

- `npm run lint` clean.
- `npm run build` produces `dist/` without errors.
- With the backend running, the dev server shows the health-check
  result rendered on the page.
