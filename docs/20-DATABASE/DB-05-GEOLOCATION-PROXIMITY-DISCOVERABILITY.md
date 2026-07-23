# Velvet Database Bible — DB-05

## Geolocation, proximity and discoverability

**Status:** Proposed for validation  
**Version:** 1.0  
**Scope:** Platform Core / Community  
**Depends on:** DB-01, DB-02, DB-04

---

## 1. Purpose

This chapter defines the canonical model for location, proximity search, map display, travel mode and profile discoverability without exposing a member's precise private position.

## 2. Locked principles

1. Precise device coordinates are private operational data, never public profile data.
2. Velvet never displays a member's exact home or live position.
3. Public proximity uses coarse or derived locations and distance bands.
4. Location sharing is opt-in, purpose-limited and revocable.
5. Blocking, moderation restrictions and hard limits always override geographic matching.
6. Professional venues may publish an exact business address; community profiles may not.
7. Search results are evaluated server-side.
8. Stale positions must not be presented as current.
9. Travel mode is explicit and time-bounded.
10. Every access to precise location is restricted to trusted backend services.

## 3. Core tables

### 3.1 `profile_location_preferences`

| Column | Type | Rules |
|---|---|---|
| `profile_id` | `uuid` | PK/FK profiles |
| `location_enabled` | `boolean` | default false |
| `proximity_discovery_enabled` | `boolean` | default false |
| `map_visibility` | `text` | `hidden`, `area_only`, `approximate_pin` |
| `distance_visibility` | `text` | `hidden`, `band`, `rounded` |
| `max_search_radius_km` | `integer` | bounded server-side |
| `share_current_area` | `boolean` | default false |
| `updated_at` | `timestamptz` | trigger maintained |

### 3.2 `account_location_samples`

Private, short-lived operational positions.

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK |
| `account_id` | `uuid` | FK accounts |
| `latitude` | `numeric(9,6)` | encrypted or protected schema |
| `longitude` | `numeric(9,6)` | encrypted or protected schema |
| `accuracy_m` | `integer` | required |
| `source` | `text` | `device`, `manual`, `travel` |
| `captured_at` | `timestamptz` | required |
| `expires_at` | `timestamptz` | mandatory |
| `consent_event_id` | `uuid` | mandatory evidence |

Rules:

- no client-readable RLS policy;
- automatic deletion after expiry;
- rejected when accuracy or timestamp is implausible;
- never joined directly into public APIs.

### 3.3 `profile_location_areas`

Safe derived location used for discovery.

| Column | Type | Rules |
|---|---|---|
| `profile_id` | `uuid` | PK/FK |
| `country_code` | `char(2)` | required |
| `region_code` | `text` | nullable |
| `city_id` | `uuid` | nullable FK reference geography |
| `geohash_coarse` | `text` | coarse precision only |
| `centroid` | `geography(Point,4326)` | derived, never exact home |
| `precision_level` | `text` | `country`, `region`, `city`, `coarse_area` |
| `source` | `text` | `manual`, `derived`, `travel` |
| `valid_from` | `timestamptz` | required |
| `valid_until` | `timestamptz` | nullable |
| `updated_at` | `timestamptz` | required |

### 3.4 `profile_travel_periods`

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK |
| `profile_id` | `uuid` | FK |
| `city_id` | `uuid` | destination |
| `area_centroid` | `geography(Point,4326)` | coarse destination |
| `starts_at` | `timestamptz` | required |
| `ends_at` | `timestamptz` | required, after start |
| `visibility` | `text` | `private`, `matches`, `discoverable` |
| `status` | `text` | `planned`, `active`, `ended`, `cancelled` |
| `created_by_account_id` | `uuid` | audit |

### 3.5 `discoverability_snapshots`

Materialized eligibility state for fast search.

Fields include `profile_id`, `eligible`, `reason_codes`, `profile_type`, `country_code`, `region_code`, `city_id`, `coarse_point`, `last_activity_bucket`, `verification_level`, `updated_at`.

This table contains no precise coordinates and is rebuilt after relevant profile, trust, blocking, moderation or location changes.

### 3.6 `profile_location_blocks`

Allows a profile to exclude countries, regions, cities or coarse areas from its own visibility or results.

## 4. Distance rules

- Distance is computed between safe centroids, not raw device positions.
- Display bands: `<5 km`, `5–10 km`, `10–25 km`, `25–50 km`, `50–100 km`, `100+ km`.
- Rounded distance may never imply precision greater than stored safe location.
- Profiles with hidden distance may still be filtered by radius server-side.
- Travel location overrides home area only during its valid period and according to visibility.

## 5. Discoverability eligibility

A profile is discoverable only when all conditions are true:

- profile active and `is_discoverable = true`;
- mandatory profile modules complete;
- trust and age requirements satisfied;
- location consent compatible with requested feature;
- no blocking relation in either direction;
- no moderation or safety exclusion;
- search criteria and hard boundaries compatible;
- location data not expired when current-area mode is used.

## 6. Search pipeline

1. Resolve requesting account and active profile.
2. Validate entitlement and location consent.
3. Load safe requesting area.
4. Query eligible discoverability snapshots with PostGIS indexes.
5. Apply reciprocal search and hard-boundary filters.
6. Remove blocks, reports under protective restriction and hidden profiles.
7. Rank by compatibility, distance band, freshness and quality signals.
8. Return public projection only.

## 7. Security and RLS

- Clients cannot select `account_location_samples`.
- Profiles may manage only their own location preferences and travel periods through domain commands.
- Public APIs receive city/region labels and distance bands only.
- Admin access to precise location requires a documented safety purpose, elevated permission and audit event.
- Export requests include consent history and manually declared areas, not internal anti-abuse derivations where legally exempt.

## 8. Indexes

- GiST on `profile_location_areas.centroid`;
- GiST on `discoverability_snapshots.coarse_point`;
- btree on `(eligible, country_code, region_code, city_id)`;
- btree on `profile_travel_periods(profile_id, starts_at, ends_at, status)`;
- expiry index on `account_location_samples(expires_at)`.

## 9. Domain commands

- `EnableLocationDiscovery`
- `DisableLocationDiscovery`
- `RecordLocationSample`
- `SetManualLocationArea`
- `CreateTravelPeriod`
- `CancelTravelPeriod`
- `RebuildDiscoverabilitySnapshot`
- `SearchNearbyProfiles`

All commands are server-side, idempotent where applicable and audit sensitive changes.

## 10. Acceptance criteria

- exact community coordinates are never exposed;
- disabling location immediately excludes the profile from proximity search;
- expired samples cannot produce a current-area result;
- blocking removes both profiles from each other's results;
- travel mode activates and expires automatically;
- professional exact addresses remain separated from community location data;
- all proximity queries use indexed safe geography.

## 11. Migration order

1. enable required PostGIS extension;
2. geography reference tables;
3. location preferences;
4. private samples;
5. safe profile areas;
6. travel periods;
7. location exclusions;
8. discoverability snapshots;
9. indexes, RLS and expiry jobs;
10. integration and privacy tests.

## 12. Codex execution contract

Codex must not expose raw latitude/longitude through client types, GraphQL/REST payloads, logs, analytics or error messages. Any implementation that bypasses safe derived areas is non-compliant.