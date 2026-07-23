# Velvet Database Bible — DB-00

## Cross-cutting data contract and coherence review

**Status:** Accepted foundation  
**Version:** 1.0  
**Scope:** DB-01 to DB-10  
**Purpose:** Resolve cross-domain inconsistencies before SQL generation and application development.

---

## 1. Review outcome

The ten domain chapters are coherent enough to become the normative source for implementation, provided every migration, API and domain service also follows this cross-cutting contract.

This chapter has precedence when a wording difference exists between DB-01 and DB-10. A domain chapter remains authoritative for its own business rules.

No unresolved contradiction blocks schema generation.

---

## 2. Canonical ownership model

Velvet distinguishes four concepts that must never be merged:

1. `auth.users` identifies a login subject managed by the authentication provider.
2. `accounts` identifies one human Velvet account.
3. `profiles` identifies a public or operational persona.
4. `profile_memberships` authorizes an account to act for a profile.

All user-originated mutations must persist both:

- the profile on whose behalf the action is performed, where applicable;
- the authenticated account that actually performed it.

Canonical actor columns:

- `actor_account_id` for the authenticated human actor;
- `acting_profile_id` for the represented profile;
- `created_by_account_id` only for creation provenance;
- `updated_by_account_id` where the last editor is materially relevant;
- `service_actor` for trusted automated processing.

A profile identifier is never sufficient audit evidence for a sensitive action.

---

## 3. Identifier and key conventions

- Domain primary keys use `uuid` generated server-side.
- Authentication references use `auth_user_id` and remain unique.
- Foreign keys use `<singular_entity>_id`.
- Catalog machine values use immutable `code` fields.
- Provider identifiers use `provider_*_id` and are never primary domain keys.
- Join tables use a UUID primary key when lifecycle, audit or metadata is required; immutable static permission matrices may use a composite key.
- Public slugs are presentation identifiers, never authorization identifiers.

Deletion behavior must be explicit in every migration. Sensitive history must not disappear through accidental cascading deletes.

Default policy:

- `RESTRICT` for accounts, profiles, payments, consent, moderation and audit evidence;
- `CASCADE` only for true dependent configuration with no independent legal or audit value;
- controlled anonymization instead of physical cascade for user-generated history.

---

## 4. Naming conventions

### 4.1 Tables

- plural `snake_case` names;
- no module prefix unless needed to avoid ambiguity;
- event tables end in `_events`;
- immutable history tables end in `_history` or `_log`;
- materialized operational projections end in `_snapshots` or `_projections`;
- grant tables end in `_grants`;
- reference taxonomies end in `_catalog`.

### 4.2 Columns

Canonical lifecycle columns:

- `created_at timestamptz not null default now()`;
- `updated_at timestamptz not null default now()` when rows are mutable;
- `deleted_at timestamptz` for soft-deletable records;
- `archived_at timestamptz` only when archival is a distinct business state;
- `expires_at timestamptz` for time-limited rights or data;
- `occurred_at timestamptz` for immutable business events.

Boolean columns begin with `is_`, `has_`, `can_`, `requires_` or use a clear enabled form such as `location_enabled`.

### 4.3 Commands and events

- Domain commands use PascalCase verbs, for example `GrantAlbumAccess`.
- Persisted event types use lowercase dot-separated names, for example `media.album_access.granted`.
- API paths and database names must not reuse display labels as machine identifiers.

---

## 5. Enumeration strategy

PostgreSQL native enums may be used only for small, stable, infrastructure-level state machines whose values are unlikely to change.

Recommended native enums:

- `account_status`;
- `profile_type`;
- `profile_status`;
- `membership_status`;
- `approval_status`;
- payment and delivery technical states where provider mapping is stable.

Use catalog tables or text plus check constraints for product taxonomies and values expected to evolve, including:

- genders and orientations;
- relationship styles;
- practices and boundaries;
- venue and event categories;
- notification topics;
- moderation reason codes;
- promotional campaign types.

Canonical status vocabulary:

- use `pending`, not both `waiting` and `pending`;
- use `cancelled` consistently, never mixed with `canceled`;
- use `active`, `paused`, `expired`, `archived`, `deleted` according to lifecycle meaning;
- `restricted` means usable with limitations;
- `suspended` means temporarily unusable;
- `blocked` is reserved for process/module inability or a bilateral safety relation, not a generic lifecycle synonym.

Every enum or constrained text value must be defined once in migrations and referenced by exact name in application types.

---

## 6. Visibility and authorization model

Visibility and authorization are separate.

`visibility_scope` controls who may receive a field through a valid projection. It never grants mutation rights.

Canonical visibility scopes:

- `private`;
- `profile_members`;
- `matched_profiles`;
- `approved_contacts`;
- `authenticated_members`;
- `public`.

Rules:

- `public` means accessible without authentication and must be exceptional;
- `authenticated_members` does not bypass blocks, moderation or age eligibility;
- `approved_contacts` requires a valid current relationship or grant;
- album grants, conversation membership and event attendance do not silently widen unrelated profile-field visibility;
- every client query uses a server-defined projection, never unrestricted table selection.

