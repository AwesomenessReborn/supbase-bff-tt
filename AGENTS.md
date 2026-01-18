# Repository Guidelines

## Project Structure & Module Organization
The Rush Backend-for-Frontend lives under `src/`, with `routes/` exposing HTTP endpoints, `services/` encapsulating business rules (attendance, votes, dues), `utils/` for shared helpers, and `config/` for Supabase, dotenv, and Prisma bindings. Prisma schemas stay in `prisma/`, while deployment assets (Dockerfiles, manifests) belong in `infra/` when introduced. Keep feature-specific modules co-located (e.g., `src/routes/votes`, `src/services/votes`). Store fixtures and contract mocks in `tests/fixtures` to keep production code clean.

## Build, Test, and Development Commands
- `pnpm install`: Respects the repo lockfile; run after pulling new dependencies.
- `pnpm dev`: Starts the Express server with ts-node-dev for hot reload; expects `.env` values for Supabase keys.
- `pnpm build`: Compiles TypeScript into `dist/`; bundling must succeed before releasing.
- `pnpm start`: Runs the compiled `dist/index.js`; mirrors production behavior.
- `pnpm test`: Executes unit/integration suites (Jest + Supertest once configured) and enforces TypeScript types. Use `pnpm test --watch` while iterating.
- `pnpm lint`: Runs ESLint + Prettier checks.

## Coding Style & Naming Conventions
Use TypeScript, ES2020 modules, and 2-space indentation. Favor `camelCase` for variables/functions, `PascalCase` for classes/types, and `SCREAMING_SNAKE_CASE` only for environment constants. Every new module should export a single entry point to reduce import churn (e.g., `src/services/attendance/index.ts`). Run `pnpm lint` or enable the editor ESLint plugin before committing. Document route handlers with concise JSDoc describing request/response DTOs.

## Testing Guidelines
Place Jest specs beside code using `*.spec.ts` naming (e.g., `routes/__tests__/attendance.spec.ts`) and integration tests under `tests/`. Mock Supabase via the provided fixtures to avoid hitting real instances. Maintain ≥80% statement coverage; add `pnpm test --coverage` to verify before opening a PR. Prefer behavior-driven descriptions (`describe('attendance submission')`).

## Commit & Pull Request Guidelines
Follow the existing short, imperative style (`git log` shows `first commit`, `gitignore`). Keep subject ≤50 characters and include a scope when helpful (`feat(votes): add ballot routes`). Reference issues in the body (`Closes #123`). Every PR should include: summary of changes, validation steps (`pnpm test`, `pnpm lint`), screenshots or curl examples for new endpoints, and links to Supabase migration IDs if applicable. Request review from at least one backend maintainer before merging.

## Environment & Security Notes
Never commit `.env` or Supabase service keys; use `.env.example` to illustrate required values. Rotate Supabase tokens after incidents and store secrets in the deployment platform (Vercel/Render). When adding third-party integrations, encapsulate credentials under `config/` and gate routes through the central auth middleware in `src/routes/index.ts`.
