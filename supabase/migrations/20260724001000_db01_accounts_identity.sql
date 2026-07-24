begin;

create type public.account_status as enum (
  'pending_onboarding',
  'active',
  'restricted',
  'suspended',
  'deletion_requested',
  'deleted'
);

create type public.verification_level as enum (
  'none',
  'email_verified',
  'phone_verified',
  'age_verified',
  'identity_verified',
  'enhanced_verified'
);

create table public.accounts (
  id uuid primary key default extensions.gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete restrict,
  status public.account_status not null default 'pending_onboarding',
  primary_email extensions.citext not null,
  email_verified_at timestamptz,
  phone_e164 text,
  phone_verified_at timestamptz,
  verification_level public.verification_level not null default 'none',
  onboarding_completed_at timestamptz,
  last_active_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  constraint accounts_primary_email_not_blank check (length(trim(primary_email::text)) > 3),
  constraint accounts_phone_e164_format check (phone_e164 is null or phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  constraint accounts_deleted_state_consistency check (
    (status = 'deleted' and deleted_at is not null)
    or (status <> 'deleted')
  )
);

create unique index accounts_primary_email_active_uq
  on public.accounts (primary_email)
  where deleted_at is null;

create unique index accounts_phone_e164_active_uq
  on public.accounts (phone_e164)
  where phone_e164 is not null and deleted_at is null;

create index accounts_status_idx on public.accounts (status);
create index accounts_last_active_idx on public.accounts (last_active_at desc);

create trigger accounts_set_updated_at
before update on public.accounts
for each row execute function public.set_updated_at();

create table private.account_identities (
  account_id uuid primary key references public.accounts(id) on delete cascade,
  legal_first_name text not null,
  legal_last_name text not null,
  date_of_birth date not null,
  country_code char(2) not null,
  identity_gender text,
  verification_provider_subject text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint account_identities_country_code_format check (country_code ~ '^[A-Z]{2}$'),
  constraint account_identities_adult check (date_of_birth <= (current_date - interval '18 years')::date),
  constraint account_identities_legal_first_name_not_blank check (length(trim(legal_first_name)) > 0),
  constraint account_identities_legal_last_name_not_blank check (length(trim(legal_last_name)) > 0)
);

create trigger account_identities_set_updated_at
before update on private.account_identities
for each row execute function public.set_updated_at();

create table private.account_settings (
  account_id uuid primary key references public.accounts(id) on delete cascade,
  locale text not null default 'fr-FR',
  timezone text not null default 'Europe/Paris',
  marketing_email_opt_in boolean not null default false,
  product_email_opt_in boolean not null default true,
  push_opt_in boolean not null default false,
  analytics_opt_in boolean not null default false,
  discoverability_default boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint account_settings_locale_not_blank check (length(trim(locale)) > 0),
  constraint account_settings_timezone_not_blank check (length(trim(timezone)) > 0)
);

create trigger account_settings_set_updated_at
before update on private.account_settings
for each row execute function public.set_updated_at();

alter table public.accounts enable row level security;

create policy accounts_select_self
on public.accounts
for select
to authenticated
using (auth_user_id = auth.uid() and deleted_at is null);

create policy accounts_update_self_limited
on public.accounts
for update
to authenticated
using (auth_user_id = auth.uid() and deleted_at is null)
with check (auth_user_id = auth.uid() and deleted_at is null);

revoke insert, delete on public.accounts from anon, authenticated;
revoke all on private.account_identities from anon, authenticated;
revoke all on private.account_settings from anon, authenticated;

grant select, update on public.accounts to authenticated;
grant all on public.accounts, private.account_identities, private.account_settings to service_role;

commit;
