begin;

create table private.account_taxonomy_preferences (
  account_id uuid not null references public.accounts(id) on delete cascade,
  taxonomy_item_id uuid not null references public.taxonomy_items(id) on delete cascade,
  level public.preference_level not null,
  note text,
  visible_to_profile_members boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key(account_id, taxonomy_item_id),
  constraint account_taxonomy_preferences_note_length check (note is null or length(note) <= 500)
);

create trigger account_taxonomy_preferences_set_updated_at
before update on private.account_taxonomy_preferences
for each row execute function public.set_updated_at();

create table public.profile_taxonomy_preferences (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  taxonomy_item_id uuid not null references public.taxonomy_items(id) on delete cascade,
  level public.preference_level not null,
  source text not null default 'declared',
  visible_on_profile boolean not null default false,
  created_by_account_id uuid not null references public.accounts(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key(profile_id, taxonomy_item_id),
  constraint profile_taxonomy_preferences_source_check check (source in ('declared','joint_decision','derived'))
);

create trigger profile_taxonomy_preferences_set_updated_at
before update on public.profile_taxonomy_preferences
for each row execute function public.set_updated_at();

create table public.profile_boundaries (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  taxonomy_item_id uuid references public.taxonomy_items(id) on delete restrict,
  custom_label text,
  level public.boundary_level not null,
  conditions text,
  visible_to_matches boolean not null default false,
  jointly_confirmed_at timestamptz,
  created_by_account_id uuid not null references public.accounts(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profile_boundaries_subject_required check (
    taxonomy_item_id is not null or length(trim(coalesce(custom_label,''))) between 2 and 120
  ),
  constraint profile_boundaries_conditions_length check (conditions is null or length(conditions) <= 1000)
);

create unique index profile_boundaries_taxonomy_uq
  on public.profile_boundaries(profile_id, taxonomy_item_id)
  where taxonomy_item_id is not null;

create index profile_boundaries_profile_level_idx
  on public.profile_boundaries(profile_id, level);

create trigger profile_boundaries_set_updated_at
before update on public.profile_boundaries
for each row execute function public.set_updated_at();

alter table public.profile_taxonomy_preferences enable row level security;
alter table public.profile_boundaries enable row level security;

create policy profile_taxonomy_preferences_select_members
on public.profile_taxonomy_preferences for select to authenticated
using (public.is_active_profile_member(profile_id));

create policy profile_taxonomy_preferences_select_visible
on public.profile_taxonomy_preferences for select to authenticated
using (
  visible_on_profile
  and exists (
    select 1 from public.profiles p
    where p.id = profile_taxonomy_preferences.profile_id
      and p.status = 'active'
      and p.is_discoverable
      and p.deleted_at is null
  )
);

create policy profile_boundaries_select_members
on public.profile_boundaries for select to authenticated
using (public.is_active_profile_member(profile_id));

create policy profile_boundaries_select_visible_matches
on public.profile_boundaries for select to authenticated
using (
  visible_to_matches
  and exists (
    select 1 from public.profiles p
    where p.id = profile_boundaries.profile_id
      and p.status = 'active'
      and p.is_discoverable
      and p.deleted_at is null
  )
);

revoke all on private.account_taxonomy_preferences from anon, authenticated;
grant all on private.account_taxonomy_preferences to service_role;

revoke insert, update, delete on public.profile_taxonomy_preferences, public.profile_boundaries from anon, authenticated;
grant select on public.profile_taxonomy_preferences, public.profile_boundaries to authenticated;
grant all on public.profile_taxonomy_preferences, public.profile_boundaries to service_role;

commit;
