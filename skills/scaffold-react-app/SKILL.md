---
name: scaffold-react-app
description: Scaffold a TypeScript + React frontend under /frontend with Vite, ESLint configured, and a sample page that hits the backend health endpoint. Use when the user says "add the React frontend", "scaffold the UI", "init the frontend", "add the web app", or invokes `/scaffold-react-app`.
---

This skill scaffolds the frontend under `/frontend`. Assumes the monorepo
skeleton already exists — run `scaffold-monorepo` first if `/frontend` is
missing.

Follows the language defaults in `home/CLAUDE.md`: **TypeScript 6, React
19**, ESLint required (frontend code must pass ESLint before a task is
declared done).

The sample page hits the backend `/health` endpoint, so the first
vertical slice (backend + frontend talking to each other) works
out-of-the-box — matches the "vertical slices over horizontal layers"
rule.

## Process

1. **Preflight:**
   - Verify `/frontend` exists and is empty.
   - Verify Node.js is at a current LTS (Node 22+ for Vite 6 / React 19).
   - Use `context7` MCP (`/reactjs/react.dev`, `/vitejs/vite`) to confirm
     current React 19 + Vite scaffolding idioms — APIs have changed
     recently, do not rely on memory.

2. **Generate the project:**

   ```bash
   cd frontend
   npm create vite@latest . -- --template react-ts
   npm install
   ```

3. **Pin versions** — edit `package.json` to use React 19 and
   TypeScript 6 (Vite's default may lag). Run `npm install` again to
   refresh `package-lock.json`.

4. **Replace the default page with a vertical-slice demo:**
   - `src/App.tsx` — one component that calls `fetch('/api/health')`
     on mount and displays the response. Loading / error / success
     states all handled.
   - Configure Vite dev-server proxy in `vite.config.ts` to forward
     `/api/*` to the backend (default `http://localhost:5000` for
     .NET; ask if a different port is configured).
   - Delete the default Vite logos and sample CSS.

5. **ESLint setup:**
   - Use Vite's default `eslint.config.js`, add `eslint-plugin-react`
     and `eslint-plugin-react-hooks` if not already present.
   - Add `"lint": "eslint ."` and `"lint:fix": "eslint . --fix"`
     scripts.
   - Run `npm run lint` and fix any violations before declaring done.

6. **Add `frontend/README.md`** — run locally (`npm run dev`), build
   (`npm run build`), lint (`npm run lint`).

7. **Sanity check:**
   - `npm run lint` → clean.
   - `npm run build` → succeeds.
   - `npm run dev` → page loads at `http://localhost:5173` and
     successfully fetches `/health` from the backend (if backend is
     also running).

8. **Commit on the current feature branch** with a message like
   `feat(frontend): scaffold React 19 + TS 6 app with health check
   demo`. Do not push or open a PR unless asked.

## Verification

- `npm run lint` is clean.
- `npm run build` produces a `dist/` folder with no errors.
- With the backend running, `npm run dev` shows the health-check
  result on the page (true end-to-end smoke test).
