-- Verify t_tokens

BEGIN;

SELECT * FROM auth.tokens WHERE FALSE;

ROLLBACK;
