begin;

create extension if not exists pgtap with schema extensions;

select plan(14);

select has_table('public','accounts','accounts table exists');
select has_table('public','profiles','profiles table exists');
select has_table('public','profile_memberships','profile memberships table exists');
select has_table('public','profile_sensitive_actions','sensitive actions table exists');
select has_table('private','account_identities','private identities table exists');
select has_table('private','identity_verification_cases','private verification cases table exists');

select col_is_pk('public','profiles','id','profiles primary key');
select col_is_fk('public','profiles','created_by_account_id','profiles creator foreign key');
select col_is_fk('public','profile_memberships','profile_id','membership profile foreign key');
select col_is_fk('public','profile_memberships','account_id','membership account foreign key');

select policies_are('public','accounts',array['accounts_select_self','accounts_update_self_limited'],'accounts RLS policies are explicit');
select policies_are('public','profiles',array['profiles_select_member','profiles_select_discoverable'],'profiles RLS policies are explicit');
select policies_are('public','profile_memberships',array['memberships_select_own_profiles'],'membership RLS policy is explicit');
select policies_are('public','profile_sensitive_actions',array['sensitive_actions_select_members'],'sensitive-action RLS policy is explicit');

select * from finish();
rollback;
