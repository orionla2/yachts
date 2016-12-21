-- Verify f_createbooking

BEGIN;

SELECT has_function_privilege('my_yacht.createbooking(text, timestamp with time zone, timestamp with time zone, integer, text, text, text, text, integer, integer, text)', 'execute');

ROLLBACK;
