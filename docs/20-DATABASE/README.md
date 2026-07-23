# Velvet Database Bible

This directory is the canonical source for Velvet data architecture, domain rules, permissions, constraints, security boundaries and implementation order.

## Chapters

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

The ten domain chapters are now drafted. Before implementation, the Bible must pass a cross-chapter consistency review covering naming, enumerations, foreign keys, data classification, retention rules, permissions and unresolved product decisions.

## Rule

No migration or domain implementation may contradict an accepted chapter without a new documented architecture decision.