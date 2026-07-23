# Velvet Database Bible — DB-07

## Trust, verification, reviews, reports and moderation

**Status:** Proposed for validation  
**Version:** 1.0  
**Scope:** Platform Core / Community / Professionals / Administration  
**Depends on:** DB-01, DB-03, DB-04, DB-06

---

## 1. Purpose

This chapter defines the canonical trust and safety model for verification, reputation signals, reviews, reports, moderation cases, sanctions and appeals.

## 2. Locked principles

1. Trust is evidence-based, explainable and never reduced to one opaque score.
2. Identity verification, profile verification, attendance verification and reputation are distinct.
3. Reviews require a qualifying interaction and cannot be purchased.
4. Reports are confidential and never exposed to the reported profile.
5. Moderation decisions are attributable, reason-coded, time-bounded where appropriate and appealable.
6. Safety restrictions override subscriptions and growth objectives.
7. No automated model may permanently sanction an account without human review.
8. Sensitive evidence is access-controlled and retained only as necessary.
9. Shared-profile sanctions must distinguish profile-level and account-level responsibility.
10. All administrative access and actions are audited.

## 3. Core tables

### 3.1 `trust_assertions`

Normalized evidence attached to an account, profile, professional entity, venue or event.

Fields: `id`, `subject_type`, `subject_id`, `assertion_type`, `status`, `assurance_level`, `source_type`, `source_reference`, `issued_at`, `expires_at`, `revoked_at`, `metadata_safe`, timestamps.

Examples: `age_verified`, `identity_verified`, `phone_verified`, `couple_members_verified`, `business_verified`, `venue_verified`, `attendance_verified`, `trusted_organizer`.

### 3.2 `verification_cases`

Unified workflow record for manual or provider-assisted verification.

Fields include subject, requested assertion, provider, state, reviewer, result code, timestamps and evidence retention deadline. Raw documents remain in protected storage and are never copied into public tables.

### 3.3 `review_eligibility_evidence`

Fields: `id`, `reviewer_profile_id`, `subject_type`, `subject_id`, `evidence_type`, `evidence_reference_id`, `eligible_from`, `expires_at`, `consumed_at`, `revoked_at`.

Evidence types include confirmed event attendance, completed booking, mutually confirmed interaction or administrator-approved exception.

### 3.4 `reviews`

Fields: `id`, `author_profile_id`, `subject_type`, `subject_id`, `eligibility_evidence_id`, `rating_overall`, category ratings, `body`, `status`, `visibility`, `published_at`, `edited_at`, `moderation_case_id`, timestamps.

Statuses: `draft`, `pending_moderation`, `published`, `hidden`, `rejected`, `deleted`.

Rules:

- one active review per author and qualifying evidence unless policy permits updates;
- no anonymous review to administrators, even if pseudonymous publicly;
- edits preserve revision history;
- reviews cannot disclose private sexual, health or identity information.

### 3.5 `review_revisions`

Immutable snapshots of changed review content and moderation reason.

### 3.6 `reports`

Fields: `id`, `reporter_account_id`, optional `reporter_profile_id`, `subject_type`, `subject_id`, `category`, `severity`, `description`, `status`, `safety_immediate`, `created_at`, `closed_at`.

Categories include harassment, impersonation, non-consensual media, underage concern, fraud, spam, hate, threat, unsafe event, payment dispute and other.

### 3.7 `report_evidence`

Protected references to messages, media, event records or uploaded evidence. Evidence access is role-restricted and logged.

### 3.8 `moderation_cases`

Fields: `id`, `case_type`, `priority`, `status`, `subject_type`, `subject_id`, `source_report_id`, `assigned_team`, `assigned_account_id`, `opened_at`, `decision_at`, `closed_at`, `decision_code`, `decision_summary_internal`.

### 3.9 `moderation_actions`

Immutable actions such as warning, content removal, profile restriction, messaging restriction, event suspension, temporary suspension, permanent ban, verification revocation or no action.

Each action records scope, effective period, actor, legal/safety basis and rollback status.

### 3.10 `appeals`

Fields: `id`, `moderation_action_id`, `appellant_account_id`, `reason`, `status`, `reviewer_account_id`, `decision`, timestamps.

### 3.11 `blocks`

Canonical bilateral safety exclusion initiated by one account/profile. Blocking immediately removes discovery, messaging and private media access in both directions while retaining evidence needed for safety and legal obligations.

## 4. Trust presentation

Public trust indicators are derived projections, for example:

- identity verified;
- couple members verified;
- professional entity verified;
- recent verified attendance count band;
- review count and aggregate rating where statistically meaningful;
- account age band;
- moderation good-standing indicator only when non-misleading.

Internal risk signals must never be exposed as public labels.

## 5. Review publication rules

A review is publishable only when:

- evidence is valid and belongs to the author;
- author and subject were eligible at interaction time;
- no coercion, incentive or conflict rule is detected;
- content passes moderation checks;
- no active protective restriction prohibits publication;
- minimum privacy requirements are satisfied.

Aggregate ratings use anti-manipulation thresholds and do not reveal a single reviewer's identity beyond configured public profile identity.

## 6. Report workflow

1. Accept report and preserve relevant evidence.
2. Apply immediate protective measures when severity requires.
3. Deduplicate linked reports without hiding volume.
4. Assign priority and moderation queue.
5. Investigate through least-privilege tools.
6. Record reason-coded decision.
7. Apply actions transactionally.
8. Notify parties with safe, proportionate information.
9. Enable appeal when applicable.
10. Retain or delete evidence under DB-10 policy.

## 7. RLS and permissions

- reporters see their own report status but not investigation details;
- reported subjects cannot access reports or reporter identity;
- moderators access cases based on queue and role;
- high-risk evidence requires elevated scope;
- professional managers cannot moderate reviews about their own entity;
- no moderator may decide their own report or appeal;
- all evidence reads and exports create audit events.

## 8. Indexes

- `(subject_type, subject_id, status)` on assertions, reviews and cases;
- `(status, priority, opened_at)` on moderation cases;
- `(reporter_account_id, created_at)` on reports;
- unique active block on blocker/blockee scope;
- review aggregate indexes by subject and published status;
- expiry indexes for assertions and temporary sanctions.

## 9. Domain commands

- `RequestVerification`
- `ResolveVerificationCase`
- `IssueTrustAssertion`
- `RevokeTrustAssertion`
- `CreateReviewEligibilityEvidence`
- `SubmitReview`
- `EditReview`
- `ReportSubject`
- `OpenModerationCase`
- `ApplyProtectiveRestriction`
- `DecideModerationCase`
- `SubmitAppeal`
- `DecideAppeal`
- `BlockSubject`
- `UnblockSubject`

## 10. Acceptance criteria

- no review can be published without qualifying evidence;
- reported users cannot identify reporters through product APIs;
- a block immediately removes discovery, messaging and media grants;
- permanent sanctions require recorded human decision;
- shared-profile cases preserve account-level attribution;
- moderators cannot self-review cases or appeals;
- verification revocation updates public projections immediately;
- all high-risk evidence access is audited.

## 11. Migration order

1. trust assertions and verification cases;
2. review eligibility and reviews;
3. revisions and aggregates;
4. reports and evidence;
5. moderation cases and actions;
6. appeals;
7. blocks;
8. projections, indexes, RLS and expiry jobs;
9. test fixtures and security tests.

## 12. Codex execution contract

Codex must model trust as separate assertions and evidence. It must not invent a single permanent trust score, expose internal risk data or allow direct client writes to moderation outcomes.