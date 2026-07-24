begin;

create type public.media_grant_scope as enum ('album','asset');
create type public.media_grant_status as enum ('active','revoked','expired');

create table public.media_access_grants (
  id uuid primary key default extensions.gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  grantee_profile_id uuid not null references public.profiles(id) on delete cascade,
  scope public.media_grant_scope not null,
  album_id uuid references public.media_albums(id) on delete cascade,
  asset_id uuid references public.media_assets(id) on delete cascade,
  status public.media_grant_status not null default 'active',
  granted_by_account_id uuid not null references public.accounts(id) on delete restrict,
  granted_at timestamptz not null default timezone('utc',now()),
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc',now()),
  constraint media_access_grants_distinct_profiles check (owner_profile_id <> grantee_profile_id),
  constraint media_access_grants_scope_target check (
    (scope='album' and album_id is not null and asset_id is null)
    or (scope='asset' and asset_id is not null and album_id is null)
  ),
  constraint media_access_grants_expiry check (expires_at is null or expires_at > granted_at),
  constraint media_access_grants_revocation check (status <> 'revoked' or revoked_at is not null)
);

create unique index media_access_grants_active_album_uq
on public.media_access_grants(owner_profile_id,grantee_profile_id,album_id)
where scope='album' and status='active';

create unique index media_access_grants_active_asset_uq
on public.media_access_grants(owner_profile_id,grantee_profile_id,asset_id)
where scope='asset' and status='active';

create index media_access_grants_grantee_idx on public.media_access_grants(grantee_profile_id,status,expires_at);

create table private.media_moderation_cases (
  id uuid primary key default extensions.gen_random_uuid(),
  asset_id uuid not null references public.media_assets(id) on delete cascade,
  provider text not null,
  provider_case_id text,
  status text not null,
  labels jsonb not null default '[]'::jsonb,
  confidence jsonb not null default '{}'::jsonb,
  decision_reason text,
  reviewed_at timestamptz,
  created_at timestamptz not null default timezone('utc',now()),
  constraint media_moderation_status_check check (status in ('queued','processing','approved','rejected','manual_review'))
);

alter table public.media_access_grants enable row level security;

create policy media_access_grants_select_owner on public.media_access_grants
for select to authenticated using (public.is_active_profile_member(owner_profile_id));

create policy media_access_grants_select_grantee on public.media_access_grants
for select to authenticated using (public.is_active_profile_member(grantee_profile_id));

revoke insert,update,delete on public.media_access_grants from anon,authenticated;
grant select on public.media_access_grants to authenticated;
grant all on public.media_access_grants,private.media_moderation_cases to service_role;
revoke all on private.media_moderation_cases from anon,authenticated;

create or replace function public.can_view_media_album(target_album_id uuid, viewer_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public,pg_temp
as $$
  select exists (
    select 1
    from public.media_albums a
    join public.profiles p on p.id=a.profile_id
    where a.id=target_album_id
      and a.deleted_at is null
      and (
        public.is_active_profile_member(a.profile_id)
        or (
          a.visibility='public'
          and p.status='active' and p.is_discoverable and p.deleted_at is null
        )
        or exists (
          select 1 from public.media_access_grants g
          where g.owner_profile_id=a.profile_id
            and g.grantee_profile_id=viewer_profile_id
            and g.scope='album'
            and g.album_id=a.id
            and g.status='active'
            and (g.expires_at is null or g.expires_at>timezone('utc',now()))
        )
      )
  );
$$;

revoke all on function public.can_view_media_album(uuid,uuid) from public;
grant execute on function public.can_view_media_album(uuid,uuid) to authenticated,service_role;

commit;
