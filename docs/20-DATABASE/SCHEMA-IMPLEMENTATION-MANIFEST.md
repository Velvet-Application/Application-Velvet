# Velvet Database Schema Implementation Manifest

**Status:** Ready for Codex execution  
**Source of truth:** DB-00 and DB-01 to DB-10  
**Target:** PostgreSQL / Supabase with PostGIS  
**Rule:** No application feature may bypass the domain services, RLS policies or audit rules defined by the Database Bible.

---

## 1. Objective

This manifest converts the Database Bible into an ordered implementation plan for migrations, generated types, policies, jobs and tests.

The schema must be delivered as small, reversible, reviewable migrations. Each migration must include its own integrity checks and must leave the database in a deployable state.

---

## 2. Required repository structure

```text
supabase/
├── migrations/
├── seed/
├── tests/
│   ├── schema/
│   ├── rls/
│   ├── privacy/
│   └── workflows/
└── functions/

docs/20-DATABASE/
└── generated/
    ├── schema-catalog.md
    ├── enum-registry.md
    ├── rls-matrix.md
    ├── retention-matrix.md
    └── data-classification-matrix.md
```

Generated documentation must be reproducible from the implemented schema and checked in CI for drift.

---

## 3. Migration phases

### Phase 00 — Extensions and infrastructure

Create:

- `pgcrypto`;
- `citext`;
- `postgis`;
- private schemas for security-sensitive functions where required;
- shared timestamp trigger;
- correlation and request context support;
- audit event foundation;
- transactional outbox foundation;
- migration metadata registry.

Acceptance:

- extensions are idempotently enabled;
- no public execute privilege exists on unsafe helper functions;
- all security-definer functions use fixed `search_path`.

### Phase 01 — Accounts and identity

Implement DB-01 foundations:

- `accounts`;
- `account_identities`;
- `identity_verification_cases`;
- `account_settings`;
- account lifecycle constraints;
- `current_account_id()`;
- account bootstrap trigger or controlled service function.

Acceptance:

- one auth subject maps to one account;
- legal identity is inaccessible to ordinary clients;
- active account requirements are enforced server-side.

### Phase 02 — Profiles and governance

Create:

- `profiles`;
- `profile_memberships`;
- `profile_role_permissions`;
- sensitive action requests, approvals and execution evidence;
- canonical permission helper functions;
- shared-profile integrity triggers.

Acceptance:

- individual profiles have exactly one active owner;
- couple profiles cannot activate without required verified members;
- no client can execute a sensitive shared-profile action directly.

### Phase 03 — Profile modules and taxonomies

Create DB-02 catalogs and modules:

- gender, orientation, relationship, practice, boundary, meeting-context and language catalogs;
- profile presentation;
- member attributes;
- relationship contexts;
- search intents and targets;
- practice preferences;
- boundaries;
- consent preferences;
- availability preferences;
- visibility rules;
- module states and sensitive change history.

Acceptance:

- no sensitive profile module is stored as an authorization-driving JSON blob;
- all catalog codes are immutable;
- discoverability is impossible while required modules are incomplete.

### Phase 04 — Media

Implement DB-03:

- media assets and derivatives;
- albums and album items;
- publication status;
- access grants and revocation;
- moderation state;
- joint-media approval linkage;
- storage-object mapping.

Acceptance:

- private media has no permanent public URL;
- expired or revoked grants fail immediately;
- EXIF removal and derivative generation are represented as required processing states.

### Phase 05 — Conversations and interaction

Implement DB-04:

- conversations;
- participants;
- first-contact requests;
- messages and message versions;
- reactions;
- read state;
- attachments;
- mute, archive and participant lifecycle;
- block-aware interaction permissions.

Acceptance:

- each message stores actor account and acting profile;
- blocked profiles cannot open or continue ordinary direct interaction;
- reported evidence can be preserved independently from user-facing deletion.

### Phase 06 — Location and discovery

Implement DB-05:

- geography references;
- profile location preferences;
- private account location samples;
- safe profile areas;
- travel periods;
- location exclusions;
- discoverability snapshots;
- PostGIS indexes and expiry jobs.

