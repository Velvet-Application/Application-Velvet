begin;

create extension if not exists pgtap with schema extensions;
select plan(16);

select has_table('public','media_assets','media assets table exists');
select has_table('public','media_albums','media albums table exists');
select has_table('public','media_album_items','media album items table exists');
select has_table('public','media_access_grants','media access grants table exists');
select has_table('private','media_moderation_cases','private moderation table exists');

select col_is_pk('public','media_assets','id','media assets primary key');
select col_is_fk('public','media_assets','owner_profile_id','media assets owner foreign key');
select col_is_fk('public','media_albums','profile_id','albums profile foreign key');
select col_is_fk('public','media_album_items','album_id','album items album foreign key');
select col_is_fk('public','media_access_grants','grantee_profile_id','grants grantee foreign key');

select policies_are('public','media_assets',array['media_assets_select_owner_members'],'media asset policies explicit');
select policies_are('public','media_albums',array['media_albums_select_owner_members','media_albums_select_public'],'album policies explicit');
select policies_are('public','media_album_items',array['media_album_items_select_authorized'],'album item policies explicit');
select policies_are('public','media_access_grants',array['media_access_grants_select_owner','media_access_grants_select_grantee'],'grant policies explicit');

select function_privs_are('public','grant_album_access',array['uuid','uuid','timestamp with time zone'],'authenticated',array['EXECUTE'],'authenticated can use secure grant command');
select table_privs_are('private','media_moderation_cases','authenticated',array[]::text[],'moderation cases remain private');

select * from finish();
rollback;