Authorization evaluation order:

1. authenticated account status;
2. acting profile membership and permission;
3. object ownership or participation;
4. bilateral block and protective safety rules;
5. moderation restrictions;
6. consent and visibility scope;
7. entitlement or subscription;
8. object lifecycle and expiry.

Safety, consent and legal restrictions always override commercial entitlement.

---

## 7. Shared-profile governance

For individual profiles, one active owner is required.

For couple profiles:

- at least two active verified account members are required for activation;
- both partners have independent credentials and consent records;
- sensitive actions use `sensitive_action_requests` and individual approvals;
- daily operations may use delegated permissions;
- a member's departure cannot erase the other member's account or personal evidence;
- joint identifying media and shared boundaries require the approval policy defined in DB-01 and DB-03.

Canonical sensitive actions are maintained in one registry. Domain chapters may add actions but must not create parallel approval mechanisms.

---

## 8. Consent model

Consent is purpose-specific, versioned, revocable and attributable to an account.

The canonical consent evidence model must include:

- `account_id`;
- optional `profile_id`;
- `purpose_code`;
- `policy_version`;
- `decision`;
- `source`;
- `occurred_at`;
- optional expiry or withdrawal relation;
- technical evidence sufficient for legal demonstration without retaining unnecessary device data.

A preference, declared practice, match, subscription, conversation, event registration or album grant is not sexual or interpersonal consent.

Consent withdrawal must stop future processing immediately where technically applicable. Historic evidence may be retained when required to demonstrate compliance or defend legal claims.

---

## 9. Data classification

Every column must receive one classification in migration metadata or the schema registry:

- `PUBLIC`: intentionally public web data;
- `MEMBER`: visible to eligible authenticated members;
- `PRIVATE`: accessible only to the data subject and authorized services;
- `SENSITIVE`: intimate, identity, location, moderation or financial data requiring strict purpose control;
- `SECRET`: credentials, provider secrets and signing material, which must not be stored in ordinary domain tables.

Minimum classifications:

- legal identity and date of birth: `SENSITIVE`;
- precise coordinates: `SENSITIVE`;
- practices, boundaries and intimate preferences: `SENSITIVE`;
- private media and grants: `SENSITIVE`;
- message content: `PRIVATE`, elevated to `SENSITIVE` when reported or moderation evidence;
- payment instruments and provider secrets: `SECRET` and provider-managed;
- public profile display name and approved public media derivative: `PUBLIC` only when explicitly published.

Logs, analytics, errors, search indexes and caches inherit the highest classification of their source data unless transformed through an approved irreversible derivation.

---

## 10. Location contract

Precise account location samples are private, short-lived and backend-only.

Community discovery uses safe derived profile areas and distance bands. No public or member API may expose raw latitude, longitude, device accuracy, exact home position or a precision-reversible geohash.

Professional venues may expose a verified business address through a separate professional projection.

Location retention and expiry jobs are mandatory, not optional operational improvements.

---

## 11. Media and messaging contract

- Media binaries live in private object storage; database rows hold metadata and lifecycle.
- Access uses short-lived signed delivery, never permanent public bucket URLs for private assets.
- EXIF and unnecessary metadata are removed before publication.
- Revocation prevents future retrieval but does not falsely promise deletion from recipient-controlled devices.
- Message rows identify both the acting profile and actor account.
- Editing creates history or version evidence; moderation evidence is immutable.
- Client-side deletion and legal erasure are different operations.
- Reported content may be preserved in a restricted evidence store while hidden from ordinary users.

---

## 12. Trust, reviews and moderation contract

Trust scores are derived operational signals and never the sole basis for an irreversible adverse decision.

Moderation uses:

- immutable reports and evidence references;
- case-based investigation;
- time-bounded restrictions where appropriate;
- reason codes and actor attribution;
- appeal capability for material sanctions;
- separation between community-facing reviews and private safety reports.

A review cannot disclose intimate details, personal data or unverified criminal allegations.

Blocks are bilateral for discovery and direct interaction. Blocking does not erase audit, payment or safety evidence.

---

## 13. Commerce contract

- Product access is represented by entitlements, not by reading payment-provider status directly.
- Provider webhooks are idempotent and retained as normalized evidence.
- Subscription, payment and entitlement are separate aggregates.
- Promotions may grant entitlements but cannot weaken age, consent, safety or moderation rules.
- Currency amounts use integer minor units plus ISO currency code.
- Financial records are append-oriented; corrections use compensating events rather than destructive edits.

---

## 14. Notifications contract

Notifications are derived delivery objects, not the authoritative source of domain truth.

- Domain events create notification intents.
- Preferences and legal basis are evaluated before each channel delivery.
- Sensitive content is minimized on lock screens, email subjects and push payloads.
- Device tokens are private and revocable.
- Delivery logs contain provider references and status but no unnecessary message or intimate profile content.
- Marketing and transactional communications use separate consent and suppression rules.

