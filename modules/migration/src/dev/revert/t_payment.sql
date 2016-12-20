-- Revert t_payment

BEGIN;

DROP TABLE IF EXISTS my_yacht.payment CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.payment_id_seq CASCADE;

COMMIT;
