# Velvet Database Bible — DB-10

## GDPR retention, audit, deletion and anonymization

**Status:** Proposed for validation  
**Version:** 1.0  
**Scope:** Platform Core / Administration  
**Depends on:** DB-01 to DB-09

---

## 1. Purpose

This chapter defines the canonical governance model for consent evidence, processing purposes, data retention, subject-right requests, audit trails, deletion, legal holds and anonymization.

This document is a technical specification and does not replace final legal validation before public launch.

## 2. Locked principles

1. Every personal-data category has a documented purpose, lawful basis, owner and retention rule.
2. Data minimization applies at collection, storage, projection, logging and analytics layers.
3. Consent must be specific, evidenced, versioned and withdrawable where consent is the legal basis.
4. Withdrawal stops future processing but does not falsify historical evidence.
5. Account deletion is an orchestrated workflow, not a direct cascade.
6. Safety, fraud, financial and legal obligations may require limited retention after deletion.
7. Retained records must be anonymized or access-restricted whenever identification is no longer necessary.
8. Audit records are immutable but must avoid unnecessary sensitive payloads.
9. Backups have their own expiry and restoration controls.
10. Access to privacy tooling and exported data is strongly authenticated and audited.

## 3. Core tables

### 3.1 `processing_purposes`

Registry fields: `key`, `name`, `description`, `lawful_basis`, `data_categories`, `retention_policy_id`, `controller_scope`, `active_from`, `active_until`, `policy_version`.

### 3.2 `consent_definitions`

Versioned definitions for marketing, analytics, location, sensitive profile publication, private media processing and other consent-based purposes.

Fields: `key`, `version`, `purpose_key`, `display_text_hash`, `locale`, `effective_from`, `effective_until`, `required`, timestamps.

### 3.3 `consent_events`

Immutable evidence.

Fields: `id`, `account_id`, optional `profile_id`, `consent_key`, `definition_version`, `action`, `occurred_at`, `source`, `proof_context_safe`, `ip_hash`, `user_agent_hash`, timestamps.

Actions: `granted`, `withdrawn`, `renewed`, `declined`.

### 3.4 `retention_policies`

Fields: `id`, `key`, `data_category`, `active_retention_days`, `post_deletion_retention_days`, `anonymization_strategy`, `deletion_strategy`, `legal_basis`, `review_date`, timestamps.

### 3.5 `data_subject_requests`

Fields: `id`, `account_id`, `request_type`, `status`, `identity_verified_at`, `received_at`, `due_at`, `completed_at`, `rejection_reason_code`, `assigned_to`, timestamps.

Types: `access`, `portability`, `rectification`, `restriction`, `objection`, `deletion`, `consent_history`.

### 3.6 `data_export_jobs`

Tracks encrypted export generation, expiry, download count and completion. Export files are short-lived and never public.

### 3.7 `deletion_workflows`

Fields: `id`, `account_id`, `status`, `requested_at`, `cooling_off_until`, `started_at`, `completed_at`, `failure_code`, `legal_hold_detected`, timestamps.

### 3.8 `deletion_workflow_steps`

One row per domain: authentication, account, profiles, media, messaging, location, events, trust, billing, notifications, analytics and external processors.

Each step records state, attempts, completion proof and anonymization result.

### 3.9 `legal_holds`

Fields: `id`, `subject_type`, `subject_id`, `scope`, `reason_code`, `starts_at`, `ends_at`, `authorized_by`, encrypted internal reference, timestamps.

### 3.10 `audit_events`

Immutable structured audit trail.

Fields: `id`, `occurred_at`, `actor_type`, optional `actor_account_id`, `actor_role`, `action`, `resource_type`, `resource_id`, `result`, `reason_code`, `request_id`, `ip_hash`, `metadata_safe`, `retention_policy_id`.

No raw message body, media bytes, identity document or precise location may be copied into audit metadata.

### 3.11 `data_access_events`

High-sensitivity access log for identity, precise location, moderation evidence, financial records and exports.

### 3.12 `processor_registry`

Tracks external processors, purpose, region, data categories, contract version and deletion/export capabilities.

### 3.13 `processor_requests`

Tracks deletion, correction or export propagation to external processors.

## 4. Data classification

Required classes:

- `public`;
- `member_visible`;
- `private`;
- `sensitive`;
- `highly_sensitive`;
- `financial_regulated`;
- `safety_evidence`;
- `anonymous_aggregate`.

Every table and API projection must have an explicit classification and approved audience.

