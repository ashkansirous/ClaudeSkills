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

## Fetch current docs and versions before running — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not** run
`npm create vite`, `npm install`, or write a single line of React/TS
code in this skill until you have logged context7 queries against:

- `/reactjs/react.dev` — current React major, component idioms, hook
  rules (especially `react-hooks/set-state-in-effect` and the rest of
  the v6 lint plugin).
- `/microsoft/TypeScript` — current TS major and tsconfig defaults.
- `/vitejs/vite` — current Vite scaffolding flags and dev-server
  proxy syntax.
- `/tailwindlabs/tailwindcss` — current major and config layout (v4's
  PostCSS plugin shape differs from v3; do not guess).

State the library IDs you're about to query before calling, so the
user sees the rule being followed. "I already know Vite / React 19 /
Tailwind v4" is not a valid reason to skip this — these are exactly
the libraries that have changed since training data, which is why the
rule names them.

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

4. **Replace the default page with a vertical-slice demo, structured
   so `App.tsx` stays a thin shell from day one:**
   - `src/App.tsx` — mounts providers (router stub, error boundary,
     query client if installed) and renders `<HealthPage />`. ~10–20
     lines, no business logic, no fetch calls.
   - `src/pages/HealthPage.tsx` — the page component that uses the
     hook below and renders loading / error / success states.
   - `src/hooks/useHealth.ts` — calls `fetch('/api/health')` with an
     abort signal, returns `{ status, data, error }`.
   - `src/api/client.ts` — a single place that owns the base URL and
     the fetch wrapper, so individual hooks don't hard-code paths.
   - Configure Vite dev-server proxy in `vite.config.ts` to forward
     `/api/*` to the backend (default `http://localhost:5000` for
     .NET; ask if a different port is configured).
   - Delete the default Vite logos and sample CSS.

   The first feature is small but the layering exists so the *next*
   feature has somewhere to live. `App.tsx` is intentionally boring —
   the rule is "if your first instinct is to add `useEffect` to
   `App.tsx`, make a page or hook instead."

5. **ESLint setup:**
   - Use Vite's default `eslint.config.js`; add `eslint-plugin-react`
     and `eslint-plugin-react-hooks` if not present.
   - Add `"lint": "eslint ."` and `"lint:fix": "eslint . --fix"`
     scripts.
   - Run `npm run lint` and fix violations — frontend code MUST pass
     ESLint per `home/CLAUDE.md`.

6. **Add `frontend/README.md`** — run locally (`npm run dev`), build
   (`npm run build`), lint (`npm run lint`).

7. **Dockerization: the frontend is a static artifact, not a
   container.** Per `home/CLAUDE.md` "Dockerization & build artifacts",
   do **not** write a production `Dockerfile` here. The build artifact
   is the static `dist/` bundle, deployed to static hosting (S3 +
   CloudFront / Cloud Storage + CDN) by the frontend CI workflow. For
   **local dev parity**, register a dev-only service in the root
   `docker-compose.yml` using a stock image — no Dockerfile:

   ```yaml
   frontend:
     image: node:lts-alpine     # major confirmed via context7
     working_dir: /app
     volumes:
       - ./frontend:/app
     command: sh -c "npm install && npm run dev -- --host"
     ports:
       - "5173:5173"
   ```

   Replace the `frontend` placeholder left by `scaffold-monorepo`. If
   the root `docker-compose.yml` doesn't exist yet, create it with
   just this service.

8. **Sanity check:**
   - `npm run lint` clean.
   - `npm run build` succeeds.
   - `npm run dev` loads the page at `http://localhost:5173` and
     fetches `/health` from the backend (true end-to-end smoke test
     when both are running).
   - `docker compose config` validates with the new `frontend` service.

9. **Commit on the current feature branch** with a message like
   `feat(frontend): scaffold React + TS app with health check demo`.
   Do not push or open a PR unless asked.

## Verification

- `npm run lint` clean.
- `npm run build` produces `dist/` without errors.
- With the backend running, the dev server shows the health-check
  result rendered on the page.
- No `frontend/Dockerfile` exists; the `frontend` service in the root
  compose uses a stock `node` image and boots via `docker compose up
  frontend`.
