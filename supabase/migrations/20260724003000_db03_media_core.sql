begin;

create type public.media_kind as enum ('image','video');
create type public.media_status as enum ('uploaded','processing','ready','rejected','quarantined','deleted');
create type public.album_visibility as enum ('public','members','private','temporary','hidden');
create type public.media_sensitivity as enum ('standard','identifying','intimate');

create table public.media_assets (
  id uuid primary key default extensions.gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  kind public.media_kind not null,
  status public.media_status not null default 'uploaded',
  sensitivity public.media_sensitivity not null default 'standard',
  storage_bucket text not null default 'profile-media',
  storage_path text not null,
  mime_type text not null,
  byte_size bigint not null,
  width integer,
  height integer,
  duration_ms integer,
  content_hash text,
  created_by_account_id uuid not null references public.accounts(id) on delete restrict,
  created_at timestamptz not null default timezone('utc',now()),
  updated_at timestamptz not null default timezone('utc',now()),
  deleted_at timestamptz,
  constraint media_assets_storage_path_uq unique(storage_bucket,storage_path),
  constraint media_assets_byte_size_positive check (byte_size > 0),
  constraint media_assets_dimensions_positive check ((width is null or width > 0) and (height is null or height > 0)),
  constraint media_assets_duration_positive check (duration_ms is null or duration_ms > 0),
  constraint media_assets_deleted_consistency check (status <> 'deleted' or deleted_at is not null)
);

create table public.media_albums (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  visibility public.album_visibility not null default 'private',
  cover_asset_id uuid references public.media_assets(id) on delete set null,
  created_by_account_id uuid not null references public.accounts(id) on delete restrict,
  created_at timestamptz not null default timezone('utc',now()),
  updated_at timestamptz not null default timezone('utc',now()),
  archived_at timestamptz,
  deleted_at timestamptz,
  constraint media_albums_title_length check (length(trim(title)) between 1 and 80),
  constraint media_albums_description_length check (description is null or length(description) <= 500)
);

create table public.media_album_items (
  album_id uuid not null references public.media_albums(id) on delete cascade,
  asset_id uuid not null references public.media_assets(id) on delete cascade,
  position integer not null default 0,
  caption text,
  added_by_account_id uuid not null references public.accounts(id) on delete restrict,
  created_at timestamptz not null default timezone('utc',now()),
  primary key(album_id,asset_id),
  constraint media_album_items_position_nonnegative check (position >= 0),
  constraint media_album_items_caption_length check (caption is null or length(caption) <= 300)
);

create index media_assets_owner_status_idx on public.media_assets(owner_profile_id,status,created_at desc);
create index media_albums_profile_visibility_idx on public.media_albums(profile_id,visibility,updated_at desc) where deleted_at is null;
create index media_album_items_order_idx on public.media_album_items(album_id,position,created_at);

create trigger media_assets_set_updated_at before update on public.media_assets
for each row execute function public.set_updated_at();
create trigger media_albums_set_updated_at before update on public.media_albums
for each row execute function public.set_updated_at();

alter table public.media_assets enable row level security;
alter table public.media_albums enable row level security;
alter table public.media_album_items enable row level security;

create policy media_assets_select_owner_members on public.media_assets
for select to authenticated using (deleted_at is null and public.is_active_profile_member(owner_profile_id));

create policy media_albums_select_owner_members on public.media_albums
for select to authenticated using (deleted_at is null and public.is_active_profile_member(profile_id));

create policy media_albums_select_public on public.media_albums
for select to authenticated using (
  deleted_at is null and visibility='public' and exists (
    select 1 from public.profiles p where p.id=media_albums.profile_id and p.status='active' and p.is_discoverable and p.deleted_at is null
  )
);

create policy media_album_items_select_authorized on public.media_album_items
for select to authenticated using (
  exists (select 1 from public.media_albums a where a.id=media_album_items.album_id)
);

revoke insert,update,delete on public.media_assets,public.media_albums,public.media_album_items from anon,authenticated;
grant select on public.media_assets,public.media_albums,public.media_album_items to authenticated;
grant all on public.media_assets,public.media_albums,public.media_album_items to service_role;

commit;
