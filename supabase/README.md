# Velvet Supabase backend

This directory contains the executable PostgreSQL/Supabase implementation derived from the Velvet Database Bible.

## Local workflow

```bash
supabase start
supabase db reset
supabase test db
```

## Migration principles

- migrations are append-only once merged;
- every table with user-facing data must have RLS enabled before merge;
- service-role-only tables live in restricted schemas such as `private`, `audit` or `billing`;
- raw identity, precise location and provider secrets must never be exposed through client schemas;
- schema changes must remain consistent with `docs/20-DATABASE/`;
- every sensitive mutation must be attributable to an authenticated account and auditable.

## Current implementation status

- Foundation extensions and restricted schemas
- Shared helper functions
- DB-01 account and private identity core

The remaining DB-01 profile governance tables, policies, tests and seeds are implemented in the next commits before moving to DB-02.
