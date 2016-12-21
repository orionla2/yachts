-- Verify f_reset_password

BEGIN;

SELECT has_function_privilege('my_yacht.reset_password(text, uuid, text)', 'execute');

ROLLBACK;
