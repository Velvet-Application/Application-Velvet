# Velvet Database Bible — DB-04

## Conversations, messaging and interaction permissions

**Status:** Proposed for validation  
**Version:** 1.0  
**Scope:** Platform Core / Community  
**Applies to:** Community, Professionals, Administration  
**Related chapters:** DB-01, DB-02, DB-03

---

## 1. Purpose

This document defines the canonical data model and business rules for:

- direct and group conversations;
- profile-to-profile messaging;
- message membership and sender identity;
- requests to initiate contact;
- read state and delivery state;
- attachments and private media references;
- blocking, muting, reporting and moderation holds;
- consent-aware interaction permissions;
- retention, deletion and audit boundaries.

Application code, APIs, migrations and tests must conform to this chapter.

---

## 2. Locked product principles

1. Conversations occur between profiles, while every action remains attributable to an authenticated account.
2. A shared profile may be represented by several accounts, but each message stores the acting account for audit.
3. No profile can force another profile into an active conversation.
4. First contact may require an explicit message request depending on recipient settings.
5. A block immediately prevents new interaction in both directions.
6. A mute affects notifications only and does not revoke access.
7. Deleting a message from the sender interface does not erase moderation or legal evidence when retention is required.
8. Private media access is never inferred from conversation membership; DB-03 access grants remain authoritative.
9. Sensitive interaction rules are evaluated server-side on every write.
10. Moderators may restrict access without exposing reporter identity or internal notes.

---

## 3. Domain model

```text
Profile A ── Interaction Policy ── Profile B
    │                                  │
    └──────── Conversation ────────────┘
                   │
          Conversation Members
                   │
                Messages
                   │
       Receipts / Reactions / Attachments
```

The visible sender is a profile. The accountable actor is an account with an active membership and sufficient permission on that profile.

---

## 4. Enumerations

### 4.1 `conversation_type`

- `direct`
- `group`
- `event_thread`
- `support`
- `professional_inquiry`

### 4.2 `conversation_status`

- `pending_request`
- `active`
- `restricted`
- `closed`
- `archived`

### 4.3 `conversation_member_status`

- `invited`
- `active`
- `left`
- `removed`
- `blocked`

### 4.4 `message_type`

- `text`
- `media_reference`
- `album_access_event`
- `system`
- `event_share`
- `location_share`

### 4.5 `message_status`

- `created`
- `sent`
- `moderation_held`
- `rejected`
- `redacted`
- `deleted_for_sender`

### 4.6 `interaction_request_status`

- `pending`
- `accepted`
- `declined`
- `expired`
- `cancelled`
- `blocked`

### 4.7 `block_scope`

- `profile_to_profile`
- `account_to_profile`
- `account_to_account`
- `platform_enforced`

---

## 5. Tables

## 5.1 `conversations`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK |
| `type` | `conversation_type` | no | |
| `status` | `conversation_status` | no | Default `pending_request` or `active` |
| `created_by_profile_id` | `uuid` | no | FK profiles |
| `created_by_account_id` | `uuid` | no | Audit actor |
| `subject` | `text` | yes | Required only for selected group/pro contexts |
| `last_message_id` | `uuid` | yes | Denormalized pointer |
| `last_activity_at` | `timestamptz` | no | Indexed |
| `created_at` | `timestamptz` | no | |
| `closed_at` | `timestamptz` | yes | |
| `deleted_at` | `timestamptz` | yes | Soft deletion |

Rules:

- a direct conversation must contain exactly two active profile participants;
- only one non-closed direct conversation may exist for the same normalized pair of profiles;
- creation must pass interaction policy checks;
- `last_message_id` is maintained transactionally.

Indexes:

- `conversations(last_activity_at desc)`;
- `conversations(type, status)`;
- partial index for active conversations.

---

