begin;

create extension if not exists pgtap with schema extensions;

select plan(22);

select has_table('audit','profile_lifecycle_events','profile lifecycle audit table exists');
select has_type('public','profile_lifecycle_event_type','profile lifecycle event type exists');

select has_function('private','lock_profile',array['uuid'],'profile lock helper exists');
select has_function('private','active_profile_owner_count',array['uuid'],'owner counter exists');
select has_function('private','validate_profile_activation',array['uuid'],'activation validator exists');
select has_function('private','apply_profile_activation',array['uuid','uuid','uuid'],'activation command exists');
select has_function('private','apply_member_departure',array['uuid','uuid','uuid','public.membership_status','uuid'],'member departure command exists');
select has_function('private','apply_ownership_transfer',array['uuid','uuid','uuid','uuid','uuid'],'ownership transfer command exists');
select has_function('private','execute_sensitive_profile_action',array['uuid'],'sensitive action executor exists');
select has_function('private','expire_pending_sensitive_profile_actions',array['integer'],'approval expiry worker exists');

select has_function('public','leave_profile',array['uuid'],'leave profile API exists');
select has_function('public','activate_owned_profile',array['uuid'],'owned profile activation API exists');
select has_function('public','execute_approved_sensitive_profile_action',array['uuid'],'manual idempotent execution API exists');
select has_function('public','cancel_sensitive_profile_action',array['uuid'],'approval cancellation API exists');

select col_is_fk('audit','profile_lifecycle_events','profile_id','audit profile foreign key exists');
select col_is_fk('audit','profile_lifecycle_events','actor_account_id','audit actor foreign key exists');
select col_is_fk('audit','profile_lifecycle_events','subject_account_id','audit subject foreign key exists');
select col_is_fk('audit','profile_lifecycle_events','sensitive_action_id','audit action foreign key exists');

select table_privs_are(
  'audit','profile_lifecycle_events','authenticated',array[]::text[],
  'authenticated users have no direct audit-table privileges'
);

select function_privs_are(
  'public','leave_profile',array['uuid'],'authenticated',array['EXECUTE'],
  'authenticated users can execute leave_profile only'
);

select function_privs_are(
  'private','execute_sensitive_profile_action',array['uuid'],'authenticated',array[]::text[],
  'authenticated users cannot call the private executor directly'
);

select function_privs_are(
  'private','expire_pending_sensitive_profile_actions',array['integer'],'service_role',array['EXECUTE'],
  'service role can run approval expiry batches'
);

select * from finish();
rollback;