begin;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create extension if not exists postgis with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists btree_gist with schema extensions;

create schema if not exists private;
create schema if not exists audit;
create schema if not exists billing;

comment on schema private is 'Velvet private operational data; never exposed through client APIs.';
comment on schema audit is 'Immutable security, consent and administrative audit records.';
comment on schema billing is 'Payment-provider references, subscriptions and entitlement infrastructure.';

revoke all on schema private from public, anon, authenticated;
revoke all on schema audit from public, anon, authenticated;
revoke all on schema billing from public, anon, authenticated;

grant usage on schema public to anon, authenticated, service_role;
grant usage on schema private, audit, billing to service_role;

commit;
