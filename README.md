# Rush Backend (BFF)

## Overview

This is the **Backend-for-Frontend (BFF)** service powering the **Rush App** — a cross-platform system for fraternity recruitment workflows.

It serves two frontends:

1. **Mobile (React Native + Expo)** — used by members and candidates.
2. **Web (Next.js)** — used by admins and rush chairs.

The backend provides a unified API that mediates between:

- Supabase (auth + database)
- Internal logic (attendance, votes, dues, feedback, etc.)
- Third-party integrations (if added later)

## Tech Stack

- **Language:** TypeScript (Node.js)
- **Framework:** Express.js
- **Database:** Supabase (PostgreSQL)
- **ORM:** Prisma (optional)
- **Environment:** dotenv for secrets
- **Package Manager:** pnpm (recommended) or npm

## Project Structure

```txt
rush-backend/
│
├── src/
│   ├── index.ts            # Express bootstrap
│   ├── routes/             # HTTP endpoints
│   ├── services/           # business logic helpers
│   ├── utils/              # shared helpers (logger, etc.)
│   └── config/             # env loaders, supabase bindings
│
├── prisma/
│   └── schema.prisma       # Supabase/Prisma mapping
│
├── tests/
│   └── fixtures/           # contract + mock data
│
├── sql/
│   └── migrations/         # contract + mock data
│
├── .env.example            # document required env vars
├── .gitignore
├── package.json
├── tsconfig.json
├── pnpm-lock.yaml
└── README.md
```

## Goals

- Provide unified, secure API for Rush app and any other future applications.
- Simplify Supabase queries via backend routes.
- Standardize auth, roles, and validation logic.
- Prepare for both Expo (mobile) and Next.js (web) clients.

## Getting Started

1. Install dependencies (uses pnpm by default): `pnpm install`
2. Copy `.env.example` to `.env` and populate Supabase + port values.
3. Run the dev server: `pnpm dev`
4. Build for production: `pnpm build && pnpm start`

The API exposes a `GET /api/health` route that clients and monitors can use to confirm the service is running. Add additional routes under `src/routes/*` and corresponding business logic under `src/services/*` following the module co-location guideline in `AGENTS.md`.
