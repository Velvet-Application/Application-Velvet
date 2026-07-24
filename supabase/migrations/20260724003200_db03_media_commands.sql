begin;

create or replace function public.create_media_album(
  target_profile_id uuid,
  requested_title text,
  requested_description text default null,
  requested_visibility public.album_visibility default 'private'
)
returns uuid
language plpgsql
security definer
set search_path = public,pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  target_type public.profile_type;
  album_id uuid;
begin
  if not public.has_profile_permission(target_profile_id,'profile.edit') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  select type into target_type from public.profiles where id=target_profile_id and deleted_at is null;
  if target_type='couple' and requested_visibility in ('public','private','temporary') then
    raise exception 'VELVET_COUPLE_MEDIA_VISIBILITY_REQUIRES_SENSITIVE_ACTION' using errcode='42501';
  end if;

  insert into public.media_albums(profile_id,title,description,visibility,created_by_account_id)
  values(target_profile_id,trim(requested_title),nullif(trim(requested_description),''),requested_visibility,actor)
  returning id into album_id;
  return album_id;
end;
$$;

create or replace function public.register_media_asset(
  target_profile_id uuid,
  requested_kind public.media_kind,
  requested_sensitivity public.media_sensitivity,
  requested_storage_path text,
  requested_mime_type text,
  requested_byte_size bigint
)
returns uuid
language plpgsql
security definer
set search_path = public,pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  asset_id uuid;
begin
  if not public.has_profile_permission(target_profile_id,'profile.edit') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;
  if requested_byte_size<=0 then
    raise exception 'VELVET_MEDIA_SIZE_INVALID' using errcode='22023';
  end if;

  insert into public.media_assets(owner_profile_id,kind,sensitivity,storage_path,mime_type,byte_size,created_by_account_id)
  values(target_profile_id,requested_kind,requested_sensitivity,requested_storage_path,requested_mime_type,requested_byte_size,actor)
  returning id into asset_id;
  return asset_id;
end;
$$;

create or replace function public.add_media_to_album(target_album_id uuid,target_asset_id uuid,requested_caption text default null)
returns void
language plpgsql
security definer
set search_path = public,pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  owner_profile uuid;
begin
  select profile_id into owner_profile from public.media_albums where id=target_album_id and deleted_at is null;
  if owner_profile is null or not public.has_profile_permission(owner_profile,'profile.edit') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;
  if not exists(select 1 from public.media_assets where id=target_asset_id and owner_profile_id=owner_profile and deleted_at is null) then
    raise exception 'VELVET_MEDIA_ASSET_NOT_AVAILABLE' using errcode='22023';
  end if;
  insert into public.media_album_items(album_id,asset_id,position,caption,added_by_account_id)
  values(target_album_id,target_asset_id,coalesce((select max(position)+1 from public.media_album_items where album_id=target_album_id),0),nullif(trim(requested_caption),''),actor)
  on conflict(album_id,asset_id) do update set caption=excluded.caption;
end;
$$;

create or replace function public.grant_album_access(
  target_album_id uuid,
  target_grantee_profile_id uuid,
  requested_expires_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public,pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  album_row public.media_albums;
  grant_id uuid;
begin
  select * into album_row from public.media_albums where id=target_album_id and deleted_at is null for update;
  if album_row.id is null or not public.has_profile_permission(album_row.profile_id,'profile.edit') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;
  if album_row.visibility='temporary' and requested_expires_at is null then
    raise exception 'VELVET_TEMPORARY_GRANT_EXPIRY_REQUIRED' using errcode='22023';
  end if;
  if requested_expires_at is not null and requested_expires_at<=timezone('utc',now()) then
    raise exception 'VELVET_MEDIA_GRANT_EXPIRY_INVALID' using errcode='22023';
  end if;

  insert into public.media_access_grants(owner_profile_id,grantee_profile_id,scope,album_id,granted_by_account_id,expires_at)
  values(album_row.profile_id,target_grantee_profile_id,'album',target_album_id,actor,requested_expires_at)
  returning id into grant_id;
  return grant_id;
end;
$$;

create or replace function public.revoke_media_access(target_grant_id uuid)
returns void
language plpgsql
security definer
set search_path = public,pg_temp
as $$
declare
  grant_row public.media_access_grants;
begin
  select * into grant_row from public.media_access_grants where id=target_grant_id for update;
  if grant_row.id is null or not public.has_profile_permission(grant_row.owner_profile_id,'profile.edit') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;
  update public.media_access_grants set status='revoked',revoked_at=timezone('utc',now()) where id=target_grant_id;
end;
$$;

revoke all on function public.create_media_album(uuid,text,text,public.album_visibility) from public;
revoke all on function public.register_media_asset(uuid,public.media_kind,public.media_sensitivity,text,text,bigint) from public;
revoke all on function public.add_media_to_album(uuid,uuid,text) from public;
revoke all on function public.grant_album_access(uuid,uuid,timestamptz) from public;
revoke all on function public.revoke_media_access(uuid) from public;
grant execute on function public.create_media_album(uuid,text,text,public.album_visibility),public.register_media_asset(uuid,public.media_kind,public.media_sensitivity,text,text,bigint),public.add_media_to_album(uuid,uuid,text),public.grant_album_access(uuid,uuid,timestamptz),public.revoke_media_access(uuid) to authenticated,service_role;

commit;
