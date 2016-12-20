-- Revert t_user

BEGIN;

DROP TABLE IF EXISTS my_yacht."user" CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.user_id_seq CASCADE;

COMMIT;