## 5.2 `conversation_members`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK |
| `conversation_id` | `uuid` | no | FK |
| `profile_id` | `uuid` | no | Participating profile |
| `status` | `conversation_member_status` | no | |
| `joined_at` | `timestamptz` | yes | |
| `left_at` | `timestamptz` | yes | |
| `last_read_message_id` | `uuid` | yes | Read cursor |
| `last_read_at` | `timestamptz` | yes | |
| `muted_until` | `timestamptz` | yes | Null means not muted |
| `archived_at` | `timestamptz` | yes | Personal archive state |
| `created_at` | `timestamptz` | no | |

Constraints:

- unique `(conversation_id, profile_id)`;
- a member cannot read messages older than their authorized join boundary unless explicitly permitted;
- leaving a direct conversation closes or restricts it according to policy;
- muting does not modify membership or access rights.

Indexes:

- `conversation_members(profile_id, status)`;
- `conversation_members(conversation_id, status)`.

---

## 5.3 `interaction_requests`

Represents first-contact requests before an active conversation exists.

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK |
| `requester_profile_id` | `uuid` | no | FK |
| `requester_account_id` | `uuid` | no | Audit actor |
| `recipient_profile_id` | `uuid` | no | FK |
| `intro_message` | `text` | yes | Moderated, length-limited |
| `status` | `interaction_request_status` | no | Default `pending` |
| `conversation_id` | `uuid` | yes | Set on acceptance |
| `expires_at` | `timestamptz` | no | |
| `responded_by_account_id` | `uuid` | yes | Audit actor |
| `responded_at` | `timestamptz` | yes | |
| `created_at` | `timestamptz` | no | |

Constraints:

- no pending duplicate for the same profile pair;
- blocked or restricted pairs cannot create requests;
- acceptance and conversation creation occur in one transaction;
- decline does not disclose internal reason to the requester.

---

## 5.4 `messages`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK, time-sortable UUID preferred |
| `conversation_id` | `uuid` | no | FK |
| `sender_profile_id` | `uuid` | no | Visible sender |
| `sender_account_id` | `uuid` | no | Accountable actor |
| `type` | `message_type` | no | |
| `status` | `message_status` | no | |
| `body_ciphertext` | `text` | yes | Encrypted application payload |
| `body_preview` | `text` | yes | Optional safe preview, never for sensitive content |
| `reply_to_message_id` | `uuid` | yes | Same conversation only |
| `client_message_id` | `uuid` | no | Idempotency key |
| `edited_at` | `timestamptz` | yes | |
| `redacted_at` | `timestamptz` | yes | |
| `created_at` | `timestamptz` | no | |

Constraints:

- unique `(sender_account_id, client_message_id)`;
- sender account must hold an active role on `sender_profile_id` with `send_message` permission;
- sender profile must be an active conversation member;
- the conversation must be active and not blocked;
- edits preserve immutable revision history;
- client writes never set moderation status directly.

Indexes:

- `messages(conversation_id, created_at desc, id)`;
- `messages(sender_profile_id, created_at desc)`;
- partial index for moderation-held messages.

---

## 5.5 `message_revisions`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK |
| `message_id` | `uuid` | no | FK |
| `revision_number` | `integer` | no | Monotonic |
| `body_ciphertext` | `text` | yes | Previous content |
| `changed_by_account_id` | `uuid` | no | |
| `change_reason` | `text` | yes | System/moderation code |
| `created_at` | `timestamptz` | no | |

Unique `(message_id, revision_number)`.

---

## 5.6 `message_attachments`

References DB-03 assets without granting access by itself.

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK |
| `message_id` | `uuid` | no | FK |
| `media_asset_id` | `uuid` | yes | FK DB-03 |
| `album_id` | `uuid` | yes | FK DB-03 |
| `attachment_kind` | `text` | no | `media`, `album`, `event`, `location` |
| `position` | `smallint` | no | |
| `created_at` | `timestamptz` | no | |

