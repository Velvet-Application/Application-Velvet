begin;

create extension if not exists pgtap with schema extensions;

select plan(18);

select has_type('public','taxonomy_item_kind','taxonomy item kind enum exists');
select has_type('public','preference_level','preference level enum exists');
select has_type('public','boundary_level','boundary level enum exists');
select has_type('public','compatibility_outcome','compatibility outcome enum exists');

select has_table('public','taxonomy_items','taxonomy table exists');
select has_table('private','account_taxonomy_preferences','private account preferences exist');
select has_table('public','profile_taxonomy_preferences','profile preferences exist');
select has_table('public','profile_boundaries','profile boundaries exist');
select has_table('public','profile_compatibility_snapshots','compatibility snapshots exist');

select policies_are('public','taxonomy_items',array['taxonomy_items_select_active'],'taxonomy RLS is explicit');
select policies_are('public','profile_taxonomy_preferences',array['profile_taxonomy_preferences_select_members','profile_taxonomy_preferences_select_visible'],'profile preference RLS is explicit');
select policies_are('public','profile_boundaries',array['profile_boundaries_select_members','profile_boundaries_select_visible_matches'],'profile boundary RLS is explicit');
select policies_are('public','profile_compatibility_snapshots',array['compatibility_select_source_members'],'compatibility RLS is explicit');

select has_function('public','set_my_taxonomy_preference',array['uuid','public.preference_level','text','boolean'],'personal preference command exists');
select has_function('public','request_couple_preference_change',array['uuid','uuid','public.preference_level','boolean'],'couple preference command exists');
select has_function('public','request_couple_boundary_change',array['uuid','uuid','text','public.boundary_level','text','boolean'],'couple boundary command exists');
select has_function('public','refresh_profile_compatibility',array['uuid','uuid'],'compatibility refresh command exists');
select has_function('private','invalidate_profile_compatibility_snapshots',array['uuid'],'snapshot invalidation helper exists');

select * from finish();
rollback;
