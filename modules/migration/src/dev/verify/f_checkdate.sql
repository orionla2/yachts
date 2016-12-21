-- Verify f_checkdate

BEGIN;

SELECT has_function_privilege('my_yacht.checkdate(timestamp with time zone, timestamp with time zone, integer)', 'execute');

ROLLBACK;
