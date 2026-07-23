# Velvet Database Bible — DB-06

## Events, organizers, clubs and professional entities

**Status:** Proposed for validation  
**Version:** 1.0  
**Scope:** Community / Professionals / Administration  
**Depends on:** DB-01, DB-02, DB-05

---

## 1. Purpose

This chapter defines the canonical model for professional entities, venues, organizers, events, capacities, attendance, reservations and operational ownership.

## 2. Locked principles

1. A professional entity is not a personal identity.
2. Every professional entity is managed by verified personal accounts through profile memberships.
3. Organizers, venues and events have independent lifecycle and moderation states.
4. Public business addresses may be exact; private event locations may remain hidden until eligibility is met.
5. Attendance intent, booking and verified attendance are separate concepts.
6. Capacity and inventory changes are transactional.
7. Reviews require a qualifying relationship defined in DB-07.
8. Payment records are delegated to DB-08.
9. Event visibility never bypasses blocks, moderation or legal restrictions.
10. All professional mutations are attributable to an authenticated account.

## 3. Core tables

### 3.1 `professional_entities`

Fields: `id`, `profile_id`, `entity_type`, `legal_name`, `public_name`, `registration_country`, `registration_number_encrypted`, `vat_number_encrypted`, `status`, `verification_status`, `created_at`, `updated_at`, `deleted_at`.

`entity_type`: `club`, `spa`, `bar`, `love_room`, `hotel`, `travel_operator`, `event_organizer`, `other`.

### 3.2 `professional_entity_memberships`

Links verified accounts to a professional entity with roles: `owner`, `administrator`, `event_manager`, `booking_manager`, `content_manager`, `finance_viewer`, `viewer`.

Contains invitation, acceptance, revocation and audit timestamps.

### 3.3 `venues`

Fields include `id`, `professional_entity_id`, `name`, `venue_type`, `description`, `status`, exact postal address, public coordinates, contact channels, accessibility information, timezone, legal capacity, check-in policy, created/updated timestamps.

Exact addresses are public only when `address_visibility = public`. Private venue addresses require an authorized booking or invitation.

### 3.4 `venue_opening_hours`

Supports weekly schedules, exceptions, closures and timezone-aware periods.

### 3.5 `events`

Fields: `id`, `organizer_entity_id`, optional `venue_id`, `event_type`, `title`, `slug`, `description`, `status`, `visibility`, `starts_at`, `ends_at`, `timezone`, `minimum_age`, `capacity_total`, `capacity_reserved`, `capacity_confirmed`, `location_disclosure_policy`, `booking_policy`, `cancellation_policy_id`, `created_by_account_id`, timestamps.

Statuses: `draft`, `pending_review`, `published`, `sold_out`, `cancelled`, `completed`, `suspended`, `archived`.

### 3.6 `event_sessions`

Optional sub-periods for multi-day programs, workshops, meals or activities.

### 3.7 `event_audience_rules`

Defines allowed profile types, verification levels, age bands, membership requirements, dress codes and organizer-specific eligibility. Sensitive characteristics must only be used where lawful and explicitly declared.

### 3.8 `event_attendance_intents`

Represents `interested`, `going`, `not_going`, `waitlist_requested`. It is not a reservation.

### 3.9 `event_reservations`

Fields include `id`, `event_id`, `booking_profile_id`, `booked_by_account_id`, `status`, `party_size`, `inventory_class_id`, `price_snapshot`, `currency`, `payment_status`, `confirmation_code_hash`, timestamps.

Statuses: `pending`, `awaiting_payment`, `confirmed`, `waitlisted`, `cancelled`, `refunded`, `expired`, `checked_in`, `no_show`.

### 3.10 `event_inventory_classes`

Supports couple, solo, table, room, VIP or custom inventory without hardcoding product rules into the event table.

### 3.11 `event_checkins`

Records validated attendance with `reservation_id`, `checked_in_at`, `checked_in_by_account_id`, `method`, `evidence_reference`, `revoked_at`.

### 3.12 `event_media_links`

References DB-03 media with publication approval and organizer permissions.

## 4. Reservation transaction

A reservation confirmation must atomically:

1. lock relevant inventory row;
2. re-evaluate event status and audience eligibility;
3. verify available capacity;
4. create or transition reservation;
5. reserve inventory;
6. create payment intent reference where required;
7. emit audit and notification events;
8. commit or roll back entirely.

## 5. Private location disclosure

Policies:

- `public_immediately`;
- `after_confirmation`;
- `before_event_window`;
- `manual_approval`;
- `never_in_app`.

Location disclosure events are auditable and revocable when a reservation is cancelled, subject to practical limits after disclosure.

## 6. Professional verification

Publication may require:

- verified controlling account;
- business registration verification;
- validated contact channel;
- venue ownership or operating authority evidence;
- accepted professional terms;
- moderation approval for selected categories.

Raw evidence is stored outside public tables with limited retention.

## 7. RLS and permissions

- public users see only published projections;
- entity members see operational data according to role;
- finance data is isolated from content management;
- reservation owners see only their own bookings;
- organizers never receive private identity data beyond legally justified booking fields;
- admins access restricted data through audited support workflows.

## 8. Indexes

- unique public slug indexes for entities, venues and events;
- `(status, starts_at)` on events;
- `(organizer_entity_id, status, starts_at)`;
- GiST venue public coordinates;
- `(event_id, status)` on reservations;
- partial unique active reservation per `(event_id, booking_profile_id, inventory_class_id)` where policy requires;
- capacity and expiry indexes.

## 9. Domain commands

- `CreateProfessionalEntity`
- `InviteProfessionalMember`
- `VerifyProfessionalEntity`
- `CreateVenue`
- `CreateEvent`
- `PublishEvent`
- `ReserveEventInventory`
- `ConfirmReservation`
- `CancelReservation`
- `JoinWaitlist`
- `PromoteWaitlistEntry`
- `CheckInReservation`
- `CancelEvent`

## 10. Acceptance criteria

- no event can be published by an unauthorized account;
- capacities cannot become negative or exceed total inventory;
- attendance intent cannot be treated as paid booking;
- private address disclosure follows policy and is audited;
- cancelled or suspended events cannot accept reservations;
- check-in creates qualifying evidence for later review eligibility;
- professional finance data is inaccessible to content-only roles.

## 11. Migration order

1. professional entities and memberships;
2. venues and schedules;
3. events and sessions;
4. audience rules;
5. inventory classes;
6. attendance intents;
7. reservations and check-ins;
8. media links;
9. indexes, RLS, triggers and transactional functions;
10. tests.

## 12. Codex execution contract

Codex must implement booking and inventory mutations through transactional domain services. Client-side capacity checks are advisory only and never authoritative.