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

### Foundation

- PostgreSQL extensions and restricted schemas
- Shared account, request and timestamp helpers
- Supabase local configuration

### DB-01 — complete implementation scope

- Accounts, private identities and settings
- Individual, couple, organizer and professional profiles
- Profile memberships, invitations and role permissions
- Identity-verification case storage
- Shared-profile sensitive-action approvals
- Dual-consent enforcement for couple profiles
- Atomic execution of approved lifecycle decisions
- Profile activation, hiding, archiving and logical deletion
- Voluntary member departure and governed member removal
- Ownership transfer
- Immutable lifecycle audit events
- Approval expiry and cancellation
- RLS and pgTAP schema/security tests

## Validation gate before DB-02

The DB-01 implementation is considered ready for the next chapter after the following commands pass in a local or CI Supabase environment:

```bash
supabase db reset
supabase test db
```

No migration in this directory should be edited after merge; corrections must be delivered as a new append-only migration.