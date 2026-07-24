begin;

create type public.profile_lifecycle_event_type as enum (
  'profile_activated',
  'profile_hidden',
  'profile_archived',
  'profile_deleted',
  'member_left',
  'member_revoked',
  'ownership_transferred',
  'sensitive_action_executed'
);

create table audit.profile_lifecycle_events (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete restrict,
  event_type public.profile_lifecycle_event_type not null,
  actor_account_id uuid references public.accounts(id) on delete set null,
  subject_account_id uuid references public.accounts(id) on delete set null,
  sensitive_action_id uuid references public.profile_sensitive_actions(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default timezone('utc', now())
);

create index profile_lifecycle_events_profile_idx
  on audit.profile_lifecycle_events(profile_id, occurred_at desc);
create index profile_lifecycle_events_actor_idx
  on audit.profile_lifecycle_events(actor_account_id, occurred_at desc)
  where actor_account_id is not null;

create or replace function private.lock_profile(target_profile_id uuid)
returns public.profiles
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  locked_profile public.profiles;
begin
  select * into locked_profile
  from public.profiles
  where id = target_profile_id
  for update;

  if locked_profile.id is null or locked_profile.deleted_at is not null then
    raise exception 'VELVET_PROFILE_NOT_AVAILABLE' using errcode = 'P0002';
  end if;

  return locked_profile;
end;
$$;

create or replace function private.active_profile_owner_count(target_profile_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select count(*)::integer
  from public.profile_memberships pm
  where pm.profile_id = target_profile_id
    and pm.status = 'active'
    and pm.role in ('owner','co_owner');
$$;

create or replace function private.validate_profile_activation(target_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  target_profile public.profiles;
  owner_count integer;
  verified_owner_count integer;
begin
  target_profile := private.lock_profile(target_profile_id);

  if target_profile.status not in ('draft','pending_members','pending_verification','hidden') then
    raise exception 'VELVET_PROFILE_CANNOT_BE_ACTIVATED' using errcode = '23514';
  end if;

  select count(*)::integer,
         count(*) filter (where a.verification_level in ('age_verified','identity_verified','enhanced_verified'))::integer
  into owner_count, verified_owner_count
  from public.profile_memberships pm
  join public.accounts a on a.id = pm.account_id
  where pm.profile_id = target_profile_id
    and pm.status = 'active'
    and pm.role in ('owner','co_owner')
    and a.deleted_at is null
    and a.status = 'active';

  if target_profile.type = 'individual' and owner_count <> 1 then
    raise exception 'VELVET_INDIVIDUAL_PROFILE_REQUIRES_ONE_OWNER' using errcode = '23514';
  end if;

  if target_profile.type = 'couple' and owner_count <> 2 then
    raise exception 'VELVET_COUPLE_PROFILE_REQUIRES_TWO_OWNERS' using errcode = '23514';
  end if;

  if owner_count = 0 or verified_owner_count <> owner_count then
    raise exception 'VELVET_PROFILE_OWNERS_MUST_BE_AGE_VERIFIED' using errcode = '23514';
  end if;
end;
$$;

create or replace function private.apply_profile_activation(
  target_profile_id uuid,
  actor_account_id uuid,
  source_action_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, audit, private, pg_temp
as $$
begin
  perform private.validate_profile_activation(target_profile_id);

  update public.profiles
  set status = 'active',
      is_discoverable = false,
      discoverable_since = null,
      archived_at = null
  where id = target_profile_id;

  insert into audit.profile_lifecycle_events(
    profile_id,event_type,actor_account_id,sensitive_action_id
  ) values (
    target_profile_id,'profile_activated',actor_account_id,source_action_id
  );
end;
$$;

create or replace function private.apply_member_departure(
  target_profile_id uuid,
  departing_account_id uuid,
  actor_account_id uuid,
  departure_status public.membership_status,
  source_action_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, audit, private, pg_temp
as $$
declare
  target_membership public.profile_memberships;
  remaining_owner_count integer;
  target_profile public.profiles;
begin
  if departure_status not in ('left','revoked') then
    raise exception 'VELVET_INVALID_DEPARTURE_STATUS' using errcode = '22023';
  end if;

  target_profile := private.lock_profile(target_profile_id);

  select * into target_membership
  from public.profile_memberships
  where profile_id = target_profile_id
    and account_id = departing_account_id
    and status = 'active'
  for update;

  if target_membership.id is null then
    raise exception 'VELVET_ACTIVE_MEMBERSHIP_NOT_FOUND' using errcode = 'P0002';
  end if;

  if target_membership.role in ('owner','co_owner') then
    select count(*)::integer into remaining_owner_count
    from public.profile_memberships pm
    where pm.profile_id = target_profile_id
      and pm.status = 'active'
      and pm.role in ('owner','co_owner')
      and pm.account_id <> departing_account_id;

    if remaining_owner_count = 0 then
      raise exception 'VELVET_FINAL_OWNER_REQUIRED' using errcode = '23514';
    end if;
  end if;

  update public.profile_memberships
  set status = departure_status,
      ended_at = timezone('utc',now()),
      invitation_token_hash = null
  where id = target_membership.id;

  if target_profile.type = 'couple' and target_membership.role in ('owner','co_owner') then
    update public.profiles
    set status = 'hidden',
        is_discoverable = false,
        discoverable_since = null
    where id = target_profile_id;
  end if;

  insert into audit.profile_lifecycle_events(
    profile_id,event_type,actor_account_id,subject_account_id,sensitive_action_id
  ) values (
    target_profile_id,
    case when departure_status = 'left' then 'member_left'::public.profile_lifecycle_event_type
         else 'member_revoked'::public.profile_lifecycle_event_type end,
    actor_account_id,
    departing_account_id,
    source_action_id
  );
end;
$$;

create or replace function private.apply_ownership_transfer(
  target_profile_id uuid,
  from_account_id uuid,
  to_account_id uuid,
  actor_account_id uuid,
  source_action_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, audit, private, pg_temp
as $$
declare
  source_membership public.profile_memberships;
  destination_membership public.profile_memberships;
  target_profile public.profiles;
begin
  target_profile := private.lock_profile(target_profile_id);

  select * into source_membership
  from public.profile_memberships
  where profile_id = target_profile_id
    and account_id = from_account_id
    and status = 'active'
    and role in ('owner','co_owner')
  for update;

  select * into destination_membership
  from public.profile_memberships
  where profile_id = target_profile_id
    and account_id = to_account_id
    and status = 'active'
  for update;

  if source_membership.id is null or destination_membership.id is null then
    raise exception 'VELVET_OWNERSHIP_TRANSFER_MEMBERSHIP_INVALID' using errcode = '23514';
  end if;

  if from_account_id = to_account_id then
    raise exception 'VELVET_OWNERSHIP_TRANSFER_SAME_ACCOUNT' using errcode = '22023';
  end if;

  update public.profile_memberships
  set role = case when target_profile.type = 'couple' then 'co_owner'::public.profile_membership_role
                  else 'manager'::public.profile_membership_role end
  where id = source_membership.id;

  update public.profile_memberships
  set role = 'owner'
  where id = destination_membership.id;

  insert into audit.profile_lifecycle_events(
    profile_id,event_type,actor_account_id,subject_account_id,sensitive_action_id,metadata
  ) values (
    target_profile_id,'ownership_transferred',actor_account_id,to_account_id,source_action_id,
    jsonb_build_object('from_account_id',from_account_id,'to_account_id',to_account_id)
  );
end;
$$;

create or replace function private.execute_sensitive_profile_action(target_action_id uuid)
returns public.approval_status
language plpgsql
security definer
set search_path = public, private, audit, pg_temp
as $$
declare
  action_row public.profile_sensitive_actions;
  approved_count integer;
  target_account_id uuid;
  from_account_id uuid;
  to_account_id uuid;
begin
  select * into action_row
  from public.profile_sensitive_actions
  where id = target_action_id
  for update;

  if action_row.id is null then
    raise exception 'VELVET_SENSITIVE_ACTION_NOT_FOUND' using errcode = 'P0002';
  end if;

  if action_row.status = 'executed' then
    return 'executed';
  end if;

  if action_row.status not in ('pending','approved') then
    raise exception 'VELVET_SENSITIVE_ACTION_NOT_EXECUTABLE' using errcode = '23514';
  end if;

  if action_row.expires_at <= timezone('utc',now()) then
    update public.profile_sensitive_actions set status='expired' where id=target_action_id;
    return 'expired';
  end if;

  select count(*)::integer into approved_count
  from public.profile_sensitive_action_approvals
  where action_id = target_action_id and decision = 'approved';

  if approved_count < action_row.required_approvals then
    raise exception 'VELVET_SENSITIVE_ACTION_APPROVALS_INCOMPLETE' using errcode = '23514';
  end if;

  case action_row.action_type
    when 'activate_shared_profile' then
      perform private.apply_profile_activation(action_row.profile_id,action_row.requested_by_account_id,action_row.id);

    when 'remove_profile_member' then
      target_account_id := nullif(action_row.payload->>'account_id','')::uuid;
      if target_account_id is null then
        raise exception 'VELVET_ACTION_PAYLOAD_ACCOUNT_REQUIRED' using errcode='22023';
      end if;
      perform private.apply_member_departure(action_row.profile_id,target_account_id,action_row.requested_by_account_id,'revoked',action_row.id);

    when 'transfer_ownership' then
      from_account_id := nullif(action_row.payload->>'from_account_id','')::uuid;
      to_account_id := nullif(action_row.payload->>'to_account_id','')::uuid;
      if from_account_id is null or to_account_id is null then
        raise exception 'VELVET_ACTION_PAYLOAD_TRANSFER_REQUIRED' using errcode='22023';
      end if;
      perform private.apply_ownership_transfer(action_row.profile_id,from_account_id,to_account_id,action_row.requested_by_account_id,action_row.id);

    when 'hide_profile' then
      perform private.lock_profile(action_row.profile_id);
      update public.profiles set status='hidden',is_discoverable=false,discoverable_since=null where id=action_row.profile_id;
      insert into audit.profile_lifecycle_events(profile_id,event_type,actor_account_id,sensitive_action_id)
      values(action_row.profile_id,'profile_hidden',action_row.requested_by_account_id,action_row.id);

    when 'archive_profile' then
      perform private.lock_profile(action_row.profile_id);
      update public.profiles set status='archived',archived_at=timezone('utc',now()),is_discoverable=false,discoverable_since=null where id=action_row.profile_id;
      insert into audit.profile_lifecycle_events(profile_id,event_type,actor_account_id,sensitive_action_id)
      values(action_row.profile_id,'profile_archived',action_row.requested_by_account_id,action_row.id);

    when 'delete_profile' then
      perform private.lock_profile(action_row.profile_id);
      update public.profiles set status='deleted',deleted_at=timezone('utc',now()),is_discoverable=false,discoverable_since=null where id=action_row.profile_id;
      insert into audit.profile_lifecycle_events(profile_id,event_type,actor_account_id,sensitive_action_id)
      values(action_row.profile_id,'profile_deleted',action_row.requested_by_account_id,action_row.id);

    else
      raise exception 'VELVET_SENSITIVE_ACTION_HANDLER_NOT_IMPLEMENTED' using errcode='0A000';
  end case;

  update public.profile_sensitive_actions
  set status='executed',executed_at=timezone('utc',now())
  where id=target_action_id;

  insert into audit.profile_lifecycle_events(
    profile_id,event_type,actor_account_id,sensitive_action_id,metadata
  ) values (
    action_row.profile_id,'sensitive_action_executed',action_row.requested_by_account_id,action_row.id,
    jsonb_build_object('action_type',action_row.action_type)
  );

  return 'executed';
end;
$$;

create or replace function public.leave_profile(target_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
begin
  if not public.is_active_profile_member(target_profile_id) then
    raise exception 'VELVET_MEMBERSHIP_REQUIRED' using errcode='42501';
  end if;

  perform private.apply_member_departure(target_profile_id,actor,actor,'left',null);
end;
$$;

create or replace function public.activate_owned_profile(target_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  target_type public.profile_type;
begin
  if not public.has_profile_permission(target_profile_id,'profile.manage_visibility') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  select type into target_type from public.profiles where id=target_profile_id;
  if target_type = 'couple' then
    raise exception 'VELVET_COUPLE_ACTIVATION_REQUIRES_DUAL_CONSENT' using errcode='42501';
  end if;

  perform private.apply_profile_activation(target_profile_id,actor,null);
end;
$$;

create or replace function public.execute_approved_sensitive_profile_action(target_action_id uuid)
returns public.approval_status
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  target_profile_id uuid;
begin
  select profile_id into target_profile_id
  from public.profile_sensitive_actions
  where id=target_action_id;

  if target_profile_id is null or not public.has_profile_permission(target_profile_id,'profile.approve_sensitive_action') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  return private.execute_sensitive_profile_action(target_action_id);
end;
$$;

create or replace function public.cancel_sensitive_profile_action(target_action_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  action_row public.profile_sensitive_actions;
begin
  select * into action_row from public.profile_sensitive_actions where id=target_action_id for update;

  if action_row.id is null or action_row.requested_by_account_id <> actor or action_row.status <> 'pending' then
    raise exception 'VELVET_SENSITIVE_ACTION_CANNOT_BE_CANCELLED' using errcode='42501';
  end if;

  update public.profile_sensitive_actions
  set status='cancelled',cancelled_at=timezone('utc',now())
  where id=target_action_id;
end;
$$;

revoke all on function private.lock_profile(uuid) from public,anon,authenticated;
revoke all on function private.active_profile_owner_count(uuid) from public,anon,authenticated;
revoke all on function private.validate_profile_activation(uuid) from public,anon,authenticated;
revoke all on function private.apply_profile_activation(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function private.apply_member_departure(uuid,uuid,uuid,public.membership_status,uuid) from public,anon,authenticated;
revoke all on function private.apply_ownership_transfer(uuid,uuid,uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function private.execute_sensitive_profile_action(uuid) from public,anon,authenticated;

grant execute on function private.lock_profile(uuid),private.active_profile_owner_count(uuid),private.validate_profile_activation(uuid),private.apply_profile_activation(uuid,uuid,uuid),private.apply_member_departure(uuid,uuid,uuid,public.membership_status,uuid),private.apply_ownership_transfer(uuid,uuid,uuid,uuid,uuid),private.execute_sensitive_profile_action(uuid) to service_role;

revoke all on function public.leave_profile(uuid) from public;
revoke all on function public.activate_owned_profile(uuid) from public;
revoke all on function public.execute_approved_sensitive_profile_action(uuid) from public;
revoke all on function public.cancel_sensitive_profile_action(uuid) from public;
grant execute on function public.leave_profile(uuid),public.activate_owned_profile(uuid),public.execute_approved_sensitive_profile_action(uuid),public.cancel_sensitive_profile_action(uuid) to authenticated,service_role;

revoke all on audit.profile_lifecycle_events from public,anon,authenticated;
grant all on audit.profile_lifecycle_events to service_role;

commit;