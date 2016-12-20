-- Verify f_update_users

BEGIN;

SELECT has_function_privilege('my_yacht.update_users()', 'execute');

ROLLBACK;
