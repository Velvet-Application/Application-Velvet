begin;

create table public.profile_role_permissions (
  profile_type public.profile_type not null,
  role public.profile_membership_role not null,
  permission_key text not null,
  allowed boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (profile_type, role, permission_key),
  constraint profile_role_permissions_key_format check (permission_key ~ '^[a-z][a-z0-9_.-]{2,79}$')
);

insert into public.profile_role_permissions(profile_type, role, permission_key, allowed)
select pt, role, permission_key, allowed
from (values
  ('individual'::public.profile_type,'owner'::public.profile_membership_role,'profile.read_private',true),
  ('individual','owner','profile.edit',true),
  ('individual','owner','profile.manage_members',false),
  ('individual','owner','profile.manage_visibility',true),
  ('individual','owner','profile.archive',true),
  ('individual','owner','profile.delete',true),
  ('couple','owner','profile.read_private',true),
  ('couple','owner','profile.edit',true),
  ('couple','owner','profile.manage_members',true),
  ('couple','owner','profile.manage_visibility',true),
  ('couple','owner','profile.request_sensitive_action',true),
  ('couple','owner','profile.approve_sensitive_action',true),
  ('couple','co_owner','profile.read_private',true),
  ('couple','co_owner','profile.edit',true),
  ('couple','co_owner','profile.manage_members',true),
  ('couple','co_owner','profile.manage_visibility',true),
  ('couple','co_owner','profile.request_sensitive_action',true),
  ('couple','co_owner','profile.approve_sensitive_action',true),
  ('professional','owner','profile.read_private',true),
  ('professional','owner','profile.edit',true),
  ('professional','owner','profile.manage_members',true),
  ('professional','manager','profile.read_private',true),
  ('professional','manager','profile.edit',true),
  ('organizer','owner','profile.read_private',true),
  ('organizer','owner','profile.edit',true),
  ('organizer','owner','profile.manage_members',true),
  ('organizer','manager','profile.read_private',true),
  ('organizer','manager','profile.edit',true)
) as seed(pt, role, permission_key, allowed);

create or replace function public.is_active_profile_member(target_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1 from public.profile_memberships pm
    where pm.profile_id = target_profile_id
      and pm.account_id = public.current_account_id()
      and pm.status = 'active'
  );
$$;

create or replace function public.has_profile_permission(target_profile_id uuid, requested_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1
    from public.profile_memberships pm
    join public.profiles p on p.id = pm.profile_id
    join public.profile_role_permissions rp
      on rp.profile_type = p.type
     and rp.role = pm.role
     and rp.permission_key = requested_permission
     and rp.allowed
    where pm.profile_id = target_profile_id
      and pm.account_id = public.current_account_id()
      and pm.status = 'active'
      and p.deleted_at is null
  );
$$;

revoke all on function public.is_active_profile_member(uuid) from public;
revoke all on function public.has_profile_permission(uuid,text) from public;
grant execute on function public.is_active_profile_member(uuid), public.has_profile_permission(uuid,text) to authenticated, service_role;

create or replace function public.create_profile(
  requested_type public.profile_type,
  requested_display_name text,
  requested_slug text,
  requested_country_code char(2),
  requested_locale text default 'fr-FR'
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  new_profile_id uuid;
begin
  if requested_type = 'couple' then
    insert into public.profiles(type,status,display_name,slug,country_code,primary_locale,created_by_account_id)
    values (requested_type,'pending_members',requested_display_name,requested_slug,requested_country_code,requested_locale,actor)
    returning id into new_profile_id;
  else
    insert into public.profiles(type,status,display_name,slug,country_code,primary_locale,created_by_account_id)
    values (requested_type,'draft',requested_display_name,requested_slug,requested_country_code,requested_locale,actor)
    returning id into new_profile_id;
  end if;

  insert into public.profile_memberships(profile_id,account_id,role,status,accepted_at)
  values (new_profile_id,actor,'owner','active',timezone('utc',now()));

  return new_profile_id;
end;
$$;

create or replace function public.invite_profile_member(
  target_profile_id uuid,
  invited_account_id uuid,
  invited_role public.profile_membership_role,
  invitation_token_hash text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  membership_id uuid;
begin
  if not public.has_profile_permission(target_profile_id,'profile.manage_members') then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;

  if actor = invited_account_id then
    raise exception 'VELVET_SELF_INVITATION_FORBIDDEN' using errcode='22023';
  end if;

  insert into public.profile_memberships(
    profile_id,account_id,role,status,invited_by_account_id,invitation_token_hash,invited_at
  ) values (
    target_profile_id,invited_account_id,invited_role,'invited',actor,invitation_token_hash,timezone('utc',now())
  ) returning id into membership_id;

  return membership_id;
end;
$$;

create or replace function public.accept_profile_invitation(target_membership_id uuid, invitation_token_hash text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor uuid := public.require_authenticated_account();
  membership public.profile_memberships;
begin
  select * into membership
  from public.profile_memberships
  where id = target_membership_id
  for update;

  if membership.id is null or membership.account_id <> actor or membership.status <> 'invited' then
    raise exception 'VELVET_INVITATION_NOT_AVAILABLE' using errcode='42501';
  end if;

  if membership.invitation_token_hash <> invitation_token_hash then
    raise exception 'VELVET_INVITATION_TOKEN_INVALID' using errcode='42501';
  end if;

  update public.profile_memberships
  set status='active', accepted_at=timezone('utc',now()), invitation_token_hash=null
  where id=target_membership_id;
end;
$$;

revoke all on function public.create_profile(public.profile_type,text,text,char,text) from public;
revoke all on function public.invite_profile_member(uuid,uuid,public.profile_membership_role,text) from public;
revoke all on function public.accept_profile_invitation(uuid,text) from public;
grant execute on function public.create_profile(public.profile_type,text,text,char,text), public.invite_profile_member(uuid,uuid,public.profile_membership_role,text), public.accept_profile_invitation(uuid,text) to authenticated, service_role;

grant select on public.profile_role_permissions to authenticated;
grant all on public.profile_role_permissions to service_role;

commit;
