begin;

create or replace function public.request_couple_preference_change(
  target_profile_id uuid,
  target_taxonomy_item_id uuid,
  requested_level public.preference_level,
  requested_visibility boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public,pg_temp
as $$
declare
  target_type public.profile_type;
begin
  select type into target_type from public.profiles where id=target_profile_id and deleted_at is null;
  if target_type <> 'couple' then
    raise exception 'VELVET_COUPLE_PROFILE_REQUIRED' using errcode='22023';
  end if;
  if not exists(select 1 from public.taxonomy_items where id=target_taxonomy_item_id and is_active) then
    raise exception 'VELVET_TAXONOMY_ITEM_UNAVAILABLE' using errcode='22023';
  end if;
  return public.request_sensitive_profile_action(
    target_profile_id,
    'change_shared_search_preferences',
    jsonb_build_object(
      'operation','upsert_taxonomy_preference',
      'taxonomy_item_id',target_taxonomy_item_id,
      'level',requested_level,
      'visible_on_profile',requested_visibility
    )
  );
end;
$$;

create or replace function public.request_couple_boundary_change(
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
set search_path = public,pg_temp
as $$
declare
  target_type public.profile_type;
begin
  select type into target_type from public.profiles where id=target_profile_id and deleted_at is null;
  if target_type <> 'couple' then
    raise exception 'VELVET_COUPLE_PROFILE_REQUIRED' using errcode='22023';
  end if;
  if target_taxonomy_item_id is null and length(trim(coalesce(requested_custom_label,''))) < 2 then
    raise exception 'VELVET_BOUNDARY_SUBJECT_REQUIRED' using errcode='22023';
  end if;
  return public.request_sensitive_profile_action(
    target_profile_id,
    'change_shared_boundaries',
    jsonb_build_object(
      'operation','upsert_boundary',
      'taxonomy_item_id',target_taxonomy_item_id,
      'custom_label',nullif(trim(requested_custom_label),''),
      'level',requested_level,
      'conditions',nullif(trim(requested_conditions),''),
      'visible_to_matches',requested_visibility
    )
  );
end;
$$;

create or replace function private.execute_db02_sensitive_action(target_action_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public,private,audit,pg_temp
as $$
declare
  action_row public.profile_sensitive_actions;
  actor uuid;
  operation text;
  taxonomy_id uuid;
begin
  select * into action_row from public.profile_sensitive_actions where id=target_action_id for update;
  if action_row.id is null or action_row.status <> 'approved' then return false; end if;
  operation := action_row.payload->>'operation';
  actor := action_row.requested_by_account_id;

  if action_row.action_type='change_shared_search_preferences' and operation='upsert_taxonomy_preference' then
    taxonomy_id := (action_row.payload->>'taxonomy_item_id')::uuid;
    insert into public.profile_taxonomy_preferences(profile_id,taxonomy_item_id,level,source,visible_on_profile,created_by_account_id)
    values(action_row.profile_id,taxonomy_id,(action_row.payload->>'level')::public.preference_level,'joint_decision',coalesce((action_row.payload->>'visible_on_profile')::boolean,false),actor)
    on conflict(profile_id,taxonomy_item_id) do update set
      level=excluded.level, source='joint_decision', visible_on_profile=excluded.visible_on_profile,
      created_by_account_id=actor, updated_at=timezone('utc',now());
  elsif action_row.action_type='change_shared_boundaries' and operation='upsert_boundary' then
    taxonomy_id := nullif(action_row.payload->>'taxonomy_item_id','')::uuid;
    if taxonomy_id is not null then
      insert into public.profile_boundaries(profile_id,taxonomy_item_id,custom_label,level,conditions,visible_to_matches,jointly_confirmed_at,created_by_account_id)
      values(action_row.profile_id,taxonomy_id,null,(action_row.payload->>'level')::public.boundary_level,nullif(action_row.payload->>'conditions',''),coalesce((action_row.payload->>'visible_to_matches')::boolean,false),timezone('utc',now()),actor)
      on conflict(profile_id,taxonomy_item_id) where taxonomy_item_id is not null do update set
        level=excluded.level, conditions=excluded.conditions, visible_to_matches=excluded.visible_to_matches,
        jointly_confirmed_at=timezone('utc',now()), created_by_account_id=actor, updated_at=timezone('utc',now());
    else
      insert into public.profile_boundaries(profile_id,custom_label,level,conditions,visible_to_matches,jointly_confirmed_at,created_by_account_id)
      values(action_row.profile_id,nullif(action_row.payload->>'custom_label',''),(action_row.payload->>'level')::public.boundary_level,nullif(action_row.payload->>'conditions',''),coalesce((action_row.payload->>'visible_to_matches')::boolean,false),timezone('utc',now()),actor);
    end if;
  else
    return false;
  end if;

  update public.profile_sensitive_actions
  set status='executed', executed_at=timezone('utc',now())
  where id=target_action_id and status='approved';

  delete from public.profile_compatibility_snapshots
  where source_profile_id=action_row.profile_id or target_profile_id=action_row.profile_id;

  return true;
end;
$$;

create or replace function private.execute_approved_db02_actions()
returns trigger
language plpgsql
security definer
set search_path = public,private,pg_temp
as $$
begin
  if new.status='approved' and old.status is distinct from new.status
     and new.action_type in ('change_shared_search_preferences','change_shared_boundaries') then
    perform private.execute_db02_sensitive_action(new.id);
  end if;
  return new;
end;
$$;

create trigger profile_sensitive_actions_execute_db02
after update of status on public.profile_sensitive_actions
for each row execute function private.execute_approved_db02_actions();

revoke all on function public.request_couple_preference_change(uuid,uuid,public.preference_level,boolean) from public;
revoke all on function public.request_couple_boundary_change(uuid,uuid,text,public.boundary_level,text,boolean) from public;
grant execute on function public.request_couple_preference_change(uuid,uuid,public.preference_level,boolean) to authenticated,service_role;
grant execute on function public.request_couple_boundary_change(uuid,uuid,text,public.boundary_level,text,boolean) to authenticated,service_role;
revoke all on function private.execute_db02_sensitive_action(uuid),private.execute_approved_db02_actions() from public,anon,authenticated;
grant execute on function private.execute_db02_sensitive_action(uuid),private.execute_approved_db02_actions() to service_role;

commit;