Acceptance:

- raw coordinates are not client-readable;
- discovery uses safe geography only;
- travel and current-location modes expire automatically.

### Phase 07 — Events and professional entities

Implement DB-06:

- professional organizations and venues;
- professional verification;
- organizers and staff permissions;
- events, sessions and publication;
- registration, invitations, attendance and capacity reservations;
- venue reviews linkage;
- organizer audit trail.

Acceptance:

- exact addresses are exposed only through approved professional projections;
- event capacity is transactionally protected;
- cancelled or restricted events cannot accept registrations.

### Phase 08 — Trust and moderation

Implement DB-07:

- verifications and trust badges;
- community reviews;
- reports and evidence references;
- moderation cases;
- case assignments and decisions;
- restrictions and appeals;
- profile blocks;
- derived trust signals.

Acceptance:

- reports are private;
- blocks override discovery and interaction;
- sanctions are attributable, reasoned and auditable;
- trust signals do not directly authorize irreversible sanctions.

### Phase 09 — Commerce

Implement DB-08:

- products and prices;
- subscriptions;
- invoices and payment transaction references;
- entitlements;
- promotions, codes and redemptions;
- provider webhook inbox;
- commercial outbox events.

Acceptance:

- amounts use minor units and ISO currency;
- webhook processing is idempotent;
- entitlement state is independent from raw provider state;
- commercial access never bypasses safety rules.

### Phase 10 — Notifications

Implement DB-09:

- devices and push tokens;
- notification preferences;
- notification intents;
- channel deliveries;
- provider delivery attempts;
- suppression and quiet-hour logic;
- templates and localization references.

Acceptance:

- sensitive payloads are minimized;
- marketing consent is independent from transactional delivery;
- notifications are reproducible from domain events and are not audit truth.

### Phase 11 — GDPR lifecycle

Implement DB-10:

- consent events;
- data-subject requests;
- export jobs;
- deletion and anonymization workflows;
- retention policies and execution jobs;
- legal holds;
- processing activity and evidence references;
- erasure completion events.

Acceptance:

- deletion is retryable and stateful;
- sessions, discoverability and grants are revoked at request execution start;
- legal holds prevent unjustified purge while remaining purpose-limited;
- expired operational data is physically removed.

### Phase 12 — Projections and performance

Create:

- public profile projections;
- approved-contact projections;
- discovery projections;
- moderation/admin projections;
- professional public projections;
- materialized view refresh or snapshot rebuild mechanisms;
- indexes based on measured access paths.

No projection may contain fields broader than its declared visibility purpose.

### Phase 13 — Seed and controlled catalogs

Seed only:

- roles and permission keys;
- stable technical enums where represented as tables;
- initial taxonomies approved by product and moderation;
- notification topics;
- default retention categories;
- product catalog placeholders where environment-safe.

Never seed fake production profiles into production migrations.

---

## 4. Canonical migration naming

Use UTC sortable prefixes and one purpose per migration:

```text
YYYYMMDDHHMMSS_<domain>_<action>.sql
```

Examples:

```text
20260723160000_core_enable_extensions.sql
20260723160100_accounts_create_accounts.sql
20260723160200_profiles_create_profiles.sql
20260723160300_profiles_add_membership_rls.sql
```

Do not edit a migration already applied outside local development. Add a corrective migration.

---

## 5. Mandatory migration contents

Every table migration must declare:

- table and column comments;
- primary key;
- foreign keys with explicit delete behavior;
- nullability and defaults;
- check constraints;
- uniqueness constraints;
- indexes justified by access patterns;
- RLS enablement;
- explicit policies or an intentional deny-all state;
- grants and revoked default privileges;
- data classification metadata;
- retention category;
- owning domain;
- audit behavior;
- update timestamp behavior where applicable.

---

## 6. Schema registry tables

Create internal metadata tables to prevent undocumented schema growth.

### `schema_data_classifications`

Minimum columns:

- schema name;
- table name;
- column name;
- classification;
- processing purpose;
- legal basis category where relevant;
- owner domain;
- reviewed version.

### `schema_retention_rules`

Minimum columns:

