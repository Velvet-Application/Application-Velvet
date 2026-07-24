begin;

create or replace function public.request_sensitive_profile_action(
  target_profile_id uuid,
  requested_action public.sensitive_action_type,
  requested_payload jsonb default '{}'::jsonb,
  lifetime interval default interval '72 hours'
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  action_id uuid;
  approvals smallint;
  profile_kind public.profile_type;
begin
  if not public.has_profile_permission(target_profile_id,'profile.request_sensitive_action') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  if lifetime <= interval '0' or lifetime > interval '30 days' then
    raise exception 'VELVET_INVALID_APPROVAL_LIFETIME' using errcode='22023';
  end if;

  select type into profile_kind
  from public.profiles
  where id=target_profile_id and deleted_at is null
  for update;

  if profile_kind is null then
    raise exception 'VELVET_PROFILE_NOT_AVAILABLE' using errcode='P0002';
  end if;

  if profile_kind <> 'couple' then
    raise exception 'VELVET_SHARED_ACTION_REQUIRES_SHARED_PROFILE' using errcode='22023';
  end if;

  approvals := private.required_shared_profile_approvals(target_profile_id);
  if approvals < 2 then
    raise exception 'VELVET_DUAL_CONSENT_REQUIRES_TWO_OWNERS' using errcode='23514';
  end if;

  insert into public.profile_sensitive_actions(
    profile_id,action_type,requested_by_account_id,payload,required_approvals,expires_at
  ) values (
    target_profile_id,requested_action,actor,coalesce(requested_payload,'{}'::jsonb),approvals,timezone('utc',now()) + lifetime
  ) returning id into action_id;

  insert into public.profile_sensitive_action_approvals(action_id,account_id,decision)
  values(action_id,actor,'approved');

  return action_id;
end;
$$;

create or replace function public.decide_sensitive_profile_action(
  target_action_id uuid,
  requested_decision public.approval_status,
  requested_comment text default null
)
returns public.approval_status
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  action_row public.profile_sensitive_actions;
  approval_count integer;
begin
  if requested_decision not in ('approved','rejected') then
    raise exception 'VELVET_INVALID_APPROVAL_DECISION' using errcode='22023';
  end if;

  select * into action_row
  from public.profile_sensitive_actions
  where id=target_action_id
  for update;

  if action_row.id is null or action_row.status <> 'pending' then
    raise exception 'VELVET_APPROVAL_NOT_PENDING' using errcode='P0001';
  end if;

  if action_row.expires_at <= timezone('utc',now()) then
    update public.profile_sensitive_actions set status='expired' where id=target_action_id;
    return 'expired';
  end if;

  if not public.has_profile_permission(action_row.profile_id,'profile.approve_sensitive_action') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  insert into public.profile_sensitive_action_approvals(action_id,account_id,decision,comment)
  values(target_action_id,actor,requested_decision,requested_comment)
  on conflict(action_id,account_id) do update
    set decision=excluded.decision,
        decided_at=timezone('utc',now()),
        comment=excluded.comment;

  if requested_decision='rejected' then
    update public.profile_sensitive_actions
    set status='rejected'
    where id=target_action_id;
    return 'rejected';
  end if;

  select count(*)::integer into approval_count
  from public.profile_sensitive_action_approvals
  where action_id=target_action_id and decision='approved';

  if approval_count >= action_row.required_approvals then
    update public.profile_sensitive_actions
    set status='approved'
    where id=target_action_id;

    return private.execute_sensitive_profile_action(target_action_id);
  end if;

  return 'pending';
end;
$$;

create or replace function private.expire_pending_sensitive_profile_actions(batch_limit integer default 500)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected integer;
begin
  if batch_limit < 1 or batch_limit > 5000 then
    raise exception 'VELVET_INVALID_EXPIRY_BATCH_LIMIT' using errcode='22023';
  end if;

  with expirable as (
    select id
    from public.profile_sensitive_actions
    where status='pending'
      and expires_at <= timezone('utc',now())
    order by expires_at
    limit batch_limit
    for update skip locked
  )
  update public.profile_sensitive_actions sa
  set status='expired'
  from expirable e
  where sa.id=e.id;

  get diagnostics affected = row_count;
  return affected;
end;
$$;

revoke all on function private.expire_pending_sensitive_profile_actions(integer) from public,anon,authenticated;
grant execute on function private.expire_pending_sensitive_profile_actions(integer) to service_role;

revoke all on function public.request_sensitive_profile_action(uuid,public.sensitive_action_type,jsonb,interval) from public;
revoke all on function public.decide_sensitive_profile_action(uuid,public.approval_status,text) from public;
grant execute on function public.request_sensitive_profile_action(uuid,public.sensitive_action_type,jsonb,interval),public.decide_sensitive_profile_action(uuid,public.approval_status,text) to authenticated,service_role;

commit;