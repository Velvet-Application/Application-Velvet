begin;

create type public.compatibility_outcome as enum ('blocked','insufficient_data','low','possible','strong','excellent');

create table public.profile_compatibility_snapshots (
  source_profile_id uuid not null references public.profiles(id) on delete cascade,
  target_profile_id uuid not null references public.profiles(id) on delete cascade,
  outcome public.compatibility_outcome not null,
  score smallint,
  confidence smallint not null default 0,
  blockers jsonb not null default '[]'::jsonb,
  positive_signals jsonb not null default '[]'::jsonb,
  discussion_points jsonb not null default '[]'::jsonb,
  calculation_version text not null,
  calculated_at timestamptz not null default timezone('utc',now()),
  expires_at timestamptz not null,
  primary key(source_profile_id,target_profile_id),
  constraint compatibility_distinct_profiles check (source_profile_id <> target_profile_id),
  constraint compatibility_score_range check (score is null or score between 0 and 100),
  constraint compatibility_confidence_range check (confidence between 0 and 100),
  constraint compatibility_blocked_score check (outcome <> 'blocked' or score is null),
  constraint compatibility_expiry check (expires_at > calculated_at)
);

create index profile_compatibility_target_idx on public.profile_compatibility_snapshots(target_profile_id,outcome,score desc);
create index profile_compatibility_expiry_idx on public.profile_compatibility_snapshots(expires_at);

alter table public.profile_compatibility_snapshots enable row level security;

create policy compatibility_select_source_members
on public.profile_compatibility_snapshots for select to authenticated
using (public.is_active_profile_member(source_profile_id));

revoke insert,update,delete on public.profile_compatibility_snapshots from anon,authenticated;
grant select on public.profile_compatibility_snapshots to authenticated;
grant all on public.profile_compatibility_snapshots to service_role;

create or replace function private.calculate_profile_compatibility(
  source_profile uuid,
  target_profile uuid,
  algorithm_version text default 'db02-v1'
)
returns public.profile_compatibility_snapshots
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  result public.profile_compatibility_snapshots;
  hard_blockers jsonb;
  positives jsonb;
  discussions jsonb;
  compared_count integer;
  compatible_count integer;
  confidence_value smallint;
  score_value smallint;
  outcome_value public.compatibility_outcome;
begin
  if source_profile = target_profile then
    raise exception 'VELVET_COMPATIBILITY_REQUIRES_DISTINCT_PROFILES' using errcode='22023';
  end if;

  if not exists(select 1 from public.profiles where id=source_profile and status='active' and deleted_at is null)
     or not exists(select 1 from public.profiles where id=target_profile and status='active' and deleted_at is null) then
    raise exception 'VELVET_PROFILE_NOT_AVAILABLE' using errcode='22023';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object('taxonomy_item_id',x.taxonomy_item_id,'reason','hard_limit_conflict')),'[]'::jsonb)
  into hard_blockers
  from (
    select distinct b.taxonomy_item_id
    from public.profile_boundaries b
    join public.profile_taxonomy_preferences p
      on p.taxonomy_item_id=b.taxonomy_item_id
     and p.profile_id=case when b.profile_id=source_profile then target_profile else source_profile end
    where b.profile_id in (source_profile,target_profile)
      and b.level='hard_limit'
      and p.level in ('interested','curious','desired','enthusiastic')
  ) x;

  select count(*), count(*) filter(where a.level=b.level or (a.level in ('desired','enthusiastic') and b.level in ('desired','enthusiastic')))
  into compared_count, compatible_count
  from public.profile_taxonomy_preferences a
  join public.profile_taxonomy_preferences b on b.taxonomy_item_id=a.taxonomy_item_id
  where a.profile_id=source_profile and b.profile_id=target_profile;

  select coalesce(jsonb_agg(jsonb_build_object('taxonomy_item_id',a.taxonomy_item_id,'source_level',a.level,'target_level',b.level)),'[]'::jsonb)
  into positives
  from public.profile_taxonomy_preferences a
  join public.profile_taxonomy_preferences b on b.taxonomy_item_id=a.taxonomy_item_id
  where a.profile_id=source_profile and b.profile_id=target_profile
    and a.level in ('desired','enthusiastic') and b.level in ('desired','enthusiastic');

  select coalesce(jsonb_agg(jsonb_build_object('taxonomy_item_id',taxonomy_item_id,'reason','conditional_boundary')),'[]'::jsonb)
  into discussions
  from (
    select distinct taxonomy_item_id from public.profile_boundaries
    where profile_id in(source_profile,target_profile) and level in('conditional','soft_limit') and taxonomy_item_id is not null
  ) d;

  confidence_value := least(100, compared_count * 10)::smallint;

  if jsonb_array_length(hard_blockers)>0 then
    outcome_value := 'blocked'; score_value := null;
  elsif compared_count < 3 then
    outcome_value := 'insufficient_data'; score_value := null;
  else
    score_value := greatest(0,least(100,round((compatible_count::numeric/compared_count::numeric)*100)))::smallint;
    outcome_value := case when score_value>=85 then 'excellent' when score_value>=70 then 'strong' when score_value>=50 then 'possible' else 'low' end;
  end if;

  insert into public.profile_compatibility_snapshots(source_profile_id,target_profile_id,outcome,score,confidence,blockers,positive_signals,discussion_points,calculation_version,expires_at)
  values(source_profile,target_profile,outcome_value,score_value,confidence_value,hard_blockers,positives,discussions,algorithm_version,timezone('utc',now())+interval '24 hours')
  on conflict(source_profile_id,target_profile_id) do update set
    outcome=excluded.outcome, score=excluded.score, confidence=excluded.confidence,
    blockers=excluded.blockers, positive_signals=excluded.positive_signals,
    discussion_points=excluded.discussion_points, calculation_version=excluded.calculation_version,
    calculated_at=timezone('utc',now()), expires_at=excluded.expires_at
  returning * into result;

  return result;
end;
$$;

create or replace function public.refresh_profile_compatibility(source_profile uuid,target_profile uuid)
returns public.profile_compatibility_snapshots
language plpgsql
security definer
set search_path = public,private,pg_temp
as $$
begin
  if not public.is_active_profile_member(source_profile) then
    raise exception 'VELVET_PERMISSION_DENIED' using errcode='42501';
  end if;
  return private.calculate_profile_compatibility(source_profile,target_profile,'db02-v1');
end;
$$;

revoke all on function private.calculate_profile_compatibility(uuid,uuid,text) from public,anon,authenticated;
grant execute on function private.calculate_profile_compatibility(uuid,uuid,text) to service_role;
revoke all on function public.refresh_profile_compatibility(uuid,uuid) from public;
grant execute on function public.refresh_profile_compatibility(uuid,uuid) to authenticated,service_role;

commit;