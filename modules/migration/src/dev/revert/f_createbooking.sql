-- Revert f_createbooking

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.createbooking(text, timestamp with time zone, timestamp with time zone, integer, text, text, text, text, integer, integer, text) CASCADE;

COMMIT;
