-- Revert f_notify

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.notify(text) CASCADE;

COMMIT;
