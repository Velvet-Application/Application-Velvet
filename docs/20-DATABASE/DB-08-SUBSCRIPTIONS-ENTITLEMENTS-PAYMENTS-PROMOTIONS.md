# Velvet Database Bible — DB-08

## Subscriptions, entitlements, payments and promotions

**Status:** Proposed for validation  
**Version:** 1.0  
**Scope:** Platform Core / Community / Professionals  
**Depends on:** DB-01, DB-06, DB-07

---

## 1. Purpose

This chapter defines the canonical commercial model for plans, subscriptions, entitlements, payments, refunds, promotions and professional billing.

## 2. Locked principles

1. Product access is controlled by entitlements, not by hardcoded plan names.
2. Payment providers are external processors; Velvet stores normalized references and accounting state.
3. Safety and moderation restrictions override paid entitlements.
4. A subscription belongs to a billing account or professional entity, not directly to a public profile.
5. Shared profiles may benefit from account entitlements according to explicit allocation rules.
6. Prices and tax context are snapshotted at purchase time.
7. Webhooks are untrusted until signature and idempotency validation succeed.
8. Refunds and disputes never delete financial history.
9. Promotions are bounded, auditable and abuse-resistant.
10. No card or bank credential is stored by Velvet.

## 3. Core tables

### 3.1 `products`

Fields: `id`, `code`, `audience`, `name`, `description`, `status`, timestamps.

Audience: `community`, `professional`, `event`, `mixed`.

### 3.2 `prices`

Fields: `id`, `product_id`, `provider`, `provider_price_id`, `currency`, `unit_amount`, `billing_interval`, `interval_count`, `tax_behavior`, `country_scope`, `active_from`, `active_until`, `status`.

Prices are immutable after use; corrections create new rows.

### 3.3 `features`

Canonical feature registry with stable keys such as `private_album_grants`, `advanced_filters`, `travel_mode`, `unlimited_contact_requests`, `professional_booking_tools`, `analytics_dashboard`.

### 3.4 `product_entitlements`

Maps a product to feature limits or capabilities.

Fields: `product_id`, `feature_id`, `value_type`, `boolean_value`, `integer_value`, `text_value`, `reset_period`, timestamps.

### 3.5 `billing_customers`

Links an account or professional entity to a provider customer reference. Contains no payment credentials.

### 3.6 `subscriptions`

Fields: `id`, `billing_customer_id`, `product_id`, `price_id`, `provider_subscription_id`, `status`, `current_period_start`, `current_period_end`, `cancel_at_period_end`, `cancelled_at`, `trial_start`, `trial_end`, `quantity`, timestamps.

Statuses: `incomplete`, `trialing`, `active`, `past_due`, `paused`, `cancelled`, `unpaid`, `expired`.

### 3.7 `entitlement_grants`

Effective grants from subscriptions, promotions, partnerships, administration or grandfathering.

Fields: `id`, `beneficiary_type`, `beneficiary_id`, `feature_id`, `source_type`, `source_id`, value fields, `starts_at`, `ends_at`, `revoked_at`, `priority`, timestamps.

### 3.8 `entitlement_allocations`

Explicitly allocates an account entitlement to one or more eligible profiles where product policy requires.

### 3.9 `payment_transactions`

Normalized provider events for charges, invoices, payment intents and transfers.

Fields include provider IDs, amount, currency, status, transaction type, billing customer, subscription/reservation reference, timestamps, provider payload hash.

### 3.10 `refunds`

Fields: `id`, `payment_transaction_id`, `provider_refund_id`, `amount`, `currency`, `reason_code`, `status`, `requested_by_account_id`, timestamps.

### 3.11 `payment_disputes`

Tracks provider disputes, evidence deadlines and resolution without exposing provider secrets.

### 3.12 `promotion_campaigns`

Fields: `id`, `code`, `name`, `status`, `benefit_type`, benefit value, `starts_at`, `ends_at`, `max_redemptions`, `max_per_account`, eligibility rule reference, timestamps.

### 3.13 `promotion_redemptions`

Unique redemption history linked to account/entity, campaign, subscription or order.

### 3.14 `provider_webhook_events`

Fields: provider event ID, event type, signature validation status, payload hash, processing status, attempts, error code, received/processed timestamps.

## 4. Effective entitlement resolution

1. Identify authenticated account and selected profile/entity.
2. Load active, non-expired grants.
3. Apply beneficiary and allocation rules.
4. Resolve feature values by priority and restrictive safety overrides.
5. Apply usage counters and reset windows.
6. Return an explainable entitlement result with source references safe for internal debugging.

No page or API may infer entitlement from a plan name alone.

## 5. Subscription lifecycle

- provider webhook is authoritative for external payment state;
- local transitions are idempotent;
- grace periods are explicit policy, not implicit delays;
- cancellation may preserve access until period end;
- past-due access follows product policy;
- deletion requests do not remove legally required financial records;
- account suspension blocks use without altering paid transaction history.

## 6. Promotions and referral controls

- normalized unique codes;
- campaign date and inventory limits;
- per-account, device, payment instrument and household abuse signals where lawful;
- no self-referral benefit without explicit policy;
- redemption is transactional;
- revocation records reason and preserves history;
- promotional grants expire independently of subscription state.

## 7. RLS and permissions

- users see their own customer, subscription, invoice summaries and entitlements;
- professional finance roles see their entity billing only;
- public profiles never expose billing status;
- provider payloads and webhook records are backend/admin only;
- support adjustments require elevated permission, reason and audit event;
- no client can directly create an entitlement grant.

## 8. Indexes and constraints

- unique provider customer, subscription, transaction, refund, dispute and webhook IDs;
- `(billing_customer_id, status)` on subscriptions;
- `(beneficiary_type, beneficiary_id, feature_id, starts_at, ends_at)` on grants;
- unique valid promotion code;
- unique campaign/account redemption according to campaign rules;
- expiry indexes for grants and promotions;
- amount values non-negative and currency immutable after transaction creation.

## 9. Domain commands

- `CreateCheckoutSession`
- `CreateBillingPortalSession`
- `ProcessProviderWebhook`
- `ActivateSubscription`
- `CancelSubscription`
- `ResolveEntitlements`
- `AllocateEntitlementToProfile`
- `RedeemPromotion`
- `GrantAdministrativeEntitlement`
- `RevokeEntitlement`
- `RequestRefund`
- `RecordDispute`

## 10. Acceptance criteria

- duplicate webhooks cannot duplicate grants or transactions;
- cancelling a subscription follows period-end policy exactly;
- a moderation suspension prevents feature use despite active payment;
- client code cannot grant premium access;
- historical prices and taxes remain reconstructable;
- promotion limits are enforced atomically;
- shared-profile access follows explicit allocations;
- financial records survive account anonymization where legally required.

## 11. Migration order

1. products, prices and features;
2. product entitlements;
3. billing customers and subscriptions;
4. entitlement grants and allocations;
5. transactions, refunds and disputes;
6. promotions and redemptions;
7. webhook inbox;
8. usage counters, indexes, RLS and jobs;
9. provider integration tests.

## 12. Codex execution contract

Codex must use an entitlement service as the only product-access authority. It must never store raw payment credentials or trust client-reported payment success.