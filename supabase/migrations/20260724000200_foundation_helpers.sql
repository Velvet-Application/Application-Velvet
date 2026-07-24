begin;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.current_auth_user_id()
returns uuid
language sql
stable
security invoker
set search_path = public, auth, pg_temp
as $$
  select auth.uid();
$$;

create or replace function public.current_account_id()
returns uuid
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select a.id
  from public.accounts a
  where a.auth_user_id = auth.uid()
    and a.deleted_at is null
  limit 1;
$$;

comment on function public.current_account_id() is
  'Resolves the current authenticated Supabase user to the canonical Velvet account.';

revoke all on function public.current_account_id() from public;
grant execute on function public.current_account_id() to authenticated, service_role;

create or replace function public.require_authenticated_account()
returns uuid
language plpgsql
stable
security definer
set search_path = public, auth, pg_temp
as $$
declare
  resolved_account_id uuid;
begin
  resolved_account_id := public.current_account_id();

  if resolved_account_id is null then
    raise exception 'VELVET_ACCOUNT_REQUIRED'
      using errcode = '42501';
  end if;

  return resolved_account_id;
end;
$$;

revoke all on function public.require_authenticated_account() from public;
grant execute on function public.require_authenticated_account() to authenticated, service_role;

create or replace function private.request_id()
returns uuid
language sql
volatile
security invoker
set search_path = extensions, pg_temp
as $$
  select gen_random_uuid();
$$;

create or replace function private.assert_service_role()
returns void
language plpgsql
stable
security invoker
set search_path = pg_catalog, pg_temp
as $$
begin
  if coalesce(current_setting('request.jwt.claim.role', true), '') <> 'service_role' then
    raise exception 'VELVET_SERVICE_ROLE_REQUIRED'
      using errcode = '42501';
  end if;
end;
$$;

revoke all on function private.assert_service_role() from public, anon, authenticated;
grant execute on function private.assert_service_role() to service_role;

commit;