- table or data category;
- lifecycle trigger;
- retention policy code;
- deletion/anonymization action;
- legal-hold behavior;
- job owner.

### `schema_domain_owners`

Maps every domain table to an owning module and documentation chapter.

CI must fail when a user-data column has no classification or when a domain table has no owner.

---

## 7. RLS implementation order

For each domain:

1. create tables with RLS enabled immediately;
2. revoke broad privileges;
3. create tested helper functions;
4. add subject/owner policies;
5. add profile-membership policies;
6. add approved cross-profile projections;
7. add trusted service policies only where required;
8. write negative tests before enabling application usage.

RLS helpers must avoid recursive policy evaluation and must be benchmarked.

---

## 8. API and generated-type contract

After each migration phase:

- regenerate TypeScript database types;
- generate application-facing domain DTOs separately from raw table types;
- prohibit direct client imports of private table row types;
- expose command/request schemas with runtime validation;
- keep public API projections allow-listed;
- mark sensitive values as server-only in package boundaries.

Raw database types are not public API contracts.

---

## 9. Outbox and idempotency

External side effects use a transactional outbox.

Minimum outbox fields:

- `id`;
- `event_type`;
- aggregate type and identifier;
- payload version;
- minimal payload;
- correlation identifier;
- occurred timestamp;
- publication state;
- attempt count;
- next attempt timestamp;
- published timestamp.

Inbound provider events use an inbox table with a unique provider event key and processing result.

Commands that may be retried accept an idempotency key scoped to account, command and target.

---

## 10. Test suite required before merge

### Schema tests

- all expected tables and constraints exist;
- foreign-key deletion behavior matches the manifest;
- no undocumented enum or catalog duplication exists;
- all mutable tables have timestamp/version behavior;
- all expiry tables have indexes.

### RLS tests

Test at least:

- anonymous user;
- authenticated account without profile membership;
- profile owner;
- couple co-owner;
- delegated manager;
- blocked counterpart;
- suspended account;
- moderator with scoped rights;
- service worker role.

Every positive RLS test must have corresponding negative tests.

### Privacy tests

- raw coordinates never appear in client queries;
- legal identity never appears in profile projections;
- private media cannot be fetched after grant revocation;
- hidden fields remain absent, not merely null-masked inconsistently;
- push/email payloads do not expose intimate content;
- deleted profiles leave no discoverability projection.

### Workflow tests

- couple sensitive approval;
- first-contact acceptance;
- block propagation;
- event capacity race;
- payment webhook replay;
- entitlement expiry;
- consent withdrawal;
- deletion request with legal hold;
- expired location cleanup.

---

## 11. CI quality gates

A pull request changing the database must fail when:

- migrations do not apply from an empty database;
- migrations do not apply on the previous release schema;
- generated types are stale;
- RLS is disabled on a domain table;
- a table or sensitive column lacks classification;
- SQL linting fails;
- schema tests fail;
- destructive SQL lacks an approved migration annotation;
- a public projection gains a sensitive column;
- documentation references an enum or table that does not exist.

---

## 12. Codex execution batches

Codex must work in ordered batches and open one PR per coherent implementation phase.

Recommended batches:

1. core infrastructure and accounts;
2. profiles and governance;
3. profile modules and catalogs;
4. media;
5. conversations;
6. location and discovery;
7. events and professionals;
8. trust and moderation;
9. commerce;
10. notifications;
11. GDPR lifecycle;
12. projections, seeds and complete hardening.

Each PR must include:

- migrations;
- tests;
- generated type updates;
- schema documentation updates;
- rollback or corrective strategy;
- a checklist mapping implementation to exact DB chapter sections.

---

## 13. Definition of done

The schema foundation is complete only when:

- DB-01 to DB-10 and DB-00 are implemented without contradictions;
- all migrations pass locally and in CI;
- RLS and storage policies pass negative security tests;
- generated documentation has no drift;
- all domain commands have a defined transaction boundary;
- retention and deletion jobs are deployable;
- public, member, private, sensitive and secret data boundaries are demonstrably enforced;
- application development can proceed without inventing new authorization or ownership rules.
