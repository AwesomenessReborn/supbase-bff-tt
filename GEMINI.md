# Gemini Project: Rush Backend (BFF)

## Project Overview

This is the **Backend-for-Frontend (BFF)** service for the **Rush App**, a cross-platform system for fraternity recruitment. It's a Node.js application built with Express.js and TypeScript. The backend serves as a unified API for a mobile app (React Native) and a web app (Next.js), mediating between the clients and a Supabase (PostgreSQL) database. Prisma is used as the ORM.

## Building and Running

### Prerequisites

- Node.js (>=20.0.0)
- pnpm (recommended)

### Installation

```bash
pnpm install
```

### Configuration

1.  Copy `.env.example` to `.env`.
2.  Populate the `.env` file with your Supabase and port values.

### Running in Development

```bash
pnpm dev
```

The server will start in development mode with auto-reloading.

### Building for Production

```bash
pnpm build
```

This command transpiles the TypeScript code to JavaScript in the `dist` directory.

### Running in Production

```bash
pnpm start
```

This command starts the server from the compiled code in the `dist` directory.

### Linting

```bash
pnpm lint
```

### Testing

The project is not yet configured with a test runner. The `package.json` suggests adding Jest or another test runner.

```bash
pnpm test
```

## Development Conventions

-   **Code Style:** The project uses ESLint and Prettier for code formatting and style checking.
-   **Project Structure:**
    -   `src/index.ts`: Express server bootstrap.
    -   `src/routes/`: HTTP endpoint definitions.
    -   `src/services/`: Business logic.
    -   `src/utils/`: Shared utilities (e.g., logger).
    -   `src/config/`: Environment variable loading and Supabase configuration.
    -   `prisma/schema.prisma`: Database schema definition.
-   **API:** The API is prefixed with `/api`. For example, the health check endpoint is at `/api/health`.
