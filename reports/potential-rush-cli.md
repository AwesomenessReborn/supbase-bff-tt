# Rush CLI - Potential Go Project

**Generated:** 2026-01-18

## Overview

A command-line tool for **administrative operations** and **bulk tasks** in the Rush App fraternity recruitment system. This would complement the mobile/web UIs similar to how AWS has both Console and AWS CLI, or GitHub has web UI + `gh` CLI.

## Concrete Use Cases

### 1. Rush Chair Administration

```bash
# Bulk import rush candidates from CSV
rush-cli candidates import --file candidates.csv --event-id fall-2026

# Generate rush schedule for the week
rush-cli schedule generate --start 2026-09-01 --end 2026-09-07

# Export attendance report
rush-cli reports attendance --event-id fall-2026 --format pdf

# Close voting for a candidate
rush-cli votes close --candidate-id abc123 --tally
```

### 2. Data Management

```bash
# Seed database with test data for development
rush-cli db seed --env development

# Backup candidate data before rush season
rush-cli backup create --include candidates,votes,feedback

# Anonymize data for analytics (GDPR-friendly)
rush-cli data anonymize --year 2025
```

### 3. Automated Workflows

```bash
# Send reminder notifications to members
rush-cli notify members --event "Brotherhood Dinner" --time "2 hours before"

# Generate post-rush analytics
rush-cli analytics generate --season fall-2026 --output ./reports

# Sync data between chapters (if multi-chapter)
rush-cli sync --from "alpha-chapter" --to "beta-chapter"
```

### 4. Developer/DevOps Tasks

```bash
# Validate database state
rush-cli validate db --check-constraints

# Run health checks on all services
rush-cli health check --services bff,supabase,mobile-api

# Generate TypeScript types from database schema
rush-cli codegen types --output ../mobile/src/types
```

## Why Go is Perfect for This

1. **Single Binary** - Distribute to rush chairs as a single executable (no "install Node.js first")
2. **Fast Execution** - Bulk operations (importing 500 candidates) are snappy
3. **Great CLI Libraries** - [Cobra](https://github.com/spf13/cobra) (used by kubectl, Docker, GitHub CLI) makes building CLIs elegant
4. **Cross-Platform** - Compile for macOS (your laptop), Linux (server cron jobs), Windows (chapter officers)
5. **Concurrent Operations** - Goroutines shine when processing batches (e.g., sending 200 notifications in parallel)

## Learning Benefits

Building this CLI would teach you:

- ✅ Real Go concurrency (process CSV rows in parallel)
- ✅ Interfacing with PostgreSQL (using `pgx` or `sqlc`)
- ✅ Building structured commands (Cobra framework)
- ✅ Cross-compilation and distribution
- ✅ Progress bars, spinners, colored output (TUI libraries)

These are Go's actual strengths, unlike a BFF which is primarily I/O-bound HTTP routing.

## Architecture Integration

```
┌─────────────┐
│  Mobile App │───┐
└─────────────┘   │
                  ├──► ┌─────────────┐      ┌──────────┐
┌─────────────┐   │    │   Node.js   │──────│ Supabase │
│  Web Admin  │───┼───►│  BFF (TS)   │      │   (PG)   │
└─────────────┘   │    └─────────────┘      └──────────┘
                  │           ▲                    ▲
┌─────────────┐   │           │                    │
│  rush-cli   │───┘           │                    │
└─────────────┘          (can call)           (direct access)
    (Go)                 for some ops         for bulk ops
```

The CLI could:
- Call the BFF API for operations that need business logic validation
- Connect directly to Supabase for bulk/admin operations
- Be standalone for local dev tasks (seeding, type generation)

## Example Code Structure

```go
// cmd/candidates.go
package cmd

import (
    "github.com/spf13/cobra"
)

var candidatesCmd = &cobra.Command{
    Use:   "candidates",
    Short: "Manage rush candidates",
}

var importCmd = &cobra.Command{
    Use:   "import",
    Short: "Import candidates from CSV",
    Run: func(cmd *cobra.Command, args []string) {
        file, _ := cmd.Flags().GetString("file")
        // 1. Parse CSV
        // 2. Validate data
        // 3. Use goroutines for parallel DB inserts
        // 4. Show progress bar
        // 5. Report results
    },
}

func init() {
    candidatesCmd.AddCommand(importCmd)
    importCmd.Flags().StringP("file", "f", "", "CSV file to import")
    importCmd.Flags().String("event-id", "", "Rush event ID")
}
```

## When to Build This

**Not immediately.** Build this after you:

1. Have a working database schema with real data
2. Identify manual admin pain points (bulk imports, reports, data cleanup)
3. Complete core features in mobile + web frontends
4. Have time to learn Go properly

This makes `rush-cli` a **practical project** that solves real problems while teaching you Go in a context where it excels.

## Recommended Tech Stack

- **CLI Framework:** [Cobra](https://github.com/spf13/cobra) + [Viper](https://github.com/spf13/viper) (config)
- **Database:** [pgx](https://github.com/jackc/pgx) (PostgreSQL driver) or [sqlc](https://sqlc.dev/) (type-safe queries)
- **Progress UI:** [bubbletea](https://github.com/charmbracelet/bubbletea) or [progressbar](https://github.com/schollz/progressbar)
- **CSV Processing:** Standard library `encoding/csv`
- **Testing:** Standard library `testing` + [testify](https://github.com/stretchr/testify)

## Alternative: Start Small

If you want to experiment with Go sooner, start with a single-purpose tool:

```bash
# Simple CSV validator
rush-validate candidates.csv --schema rush-candidate

# Database health checker
rush-healthcheck --db $DATABASE_URL

# Type generator
rush-codegen --schema prisma/schema.prisma --output types/
```

Build one tool, learn the basics, then expand into the full CLI when you have real use cases.
