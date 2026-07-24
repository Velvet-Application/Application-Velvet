begin;

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

commit;
