# Velvet Database Bible — DB-09

## Notifications, devices, preferences and delivery logs

**Status:** Proposed for validation  
**Version:** 1.0  
**Scope:** Platform Core  
**Depends on:** DB-01, DB-04, DB-06, DB-08

---

## 1. Purpose

This chapter defines the canonical notification model for in-app, email, push and operational delivery while respecting consent, privacy, frequency and safety constraints.

## 2. Locked principles

1. Notifications are generated from domain events, not directly from page code.
2. Delivery channel consent is evaluated at send time.
3. Transactional, security, safety and marketing communications are separate categories.
4. Sensitive message content must not appear on lock screens by default.
5. Device tokens are private, revocable and scoped to one account installation.
6. Duplicate domain events must not create duplicate notifications.
7. Delivery failures are recorded without storing unnecessary provider payloads.
8. Quiet hours and digests are timezone-aware.
9. Blocking, conversation mute and profile restrictions affect notification eligibility.
10. Marketing opt-out never blocks legally or operationally necessary security messages.

## 3. Core tables

### 3.1 `notification_types`

Registry fields: `key`, `category`, `default_priority`, `supported_channels`, `template_group`, `sensitive_content`, `active`.

Categories: `security`, `safety`, `transactional`, `social`, `professional`, `product`, `marketing`.

### 3.2 `notification_preferences`

Per-account and optional per-profile preferences.

Fields include `account_id`, optional `profile_id`, `notification_type_key`, channel booleans, digest mode, quiet-hours policy, locale and timestamps.

### 3.3 `devices`

Fields: `id`, `account_id`, `platform`, `installation_id_hash`, `device_name_safe`, `status`, `last_seen_at`, `created_at`, `revoked_at`.

### 3.4 `push_endpoints`

Fields: `id`, `device_id`, `provider`, encrypted token/endpoint, public key material where required, `status`, `last_success_at`, `last_failure_at`, `failure_count`, timestamps.

Tokens are never returned through normal client reads after registration.

### 3.5 `notification_events`

Normalized inbox of domain events eligible to produce notifications.

Fields: `id`, `event_key`, `aggregate_type`, `aggregate_id`, `actor_account_id`, optional `actor_profile_id`, `recipient_resolution_key`, `payload_safe`, `occurred_at`, `deduplication_key`, `status`.

### 3.6 `notifications`

In-app notification record.

Fields: `id`, `recipient_account_id`, optional `recipient_profile_id`, `type_key`, `event_id`, `title_key`, `body_key`, `render_context_safe`, `priority`, `status`, `available_at`, `expires_at`, `read_at`, `dismissed_at`, timestamps.

### 3.7 `notification_deliveries`

One row per attempted channel delivery.

Fields: `id`, `notification_id`, `channel`, `destination_reference`, `provider`, `provider_message_id`, `status`, `attempt_count`, `next_attempt_at`, `sent_at`, `delivered_at`, `failed_at`, `failure_code`, timestamps.

### 3.8 `notification_digests`

Groups eligible low-priority notifications by account, channel and time window.

### 3.9 `email_suppressions`

Records bounces, complaints, manual suppression and legal opt-out scope.

### 3.10 `notification_template_versions`

Immutable template metadata by locale and channel. Full rendering assets may live in application code or provider systems but version references remain auditable.

## 4. Recipient resolution

Recipient resolution is server-side and may depend on:

- profile memberships and role permissions;
- conversation membership and mute state;
- event organizer roles;
- reservation ownership;
- billing customer ownership;
- block relations;
- moderation restrictions;
- account status and verified destinations.

A domain event must not contain a public list of private recipient addresses.

## 5. Delivery pipeline

1. Accept idempotent domain event.
2. Resolve recipients.
3. Create in-app notification records.
4. Evaluate category, preferences, consent, quiet hours and urgency.
5. Redact sensitive content for push/email previews.
6. Queue immediate delivery or digest.
7. Record provider outcome.
8. Retry only transient failures with bounded backoff.
9. Disable invalid endpoints after threshold.
10. Preserve minimal delivery history under DB-10.

## 6. Content privacy

Push defaults for sensitive notifications use generic copy such as “Vous avez reçu une nouvelle interaction sur Velvet.” Names, message excerpts, exact event locations and private album content are excluded unless the user explicitly enables previews and policy permits it.

## 7. RLS and permissions

- accounts read and update only their own notification state and preferences;
- profile managers may receive operational notifications but cannot inspect another member's private account notifications;
- push endpoints are write-only through registration commands and backend-readable only;
- provider IDs, failures and suppression records are support/admin only;
- marketing exports require explicit authorized workflows.

## 8. Indexes and constraints

- unique `notification_events(deduplication_key)`;
- `(recipient_account_id, status, created_at desc)` on notifications;
- `(status, next_attempt_at)` on deliveries;
- unique active push endpoint token hash;
- `(account_id, notification_type_key, profile_id)` on preferences;
- expiry indexes for notifications and devices;
- unique provider message ID when present.

## 9. Domain commands

- `RegisterDevice`
- `RegisterPushEndpoint`
- `RevokeDevice`
- `UpdateNotificationPreference`
- `PublishNotificationEvent`
- `ResolveNotificationRecipients`
- `QueueNotificationDelivery`
- `ProcessNotificationDelivery`
- `MarkNotificationRead`
- `DismissNotification`
- `BuildNotificationDigest`
- `RecordEmailSuppression`

## 10. Acceptance criteria

- one domain event cannot create duplicate recipient notifications;
- blocked profiles generate no social notifications to each other;
- muted conversations suppress configured channels;
- invalid push tokens are disabled after verified provider response;
- security notifications ignore marketing opt-out but use verified destinations;
- sensitive content is absent from default push previews;
- quiet hours respect the recipient timezone;
- account logout or device revocation immediately invalidates the endpoint.

## 11. Migration order

1. notification type registry;
2. preferences;
3. devices and push endpoints;
4. event inbox;
5. notifications and deliveries;
6. digests and suppressions;
7. template versions;
8. indexes, RLS, queues and retention jobs;
9. channel integration tests.

## 12. Codex execution contract

Codex must publish domain events and call the notification service. It must not send provider messages directly from page components or include sensitive data in push payloads by default.