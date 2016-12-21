-- Revert t_tokens

BEGIN;

DROP TABLE IF EXISTS auth.tokens CASCADE;

COMMIT;
