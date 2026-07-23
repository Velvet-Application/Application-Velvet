# Velvet Database Bible

This directory is the canonical source for Velvet data architecture, domain rules, permissions, constraints, security boundaries and implementation order.

## Cross-cutting contract

- [DB-00 — Cross-cutting data contract and coherence review](./DB-00-CROSS-CUTTING-DATA-CONTRACT.md)
- [Schema implementation manifest](./SCHEMA-IMPLEMENTATION-MANIFEST.md)

DB-00 has precedence when a cross-domain naming, authorization, audit, classification, retention or lifecycle convention requires clarification.

## Domain chapters

- [DB-01 — Accounts, identities, profiles and shared profile governance](./DB-01-ACCOUNTS-PROFILES-IDENTITIES.md)
- [DB-02 — Profile modules, searches, practices, limits and consent](./DB-02-PROFILE-MODULES-SEARCH-PRACTICES-LIMITS-CONSENT.md)
- [DB-03 — Media, albums, videos and access grants](./DB-03-MEDIA-ALBUMS-VIDEOS-ACCESS-GRANTS.md)
- [DB-04 — Conversations, messaging and interaction permissions](./DB-04-CONVERSATIONS-MESSAGING-INTERACTION-PERMISSIONS.md)
- [DB-05 — Geolocation, proximity and discoverability](./DB-05-GEOLOCATION-PROXIMITY-DISCOVERABILITY.md)
- [DB-06 — Events, organizers, clubs and professional entities](./DB-06-EVENTS-ORGANIZERS-CLUBS-PROFESSIONAL-ENTITIES.md)
- [DB-07 — Trust, verification, reviews, reports and moderation](./DB-07-TRUST-VERIFICATION-REVIEWS-REPORTS-MODERATION.md)
- [DB-08 — Subscriptions, entitlements, payments and promotions](./DB-08-SUBSCRIPTIONS-ENTITLEMENTS-PAYMENTS-PROMOTIONS.md)
- [DB-09 — Notifications, devices, preferences and delivery logs](./DB-09-NOTIFICATIONS-DEVICES-PREFERENCES-DELIVERY-LOGS.md)
- [DB-10 — GDPR retention, audit, deletion and anonymization](./DB-10-GDPR-RETENTION-AUDIT-DELETION-ANONYMIZATION.md)

## Status

The cross-chapter consistency review is complete.

The Database Bible now defines:

- canonical ownership and actor attribution;
- naming and identifier conventions;
- enum and catalog strategy;
- authorization and visibility precedence;
- shared-profile governance;
- consent and data classification rules;
- audit, retention, deletion and anonymization boundaries;
- RLS foundations;
- ordered migration phases, tests and CI quality gates.

The documentation is ready to drive executable PostgreSQL/Supabase schema implementation through Codex.

## Rule

No migration or domain implementation may contradict DB-00 or an accepted domain chapter without a new documented architecture decision.