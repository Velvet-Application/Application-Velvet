begin;

create or replace function public.set_my_taxonomy_preference(
  target_taxonomy_item_id uuid,
  requested_level public.preference_level,
  requested_note text default null,
  share_with_profile_members boolean default false
)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
begin
  if not exists (
    select 1 from public.taxonomy_items
    where id = target_taxonomy_item_id and is_active
  ) then
    raise exception 'VELVET_TAXONOMY_ITEM_UNAVAILABLE' using errcode='22023';
  end if;

  insert into private.account_taxonomy_preferences(
    account_id, taxonomy_item_id, level, note, visible_to_profile_members
  ) values (
    actor, target_taxonomy_item_id, requested_level, nullif(trim(requested_note),''), share_with_profile_members
  )
  on conflict(account_id, taxonomy_item_id) do update
    set level = excluded.level,
        note = excluded.note,
        visible_to_profile_members = excluded.visible_to_profile_members,
        updated_at = timezone('utc', now());
end;
$$;

create or replace function public.set_profile_taxonomy_preference(
  target_profile_id uuid,
  target_taxonomy_item_id uuid,
  requested_level public.preference_level,
  requested_visibility boolean default false
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  target_type public.profile_type;
begin
  if not public.has_profile_permission(target_profile_id,'profile.edit') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  select type into target_type from public.profiles where id = target_profile_id and deleted_at is null;
  if target_type is null then
    raise exception 'VELVET_PROFILE_NOT_AVAILABLE' using errcode='22023';
  end if;

  if not exists (select 1 from public.taxonomy_items where id = target_taxonomy_item_id and is_active) then
    raise exception 'VELVET_TAXONOMY_ITEM_UNAVAILABLE' using errcode='22023';
  end if;

  if target_type = 'couple' then
    raise exception 'VELVET_SHARED_PREFERENCE_REQUIRES_SENSITIVE_ACTION' using errcode='42501';
  end if;

  insert into public.profile_taxonomy_preferences(
    profile_id, taxonomy_item_id, level, source, visible_on_profile, created_by_account_id
  ) values (
    target_profile_id, target_taxonomy_item_id, requested_level, 'declared', requested_visibility, actor
  )
  on conflict(profile_id, taxonomy_item_id) do update
    set level = excluded.level,
        visible_on_profile = excluded.visible_on_profile,
        created_by_account_id = actor,
        updated_at = timezone('utc', now());
end;
$$;

create or replace function public.set_profile_boundary(
  target_profile_id uuid,
  target_taxonomy_item_id uuid,
  requested_custom_label text,
  requested_level public.boundary_level,
  requested_conditions text default null,
  requested_visibility boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  target_type public.profile_type;
  boundary_id uuid;
begin
  if not public.has_profile_permission(target_profile_id,'profile.edit') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  select type into target_type from public.profiles where id = target_profile_id and deleted_at is null;
  if target_type = 'couple' then
    raise exception 'VELVET_SHARED_BOUNDARY_REQUIRES_SENSITIVE_ACTION' using errcode='42501';
  end if;

  insert into public.profile_boundaries(
    profile_id, taxonomy_item_id, custom_label, level, conditions,
    visible_to_matches, jointly_confirmed_at, created_by_account_id
  ) values (
    target_profile_id, target_taxonomy_item_id, nullif(trim(requested_custom_label),''), requested_level,
    nullif(trim(requested_conditions),''), requested_visibility, timezone('utc',now()), actor
  ) returning id into boundary_id;

  return boundary_id;
end;
$$;

revoke all on function public.set_my_taxonomy_preference(uuid,public.preference_level,text,boolean) from public;
revoke all on function public.set_profile_taxonomy_preference(uuid,uuid,public.preference_level,boolean) from public;
revoke all on function public.set_profile_boundary(uuid,uuid,text,public.boundary_level,text,boolean) from public;

grant execute on function public.set_my_taxonomy_preference(uuid,public.preference_level,text,boolean) to authenticated,service_role;
grant execute on function public.set_profile_taxonomy_preference(uuid,uuid,public.preference_level,boolean) to authenticated,service_role;
grant execute on function public.set_profile_boundary(uuid,uuid,text,public.boundary_level,text,boolean) to authenticated,service_role;

commit;
