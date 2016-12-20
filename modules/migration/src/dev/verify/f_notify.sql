-- Verify f_notify

BEGIN;

SELECT has_function_privilege('my_yacht.notify(text)', 'execute');

ROLLBACK;
