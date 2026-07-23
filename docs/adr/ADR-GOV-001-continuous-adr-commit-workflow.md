# ADR-GOV-001 – Continuous ADR Commit Workflow

Status: Accepted

## Decision

Every product ADR explicitly accepted by the product owner must be documented and committed immediately before the next ADR discussion begins.

## Required workflow

For each accepted ADR:

1. Write or update the normative ADR file.
2. Update the validated decision registry.
3. Update any directly impacted product specification when necessary.
4. Create a dedicated Git commit using a clear Conventional Commit message.
5. Keep the commit focused on that ADR and its required documentation changes.
6. Do not reopen the accepted decision unless a later ADR explicitly amends or supersedes it.

## Development handoff

Each ADR should also identify implementation impacts when relevant, including front end, back end, data model, APIs, moderation, artificial intelligence, privacy, security and administration.

Implementation work may follow in separate commits or pull requests. The ADR commit remains the authoritative record of the product decision.

## Operating rule

The phrase “Go commits” means: apply the validated changes to the active GitHub repository and branch, create the real commit or commits, and report the resulting commit references. It does not mean merely proposing commit messages.
