begin;

create extension if not exists pgtap with schema extensions;

select plan(18);

select has_table('public','taxonomy_items','taxonomy table exists');
select has_table('private','account_taxonomy_preferences','private account preferences exist');
select has_table('public','profile_taxonomy_preferences','profile preferences exist');
select has_table('public','profile_boundaries','profile boundaries exist');

select col_is_pk('public','taxonomy_items','id','taxonomy item primary key');
select col_is_fk('public','taxonomy_items','parent_id','taxonomy parent foreign key');
select col_is_fk('private','account_taxonomy_preferences','account_id','private preference account foreign key');
select col_is_fk('private','account_taxonomy_preferences','taxonomy_item_id','private preference taxonomy foreign key');
select col_is_fk('public','profile_taxonomy_preferences','profile_id','profile preference profile foreign key');
select col_is_fk('public','profile_boundaries','profile_id','boundary profile foreign key');

select policies_are('public','taxonomy_items',array['taxonomy_items_select_active'],'taxonomy RLS is explicit');
select policies_are(
  'public','profile_taxonomy_preferences',
  array['profile_taxonomy_preferences_select_members','profile_taxonomy_preferences_select_visible'],
  'profile preference RLS is explicit'
);
select policies_are(
  'public','profile_boundaries',
  array['profile_boundaries_select_members','profile_boundaries_select_visible_matches'],
  'boundary RLS is explicit'
);

select function_returns('public','set_my_taxonomy_preference',array['uuid','preference_level','text','boolean'],'void','private preference command exists');
select function_returns('public','set_profile_taxonomy_preference',array['uuid','uuid','preference_level','boolean'],'void','profile preference command exists');
select function_returns('public','set_profile_boundary',array['uuid','uuid','text','boundary_level','text','boolean'],'uuid','boundary command exists');

select hasnt_table_privilege('authenticated','private','account_taxonomy_preferences','SELECT','private preferences are not client-readable');
select hasnt_table_privilege('authenticated','public','profile_boundaries','INSERT','boundaries cannot be inserted directly');

select * from finish();
rollback;
