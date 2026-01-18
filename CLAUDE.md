# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Backend-for-Frontend (BFF)** service for the **Rush App** — a cross-platform fraternity recruitment workflow system. It provides a unified API layer that mediates between:
- Mobile frontend (React Native + Expo) for members and candidates
- Web frontend (Next.js) for admins and rush chairs
- Supabase backend (auth + PostgreSQL database)
- Internal business logic (attendance, votes, dues, feedback)

## Technology Stack Decision

**Stack:** Node.js + TypeScript + Express.js

This project uses Node.js/TypeScript and will NOT be migrated to other languages (e.g., Go). This decision is intentional and based on architectural integration requirements:

### Key Integration Reasons
1. **Type Sharing** - TypeScript types are shared across the full stack (mobile React Native, web Next.js, and this BFF). Migrating to another language would break this type safety and require duplicate definitions or code generation.

2. **Supabase Integration** - Supabase provides first-class TypeScript support via `@supabase/supabase-js`. The Node.js ecosystem has mature auth, real-time, and RLS integration that would need to be rebuilt in other languages.

3. **BFF Pattern Fit** - BFFs are I/O-bound (HTTP aggregation, JSON transformation, session management). Node.js's event loop and middleware ecosystem excel at this pattern.

4. **Ecosystem Velocity** - Express.js has battle-tested middleware for auth, validation, rate limiting, and error handling. This enables faster feature development than rebuilding these patterns in other frameworks.

### Future Microservices
If performance-critical or CPU-intensive services are needed (analytics aggregation, bulk notifications, report generation), those should be built as **separate microservices** in appropriate languages (Go, Rust) that call into or are called by this BFF.

**See `reports/migration-analysis.md` for detailed reasoning and architectural tradeoffs.**

## Development Commands

### Essential Commands
- `pnpm install` - Install dependencies (respects lockfile)
- `pnpm dev` - Start development server with hot reload on port 4000
- `pnpm build` - Compile TypeScript to `dist/` directory
- `pnpm start` - Run compiled production build
- `pnpm lint` - Run ESLint + Prettier checks
- `pnpm test` - Run tests (currently placeholder, will use Jest + Supertest)

### Environment Setup
Copy `.env.example` to `.env` and populate:
- `PORT` - Server port (default: 4000)
- `NODE_ENV` - Environment mode (development/production)
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Public anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (never commit!)

## Architecture

**See `reports/architecture-vision.md` for full system architecture, integration patterns, and future microservices strategy.**

### Request Flow
1. Express app (`src/index.ts`) bootstraps with JSON middleware
2. All routes mount under `/api` prefix
3. Routes delegate to route registration functions (e.g., `registerHealthRoutes`)
4. Route handlers call service layer functions for business logic
5. Services interact with Supabase or other data sources

### Module Organization Pattern
The codebase follows a **feature-based co-location** pattern:

```
src/
├── routes/          # HTTP endpoint registration
│   ├── health.ts    # registerHealthRoutes()
│   └── index.ts     # Central router that imports all route modules
├── services/        # Business logic layer
│   └── health/      # Feature-specific service
│       └── index.ts
├── config/          # Environment and configuration
│   ├── env.ts       # appConfig with Supabase settings
│   └── index.ts
└── utils/           # Shared utilities
    └── logger.ts
```

**Key principle**: Keep related functionality together. When adding a new feature (e.g., "votes"), create:
- `src/routes/votes.ts` - Route registration function
- `src/services/votes/` - Business logic module
- Register routes in `src/routes/index.ts`

### Configuration System
- All config centralized in `src/config/env.ts` as `appConfig` object
- Dotenv loads from `.env` file
- Provides type-safe accessors with fallback defaults
- Supabase credentials available at `appConfig.supabase.*`

### TypeScript Module System
- Uses ES modules (`"type": "module"` in package.json)
- All imports must include `.js` extension (TypeScript convention for ES modules)
- Example: `import routes from './routes/index.js'`
- Compiles to NodeNext module resolution

## Code Style

### Naming Conventions
- **camelCase**: variables, functions (`getHealthStatus`, `appConfig`)
- **PascalCase**: classes, types, interfaces (`Router`, `RequestHandler`)
- **SCREAMING_SNAKE_CASE**: environment constants only
- **Route registration pattern**: Use `register{Feature}Routes(router: Router)` pattern

### File Structure
- Use 2-space indentation
- One feature per module with single entry point (`index.ts`)
- Place tests beside code using `*.spec.ts` naming
- Integration tests go in `tests/` directory

### Documentation
- Add concise JSDoc for route handlers describing request/response DTOs
- Document non-obvious business logic
- Avoid comments for self-evident code

## Testing Strategy

### When Tests Are Added
- Use Jest + Supertest framework
- Mock Supabase via fixtures in `tests/fixtures/`
- Place unit tests in `__tests__/` subdirectories or as `*.spec.ts` files
- Maintain ≥80% statement coverage
- Use behavior-driven descriptions: `describe('attendance submission')`
- Run tests with `pnpm test --watch` while developing
- Verify coverage with `pnpm test --coverage`

## Database & Prisma

### Current State
- Prisma schema exists at `prisma/schema.prisma` (currently placeholder)
- SQL migrations stored in `sql/migrations/` directory
- Database: PostgreSQL via Supabase

### When Adding Database Features
- Extend Prisma schema to map Supabase tables
- Create migrations in `sql/migrations/` with sequential numbering
- Reference migration IDs in PR descriptions
- Use Prisma Client for type-safe database access

## Security & Environment

### Critical Rules
- Never commit `.env` files or Supabase service keys
- Store secrets in deployment platform (Vercel/Render)
- Rotate Supabase tokens after security incidents
- Encapsulate third-party credentials under `config/`

### Authentication
- Central auth middleware will be added to `src/routes/index.ts`
- All protected routes should use this middleware
- Service role key used for server-side operations only

## Commit Conventions

Follow existing short, imperative style:
- Keep subject ≤50 characters
- Use format: `feat(scope): description` or simple imperative
- Examples: `feat(votes): add ballot routes`, `fix: handle null timestamps`
- Reference issues in body: `Closes #123`

## Pull Request Requirements

Every PR should include:
1. Summary of changes
2. Validation steps (`pnpm test`, `pnpm lint` passing)
3. curl examples or screenshots for new endpoints
4. Supabase migration IDs if applicable
5. Request review from backend maintainer

## Adding New Features

### Checklist for New Endpoints
1. Create service module: `src/services/{feature}/index.ts`
2. Create route registration: `src/routes/{feature}.ts`
3. Import and register in `src/routes/index.ts`
4. Add tests in `src/routes/__tests__/{feature}.spec.ts`
5. Document request/response DTOs with JSDoc
6. Update Prisma schema if database changes needed
7. Run `pnpm lint` and `pnpm test` before committing

### Example Route Pattern
```typescript
// src/routes/votes.ts
import { Router } from 'express';
import { submitBallot } from '../services/votes/index.js';

export const registerVotesRoutes = (router: Router): void => {
  router.post('/votes/ballot', async (req, res) => {
    const result = await submitBallot(req.body);
    res.json(result);
  });
};

// src/routes/index.ts
import { registerVotesRoutes } from './votes.js';
registerVotesRoutes(router);
```
