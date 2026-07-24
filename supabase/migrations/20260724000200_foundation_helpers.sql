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
