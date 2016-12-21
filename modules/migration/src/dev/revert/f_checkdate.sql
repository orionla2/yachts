-- Revert f_checkdate

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.checkdate(timestamp with time zone, timestamp with time zone, integer) CASCADE;
COMMIT;