## 5. Deletion workflow

1. Strongly authenticate request.
2. Record request and optional cooling-off period.
3. Disable discoverability, new interactions and marketing immediately.
4. Revoke sessions, devices, media grants and active location processing.
5. Detect financial, safety or legal holds.
6. Delete or anonymize profiles and public content.
7. Remove or anonymize messages according to participant and legal constraints.
8. Delete source media and derived renditions unless held.
9. Anonymize operational records where identity is unnecessary.
10. Preserve narrowly required financial, fraud or safety evidence with restricted access.
11. Propagate requests to processors.
12. Delete authentication identity after dependencies complete.
13. Record completion proof without retaining unnecessary identity.

## 6. Anonymization standards

- replace direct identifiers with irreversible random subject references;
- remove emails, phone numbers, names, addresses, device tokens and precise coordinates;
- generalize dates and locations when records remain useful for aggregate analysis;
- break linkability across domains unless required for retained legal evidence;
- do not use reversible encryption as anonymization;
- validate re-identification risk before classifying a dataset as anonymous.

## 7. Messaging and shared-content deletion

Deletion of one account must not silently rewrite another participant's legitimate conversation history. The deleted actor is represented by a neutral deleted-profile label, while direct identifiers, profile links and optional media are removed or unavailable. Content subject to safety reports or legal hold follows restricted retention rules.

For shared couple profiles, deletion or withdrawal by one member triggers governance rules from DB-01 and consent removal from DB-02/DB-03 before profile-level deletion decisions.

## 8. Backup policy

- encrypted backups with access separation;
- documented rolling retention;
- deleted data may persist only until backup expiry;
- restoration procedures re-run deletion tombstones before production access;
- backup access and restores are audited;
- no indefinite unmanaged snapshots.

## 9. RLS and permissions

- users access their own consent history and request status;
- exports require short-lived authenticated download links;
- privacy operators access request workflows, not unrelated product data;
- legal holds require a distinct elevated role;
- audit and data-access logs are append-only for services and read-restricted for administrators;
- no administrator can erase their own audit trail through normal tooling.

## 10. Indexes and operational jobs

- `(account_id, occurred_at desc)` on consent events and requests;
- `(status, due_at)` on subject requests;
- `(status, cooling_off_until)` on deletion workflows;
- `(resource_type, resource_id, occurred_at)` on audit events;
- `(subject_type, subject_id, starts_at, ends_at)` on legal holds;
- scheduled retention sweeps by policy;
- deletion retry queue;
- processor propagation reconciliation;
- backup tombstone reconciliation.

## 11. Domain commands

- `RecordConsentEvent`
- `WithdrawConsent`
- `CreateDataSubjectRequest`
- `VerifyPrivacyRequestIdentity`
- `GenerateDataExport`
- `StartDeletionWorkflow`
- `ExecuteDeletionStep`
- `ApplyLegalHold`
- `ReleaseLegalHold`
- `AnonymizeSubjectData`
- `RecordAuditEvent`
- `RecordSensitiveDataAccess`
- `PropagateProcessorRequest`

## 12. Acceptance criteria

- withdrawal immediately disables future consent-based processing;
- account deletion cannot be implemented as one uncontrolled SQL cascade;
- exact deletion progress is visible internally and failures are retryable;
- legally retained records are minimized and access-restricted;
- raw sensitive payloads never enter audit logs;
- exports expire and require strong authentication;
- restored backups reapply completed deletions;
- processor propagation is traceable;
- shared-profile consent withdrawal is enforced before media or profile publication continues;
- retention jobs are testable and produce reconciliation reports.

## 13. Migration and implementation order

1. processing-purpose and retention registries;
2. consent definitions and events;
3. subject requests and export jobs;
4. deletion workflows and steps;
5. legal holds;
6. audit and sensitive-access events;
7. processor registry and requests;
8. retention/deletion jobs and tombstones;
9. RLS, immutable triggers and monitoring;
10. privacy integration tests and legal review checklist.

## 14. Database Bible completion gate

Before schema generation begins:

- all DB-01 to DB-10 chapters must be cross-reviewed for naming and foreign-key consistency;
- all enumerations must be consolidated;
- data classification and retention must be mapped table by table;
- unresolved product decisions must be listed explicitly;
- security and legal validation items must be converted into tracked issues.

## 15. Codex execution contract

Codex must treat deletion, retention and consent as cross-domain workflows. It must not invent retention durations, store raw sensitive content in logs or claim legal compliance without documented validation.