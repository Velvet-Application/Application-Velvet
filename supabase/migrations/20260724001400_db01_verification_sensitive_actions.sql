begin;

create type public.sensitive_action_type as enum (
  'activate_shared_profile',
  'change_shared_profile_identity',
  'change_shared_search_preferences',
  'change_shared_boundaries',
  'publish_joint_identifying_media',
  'grant_private_album_access',
  'add_profile_member',
  'remove_profile_member',
  'transfer_ownership',
  'hide_profile',
  'archive_profile',
  'delete_profile'
);

create type public.approval_status as enum ('pending','approved','rejected','expired','cancelled','executed');

create table private.identity_verification_cases (
  id uuid primary key default extensions.gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  provider text not null,
  provider_case_id text not null,
  requested_level public.verification_level not null,
  status text not null,
  age_over_18_confirmed boolean,
  identity_match_confirmed boolean,
  failure_reason_code text,
  submitted_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default timezone('utc',now()),
  constraint identity_verification_cases_provider_case_uq unique(provider,provider_case_id),
  constraint identity_verification_cases_status_check check (status in ('created','processing','approved','rejected','expired','cancelled')),
  constraint identity_verification_cases_provider_not_blank check (length(trim(provider)) > 0)
);

create index identity_verification_cases_account_idx on private.identity_verification_cases(account_id,created_at desc);

create table public.profile_sensitive_actions (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  action_type public.sensitive_action_type not null,
  status public.approval_status not null default 'pending',
  requested_by_account_id uuid not null references public.accounts(id) on delete restrict,
  payload jsonb not null default '{}'::jsonb,
  required_approvals smallint not null,
  expires_at timestamptz not null,
  executed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default timezone('utc',now()),
  updated_at timestamptz not null default timezone('utc',now()),
  constraint profile_sensitive_actions_required_approvals_check check (required_approvals > 0),
  constraint profile_sensitive_actions_expiry_check check (expires_at > created_at),
  constraint profile_sensitive_actions_execution_consistency check (status <> 'executed' or executed_at is not null)
);

create table public.profile_sensitive_action_approvals (
  action_id uuid not null references public.profile_sensitive_actions(id) on delete cascade,
  account_id uuid not null references public.accounts(id) on delete restrict,
  decision public.approval_status not null,
  decided_at timestamptz not null default timezone('utc',now()),
  comment text,
  primary key(action_id,account_id),
  constraint profile_sensitive_action_approval_decision check (decision in ('approved','rejected'))
);

create index profile_sensitive_actions_profile_idx on public.profile_sensitive_actions(profile_id,status,expires_at);
create index profile_sensitive_action_approvals_account_idx on public.profile_sensitive_action_approvals(account_id,decided_at desc);

create trigger profile_sensitive_actions_set_updated_at before update on public.profile_sensitive_actions
for each row execute function public.set_updated_at();

create or replace function private.required_shared_profile_approvals(target_profile_id uuid)
returns smallint
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select greatest(1,count(*)::smallint)
  from public.profile_memberships pm
  where pm.profile_id = target_profile_id
    and pm.status = 'active'
    and pm.role in ('owner','co_owner');
$$;

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
begin
  if not public.has_profile_permission(target_profile_id,'profile.request_sensitive_action') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;
  if lifetime <= interval '0' or lifetime > interval '30 days' then
    raise exception 'VELVET_INVALID_APPROVAL_LIFETIME' using errcode='22023';
  end if;

  approvals := private.required_shared_profile_approvals(target_profile_id);

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

create or replace function public.decide_sensitive_profile_action(target_action_id uuid, requested_decision public.approval_status, requested_comment text default null)
returns public.approval_status
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  action_row public.profile_sensitive_actions;
  approval_count integer;
begin
  if requested_decision not in ('approved','rejected') then
    raise exception 'VELVET_INVALID_APPROVAL_DECISION' using errcode='22023';
  end if;

  select * into action_row from public.profile_sensitive_actions where id=target_action_id for update;
  if action_row.id is null or action_row.status <> 'pending' then
    raise exception 'VELVET_APPROVAL_NOT_PENDING' using errcode='40900';
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
    set decision=excluded.decision, decided_at=timezone('utc',now()), comment=excluded.comment;

  if requested_decision='rejected' then
    update public.profile_sensitive_actions set status='rejected' where id=target_action_id;
    return 'rejected';
  end if;

  select count(*) into approval_count from public.profile_sensitive_action_approvals
  where action_id=target_action_id and decision='approved';

  if approval_count >= action_row.required_approvals then
    update public.profile_sensitive_actions set status='approved' where id=target_action_id;
    return 'approved';
  end if;

  return 'pending';
end;
$$;

alter table public.profile_sensitive_actions enable row level security;
alter table public.profile_sensitive_action_approvals enable row level security;

create policy sensitive_actions_select_members on public.profile_sensitive_actions
for select to authenticated using (public.is_active_profile_member(profile_id));

create policy sensitive_action_approvals_select_members on public.profile_sensitive_action_approvals
for select to authenticated using (
  exists (
    select 1 from public.profile_sensitive_actions sa
    where sa.id=profile_sensitive_action_approvals.action_id
      and public.is_active_profile_member(sa.profile_id)
  )
);

revoke insert,update,delete on public.profile_sensitive_actions,public.profile_sensitive_action_approvals from anon,authenticated;
grant select on public.profile_sensitive_actions,public.profile_sensitive_action_approvals to authenticated;
grant all on public.profile_sensitive_actions,public.profile_sensitive_action_approvals,private.identity_verification_cases to service_role;
revoke all on private.identity_verification_cases from anon,authenticated;

revoke all on function public.request_sensitive_profile_action(uuid,public.sensitive_action_type,jsonb,interval) from public;
revoke all on function public.decide_sensitive_profile_action(uuid,public.approval_status,text) from public;
grant execute on function public.request_sensitive_profile_action(uuid,public.sensitive_action_type,jsonb,interval),public.decide_sensitive_profile_action(uuid,public.approval_status,text) to authenticated,service_role;

commit;
