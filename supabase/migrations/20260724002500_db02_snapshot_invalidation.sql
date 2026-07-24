begin;

create or replace function private.invalidate_profile_compatibility_snapshots(target_profile_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.profile_compatibility_snapshots
  where source_profile_id = target_profile_id
     or target_profile_id = target_profile_id;
$$;

create or replace function private.invalidate_compatibility_from_preference_change()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  perform private.invalidate_profile_compatibility_snapshots(coalesce(new.profile_id, old.profile_id));
  return coalesce(new, old);
end;
$$;

create trigger profile_taxonomy_preferences_invalidate_compatibility
  after insert or update or delete on public.profile_taxonomy_preferences
  for each row execute function private.invalidate_compatibility_from_preference_change();

create trigger profile_boundaries_invalidate_compatibility
  after insert or update or delete on public.profile_boundaries
  for each row execute function private.invalidate_compatibility_from_preference_change();

revoke all on function private.invalidate_profile_compatibility_snapshots(uuid) from public, anon, authenticated;
revoke all on function private.invalidate_compatibility_from_preference_change() from public, anon, authenticated;
grant execute on function private.invalidate_profile_compatibility_snapshots(uuid), private.invalidate_compatibility_from_preference_change() to service_role;

commit;