---

## 15. Audit contract

Sensitive domain changes create immutable audit events containing:

- event identifier;
- event type;
- actor account or trusted service;
- optional acting profile;
- target type and identifier;
- occurred timestamp;
- request/correlation identifier;
- normalized reason code where required;
- minimal structured change metadata;
- integrity sequence or hash when required by the audit tier.

Audit events must not duplicate raw message bodies, media binaries, credentials or full identity documents.

Three levels apply:

- operational activity: short-lived and non-evidentiary;
- security audit: restricted and retained according to security policy;
- legal/compliance evidence: immutable, purpose-limited and retained according to the legal schedule.

---

## 16. Retention and deletion precedence

Retention is defined by data category, purpose and legal basis, not by table alone.

Deletion precedence:

1. immediately revoke sessions, discoverability, grants and future processing;
2. freeze or settle open payment, safety and legal workflows;
3. anonymize user-facing content where deletion is required;
4. preserve restricted evidence only where a documented legal basis applies;
5. physically purge expired operational and location data;
6. emit completion evidence without retaining deleted personal payloads.

`deleted_at` is a workflow marker, not proof that erasure is complete.

Every deletion request must have a state machine and retryable execution steps.

---

## 17. Transaction boundaries

The following operations must execute through domain services inside a transaction or an idempotent workflow with compensating actions:

- account activation and deletion request;
- shared-profile activation and sensitive approval execution;
- media publication and grant creation/revocation;
- conversation creation and first-contact acceptance;
- block creation;
- event publication and capacity reservation;
- professional verification;
- moderation sanction;
- subscription and entitlement updates;
- consent withdrawal;
- discoverability snapshot rebuild.

Direct client writes to underlying tables are forbidden for these operations.

---

## 18. RLS baseline

- RLS is enabled on every user, profile, media, message, location, event, trust, commerce and notification table.
- The default policy is deny.
- Service-role bypass is limited to named backend services and audited jobs.
- Membership checks use stable helper functions to avoid policy drift.
- Sensitive reads use security-definer functions only after explicit review, fixed `search_path` and least privilege.
- Storage policies mirror database grants and object lifecycle.
- Administrative interfaces never rely on a generic unrestricted client role.

Required canonical helper functions include:

- `current_account_id()`;
- `is_active_profile_member(profile_id)`;
- `has_profile_permission(profile_id, permission_key)`;
- `is_blocked_between(profile_a_id, profile_b_id)`;
- `can_view_profile_field(viewer_profile_id, target_profile_id, scope)`;
- `has_active_entitlement(account_id, entitlement_code)`.

---

## 19. Global integrity rules

1. All timestamps use UTC `timestamptz`; locale conversion occurs at presentation time.
2. All user-visible text passes moderation and length constraints.
3. Soft-deleted rows are excluded by default from application projections.
4. Every time-limited row has an expiry index and cleanup owner.
5. Every materialized snapshot declares its source-of-truth tables and rebuild triggers.
6. Every provider webhook has a unique provider event key.
7. Every mutable sensitive table has optimistic concurrency through `version integer` or equivalent.
8. Every external side effect is dispatched through an outbox after transaction commit.
9. Every background command is idempotent and traceable through a correlation identifier.
10. No application code may infer permission solely from UI state.

---

## 20. Resolved coherence decisions

The review resolves the following cross-chapter points:

- account identity is private and distinct from profile identity;
- actor attribution always uses the real account plus optional acting profile;
- `visibility_scope` is shared across profile modules but private album access remains grant-based;
- precise location belongs to accounts, discoverable safe location belongs to profiles;
- blocks and moderation restrictions override matching, messaging, events and commercial benefits;
- professional addresses are separate from community location areas;
- subscriptions create entitlements; entitlements do not directly encode payments;
- notifications derive from domain events and never replace audit events;
- deletion is orchestrated, not implemented as a single cascade;
- evolving social taxonomies use catalogs, while stable technical lifecycles may use enums;
- every domain uses the same actor, timestamp, audit, classification and RLS conventions.

---

## 21. Open implementation choices that do not block the model

These choices are delegated to the implementation ADRs and must not alter the domain contract:

- final identity-verification provider;
- final payment provider;
- object-storage CDN architecture;
- exact encryption implementation for selected columns;
- queue/outbox infrastructure;
- search engine beyond PostgreSQL/PostGIS for later scale;
- precise retention durations pending final French and Belgian legal review.

---

## 22. Acceptance criteria

The cross-cutting review is complete when:

- all generated SQL follows this naming contract;
- shared concepts are defined once;
- every table has data classification, owner, retention and RLS treatment;
- every sensitive mutation has actor attribution and audit behavior;
- all time-limited data has expiry enforcement;
- deletion workflows preserve only justified evidence;
- automated schema tests detect undocumented tables, missing RLS and unsafe grants;
- no DB-01 to DB-10 implementation contradicts this contract.
