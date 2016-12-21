-- Verify f_getid

BEGIN;

SELECT has_function_privilege('my_yacht.getid(text)', 'execute');

ROLLBACK;
