# DB-02 — Consent, practices and compatibility

## Purpose

DB-02 stores what each person wants, refuses, may consider and chooses to expose. It must support discovery without turning consent into a score, a promise or a permanent authorization.

## Product principles

1. Consent is individual, contextual, revocable and never inferred from a profile field.
2. A shared couple preference is not valid until both owners have approved it.
3. A hard limit is exclusionary and must never increase compatibility.
4. A soft limit or conditional boundary requires conversation; it is not consent.
5. Compatibility is an explanation aid, not an automatic entitlement to contact or meet.
6. Private individual preferences remain in the `private` schema.
7. Public profile data is deliberately published and can be withdrawn at any time.
8. Sensitive labels must not be exposed through unrestricted analytics or logs.

## Data model

### `public.taxonomy_items`

Versioned functional vocabulary for practices, intentions, relationship styles, venue preferences and communication styles. Only active items are readable by authenticated clients.

### `private.account_taxonomy_preferences`

Individual declarations attached to one Velvet account. These rows are private by default and never directly selectable by authenticated clients.

### `public.profile_taxonomy_preferences`

Preferences deliberately attached to a managed profile. Individual, organizer and professional profiles can be updated by secure commands. Couple changes must pass through a sensitive action requiring all active owners.

### `public.profile_boundaries`

Shared boundaries and conditions. `hard_limit`, `soft_limit`, `conditional`, `open` and `enthusiastic` describe a discussion state, not consent to an act.

## Compatibility contract

A future compatibility engine may use:

- shared intentions;
- compatible venue and communication preferences;
- mutually visible interests;
- explicit exclusions derived from hard limits;
- profile type and search eligibility;
- trust, verification and moderation eligibility.

It must not use:

- private notes;
- identity-provider data;
- precise location history;
- rejected or withdrawn preferences;
- inferred sexuality, health or intimate attributes not explicitly declared;
- a hidden preference as a reason shown to another member.

Every compatibility result must expose reason codes suitable for an understandable explanation. No single numeric percentage may be presented as proof of consent.

## Couple governance

The following operations are sensitive for couple profiles:

- publish or change a shared preference;
- publish or change a shared boundary;
- change shared search preferences;
- change shared identifying or intimate declarations.

They require approval from every active owner and atomic execution. One rejection closes the request. An expired request has no effect.

## API commands

- `set_my_taxonomy_preference` writes an individual private declaration.
- `set_profile_taxonomy_preference` updates a non-couple profile through permission checks.
- `set_profile_boundary` updates a non-couple boundary through permission checks.
- Couple equivalents will be executed by the DB-01 sensitive-action engine.

## Security acceptance criteria

- No authenticated user can directly query another account’s private preferences.
- A profile member can read shared profile declarations.
- A discoverable declaration is readable only when explicitly marked visible.
- Direct client inserts, updates and deletes are revoked.
- Couple shared mutations fail unless executed through dual consent.
- Hard limits are never returned as positive matching reasons.

## Validation

```bash
npx supabase db reset
npx supabase test db
npx supabase db lint --level error
```
