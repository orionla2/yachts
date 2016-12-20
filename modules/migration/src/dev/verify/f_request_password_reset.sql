-- Verify f_request_password_reset

BEGIN;

SELECT has_function_privilege('my_yacht.request_password_reset(text)', 'execute');

ROLLBACK;
