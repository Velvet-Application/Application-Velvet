begin;

create type public.profile_type as enum ('individual','couple','organizer','professional');
create type public.profile_status as enum ('draft','pending_members','pending_verification','active','hidden','restricted','suspended','archived','deleted');
create type public.profile_membership_role as enum ('owner','co_owner','manager','contributor','viewer');
create type public.membership_status as enum ('invited','active','declined','revoked','left');

create table public.profiles (
  id uuid primary key default extensions.gen_random_uuid(),
  type public.profile_type not null,
  status public.profile_status not null default 'draft',
  display_name text not null,
  slug extensions.citext not null,
  short_bio text,
  primary_locale text not null default 'fr-FR',
  country_code char(2) not null,
  is_discoverable boolean not null default false,
  discoverable_since timestamptz,
  created_by_account_id uuid not null references public.accounts(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  archived_at timestamptz,
  deleted_at timestamptz,
  constraint profiles_display_name_not_blank check (length(trim(display_name)) between 2 and 80),
  constraint profiles_slug_format check (slug::text ~ '^[a-z0-9][a-z0-9-]{2,49}$'),
  constraint profiles_country_code_format check (country_code ~ '^[A-Z]{2}$'),
  constraint profiles_discoverability_consistency check (
    (is_discoverable = false and discoverable_since is null)
    or (is_discoverable = true and discoverable_since is not null and status = 'active')
  ),
  constraint profiles_archived_consistency check (status <> 'archived' or archived_at is not null),
  constraint profiles_deleted_consistency check (status <> 'deleted' or deleted_at is not null)
);

create unique index profiles_slug_active_uq on public.profiles(slug) where deleted_at is null;
create index profiles_type_status_idx on public.profiles(type, status);
create index profiles_discoverable_idx on public.profiles(updated_at desc) where status = 'active' and is_discoverable and deleted_at is null;
create index profiles_creator_idx on public.profiles(created_by_account_id);

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

create table public.profile_memberships (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  account_id uuid not null references public.accounts(id) on delete restrict,
  role public.profile_membership_role not null,
  status public.membership_status not null default 'invited',
  invited_by_account_id uuid references public.accounts(id) on delete restrict,
  invitation_token_hash text,
  invited_at timestamptz,
  accepted_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profile_memberships_invitation_consistency check (
    status <> 'invited' or (invited_by_account_id is not null and invited_at is not null and invitation_token_hash is not null)
  ),
  constraint profile_memberships_active_consistency check (status <> 'active' or accepted_at is not null),
  constraint profile_memberships_ended_consistency check (
    status not in ('declined','revoked','left') or ended_at is not null
  )
);

create unique index profile_memberships_current_uq
  on public.profile_memberships(profile_id, account_id)
  where ended_at is null;
create index profile_memberships_account_idx on public.profile_memberships(account_id, status);
create index profile_memberships_profile_idx on public.profile_memberships(profile_id, status, role);

create trigger profile_memberships_set_updated_at before update on public.profile_memberships
for each row execute function public.set_updated_at();

create or replace function private.enforce_profile_membership_invariants()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  p_type public.profile_type;
  active_owner_count integer;
begin
  select type into p_type from public.profiles where id = coalesce(new.profile_id, old.profile_id) for update;

  if tg_op in ('UPDATE','DELETE') and old.status = 'active' and old.role in ('owner','co_owner') then
    select count(*) into active_owner_count
    from public.profile_memberships pm
    where pm.profile_id = old.profile_id
      and pm.status = 'active'
      and pm.role in ('owner','co_owner')
      and pm.id <> old.id;

    if active_owner_count = 0 then
      raise exception 'VELVET_FINAL_OWNER_REQUIRED' using errcode = '23514';
    end if;
  end if;

  if tg_op <> 'DELETE' and p_type = 'individual' and new.status = 'active' and new.role <> 'owner' then
    raise exception 'VELVET_INDIVIDUAL_PROFILE_SINGLE_OWNER' using errcode = '23514';
  end if;

  return coalesce(new, old);
end;
$$;

create constraint trigger profile_memberships_invariants
  after update or delete on public.profile_memberships
  deferrable initially deferred
  for each row execute function private.enforce_profile_membership_invariants();

alter table public.profiles enable row level security;
alter table public.profile_memberships enable row level security;

create policy profiles_select_member
on public.profiles for select to authenticated
using (
  deleted_at is null and exists (
    select 1 from public.profile_memberships pm
    where pm.profile_id = profiles.id
      and pm.account_id = public.current_account_id()
      and pm.status = 'active'
  )
);

create policy profiles_select_discoverable
on public.profiles for select to authenticated
using (status = 'active' and is_discoverable and deleted_at is null);

create policy memberships_select_own_profiles
on public.profile_memberships for select to authenticated
using (
  account_id = public.current_account_id()
  or exists (
    select 1 from public.profile_memberships mine
    where mine.profile_id = profile_memberships.profile_id
      and mine.account_id = public.current_account_id()
      and mine.status = 'active'
  )
);

revoke insert, update, delete on public.profiles, public.profile_memberships from anon, authenticated;
grant select on public.profiles, public.profile_memberships to authenticated;
grant all on public.profiles, public.profile_memberships to service_role;

commit;