Exactly one target reference must be present according to `attachment_kind`. Authorization is reevaluated when viewed.

---

## 5.7 `message_receipts`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `message_id` | `uuid` | no | Composite PK |
| `profile_id` | `uuid` | no | Composite PK |
| `delivered_at` | `timestamptz` | yes | |
| `read_at` | `timestamptz` | yes | Controlled by privacy settings |

Rules:

- read receipts may be disabled by policy;
- internal read cursor may still exist for unread counts without exposing it to the sender;
- receipts are not generated for the sender profile.

---

## 5.8 `message_reactions`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `message_id` | `uuid` | no | Composite PK |
| `profile_id` | `uuid` | no | Composite PK |
| `reaction_key` | `text` | no | Allowlisted values only |
| `acted_by_account_id` | `uuid` | no | Audit actor |
| `created_at` | `timestamptz` | no | |

Unique `(message_id, profile_id, reaction_key)`.

---

## 5.9 `interaction_blocks`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK |
| `actor_account_id` | `uuid` | no | Private actor |
| `actor_profile_id` | `uuid` | yes | Optional profile context |
| `target_account_id` | `uuid` | yes | |
| `target_profile_id` | `uuid` | yes | |
| `scope` | `block_scope` | no | |
| `reason_code` | `text` | yes | Private |
| `created_at` | `timestamptz` | no | |
| `revoked_at` | `timestamptz` | yes | |

Rules:

- at least one target must exist;
- block existence is private and exposed only as a generic interaction denial;
- active block immediately prevents requests, messages, reactions and access initiated through conversation context;
- platform-enforced blocks are reversible only by authorized moderation services.

---

## 5.10 `conversation_moderation_actions`

| Column | Type | Null | Rules |
|---|---|---:|---|
| `id` | `uuid` | no | PK |
| `conversation_id` | `uuid` | no | FK |
| `message_id` | `uuid` | yes | Optional target |
| `action_type` | `text` | no | `hold`, `redact`, `restrict`, `close`, `restore` |
| `reason_code` | `text` | no | Internal normalized code |
| `performed_by_account_id` | `uuid` | yes | Null for automated system |
| `metadata` | `jsonb` | no | Sanitized, no secret tokens |
| `created_at` | `timestamptz` | no | Immutable |

---

## 6. Interaction permission evaluation

Before creating a request, conversation or message, the server must evaluate in this order:

1. authenticated account status;
2. active membership and role permission on acting profile;
3. acting and target profile status;
4. active blocks and moderation restrictions;
5. recipient interaction settings;
6. compatibility with strict boundaries and consent rules from DB-02;
7. conversation membership and status;
8. rate limits and anti-spam rules;
9. content moderation prechecks;
10. attachment authorization under DB-03.

A denial returns a generic public error code. Sensitive reasons remain server-side.

---

## 7. Shared-profile rules

For a couple or other shared profile:

- any authorized member may send routine messages under the shared profile;
- `sender_account_id` is always retained for internal audit;
- the recipient sees the shared profile as sender, not the legal identity of the actor;
- each member may choose whether internal attribution is visible to co-members;
- removing a member instantly removes their ability to send or read future messages as that profile;
- historical audit attribution remains immutable;
- sensitive attachments remain subject to joint consent rules in DB-03.

---

## 8. Privacy, retention and deletion

- Conversation list APIs expose only conversations accessible to the active profile.
- Message bodies are encrypted at rest outside database-native transparent transport encryption.
- Search indexes must never contain plaintext private message bodies unless a separately approved secure architecture exists.
- User deletion removes active access and applies the retention/anonymization rules defined later in DB-10.
- A user may hide a message locally without deleting it for other participants.
- Moderation evidence may be retained for a justified limited period.
- Export workflows must distinguish profile-visible content from internal moderation metadata.

---

## 9. RLS and service boundaries

Client-side direct writes are forbidden for:

- conversation creation;
- interaction request acceptance;
- message moderation state;
- blocks involving platform enforcement;
- revisions and redactions;
- membership removal;
- attachment access grants.

RLS requirements:

- select conversations only through active profile membership;
- select messages only when the active profile is an authorized member and no platform restriction denies access;
- insert messages only through a controlled server command;
- block records are visible only to their actor and trusted services;
- moderation actions are invisible to ordinary users.

---

## 10. Transactional workflows

### 10.1 Accept interaction request

One transaction must:

1. lock the request;
2. reevaluate blocks and permissions;
3. mark request accepted;
4. create or reuse the direct conversation;
5. add both profile members;
6. persist optional intro message;
7. write audit events;
8. enqueue notifications after commit.

### 10.2 Send message

One transaction must:

1. validate idempotency key;
2. lock/check conversation state;
3. reevaluate sender permission and block state;
4. validate content and attachments;
5. insert message;
6. update conversation activity pointer;
7. create moderation event if held;
8. enqueue delivery after commit.

### 10.3 Block profile

One transaction must:

1. create active block;
2. cancel pending requests;
3. restrict matching direct conversations;
4. revoke conversation-derived ephemeral capabilities;
5. write audit event;
6. suppress future notifications between parties.

---

## 11. Required domain commands

- `requestConversation`
- `acceptInteractionRequest`
- `declineInteractionRequest`
- `cancelInteractionRequest`
- `sendMessage`
- `editMessage`
- `deleteMessageForSelf`
- `reactToMessage`
- `markConversationRead`
- `muteConversation`
- `archiveConversation`
- `leaveConversation`
- `blockInteraction`
- `unblockInteraction`
- `reportMessage`
- `moderateMessage`

Each command must be idempotent where applicable and emit an audit event for sensitive mutations.

---

## 12. Acceptance criteria

1. A profile cannot message a recipient who has blocked it.
2. A direct conversation cannot be duplicated for the same pair.
3. A shared profile message is attributable internally to the acting account.
4. Removing a profile member revokes future conversation access immediately.
5. Message attachments do not bypass DB-03 access rules.
6. Read receipts respect recipient privacy settings.
7. Pending requests cannot generate unrestricted messaging.
8. Moderation-held messages are not delivered before release.
9. Client-supplied sender profile IDs are validated against active memberships.
10. Block reasons and reporter identities are never exposed to the blocked party.

---

## 13. Required tests

### Unit

- normalized profile-pair uniqueness;
- interaction permission evaluator;
- shared-profile sender authorization;
- idempotent send behavior;
- block precedence;
- receipt visibility rules.

### Integration

- request acceptance creates one conversation;
- concurrent request acceptance is safe;
- concurrent sends preserve ordering and last-message pointer;
- member removal revokes access;
- media attachment authorization is reevaluated;
- block restricts active conversation immediately.

### Security

- forged profile sender rejected;
- cross-conversation message access rejected;
- hidden block metadata inaccessible;
- moderation tables inaccessible to clients;
- replayed client message ID does not duplicate content;
- deleted or suspended account cannot send.

---

## 14. Migration order

1. enums;
2. conversations;
3. conversation members;
4. interaction requests;
5. messages;
6. message revisions;
7. attachments;
8. receipts and reactions;
9. blocks;
10. moderation actions;
11. indexes and constraints;
12. RLS policies;
13. domain services and tests.

---

## 15. Codex implementation contract

Codex must:

- preserve profile-facing identity and account-level audit identity separately;
- place all write logic in domain services, never in UI pages;
- implement interaction checks as a reusable policy service;
- use transactions for the workflows defined above;
- implement idempotency for message creation and request acceptance;
- avoid plaintext logging of message bodies;
- create tests before exposing messaging routes;
- document every deviation through a new ADR before implementation.

No real-time transport choice is locked by this chapter. WebSocket, Supabase Realtime or another mechanism may transport events, but the database remains the source of truth.
